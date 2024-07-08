# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_06_30_153938) do

  create_table "__diesel_schema_migrations", primary_key: "version", id: { type: :string, limit: 50 }, charset: "utf8", force: :cascade do |t|
    t.timestamp "run_on", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "clarifications", charset: "utf8", force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.bigint "problem_id"
    t.bigint "user_id", null: false
    t.string "question", null: false
    t.string "answer"
    t.boolean "publish", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["contest_id"], name: "index_clarifications_on_contest_id"
    t.index ["problem_id"], name: "index_clarifications_on_problem_id"
    t.index ["user_id"], name: "index_clarifications_on_user_id"
  end

  create_table "contest_admins", charset: "utf8", force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["contest_id"], name: "index_contest_admins_on_contest_id"
    t.index ["user_id"], name: "index_contest_admins_on_user_id"
  end

  create_table "contests", charset: "utf8", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.string "description", limit: 4096
    t.string "kind", default: "normal", null: false
    t.boolean "allow_open_registration", default: false
    t.string "closed_password"
    t.boolean "allow_team_registration", default: false
    t.integer "standings_mode", default: 1, null: false
    t.integer "penalty_time", default: 0, null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "editorial_url"
    t.boolean "official_mode", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["slug"], name: "index_contests_on_slug", unique: true
  end

  create_table "posts", charset: "utf8", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.string "public_status", default: "private"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "problems", charset: "utf8", force: :cascade do |t|
    t.string "slug"
    t.string "name"
    t.bigint "contest_id"
    t.bigint "writer_user_id", default: 1, null: false
    t.string "position", limit: 4
    t.string "uuid"
    t.string "difficulty", limit: 16, null: false
    t.integer "execution_time_limit", default: 2000, null: false
    t.string "statement", limit: 4096, null: false
    t.string "constraints", limit: 2048, null: false
    t.string "input_format", limit: 1024, null: false
    t.string "output_format", limit: 1024, null: false
    t.string "checker_path"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["contest_id"], name: "index_problems_on_contest_id"
    t.index ["slug"], name: "index_problems_on_slug", unique: true
    t.index ["writer_user_id"], name: "index_problems_on_writer_user_id"
  end

  create_table "registrations", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "contest_id", null: false
    t.boolean "open_registration", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["contest_id"], name: "index_registrations_on_contest_id"
    t.index ["user_id"], name: "index_registrations_on_user_id"
  end

  create_table "submissions", charset: "utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "problem_id", null: false
    t.string "path", null: false
    t.string "status", limit: 16, null: false
    t.integer "point"
    t.integer "execution_time"
    t.integer "execution_memory"
    t.text "compile_error"
    t.string "lang", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["problem_id"], name: "index_submissions_on_problem_id"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "team_registration_users", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "team_registration_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["team_registration_id"], name: "index_team_registration_users_on_team_registration_id"
    t.index ["user_id", "team_registration_id"], name: "index_team_registration_users_on_ids", unique: true
    t.index ["user_id"], name: "index_team_registration_users_on_user_id"
  end

  create_table "team_registrations", charset: "utf8", force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.string "name"
    t.string "passphrase"
    t.boolean "open_registration", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["contest_id"], name: "index_team_registrations_on_contest_id"
  end

  create_table "testcase_results", charset: "utf8", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "testcase_id", null: false
    t.string "status", limit: 16, null: false
    t.integer "execution_time", null: false
    t.integer "execution_memory", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["submission_id"], name: "index_testcase_results_on_submission_id"
    t.index ["testcase_id"], name: "index_testcase_results_on_testcase_id"
  end

  create_table "testcase_sets", charset: "utf8", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.string "name", null: false
    t.integer "points", null: false
    t.boolean "is_sample", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["problem_id"], name: "index_testcase_sets_on_problem_id"
  end

  create_table "testcase_testcase_sets", charset: "utf8", force: :cascade do |t|
    t.bigint "testcase_id", null: false
    t.bigint "testcase_set_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["testcase_id"], name: "index_testcase_testcase_sets_on_testcase_id"
    t.index ["testcase_set_id"], name: "index_testcase_testcase_sets_on_testcase_set_id"
  end

  create_table "testcases", charset: "utf8", force: :cascade do |t|
    t.bigint "problem_id", default: 1, null: false
    t.string "name"
    t.text "input", size: :long
    t.text "output", size: :long
    t.string "explanation", limit: 2048
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["problem_id"], name: "index_testcases_on_problem_id"
  end

  create_table "tester_relations", charset: "utf8", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.bigint "tester_user_id", null: false
    t.boolean "approved", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["problem_id"], name: "index_tester_relations_on_problem_id"
    t.index ["tester_user_id"], name: "index_tester_relations_on_tester_user_id"
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "role", default: "member", null: false
    t.string "name"
    t.string "atcoder_id", limit: 16
    t.integer "atcoder_rating"
    t.string "writer_request_code"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "contest_admins", "contests"
  add_foreign_key "contest_admins", "users"
  add_foreign_key "problems", "contests"
  add_foreign_key "problems", "users", column: "writer_user_id"
  add_foreign_key "submissions", "problems"
  add_foreign_key "team_registration_users", "team_registrations"
  add_foreign_key "team_registration_users", "users"
  add_foreign_key "team_registrations", "contests"
  add_foreign_key "testcase_sets", "problems"
  add_foreign_key "testcase_testcase_sets", "testcase_sets"
  add_foreign_key "testcase_testcase_sets", "testcases"
  add_foreign_key "testcases", "problems"
  add_foreign_key "tester_relations", "problems"
  add_foreign_key "tester_relations", "users", column: "tester_user_id"

  create_view "all_registrations", sql_definition: <<-SQL
      select `registrations`.`id` AS `id`,`registrations`.`contest_id` AS `contest_id`,`registrations`.`open_registration` AS `open_registration`,`registrations`.`created_at` AS `created_at`,`registrations`.`updated_at` AS `updated_at`,`registrations`.`deleted_at` AS `deleted_at`,'individual' AS `type` from `registrations` union select `team_registrations`.`id` AS `id`,`team_registrations`.`contest_id` AS `contest_id`,`team_registrations`.`open_registration` AS `open_registration`,`team_registrations`.`created_at` AS `created_at`,`team_registrations`.`updated_at` AS `updated_at`,`team_registrations`.`deleted_at` AS `deleted_at`,'team' AS `type` from `team_registrations`
  SQL
end
