# frozen_string_literal: true

require 'test_helper'

class Api::ClarificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @contest = contests(:active_contest)
    @problem = problems(:writer_problem)
    @published = clarifications(:published_clarification)
    @unpublished = clarifications(:unpublished_clarification)
  end

  # --- index ---

  test "index returns only published clarifications for anonymous users" do
    get api_contest_clarifications_url(contest_slug: @contest.slug)
    assert_response :success

    ids = JSON.parse(response.body).map { |c| c['id'] }
    assert_includes ids, @published.id
    assert_not_includes ids, @unpublished.id
  end

  test "index returns 404 for an unknown contest" do
    get api_contest_clarifications_url(contest_slug: 'no-such-contest')
    assert_response :not_found
  end

  test "index returns the member's own clarifications" do
    sign_in_as @member
    get api_contest_clarifications_url(contest_slug: @contest.slug)
    assert_response :success

    ids = JSON.parse(response.body).map { |c| c['id'] }
    assert_includes ids, @unpublished.id
  end

  test "index hides other users' unpublished clarifications from a member" do
    @unpublished.update!(user: @writer)

    sign_in_as @member
    get api_contest_clarifications_url(contest_slug: @contest.slug)
    assert_response :success
    assert_not_includes JSON.parse(response.body).map { |c| c['id'] }, @unpublished.id
  end

  test "index returns every clarification for an admin" do
    sign_in_as @admin
    get api_contest_clarifications_url(contest_slug: @contest.slug)
    assert_response :success

    ids = JSON.parse(response.body).map { |c| c['id'] }
    assert_includes ids, @published.id
    assert_includes ids, @unpublished.id
  end

  test "index marks clarifications answerable by an admin" do
    sign_in_as @admin
    get api_contest_clarifications_url(contest_slug: @contest.slug)
    assert_response :success

    body = JSON.parse(response.body).index_by { |c| c['id'] }
    assert body.fetch(@unpublished.id)['can_answer']
  end

  # --- show ---

  test "show returns 401 when not authenticated" do
    get api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id)
    assert_response :unauthorized
  end

  test "show returns 403 for the member who asked the question" do
    sign_in_as @member
    get api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id)
    assert_response :forbidden
  end

  test "show returns 200 for the writer of the related problem" do
    sign_in_as @writer
    get api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id)
    assert_response :success
  end

  test "show returns 200 for an admin" do
    sign_in_as @admin
    get api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id)
    assert_response :success
  end

  test "show returns 403 for a writer when the clarification has no problem" do
    sign_in_as @writer
    get api_contest_clarification_url(contest_slug: @contest.slug, id: @published.id)
    assert_response :forbidden
  end

  # --- create ---

  test "create returns 401 when not authenticated" do
    post api_contest_clarifications_url(contest_slug: @contest.slug),
         params: { clarification: { question: 'Q' } }
    assert_response :unauthorized
  end

  test "create adds a clarification without a task" do
    sign_in_as @member
    assert_difference -> { @contest.clarifications.count }, 1 do
      post api_contest_clarifications_url(contest_slug: @contest.slug),
           params: { clarification: { question: 'General question' } }
    end
    assert_response :created

    body = JSON.parse(response.body)
    assert_nil body['task']
    assert_equal @member.name, body['user']
  end

  test "create adds a clarification tied to a task" do
    sign_in_as @member
    post api_contest_clarifications_url(contest_slug: @contest.slug),
         params: { clarification: { question: 'Task question', task: @problem.slug } }
    assert_response :created
    assert_equal @problem.slug, JSON.parse(response.body).dig('task', 'slug')
  end

  test "create returns 404 for an unknown task" do
    sign_in_as @member
    post api_contest_clarifications_url(contest_slug: @contest.slug),
         params: { clarification: { question: 'Q', task: 'no-such-task' } }
    assert_response :not_found
  end

  # --- update ---

  test "update returns 401 when not authenticated" do
    patch api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id),
          params: { clarification: { answer: 'A' } }
    assert_response :unauthorized
  end

  test "update returns 403 for the member who asked the question" do
    sign_in_as @member
    patch api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id),
          params: { clarification: { answer: 'A' } }
    assert_response :forbidden
  end

  test "update answers the clarification for an admin" do
    sign_in_as @admin
    patch api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id),
          params: { clarification: { answer: 'Answer', publish: true } }
    assert_response :no_content

    @unpublished.reload
    assert_equal 'Answer', @unpublished.answer
    assert @unpublished.publish
  end

  test "update answers the clarification for the writer of the related problem" do
    sign_in_as @writer
    patch api_contest_clarification_url(contest_slug: @contest.slug, id: @unpublished.id),
          params: { clarification: { answer: 'Answer' } }
    assert_response :no_content
  end
end
