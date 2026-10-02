ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

# GCS の credentials を持たない環境 (CI など) では実クライアントの読み込みが
# 失敗するため、テスト用のスタブモジュールで代替する。
unless Rails.application.credentials.gcs
  Utils.const_set(:GoogleCloudStorageClient, Module.new do
    def self.get_source(_path) = raise NotImplementedError, 'stub in tests'
  end)
end

# Load support files
Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
