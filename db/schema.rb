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

ActiveRecord::Schema[8.0].define(version: 2025_05_19_155743) do
  create_table "analyses", force: :cascade do |t|
    t.string "title"
    t.integer "word_count"
    t.string "status", default: "pending", null: false
    t.integer "web_page_id", null: false
    t.text "table_of_contents"
    t.text "top_word_frequencies"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "error_message"
    t.index ["status"], name: "index_analyses_on_status"
    t.index ["web_page_id"], name: "index_analyses_on_web_page_id"
  end

  create_table "web_pages", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "analyses", "web_pages"
end
