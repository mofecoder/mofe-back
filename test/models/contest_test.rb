require 'test_helper'

class ContestTest < ActiveSupport::TestCase
  def build_contest(**attrs)
    Contest.new({ name: 'C', slug: 'c-test', kind: 'normal',
                  start_at: 1.day.ago, end_at: 1.day.from_now }.merge(attrs))
  end

  test "valid with start_at and end_at" do
    assert build_contest.valid?
  end

  test "requires start_at" do
    c = build_contest(start_at: nil)
    assert_not c.valid?
    assert c.errors.of_kind?(:start_at, :blank)
  end

  test "requires end_at" do
    c = build_contest(end_at: nil)
    assert_not c.valid?
    assert c.errors.of_kind?(:end_at, :blank)
  end

  test "end_at must be after start_at" do
    t = Time.zone.now
    assert_not build_contest(start_at: t, end_at: t).valid?
    assert_not build_contest(start_at: t, end_at: t - 1.hour).valid?
  end


  # --- teammate_user_ids ---

  test "teammate_user_ids returns [] when not in a team or nil" do
    contest = contests(:active_contest)
    assert_equal [], contest.teammate_user_ids(users(:member_user))
    assert_equal [], contest.teammate_user_ids(nil)
  end

  test "teammate_user_ids returns all members including self, excluding discarded" do
    contest = contests(:active_contest)
    other = User.create!(
      name: 'mate', email: 'mate@example.com', password: 'password', password_confirmation: 'password',
      provider: 'email', uid: 'mate@example.com', role: 'member'
    )
    gone = User.create!(
      name: 'gone', email: 'gone@example.com', password: 'password', password_confirmation: 'password',
      provider: 'email', uid: 'gone@example.com', role: 'member'
    )
    team = TeamRegistration.create!(contest: contest, name: 'team_a', passphrase: 'pass')
    [users(:member_user), other, gone].each { |u| team.team_registration_users.create!(user: u) }
    team.team_registration_users.find_by!(user: gone).discard

    assert_equal [users(:member_user).id, other.id].sort, contest.teammate_user_ids(users(:member_user)).sort
  end
end
