# 画像アップロード
# 画像そのものはブラウザがストレージへ直接 PUT するので、ここでは記録と検証だけを行う
class V4::UploadsController < V4::ApplicationController
  PER_PAGE = 50

  before_action :set_upload, only: %i[complete destroy]

  # 自分のアップロード (completed) の一覧
  def index
    authorize Upload

    uploads = policy_scope(Upload).completed.order(id: :desc).page(params[:page]).per(PER_PAGE)
    render json: {
      uploads: UploadBlueprint.render_as_hash(uploads),
      meta: {
        total_count: uploads.total_count,
        page: uploads.current_page,
        per_page: PER_PAGE,
        used_bytes: Upload.used_bytes(current_user),
        # admin は無制限
        quota_bytes: current_user.admin? ? nil : Upload::QUOTA_BYTES
      }
    }
  end

  # blob と pending の記録を作り、ストレージへ PUT するための署名付き URL とヘッダを返す
  def create
    authorize Upload

    attrs = upload_attributes
    errors = Upload.request_errors(**attrs)
    if errors.any?
      render_api_error(errors.values.flatten.join("\n"), status: :unprocessable_content, details: errors)
      return
    end

    # 期限切れの pending を容量の集計から外す (上限超過でロールバックされないよう、ロックの外で行う)
    Upload.where(user: current_user).stale_pending.find_each(&:reject!)

    # 同じユーザーの同時リクエストで上限を超えないよう、ユーザーの行をロックして集計から作成までを直列にする
    upload = current_user.with_lock do
      Upload.check_limits!(current_user, attrs[:byte_size])

      blob = ActiveStorage::Blob.create_before_direct_upload!(**attrs)
      # PUT の前に添付するので、Active Storage が添付時に行う形式の判定 (オブジェクトを読みにいく) を止める。
      # 形式は complete で先頭バイトから判定する
      blob.identified = true
      Upload.create!(user: current_user, file: blob)
    end

    render json: {
      upload: UploadBlueprint.render_as_hash(upload),
      direct_upload: upload.direct_upload
    }, status: :created
  rescue Upload::LimitExceeded => e
    render_api_error(e.message, status: e.status)
  end

  # PUT の完了通知。ストレージ上のオブジェクトを確かめる
  def complete
    authorize @upload

    @upload.with_lock do
      if @upload.rejected?
        render_api_error('このアップロードは無効になっています。', status: :unprocessable_content)
      elsif @upload.completed? || @upload.complete!
        render json: UploadBlueprint.render(@upload)
      else
        render_api_error(@upload.rejection_reason, status: :unprocessable_content)
      end
    end
  end

  def destroy
    authorize @upload

    @upload.remove!
    head :no_content
  end

  private

  # admin が他人の画像を削除できるよう、policy_scope を通さずに探してから authorize する
  def set_upload
    @upload = Upload.find(params[:id])
  end

  def upload_attributes
    permitted = params.fetch(:upload, {}).permit(:filename, :content_type, :byte_size, :checksum)
    {
      filename: permitted[:filename].presence,
      content_type: permitted[:content_type].presence,
      byte_size: Integer(permitted[:byte_size].to_s, 10, exception: false),
      checksum: permitted[:checksum].presence
    }
  end
end
