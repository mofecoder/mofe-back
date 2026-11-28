ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

# Load support files
Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  include UploadTestHelper
  include JudgeLanguagesHelper

  # レート制限のカウントなどがテスト間で持ち越されないようにする
  setup { Rails.cache.clear }
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
