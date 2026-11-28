# frozen_string_literal: true

require 'test_helper'

class Api::LanguagesControllerTest < ActionDispatch::IntegrationTest
  test "index returns every language to anonymous users" do
    get api_languages_url
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal Language.all.size, body.size
    assert body.any? { |l| l['active'] }
    assert body.any? { |l| !l['active'] }, '過去の提出の表示に使う旧言語も返す'

    cpp = body.find { |l| l['key'] == 'cpp23' }
    assert_equal %w[active aliases compile_command key libraries mime name run_command], cpp.keys.sort
    assert_includes cpp['aliases'], { 'lang' => 'cpp23_gcc:12.2.0', 'name' => 'C++23 (g++ 12.2.0)' }
    assert_equal './Main', cpp['run_command']
  end
end
