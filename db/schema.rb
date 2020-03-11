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

ActiveRecord::Schema.define(version: 2020_03_10_130429) do

  create_table "contests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["slug"], name: "index_contests_on_slug", unique: true
  end

  create_table "problems", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name"
    t.bigint "contest_id", null: false
    t.string "position", null: false
    t.string "difficulty", null: false
    t.string "statement", null: false
    t.string "constraints", null: false
    t.string "input_format", null: false
    t.string "output_format", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["contest_id"], name: "index_problems_on_contest_id"
    t.index ["slug"], name: "index_problems_on_slug", unique: true
  end

  create_table "submits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.bigint "problem_id", null: false
    t.string "path", null: false
    t.string "status", null: false
    t.integer "point"
    t.integer "execution_time"
    t.string "execution_memory"
    t.string "lang", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["problem_id"], name: "index_submits_on_problem_id"
  end

  create_table "testcase_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.string "path", null: false
    t.string "status", null: false
    t.integer "point"
    t.integer "execution_time"
    t.string "execution_memory"
    t.string "lang", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["problem_id"], name: "index_submits_on_problem_id"
  end

  create_table "testcase_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.string "name", null: false
    t.integer "points", null: false
    t.boolean "is_sample", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["problem_id"], name: "index_testcase_sets_on_problem_id"
  end

  create_table "testcase_testcase_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.bigint "testcase_id", null: false
    t.bigint "testcase_set_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["testcase_id"], name: "index_testcase_testcase_sets_on_testcase_id"
    t.index ["testcase_set_id"], name: "index_testcase_testcase_sets_on_testcase_set_id"
  end

  create_table "testcases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.text "input", size: :long, null: false
    t.text "output", size: :long, null: false
    t.string "explanation"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
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
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "problems", "contests"
  add_foreign_key "submits", "problems"
  add_foreign_key "testcase_sets", "problems"
  add_foreign_key "testcase_testcase_sets", "testcase_sets"
  add_foreign_key "testcase_testcase_sets", "testcases"
end
