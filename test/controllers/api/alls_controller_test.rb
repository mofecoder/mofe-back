require 'test_helper'

class Api::AllsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get api_alls_show_url
    assert_response :success
  end

end
