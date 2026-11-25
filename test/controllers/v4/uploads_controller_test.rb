# frozen_string_literal: true

require 'test_helper'

class V4::UploadsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @other_writer = User.create!(name: 'other_writer', email: 'other_writer@example.com',
                                 password: 'password', role: 'writer')
  end

  def upload_params(data = image_bytes, content_type: 'image/png', byte_size: data.bytesize, filename: 'image.png')
    { upload: { filename: filename, content_type: content_type, byte_size: byte_size,
                checksum: Digest::MD5.base64digest(data) } }
  end

  def post_upload(...)
    post v4_uploads_url, params: upload_params(...), as: :json
  end

  def json
    JSON.parse(response.body)
  end

  # --- 権限 ---

  test "未ログインは 403" do
    get v4_uploads_url
    assert_response :forbidden

    post_upload
    assert_response :forbidden
  end

  test "member は一覧も作成も 403" do
    sign_in_as @member

    get v4_uploads_url
    assert_response :forbidden

    assert_no_difference -> { Upload.count } do
      post_upload
    end
    assert_response :forbidden
  end

  test "未ログインは complete と削除も 403" do
    upload = create_upload(user: @writer)

    post complete_v4_upload_url(upload)
    assert_response :forbidden

    delete v4_upload_url(upload)
    assert_response :forbidden
  end

  # --- 作成 ---

  test "writer は作成でき、署名付き URL とヘッダと公開 URL が返る" do
    sign_in_as @writer
    data = image_bytes

    assert_difference -> { Upload.count } => 1, -> { ActiveStorage::Blob.count } => 1 do
      post_upload(data, filename: '画像.png')
    end
    assert_response :created

    upload = Upload.last
    assert_equal @writer, upload.user
    assert upload.pending?
    assert_equal data.bytesize, upload.blob.byte_size
    assert_equal 'image/png', upload.blob.content_type

    assert_equal upload.id, json.dig('upload', 'id')
    assert_equal '画像.png', json.dig('upload', 'filename')
    assert_equal "https://img.example.test/#{upload.blob.key}", json.dig('upload', 'url')
    assert_equal "https://storage.example.test/direct_uploads/#{upload.blob.key}", json.dig('direct_upload', 'url')
    assert_includes json.dig('direct_upload', 'headers'), { 'name' => 'Content-Type', 'value' => 'image/png' }
  end

  test "admin も作成できる" do
    sign_in_as @admin
    post_upload
    assert_response :created
  end

  # --- 形式とサイズ ---

  test "SVG とテキストは 422" do
    sign_in_as @writer

    %w[image/svg+xml text/plain].each do |type|
      assert_no_difference -> { Upload.count } do
        post_upload(content_type: type)
      end
      assert_response :unprocessable_content
      assert json.dig('details', 'content_type').present?
    end
  end

  test "JPEG / GIF / WebP は作成できる" do
    sign_in_as @writer

    { 'image.jpg' => 'image/jpeg', 'image.gif' => 'image/gif', 'image.webp' => 'image/webp' }.each do |name, type|
      post_upload(image_bytes(name), content_type: type)
      assert_response :created
    end
  end

  test "5 MB を超えると 422、ちょうど 5 MB は作成できる" do
    sign_in_as @writer

    post_upload(byte_size: Upload::MAX_BYTE_SIZE + 1)
    assert_response :unprocessable_content
    assert json.dig('details', 'byte_size').present?

    post_upload(byte_size: Upload::MAX_BYTE_SIZE)
    assert_response :created
  end

  test "admin も 5 MB を超えると 422" do
    sign_in_as @admin
    post_upload(byte_size: Upload::MAX_BYTE_SIZE + 1)
    assert_response :unprocessable_content
  end

  test "サイズ 0 やチェックサムなしは 422" do
    sign_in_as @writer

    post_upload(byte_size: 0)
    assert_response :unprocessable_content

    post v4_uploads_url, params: { upload: { filename: 'a.png', content_type: 'image/png', byte_size: 10 } }, as: :json
    assert_response :unprocessable_content
    assert json.dig('details', 'checksum').present?
  end

  # --- 回数と容量 ---

  test "1 時間に 30 枚を超えると 429" do
    sign_in_as @writer
    insert_uploads(user: @writer, count: Upload::HOURLY_LIMIT - 1)

    post_upload
    assert_response :created

    post_upload
    assert_response :too_many_requests
  end

  test "1 日に 100 枚を超えると 429" do
    sign_in_as @writer
    insert_uploads(user: @writer, count: Upload::DAILY_LIMIT, created_at: 2.hours.ago)

    post_upload
    assert_response :too_many_requests
  end

  test "削除済みの画像も回数に数える" do
    sign_in_as @writer
    insert_uploads(user: @writer, count: Upload::HOURLY_LIMIT, deleted_at: Time.current)

    post_upload
    assert_response :too_many_requests
  end

  test "1 日より前のアップロードは回数に数えない" do
    sign_in_as @writer
    insert_uploads(user: @writer, count: Upload::DAILY_LIMIT, created_at: 25.hours.ago)

    post_upload
    assert_response :created
  end

  test "他のユーザーのアップロードは回数に数えない" do
    sign_in_as @writer
    insert_uploads(user: @other_writer, count: Upload::HOURLY_LIMIT)

    post_upload
    assert_response :created
  end

  test "合計が 1 GB を超えると 422" do
    sign_in_as @writer
    data = image_bytes
    create_upload(user: @writer, status: :completed, byte_size: Upload::QUOTA_BYTES - data.bytesize, put: false)

    post_upload(data)
    assert_response :created

    post_upload(data)
    assert_response :unprocessable_content
  end

  test "削除済みと rejected は容量に数えない" do
    sign_in_as @writer
    create_upload(user: @writer, status: :completed, byte_size: Upload::QUOTA_BYTES, put: false).remove!
    create_upload(user: @writer, status: :rejected, byte_size: Upload::QUOTA_BYTES, put: false)

    post_upload
    assert_response :created
  end

  test "admin は回数と容量の制限を受けない" do
    sign_in_as @admin
    insert_uploads(user: @admin, count: Upload::DAILY_LIMIT)
    create_upload(user: @admin, status: :completed, byte_size: Upload::QUOTA_BYTES, put: false)

    post_upload
    assert_response :created
  end

  test "期限切れの pending は作成時に rejected になり、容量から外れる" do
    sign_in_as @writer
    stale = create_upload(user: @writer, byte_size: Upload::QUOTA_BYTES, put: false,
                          created_at: (Upload::STALE_AFTER + 1.minute).ago)

    post_upload
    assert_response :created
    assert stale.reload.rejected?
    assert_enqueued_with(job: ActiveStorage::PurgeJob)
  end

  # --- 完了時の検証 ---

  test "申告どおりなら completed になる" do
    sign_in_as @writer

    { 'image.png' => 'image/png', 'image.jpg' => 'image/jpeg',
      'image.gif' => 'image/gif', 'image.webp' => 'image/webp' }.each do |name, type|
      upload = create_upload(user: @writer, data: image_bytes(name), content_type: type)

      post complete_v4_upload_url(upload)
      assert_response :success
      assert upload.reload.completed?
      assert_equal 'completed', json['status']
      assert_equal upload.public_url, json['url']
    end
  end

  test "サイズが申告と違うと rejected になり削除される" do
    sign_in_as @writer
    data = image_bytes
    upload = create_upload(user: @writer, data: data, byte_size: data.bytesize + 1)

    assert_enqueued_with(job: ActiveStorage::PurgeJob) do
      post complete_v4_upload_url(upload)
    end
    assert_response :unprocessable_content
    assert upload.reload.rejected?
    refute upload.file.attached?
  end

  test "中身が画像でなければ rejected になる" do
    sign_in_as @writer

    [
      "<svg xmlns=\"http://www.w3.org/2000/svg\"><script>alert(1)</script></svg>",
      "<html><body>hello</body></html>",
      'plain text'
    ].each do |data|
      upload = create_upload(user: @writer, data: data, content_type: 'image/png')

      post complete_v4_upload_url(upload)
      assert_response :unprocessable_content
      assert upload.reload.rejected?
    end
  end

  test "申告と違う形式の画像は rejected になる" do
    sign_in_as @writer
    upload = create_upload(user: @writer, data: image_bytes('image.jpg'), content_type: 'image/png')

    post complete_v4_upload_url(upload)
    assert_response :unprocessable_content
    assert upload.reload.rejected?
  end

  test "PUT していなければ rejected になる" do
    sign_in_as @writer
    upload = create_upload(user: @writer, put: false)

    post complete_v4_upload_url(upload)
    assert_response :unprocessable_content
    assert upload.reload.rejected?
  end

  test "rejected をもう一度 complete しても 422 のまま" do
    sign_in_as @writer
    upload = create_upload(user: @writer, status: :rejected)

    post complete_v4_upload_url(upload)
    assert_response :unprocessable_content
  end

  test "completed をもう一度 complete すると 200" do
    sign_in_as @writer
    upload = create_upload(user: @writer, status: :completed)

    post complete_v4_upload_url(upload)
    assert_response :success
  end

  test "他人のアップロードは admin でも complete できない" do
    upload = create_upload(user: @writer)

    [@other_writer, @admin].each do |user|
      sign_in_as user
      post complete_v4_upload_url(upload)
      assert_response :forbidden
    end
    assert upload.reload.pending?
  end

  # --- 削除 ---

  test "本人は削除できる" do
    sign_in_as @writer
    upload = create_upload(user: @writer, status: :completed)

    assert_enqueued_with(job: ActiveStorage::PurgeJob) do
      delete v4_upload_url(upload)
    end
    assert_response :no_content
    assert Upload.with_discarded.find(upload.id).discarded?
  end

  test "admin は他人の画像も削除できる" do
    sign_in_as @admin
    upload = create_upload(user: @writer, status: :completed)

    delete v4_upload_url(upload)
    assert_response :no_content
    assert Upload.with_discarded.find(upload.id).discarded?
  end

  test "他の writer は削除できない" do
    sign_in_as @other_writer
    upload = create_upload(user: @writer, status: :completed)

    delete v4_upload_url(upload)
    assert_response :forbidden
    refute upload.reload.discarded?
  end

  test "削除済みの画像は 404" do
    sign_in_as @writer
    upload = create_upload(user: @writer, status: :completed)
    upload.remove!

    delete v4_upload_url(upload)
    assert_response :not_found
  end

  # --- 一覧 ---

  test "一覧は自分の completed だけを新しい順に返す" do
    sign_in_as @writer
    old = create_upload(user: @writer, status: :completed)
    recent = create_upload(user: @writer, status: :completed)
    create_upload(user: @writer, status: :pending)
    create_upload(user: @writer, status: :rejected)
    create_upload(user: @writer, status: :completed).remove!
    create_upload(user: @other_writer, status: :completed)

    get v4_uploads_url
    assert_response :success
    assert_equal [recent.id, old.id], json['uploads'].map { |u| u['id'] }
    assert_equal 2, json.dig('meta', 'total_count')
    assert_equal Upload::QUOTA_BYTES, json.dig('meta', 'quota_bytes')
    assert_equal Upload.used_bytes(@writer), json.dig('meta', 'used_bytes')
  end

  test "admin の一覧の quota_bytes は null" do
    sign_in_as @admin

    get v4_uploads_url
    assert_response :success
    assert_nil json.dig('meta', 'quota_bytes')
  end
end
