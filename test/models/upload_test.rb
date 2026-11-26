# frozen_string_literal: true

require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @writer = users(:writer_user)
    @admin = users(:admin_user)
  end

  test "public_url は公開 URL のベースと blob の key から組み立てる" do
    upload = create_upload(user: @writer)
    assert_equal "https://img.example.test/#{upload.blob.key}", upload.public_url
  end

  test "direct_upload のヘッダは name と value の配列で返す" do
    upload = create_upload(user: @writer, put: false)
    headers = upload.direct_upload[:headers]
    assert_includes headers, { name: 'Content-Type', value: 'image/png' }
    assert(headers.all? { |h| h.keys == %i[name value] })
  end

  test "used_bytes は pending と completed を数え、rejected と削除済みは数えない" do
    create_upload(user: @writer, status: :completed, byte_size: 100, put: false)
    create_upload(user: @writer, status: :pending, byte_size: 20, put: false)
    create_upload(user: @writer, status: :rejected, byte_size: 3000, put: false)
    create_upload(user: @writer, byte_size: 4000, put: false).remove!
    create_upload(user: @admin, byte_size: 50_000, put: false)

    assert_equal 120, Upload.used_bytes(@writer)
  end

  test "created_count は削除済みと rejected も数え、期間外は数えない" do
    insert_uploads(user: @writer, count: 2)
    insert_uploads(user: @writer, count: 3, deleted_at: Time.current)
    insert_uploads(user: @writer, count: 4, created_at: 2.hours.ago)

    assert_equal 5, Upload.created_count(@writer, since: 1.hour.ago)
    assert_equal 9, Upload.created_count(@writer, since: 1.day.ago)
  end

  test "request_errors は許可した形式とサイズだけを通す" do
    valid = { filename: 'a.png', content_type: 'image/png', byte_size: 10, checksum: 'xa8dDrGe6LnRYHjHqFXv5Q==' }
    assert_empty Upload.request_errors(**valid)

    %w[image/png image/jpeg image/gif image/webp].each do |type|
      assert_empty Upload.request_errors(**valid, content_type: type)
    end
    assert_includes Upload.request_errors(**valid, content_type: 'image/svg+xml').keys, :content_type
    assert_includes Upload.request_errors(**valid, byte_size: Upload::MAX_BYTE_SIZE + 1).keys, :byte_size
    assert_empty Upload.request_errors(**valid, byte_size: Upload::MAX_BYTE_SIZE)
    assert_includes Upload.request_errors(**valid, checksum: 'abc').keys, :checksum
  end

  test "remove! は論理削除してファイルの削除を enqueue する" do
    upload = create_upload(user: @writer, status: :completed)

    assert_enqueued_with(job: ActiveStorage::PurgeJob) { upload.remove! }
    assert upload.discarded?
    refute Upload.with_discarded.find(upload.id).file.attached?
  end

  test "reject!(async: false) はストレージからすぐに削除する" do
    upload = create_upload(user: @writer)
    blob = upload.blob

    upload.reject!(async: false)
    assert upload.rejected?
    refute stored?(blob)
    refute ActiveStorage::Blob.exists?(blob.id)
  end
end
