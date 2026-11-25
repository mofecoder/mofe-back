# 問題文などの Markdown に貼る画像
#
# ブラウザがストレージ (本番は Cloudflare R2) へ署名付き URL で直接 PUT する。
# 1. create で blob と pending の Upload を作り、署名付き URL を返す
# 2. ブラウザが PUT する
# 3. complete でオブジェクトのサイズと先頭バイトを確かめ、completed か rejected にする
class Upload < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_BYTE_SIZE = 5.megabytes
  HOURLY_LIMIT = 30
  DAILY_LIMIT = 100
  QUOTA_BYTES = 1.gigabyte
  # 署名付き URL の有効期限 (ActiveStorage.service_urls_expire_in、既定 5 分) より十分長くする
  STALE_AFTER = 1.hour
  # 形式の判定に読む先頭のバイト数
  HEAD_BYTES = 512
  # Active Storage と同じ、MD5 の Base64 表現
  CHECKSUM_FORMAT = %r{\A[A-Za-z0-9+/]{22}==\z}

  # 回数や容量の上限に達したときの例外
  class LimitExceeded < StandardError
    attr_reader :status

    def initialize(message, status:)
      super(message)
      @status = status
    end
  end

  belongs_to :user
  has_one_attached :file

  enum :status, { pending: 'pending', completed: 'completed', rejected: 'rejected' }

  # 署名付き URL の期限が切れても完了しなかったもの
  scope :stale_pending, -> { pending.where(created_at: ...STALE_AFTER.ago) }

  attr_reader :rejection_reason

  class << self
    # アップロードの申告内容を確かめる。問題がなければ空の Hash を返す
    # @return [Hash{Symbol => Array<String>}]
    def request_errors(filename:, content_type:, byte_size:, checksum:)
      errors = Hash.new { |h, k| h[k] = [] }
      if filename.blank?
        errors[:filename] << 'ファイル名を指定してください。'
      elsif filename.length > 255
        errors[:filename] << 'ファイル名は 255 文字以内にしてください。'
      end
      unless ALLOWED_CONTENT_TYPES.include?(content_type)
        errors[:content_type] << 'アップロードできるのは PNG / JPEG / GIF / WebP の画像だけです。'
      end
      if byte_size.nil? || byte_size <= 0
        errors[:byte_size] << 'ファイルサイズが不正です。'
      elsif byte_size > MAX_BYTE_SIZE
        errors[:byte_size] << "ファイルサイズは #{MAX_BYTE_SIZE / 1.megabyte} MB 以下にしてください。"
      end
      unless checksum.is_a?(String) && checksum.match?(CHECKSUM_FORMAT)
        errors[:checksum] << 'チェックサムが不正です。'
      end
      errors.to_h
    end

    # 回数と容量の上限を確かめる。admin は対象外
    # @raise [LimitExceeded]
    def check_limits!(user, byte_size)
      return if user.admin?

      now = Time.current
      if created_count(user, since: now - 1.hour) >= HOURLY_LIMIT
        raise LimitExceeded.new("1 時間にアップロードできる画像は #{HOURLY_LIMIT} 枚までです。", status: :too_many_requests)
      end
      if created_count(user, since: now - 1.day) >= DAILY_LIMIT
        raise LimitExceeded.new("1 日にアップロードできる画像は #{DAILY_LIMIT} 枚までです。", status: :too_many_requests)
      end
      if used_bytes(user) + byte_size > QUOTA_BYTES
        raise LimitExceeded.new("アップロードできる画像の合計は #{QUOTA_BYTES / 1.gigabyte} GB までです。不要な画像を削除してください。",
                                status: :unprocessable_content)
      end
    end

    # 指定の時刻以降に作ったアップロードの数
    # 削除して再アップロードすれば回避できてしまわないよう、削除済みや rejected も数える
    def created_count(user, since:)
      with_discarded.where(user: user, created_at: since..).count
    end

    # 使用中の容量 (バイト)。pending も予約として数える
    # 削除済みのものは attachment が消えているので含まれない
    def used_bytes(user)
      ActiveStorage::Blob.joins(:attachments).where(
        active_storage_attachments: {
          record_type: name,
          name: 'file',
          record_id: where(user: user).where.not(status: :rejected).select(:id)
        }
      ).sum(:byte_size)
    end
  end

  def blob
    file.blob
  end

  # Markdown に貼る公開 URL。rails_blob_url は閲覧のたびに API を通り、
  # secret_key_base を入れ替えるとリンク切れになるので使わない
  def public_url
    return nil unless blob

    "#{Rails.configuration.x.uploads.public_base_url.to_s.chomp('/')}/#{blob.key}"
  end

  # ブラウザがストレージへ PUT するための URL とヘッダ
  # ヘッダは { name:, value: } の配列で返す (フロントがレスポンスのキーを camelCase に変換するため)
  def direct_upload
    {
      url: blob.service_url_for_direct_upload,
      headers: blob.service_headers_for_direct_upload.compact.map { |name, value| { name: name, value: value } }
    }
  end

  # ストレージ上のオブジェクトを確かめて completed にする
  # 申告と違えば rejected にして削除し、false を返す (理由は rejection_reason)
  def complete!
    reason = verification_error
    if reason
      reject!(reason)
      false
    else
      update!(status: :completed)
      true
    end
  end

  # rejected にしてストレージのオブジェクトを削除する
  # async: false は rake task などジョブを待てない場所から呼ぶとき
  def reject!(reason = nil, async: true)
    @rejection_reason = reason
    update!(status: :rejected)
    purge_file(async: async)
  end

  # 論理削除してストレージのオブジェクトを削除する
  def remove!
    discard!
    purge_file
  end

  private

  def purge_file(async: true)
    return unless file.attached?

    async ? file.purge_later : file.purge
  end

  # @return [String, nil] 問題があればその理由
  def verification_error
    return 'ファイルが見つかりません。' unless blob

    size = stored_byte_size
    return '画像のアップロードが完了していません。' if size.nil?
    return 'ファイルサイズが申告と違います。' if size != blob.byte_size

    # 名前や申告の形式を渡すと、判定できないときにそちらへフォールバックするので io だけを渡す
    head = blob.service.download_chunk(blob.key, 0...[HEAD_BYTES, size].min)
    detected = Marcel::MimeType.for(StringIO.new(head))
    return '画像の形式が申告と違います。' if detected != blob.content_type
    return 'アップロードできない形式です。' unless ALLOWED_CONTENT_TYPES.include?(detected)

    nil
  end

  # ストレージ上のオブジェクトのサイズ。なければ nil
  # Active Storage のサービスにはサイズを取る共通の API がないので、使うサービスごとに取る
  def stored_byte_size
    service = blob.service
    case service.class.name
    when 'ActiveStorage::Service::S3Service'
      begin
        service.bucket.object(blob.key).content_length
      rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
        nil
      end
    when 'ActiveStorage::Service::DiskService'
      path = service.path_for(blob.key)
      File.exist?(path) ? File.size(path) : nil
    else
      raise NotImplementedError, "#{service.class.name} には対応していません"
    end
  end
end
