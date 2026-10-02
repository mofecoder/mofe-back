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
end
