# frozen_string_literal: true

require 'test_helper'

class CodeTestControllerTest < ActionDispatch::IntegrationTest
  # CodeTestController は before_action :authenticate_user! のみでアクションが未実装、
  # config/routes.rb にもルートが存在しないためテスト対象がない。
  # アクションが実装されたらここにテストを追加すること。
end
