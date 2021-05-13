# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_05_13_112953) do

  create_table "_Migration", primary_key: "revision", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.text "name", null: false
    t.text "datamodel", size: :long, null: false
    t.text "status", null: false
    t.integer "applied", null: false
    t.integer "rolled_back", null: false
    t.text "datamodel_steps", size: :long, null: false
    t.text "database_migration", size: :long, null: false
    t.text "errors", size: :long, null: false
    t.datetime "started_at", precision: 3, null: false
    t.datetime "finished_at", precision: 3
  end

  create_table "balances", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "balance_type", null: false
    t.string "name"
    t.boolean "publish_name"
    t.string "destination"
    t.integer "amount", null: false
    t.date "date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "clarifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "contests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.string "description", limit: 4096
    t.integer "penalty_time", default: 0, null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "editorial_url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["slug"], name: "index_contests_on_slug", unique: true
  end

  create_table "donation_informations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.integer "amount", null: false
    t.string "publish_name"
    t.string "note", null: false
    t.string "destination", null: false
    t.datetime "processed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "posts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.string "public_status", default: "private"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "problems", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "slug"
    t.string "name"
    t.bigint "contest_id"
    t.bigint "writer_user_id", default: 2, null: false
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

  create_table "registrations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "contest_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["contest_id"], name: "index_registrations_on_contest_id"
    t.index ["user_id"], name: "index_registrations_on_user_id"
  end

  create_table "submits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
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
    t.index ["problem_id"], name: "index_submits_on_problem_id"
  end

  create_table "testcase_results", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "submit_id", null: false
    t.bigint "testcase_id", null: false
    t.string "status", limit: 16, null: false
    t.integer "execution_time", null: false
    t.integer "execution_memory", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["submit_id"], name: "index_testcase_results_on_submit_id"
    t.index ["testcase_id"], name: "index_testcase_results_on_testcase_id"
  end

  create_table "testcase_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.string "name", null: false
    t.integer "points", null: false
    t.boolean "is_sample", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["problem_id"], name: "index_testcase_sets_on_problem_id"
  end

  create_table "testcase_testcase_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "testcase_id", null: false
    t.bigint "testcase_set_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["testcase_id"], name: "index_testcase_testcase_sets_on_testcase_id"
    t.index ["testcase_set_id"], name: "index_testcase_testcase_sets_on_testcase_set_id"
  end

  create_table "testcases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
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

  create_table "tester_relations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.bigint "tester_user_id", null: false
    t.boolean "approved", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.index ["problem_id"], name: "index_tester_relations_on_problem_id"
    t.index ["tester_user_id"], name: "index_tester_relations_on_tester_user_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
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

  add_foreign_key "problems", "contests"
  add_foreign_key "problems", "users", column: "writer_user_id"
  add_foreign_key "submits", "problems"
  add_foreign_key "testcase_sets", "problems"
  add_foreign_key "testcase_testcase_sets", "testcase_sets"
  add_foreign_key "testcase_testcase_sets", "testcases"
  add_foreign_key "testcases", "problems"
  add_foreign_key "tester_relations", "problems"
  add_foreign_key "tester_relations", "users", column: "tester_user_id"
end
