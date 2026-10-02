# frozen_string_literal: true

# `authorize [:api, :top_page], :index?` で引くヘッドレスポリシー。
class Api::TopPagePolicy < Api::ApplicationPolicy
  def index?
    true
  end
end
