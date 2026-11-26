# frozen_string_literal: true

require 'test_helper'

class UploadPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @other_writer = User.create!(name: 'other_writer', email: 'other_writer@example.com',
                                 password: 'password', role: 'writer')
    @writer_upload = Upload.new(user: @writer)
  end

  test "未ログインは NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) { UploadPolicy.new(nil, Upload) }
  end

  test "index? と create? は writer と admin だけ" do
    assert UploadPolicy.new(@admin, Upload).index?
    assert UploadPolicy.new(@writer, Upload).index?
    refute UploadPolicy.new(@member, Upload).index?

    assert UploadPolicy.new(@admin, Upload).create?
    assert UploadPolicy.new(@writer, Upload).create?
    refute UploadPolicy.new(@member, Upload).create?
  end

  test "complete? は本人だけ" do
    assert UploadPolicy.new(@writer, @writer_upload).complete?
    refute UploadPolicy.new(@other_writer, @writer_upload).complete?
    refute UploadPolicy.new(@admin, @writer_upload).complete?
  end

  test "complete? は writer でなくなった本人も拒否する" do
    @writer.role = 'member'
    refute UploadPolicy.new(@writer, @writer_upload).complete?
  end

  test "destroy? は本人と admin" do
    assert UploadPolicy.new(@writer, @writer_upload).destroy?
    assert UploadPolicy.new(@admin, @writer_upload).destroy?
    refute UploadPolicy.new(@other_writer, @writer_upload).destroy?
    refute UploadPolicy.new(@member, @writer_upload).destroy?
  end

  test "Scope は admin でも自分の分だけを返す" do
    mine = create_upload(user: @admin)
    create_upload(user: @writer)

    assert_equal [mine], UploadPolicy::Scope.new(@admin, Upload).resolve.to_a
  end
end
