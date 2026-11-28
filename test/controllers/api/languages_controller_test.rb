# frozen_string_literal: true

require 'test_helper'

class Api::LanguagesControllerTest < ActionDispatch::IntegrationTest
  def index_with(mode)
    with_judge_languages(mode) { get api_languages_url }
    assert_response :success
    JSON.parse(response.body)
  end

  test "index returns every language to anonymous users" do
    body = index_with('new')
    assert_equal Rails.application.config.x.languages.size, body.size
    assert body.any? { |l| l['active'] }
    assert body.any? { |l| !l['active'] }, '過去の提出の表示に使う旧言語も返す'
    assert body.none? { |l| l['legacy'] }

    cpp = body.find { |l| l['key'] == 'cpp23' }
    assert_equal %w[active aliases compile_command key legacy libraries mime name run_command], cpp.keys.sort
    assert_includes cpp['aliases'], { 'lang' => 'cpp23_gcc:12.2.0', 'name' => 'C++23 (g++ 12.2.0)' }
    assert_equal './Main', cpp['run_command']
    assert_equal true, cpp['active']
  end

  # 新旧のジャッジの並行運用（S8b）
  test "index adds the languages of the legacy judge at the end in both" do
    body = index_with('both')
    legacy = body.select { |l| l['legacy'] }
    assert_equal 19, legacy.size
    assert_equal legacy, body.last(19)
    old = body.find { |l| l['key'] == 'cpp23_gcc:12.2.0' }
    assert_equal ['【旧】C++23 (g++ 12.2.0)', true, nil, nil, ''],
                 old.values_at('name', 'active', 'compile_command', 'run_command', 'libraries')
    assert_equal true, body.find { |l| l['key'] == 'cpp23' }['active']
  end

  test "index offers only the languages of the legacy judge in old" do
    body = index_with('old')
    assert_equal body.select { |l| l['legacy'] }, body.select { |l| l['active'] }
    assert_equal 'C++23 (g++ 12.2.0)', body.find { |l| l['key'] == 'cpp23_gcc:12.2.0' }['name']
    assert_equal false, body.find { |l| l['key'] == 'cpp23' }['active']
  end
end
