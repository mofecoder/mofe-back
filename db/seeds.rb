# coding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create admin user
admin_user = User.create!(
  name: "admin",
  email: "admin@example.com",
  password: "password",
  password_confirmation: "password",
  role: "admin",
  confirmed_at: Time.current
)
puts "✅ Created admin user: #{admin_user.name}"

# Create sample users
users = []
5.times do |i|
  user = User.create!(
    name: "user#{i + 1}",
    email: "user#{i + 1}@example.com",
    password: "password",
    password_confirmation: "password",
    role: "member",
    atcoder_id: "user#{i + 1}",
    atcoder_rating: rand(400..2800),
    confirmed_at: Time.current
  )
  users << user
  puts "✅ Created user: #{user.name}"
end

# Create writer user
writer_user = User.create!(
  name: "writer",
  email: "writer@example.com",
  password: "password",
  password_confirmation: "password",
  role: "writer",
  confirmed_at: Time.current
)
puts "✅ Created writer user: #{writer_user.name}"

# Create sample contests
past_contest = Contest.create!(
  slug: "sample-contest-2024",
  name: "Sample Contest 2024",
  description: "これはサンプルコンテストです。",
  kind: "normal",
  allow_open_registration: true,
  allow_team_registration: false,
  standings_mode: 1,
  penalty_time: 5,
  start_at: 1.month.ago,
  end_at: 1.month.ago + 3.hours,
  permanent: false,
  official_mode: true
)
puts "✅ Created past contest: #{past_contest.name}"

upcoming_contest = Contest.create!(
  slug: "upcoming-contest",
  name: "Upcoming Contest",
  description: "これから開催されるコンテストです。",
  kind: "normal",
  allow_open_registration: true,
  allow_team_registration: true,
  standings_mode: 1,
  penalty_time: 5,
  start_at: 1.week.from_now,
  end_at: 1.week.from_now + 3.hours,
  permanent: false,
  official_mode: true
)
puts "✅ Created upcoming contest: #{upcoming_contest.name}"

practice_contest = Contest.create!(
  slug: "practice",
  name: "Practice Contest",
  description: "練習用のコンテストです。いつでも参加できます。",
  kind: "normal",
  allow_open_registration: true,
  allow_team_registration: false,
  standings_mode: 1,
  penalty_time: 0,
  start_at: 1.year.ago,
  end_at: nil,
  permanent: true,
  official_mode: false
)
puts "✅ Created practice contest: #{practice_contest.name}"

# Create sample problems
problem_a = Problem.create!(
  slug: "sample-a",
  name: "A + B Problem",
  contest_id: past_contest.id,
  writer_user_id: writer_user.id,
  position: "A",
  uuid: SecureRandom.uuid,
  difficulty: "beginner",
  execution_time_limit: 2000,
  submission_limit_1: 5,
  submission_limit_2: 60,
  statement: "2つの整数 A, B が与えられます。A + B を出力してください。",
  constraints: "1 ≤ A, B ≤ 1000",
  input_format: "A B",
  output_format: "A + B の値"
)
puts "✅ Created problem: #{problem_a.name}"

problem_b = Problem.create!(
  slug: "sample-b",
  name: "Factorial",
  contest_id: past_contest.id,
  writer_user_id: writer_user.id,
  position: "B",
  uuid: SecureRandom.uuid,
  difficulty: "easy",
  execution_time_limit: 2000,
  submission_limit_1: 5,
  submission_limit_2: 60,
  statement: "正の整数 N が与えられます。N! (N の階乗) を出力してください。",
  constraints: "1 ≤ N ≤ 10",
  input_format: "N",
  output_format: "N! の値"
)
puts "✅ Created problem: #{problem_b.name}"

practice_problem = Problem.create!(
  slug: "hello-world",
  name: "Hello World",
  contest_id: practice_contest.id,
  writer_user_id: writer_user.id,
  position: "A",
  uuid: SecureRandom.uuid,
  difficulty: "beginner",
  execution_time_limit: 1000,
  submission_limit_1: 10,
  submission_limit_2: 100,
  statement: "\"Hello World\" を出力してください。",
  constraints: "特になし",
  input_format: "入力はありません。",
  output_format: "Hello World"
)
puts "✅ Created practice problem: #{practice_problem.name}"

# Create testcases for problems
# A + B Problem testcases
testcase_a1 = Testcase.create!(
  problem_id: problem_a.id,
  name: "sample_01",
  input: "1 2",
  output: "3",
  explanation: "1 + 2 = 3"
)

testcase_a2 = Testcase.create!(
  problem_id: problem_a.id,
  name: "sample_02",
  input: "100 200",
  output: "300",
  explanation: "100 + 200 = 300"
)

# Factorial testcases
testcase_b1 = Testcase.create!(
  problem_id: problem_b.id,
  name: "sample_01",
  input: "3",
  output: "6",
  explanation: "3! = 3 × 2 × 1 = 6"
)

testcase_b2 = Testcase.create!(
  problem_id: problem_b.id,
  name: "sample_02",
  input: "5",
  output: "120",
  explanation: "5! = 5 × 4 × 3 × 2 × 1 = 120"
)

# Hello World testcase
testcase_hello = Testcase.create!(
  problem_id: practice_problem.id,
  name: "sample_01",
  input: "",
  output: "Hello World",
  explanation: "Hello World を出力する"
)

puts "✅ Created testcases"

# Create testcase sets
testcase_set_a = TestcaseSet.create!(
  problem_id: problem_a.id,
  name: "All",
  points: 100,
  aggregate_type: 0,
  is_sample: true
)

testcase_set_b = TestcaseSet.create!(
  problem_id: problem_b.id,
  name: "All", 
  points: 100,
  aggregate_type: 0,
  is_sample: true
)

testcase_set_hello = TestcaseSet.create!(
  problem_id: practice_problem.id,
  name: "All",
  points: 100,
  aggregate_type: 0,
  is_sample: true
)

# Associate testcases with testcase sets
TestcaseTestcaseSet.create!(testcase_id: testcase_a1.id, testcase_set_id: testcase_set_a.id)
TestcaseTestcaseSet.create!(testcase_id: testcase_a2.id, testcase_set_id: testcase_set_a.id)
TestcaseTestcaseSet.create!(testcase_id: testcase_b1.id, testcase_set_id: testcase_set_b.id)
TestcaseTestcaseSet.create!(testcase_id: testcase_b2.id, testcase_set_id: testcase_set_b.id)
TestcaseTestcaseSet.create!(testcase_id: testcase_hello.id, testcase_set_id: testcase_set_hello.id)

puts "✅ Created testcase sets and associations"

# Create registrations for past contest
users.each do |user|
  Registration.create!(
    user_id: user.id,
    contest_id: past_contest.id,
    open_registration: true
  )
end
puts "✅ Created registrations for past contest"

# Create some sample submissions
users.first(3).each_with_index do |user, index|
  Submission.create!(
    user_id: user.id,
    problem_id: problem_a.id,
    path: "submissions/#{user.id}/#{problem_a.id}/main.cpp",
    status: index == 0 ? "AC" : ["WA", "TLE", "RE"].sample,
    point: index == 0 ? 100 : 0,
    execution_time: rand(100..1500),
    execution_memory: rand(1000..50000),
    lang: "cpp",
    public: true
  )
end
puts "✅ Created sample submissions"

# Create contest admins
ContestAdmin.create!(
  contest_id: past_contest.id,
  user_id: admin_user.id
)

ContestAdmin.create!(
  contest_id: upcoming_contest.id,
  user_id: admin_user.id
)

ContestAdmin.create!(
  contest_id: practice_contest.id,
  user_id: admin_user.id
)
puts "✅ Created contest admins"

# Create sample posts
Post.create!(
  title: "サイトオープンのお知らせ",
  content: "競技プログラミングオンラインジャッジサイトがオープンしました！\n\nこのサイトでは以下のことができます：\n- プログラミングコンテストに参加\n- 問題の練習\n- 他の参加者との交流\n\nぜひご利用ください！",
  public_status: "public"
)

Post.create!(
  title: "初回コンテスト開催のお知らせ",
  content: "記念すべき第1回コンテストを開催します！\n\n日時：来週の土曜日 20:00-23:00\n難易度：初心者〜中級者向け\n\n皆様のご参加をお待ちしております。",
  public_status: "public"
)
puts "✅ Created sample posts"

puts "🎉 Database seeded successfully!"
puts ""
puts "📊 Summary:"
puts "- Users: #{User.count}"
puts "- Contests: #{Contest.count}"
puts "- Problems: #{Problem.count}"
puts "- Testcases: #{Testcase.count}"
puts "- Submissions: #{Submission.count}"
puts "- Posts: #{Post.count}"