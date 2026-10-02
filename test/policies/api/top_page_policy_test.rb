# frozen_string_literal: true

require 'test_helper'

class Api::TopPagePolicyTest < ActiveSupport::TestCase
  test "index? permits everyone including anonymous users" do
    assert Api::TopPagePolicy.new(nil, :top_page).index?
    assert Api::TopPagePolicy.new(users(:member_user), :top_page).index?
    assert Api::TopPagePolicy.new(users(:admin_user), :top_page).index?
  end
end
