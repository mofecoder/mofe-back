# frozen_string_literal: true

require 'digest'

module UploadTestHelper
  def image_bytes(name = 'image.png')
    File.binread(file_fixture(name))
  end

  # blob と Upload を作る。put: true ならブラウザからの PUT の代わりにストレージへ直接書き込む
  # byte_size と content_type を data と違う値にすると、申告と違うアップロードを再現できる
  def create_upload(user:, data: image_bytes, content_type: 'image/png', byte_size: data.bytesize,
                    put: true, status: :pending, created_at: Time.current)
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: 'image.png', byte_size: byte_size,
      checksum: Digest::MD5.base64digest(data), content_type: content_type
    )
    blob.identified = true
    blob.service.upload(blob.key, StringIO.new(data)) if put
    Upload.create!(user: user, file: blob, status: status, created_at: created_at)
  end

  # 回数の制限のテスト用。ファイルなしで Upload の行だけを作る
  def insert_uploads(user:, count:, created_at: Time.current, deleted_at: nil)
    rows = Array.new(count) do
      { user_id: user.id, status: 'completed', created_at: created_at, updated_at: created_at, deleted_at: deleted_at }
    end
    Upload.insert_all(rows)
  end

  def stored?(blob)
    blob.service.exist?(blob.key)
  end
end
