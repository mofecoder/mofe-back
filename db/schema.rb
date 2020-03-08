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

ActiveRecord::Schema.define(version: 2020_03_08_072023) do

  create_table "contests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["slug"], name: "index_contests_on_slug", unique: true
  end

  create_table "problems", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "testcase_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "problem_id", null: false
    t.string "name", null: false
    t.integer "points", null: false
    t.boolean "is_sample", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["problem_id"], name: "index_testcase_sets_on_problem_id"
  end

  create_table "testcase_testcase_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "testcase_id", null: false
    t.bigint "testcase_set_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["testcase_id"], name: "index_testcase_testcase_sets_on_testcase_id"
    t.index ["testcase_set_id"], name: "index_testcase_testcase_sets_on_testcase_set_id"
  end

  create_table "testcases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.text "input", size: :long, null: false
    t.text "output", size: :long, null: false
    t.string "explanation"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "problems", "contests"
  add_foreign_key "testcase_sets", "problems"
  add_foreign_key "testcase_testcase_sets", "testcase_sets"
  add_foreign_key "testcase_testcase_sets", "testcases"
end
