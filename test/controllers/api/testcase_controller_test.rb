# frozen_string_literal: true

require 'test_helper'

class Api::TestcaseControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @problem = problems(:writer_problem)
    @testcase = testcases(:one)
    @testcase_set = testcase_sets(:one)
  end

  # 作成・更新・アップロードは Google Cloud Storage にアクセスするため、
  # 早期リターンするケース以外はテストしない。

  # --- authenticate_writer! ---

  test "index returns 401 when not authenticated" do
    get api_problem_testcases_url(problem_id: @problem.id)
    assert_response :unauthorized
  end

  test "index returns 403 for a member" do
    sign_in_as @member
    get api_problem_testcases_url(problem_id: @problem.id)
    assert_response :forbidden
  end

  test "index returns 403 for a writer who does not own the problem" do
    sign_in_as @writer
    get api_problem_testcases_url(problem_id: problems(:admin_problem).id)
    assert_response :forbidden
  end

  # --- index ---

  test "index returns testcases and testcase sets for the problem writer" do
    sign_in_as @writer
    get api_problem_testcases_url(problem_id: @problem.id)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal [@testcase_set.id], body['testcase_sets'].map { |s| s['id'] }
    assert_equal [@testcase.id], body['testcases'].map { |t| t['id'] }
    # testcase_sets の並び順に対応した所属フラグが返る
    assert_equal [true], body['testcases'].first['testcase_sets']
  end

  test "index returns 200 for an admin" do
    sign_in_as @admin
    get api_problem_testcases_url(problem_id: @problem.id)
    assert_response :success
  end

  # --- show ---

  test "show returns the testcase for the problem writer" do
    sign_in_as @writer
    get api_problem_testcase_url(problem_id: @problem.id, id: @testcase.id)
    assert_response :success
    assert_equal @testcase.name, JSON.parse(response.body)['name']
  end

  test "show returns 404 for a testcase of another problem" do
    sign_in_as @admin
    get api_problem_testcase_url(problem_id: @problem.id, id: testcases(:two).id)
    assert_response :not_found
  end

  # --- create ---

  test "create returns 400 for a duplicated testcase name" do
    sign_in_as @writer
    post api_problem_testcases_url(problem_id: @problem.id),
         params: { testcase: { name: @testcase.name, input: 'a', output: 'b' } }
    assert_response :bad_request
  end

  # --- destroy ---

  test "destroy soft-deletes the testcase" do
    sign_in_as @writer
    delete api_problem_testcase_url(problem_id: @problem.id, id: @testcase.id)
    assert_response :no_content

    assert_not Testcase.exists?(@testcase.id)
    assert Testcase.with_discarded.exists?(@testcase.id)
  end

  # --- delete_multiple ---

  test "delete_multiple soft-deletes the given testcases" do
    sign_in_as @writer
    delete delete_multiple_api_problem_testcases_url(problem_id: @problem.id),
           params: { testcases: [@testcase.id] }
    assert_response :no_content
    assert_not Testcase.exists?(@testcase.id)
  end

  # --- change_state ---

  # params[:state] は真偽値として評価されるため、フォーム形式だと文字列 "false" が
  # 真になってしまう。フロントエンドと同じく JSON で送る。
  test "change_state detaches the testcase from the set when state is false" do
    sign_in_as @writer
    assert_difference -> { TestcaseTestcaseSet.count }, -1 do
      patch change_state_api_problem_testcase_url(problem_id: @problem.id, id: @testcase.id),
            params: { testcase_set_id: @testcase_set.id, state: false }, as: :json
    end
    assert_response :no_content
  end

  test "change_state is a no-op when the testcase is already in the set" do
    sign_in_as @writer
    assert_no_difference -> { TestcaseTestcaseSet.count } do
      patch change_state_api_problem_testcase_url(problem_id: @problem.id, id: @testcase.id),
            params: { testcase_set_id: @testcase_set.id, state: true }, as: :json
    end
    assert_response :no_content
  end

  test "change_state returns 404 for a testcase set of another problem" do
    sign_in_as @admin
    patch change_state_api_problem_testcase_url(problem_id: @problem.id, id: @testcase.id),
          params: { testcase_set_id: testcase_sets(:two).id, state: true }, as: :json
    assert_response :not_found
  end

  # --- change_state_multiple ---

  test "change_state_multiple attaches the testcases to the set" do
    set = @problem.testcase_sets.create!(name: 'extra', points: 10, is_sample: false)

    sign_in_as @writer
    assert_difference -> { TestcaseTestcaseSet.count }, 1 do
      patch change_state_multiple_api_problem_testcases_url(problem_id: @problem.id),
            params: { testcase_ids: [@testcase.id], testcase_set_id: set.id }
    end
    assert_response :no_content
  end
end
