# frozen_string_literal: true

# Test-only authentication stub.
# Allows controller tests to authenticate by setting Thread.current[:test_current_user]
# without depending on Devise Token Auth headers.
if Rails.env.test?
  Rails.application.config.to_prepare do
    ApplicationController.prepend(Module.new do
      def current_user
        Thread.current[:test_current_user] || super
      end

      def authenticate_user!
        return true if Thread.current[:test_current_user]
        super
      end

      def authenticate_api_user!
        return true if Thread.current[:test_current_user]
        super
      end

      def user_signed_in?
        Thread.current[:test_current_user].present? || super
      end
    end)
  end
end
