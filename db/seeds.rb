# coding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
# This file is idempotent — safe to run multiple times.

puts "🌱 Seeding database..."

# Create admin user
admin_user = User.find_or_initialize_by(name: "admin")
if admin_user.new_record?
  admin_user.assign_attributes(
    email: "admin@example.com",
    password: "password",
    password_confirmation: "password",
    role: "admin",
    confirmed_at: Time.current
  )
  admin_user.save!
  puts "✅ Created admin user: #{admin_user.name}"
else
  puts "⏭️  Admin user already exists: #{admin_user.name}"
end

# Create sample users
users = []
5.times do |i|
  user = User.find_or_initialize_by(name: "user#{i + 1}")
  if user.new_record?
    user.assign_attributes(
      email: "user#{i + 1}@example.com",
      password: "password",
      password_confirmation: "password",
      role: "member",
      atcoder_id: "user#{i + 1}",
      atcoder_rating: rand(400..2800),
      confirmed_at: Time.current
    )
    user.save!
    puts "✅ Created user: #{user.name}"
  else
    puts "⏭️  User already exists: #{user.name}"
  end
  users << user
end

# Create writer user
writer_user = User.find_or_initialize_by(name: "writer")
if writer_user.new_record?
  writer_user.assign_attributes(
    email: "writer@example.com",
    password: "password",
    password_confirmation: "password",
    role: "writer",
    confirmed_at: Time.current
  )
  writer_user.save!
  puts "✅ Created writer user: #{writer_user.name}"
else
  puts "⏭️  Writer user already exists: #{writer_user.name}"
end

# Create sample contests
past_contest = Contest.find_or_create_by!(slug: "sample-contest-2024") do |c|
  c.name = "Sample Contest 2024"
  c.description = "これはサンプルコンテストです。"
  c.kind = "normal"
  c.allow_open_registration = true
  c.allow_team_registration = false
  c.standings_mode = :atcoder
  c.penalty_time = 5
  c.start_at = 1.month.ago
  c.end_at = 1.month.ago + 3.hours
  c.permanent = false
  c.official_mode = true
end
puts "✅ Contest: #{past_contest.name}"

upcoming_contest = Contest.find_or_create_by!(slug: "upcoming-contest") do |c|
  c.name = "Upcoming Contest"
  c.description = "これから開催されるコンテストです。"
  c.kind = "normal"
  c.allow_open_registration = true
  c.allow_team_registration = true
  c.standings_mode = :atcoder
  c.penalty_time = 5
  c.start_at = 1.week.from_now
  c.end_at = 1.week.from_now + 3.hours
  c.permanent = false
  c.official_mode = true
end
puts "✅ Contest: #{upcoming_contest.name}"

practice_contest = Contest.find_or_create_by!(slug: "practice") do |c|
  c.name = "Practice Contest"
  c.description = "練習用のコンテストです。いつでも参加できます。"
  c.kind = "normal"
  c.allow_open_registration = true
  c.allow_team_registration = false
  c.standings_mode = :atcoder
  c.penalty_time = 0
  c.start_at = 1.year.ago
  c.end_at = nil
  c.permanent = true
  c.official_mode = false
end
puts "✅ Contest: #{practice_contest.name}"

# Create sample problems
problem_a = Problem.find_or_create_by!(slug: "sample-a") do |p|
  p.name = "A + B Problem"
  p.contest_id = past_contest.id
  p.writer_user_id = writer_user.id
  p.position = "A"
  p.uuid = SecureRandom.uuid
  p.difficulty = "beginner"
  p.execution_time_limit = 2000
  p.submission_limit_1 = 5
  p.submission_limit_2 = 60
  p.statement = "2つの整数 A, B が与えられます。A + B を出力してください。"
  p.constraints = "1 ≤ A, B ≤ 1000"
  p.input_format = "A B"
  p.output_format = "A + B の値"
end
puts "✅ Problem: #{problem_a.name}"

problem_b = Problem.find_or_create_by!(slug: "sample-b") do |p|
  p.name = "Factorial"
  p.contest_id = past_contest.id
  p.writer_user_id = writer_user.id
  p.position = "B"
  p.uuid = SecureRandom.uuid
  p.difficulty = "easy"
  p.execution_time_limit = 2000
  p.submission_limit_1 = 5
  p.submission_limit_2 = 60
  p.statement = "正の整数 N が与えられます。N! (N の階乗) を出力してください。"
  p.constraints = "1 ≤ N ≤ 10"
  p.input_format = "N"
  p.output_format = "N! の値"
end
puts "✅ Problem: #{problem_b.name}"

practice_problem = Problem.find_or_create_by!(slug: "hello-world") do |p|
  p.name = "Hello World"
  p.contest_id = practice_contest.id
  p.writer_user_id = writer_user.id
  p.position = "A"
  p.uuid = SecureRandom.uuid
  p.difficulty = "beginner"
  p.execution_time_limit = 1000
  p.submission_limit_1 = 10
  p.submission_limit_2 = 100
  p.statement = "\"Hello World\" を出力してください。"
  p.constraints = "特になし"
  p.input_format = "入力はありません。"
  p.output_format = "Hello World"
end
puts "✅ Problem: #{practice_problem.name}"

# Create testcases for problems
testcase_a1 = Testcase.find_or_create_by!(problem_id: problem_a.id, name: "sample_01") do |t|
  t.input = "1 2"
  t.output = "3"
  t.explanation = "1 + 2 = 3"
end

testcase_a2 = Testcase.find_or_create_by!(problem_id: problem_a.id, name: "sample_02") do |t|
  t.input = "100 200"
  t.output = "300"
  t.explanation = "100 + 200 = 300"
end

testcase_b1 = Testcase.find_or_create_by!(problem_id: problem_b.id, name: "sample_01") do |t|
  t.input = "3"
  t.output = "6"
  t.explanation = "3! = 3 × 2 × 1 = 6"
end

testcase_b2 = Testcase.find_or_create_by!(problem_id: problem_b.id, name: "sample_02") do |t|
  t.input = "5"
  t.output = "120"
  t.explanation = "5! = 5 × 4 × 3 × 2 × 1 = 120"
end

testcase_hello = Testcase.find_or_create_by!(problem_id: practice_problem.id, name: "sample_01") do |t|
  t.input = ""
  t.output = "Hello World"
  t.explanation = "Hello World を出力する"
end

puts "✅ Created testcases"

# Create testcase sets
testcase_set_a = TestcaseSet.find_or_create_by!(problem_id: problem_a.id, name: "All") do |s|
  s.points = 100
  s.aggregate_type = :all
  s.is_sample = true
end

testcase_set_b = TestcaseSet.find_or_create_by!(problem_id: problem_b.id, name: "All") do |s|
  s.points = 100
  s.aggregate_type = :all
  s.is_sample = true
end

testcase_set_hello = TestcaseSet.find_or_create_by!(problem_id: practice_problem.id, name: "All") do |s|
  s.points = 100
  s.aggregate_type = :all
  s.is_sample = true
end

# Associate testcases with testcase sets
TestcaseTestcaseSet.find_or_create_by!(testcase_id: testcase_a1.id, testcase_set_id: testcase_set_a.id)
TestcaseTestcaseSet.find_or_create_by!(testcase_id: testcase_a2.id, testcase_set_id: testcase_set_a.id)
TestcaseTestcaseSet.find_or_create_by!(testcase_id: testcase_b1.id, testcase_set_id: testcase_set_b.id)
TestcaseTestcaseSet.find_or_create_by!(testcase_id: testcase_b2.id, testcase_set_id: testcase_set_b.id)
TestcaseTestcaseSet.find_or_create_by!(testcase_id: testcase_hello.id, testcase_set_id: testcase_set_hello.id)

puts "✅ Created testcase sets and associations"

# Create registrations for past contest
users.each do |user|
  Registration.find_or_create_by!(user_id: user.id, contest_id: past_contest.id) do |r|
    r.open_registration = true
  end
end
puts "✅ Created registrations for past contest"

# Create some sample submissions
users.first(3).each_with_index do |user, index|
  Submission.find_or_create_by!(user_id: user.id, problem_id: problem_a.id) do |s|
    s.path = "submissions/#{user.id}/#{problem_a.id}/main.cpp"
    s.status = index == 0 ? "AC" : ["WA", "TLE", "RE"].sample
    s.point = index == 0 ? 100 : 0
    s.execution_time = rand(100..1500)
    s.execution_memory = rand(1000..50000)
    s.lang = "cpp"
    s.public = true
  end
end
puts "✅ Created sample submissions"

# Create contest admins
[past_contest, upcoming_contest, practice_contest].each do |contest|
  ContestAdmin.find_or_create_by!(contest_id: contest.id, user_id: admin_user.id)
end
puts "✅ Created contest admins"

# Create sample posts
Post.find_or_create_by!(title: "サイトオープンのお知らせ") do |p|
  p.content = "競技プログラミングオンラインジャッジサイトがオープンしました！\n\nこのサイトでは以下のことができます：\n- プログラミングコンテストに参加\n- 問題の練習\n- 他の参加者との交流\n\nぜひご利用ください！"
  p.public_status = "public"
end

Post.find_or_create_by!(title: "初回コンテスト開催のお知らせ") do |p|
  p.content = "記念すべき第1回コンテストを開催します！\n\n日時：来週の土曜日 20:00-23:00\n難易度：初心者〜中級者向け\n\n皆様のご参加をお待ちしております。"
  p.public_status = "public"
end
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
