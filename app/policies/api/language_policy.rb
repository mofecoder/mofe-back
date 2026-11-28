# frozen_string_literal: true

# `authorize [:api, :language], :index?` で引くヘッドレスポリシー。
class Api::LanguagePolicy < Api::ApplicationPolicy
  def index?
    true
  end
end
