# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151228140136) do

  create_table "answers", force: :cascade do |t|
    t.integer  "question_id"
    t.integer  "level_id"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "game_entries", force: :cascade do |t|
    t.integer "game_id"
    t.integer "team_id"
    t.string  "status"
  end

  create_table "game_passings", force: :cascade do |t|
    t.integer  "game_id"
    t.integer  "team_id"
    t.integer  "current_level_id"
    t.datetime "finished_at"
    t.datetime "current_level_entered_at"
    t.text     "answered_questions",       limit: 255
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "closed_levels"
  end

  create_table "games", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "author_id"
    t.datetime "starts_at"
    t.boolean  "is_draft",               default: false,    null: false
    t.integer  "max_team_number"
    t.integer  "requested_teams_number", default: 0
    t.datetime "registration_deadline"
    t.datetime "author_finished_at"
    t.boolean  "is_testing",             default: false,    null: false
    t.datetime "test_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                   default: "linear"
    t.integer  "duration"
  end

  create_table "hints", force: :cascade do |t|
    t.integer  "level_id"
    t.text     "text"
    t.integer  "delay"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", force: :cascade do |t|
    t.string   "alt",               default: ""
    t.string   "hint",              default: ""
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
  end

  create_table "invitations", force: :cascade do |t|
    t.integer  "to_team_id"
    t.integer  "for_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "levels", force: :cascade do |t|
    t.text     "text"
    t.integer  "game_id"
    t.integer  "position"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "olymp",      default: false
  end

  create_table "logs", force: :cascade do |t|
    t.integer  "game_id"
    t.string   "team"
    t.string   "level"
    t.string   "answer"
    t.datetime "time"
    t.integer  "user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string   "name"
    t.integer  "level_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "captain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "nickname"
    t.integer  "team_id"
    t.string   "phone_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
