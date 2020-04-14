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

ActiveRecord::Schema.define(version: 2020_04_14_195429) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.integer "level_id"
    t.string "value", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "team_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "bonus_answers", id: :serial, force: :cascade do |t|
    t.integer "bonus_id"
    t.integer "team_id"
    t.string "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["bonus_id"], name: "index_bonus_answers_on_bonus_id"
  end

  create_table "bonuses", id: :serial, force: :cascade do |t|
    t.integer "level_id"
    t.string "name"
    t.text "task"
    t.text "help"
    t.integer "team_id"
    t.integer "award_time"
    t.integer "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_absolute_limited", default: false
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.boolean "is_delayed", default: false
    t.integer "delay_for"
    t.boolean "is_relative_limited", default: false
    t.integer "valid_for"
    t.integer "game_id"
    t.boolean "change_level_autocomplete", default: false
    t.integer "change_level_autocomplete_by", default: 0
  end

  create_table "closed_levels", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "team_id"
    t.integer "level_id"
    t.integer "user_id"
    t.datetime "started_at"
    t.datetime "closed_at"
    t.boolean "timeouted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "forem_categories", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.integer "position", default: 0
    t.index ["slug"], name: "index_forem_categories_on_slug", unique: true
  end

  create_table "forem_forums", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "category_id"
    t.integer "views_count", default: 0
    t.string "slug"
    t.integer "position", default: 0
    t.index ["slug"], name: "index_forem_forums_on_slug", unique: true
  end

  create_table "forem_groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_forem_groups_on_name"
  end

  create_table "forem_memberships", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "member_id"
    t.index ["group_id"], name: "index_forem_memberships_on_group_id"
  end

  create_table "forem_moderator_groups", id: :serial, force: :cascade do |t|
    t.integer "forum_id"
    t.integer "group_id"
    t.index ["forum_id"], name: "index_forem_moderator_groups_on_forum_id"
  end

  create_table "forem_posts", id: :serial, force: :cascade do |t|
    t.integer "topic_id"
    t.text "text"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "reply_to_id"
    t.string "state", default: "approved", null: false
    t.boolean "notified", default: false
    t.index ["reply_to_id"], name: "index_forem_posts_on_reply_to_id"
    t.index ["state"], name: "index_forem_posts_on_state"
    t.index ["topic_id"], name: "index_forem_posts_on_topic_id"
    t.index ["user_id"], name: "index_forem_posts_on_user_id"
  end

  create_table "forem_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "subscriber_id"
    t.integer "topic_id"
  end

  create_table "forem_topics", id: :serial, force: :cascade do |t|
    t.integer "forum_id"
    t.integer "user_id"
    t.string "subject"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "locked", default: false, null: false
    t.boolean "pinned", default: false
    t.boolean "hidden", default: false
    t.datetime "last_post_at"
    t.string "state", default: "pending_review"
    t.integer "views_count", default: 0
    t.string "slug"
    t.index ["forum_id"], name: "index_forem_topics_on_forum_id"
    t.index ["slug"], name: "index_forem_topics_on_slug", unique: true
    t.index ["state"], name: "index_forem_topics_on_state"
    t.index ["user_id"], name: "index_forem_topics_on_user_id"
  end

  create_table "forem_views", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "viewable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "count", default: 0
    t.string "viewable_type"
    t.datetime "current_viewed_at"
    t.datetime "past_viewed_at"
    t.index ["updated_at"], name: "index_forem_views_on_updated_at"
    t.index ["user_id"], name: "index_forem_views_on_user_id"
    t.index ["viewable_id"], name: "index_forem_views_on_viewable_id"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "game_bonuses", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "team_id"
    t.integer "level_id"
    t.decimal "award", precision: 16, scale: 3
    t.text "description"
    t.integer "user_id"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_bonuses_on_game_id"
  end

  create_table "game_entries", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "team_id"
    t.string "status", limit: 255
  end

  create_table "game_passings", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "team_id"
    t.integer "current_level_id"
    t.datetime "finished_at"
    t.datetime "current_level_entered_at"
    t.text "answered_questions"
    t.string "status", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "closed_levels"
    t.text "answered_bonuses"
    t.integer "sum_bonuses", default: 0
    t.text "penalty_hints"
    t.text "missed_bonuses"
  end

  create_table "game_passings_bonuses", id: :serial, force: :cascade do |t|
    t.integer "game_passing_id"
    t.integer "bonus_id"
    t.index ["bonus_id"], name: "index_game_passings_bonuses_on_bonus_id"
    t.index ["game_passing_id"], name: "index_game_passings_bonuses_on_game_passing_id"
  end

  create_table "game_passings_questions", id: :serial, force: :cascade do |t|
    t.integer "game_passing_id"
    t.integer "question_id"
    t.index ["game_passing_id"], name: "index_game_passings_questions_on_game_passing_id"
    t.index ["question_id"], name: "index_game_passings_questions_on_question_id"
  end

  create_table "games", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.integer "author_id"
    t.datetime "starts_at"
    t.boolean "is_draft", default: false, null: false
    t.integer "max_team_number"
    t.integer "requested_teams_number", default: 0
    t.datetime "registration_deadline"
    t.datetime "author_finished_at"
    t.boolean "is_testing", default: false, null: false
    t.datetime "test_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "game_type", default: "linear"
    t.integer "duration"
    t.integer "tested_team_id"
    t.integer "topic_id"
    t.string "game_size"
    t.string "slug"
    t.text "small_description"
    t.string "city"
    t.string "place"
    t.integer "price"
    t.string "image"
    t.string "team_type", default: "multy"
    t.text "show_scenario_for"
    t.boolean "hide_levels_names", default: false
    t.boolean "hide_stat", default: false
    t.string "hide_stat_type", default: "all"
    t.integer "hide_stat_level", default: 0
    t.integer "team_size_limit"
    t.index ["slug"], name: "index_games_on_slug"
  end

  create_table "games_authors", id: false, force: :cascade do |t|
    t.integer "game_id"
    t.integer "author_id"
    t.index ["author_id"], name: "index_games_authors_on_author_id"
    t.index ["game_id"], name: "index_games_authors_on_game_id"
  end

  create_table "hints", id: :serial, force: :cascade do |t|
    t.integer "level_id"
    t.text "text"
    t.integer "delay"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "team_id"
    t.index ["level_id"], name: "index_hints_on_level_id"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "alt", default: ""
    t.string "hint", default: ""
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "image"
  end

  create_table "input_locks", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "level_id"
    t.integer "team_id"
    t.integer "user_id"
    t.datetime "lock_ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", id: :serial, force: :cascade do |t|
    t.integer "to_team_id"
    t.integer "for_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "level_orders", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "team_id"
    t.integer "level_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "levels", id: :serial, force: :cascade do |t|
    t.text "text"
    t.integer "game_id"
    t.integer "position"
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "olymp", default: false
    t.integer "complete_later"
    t.integer "olymp_base", default: 2
    t.integer "sectors_for_close", default: 0
    t.boolean "is_autocomplete_penalty", default: false
    t.integer "autocomplete_penalty"
    t.boolean "is_wrong_code_penalty", default: false
    t.integer "wrong_code_penalty", default: 0
    t.boolean "dismissed", default: false
    t.text "description"
    t.boolean "input_lock", default: false
    t.integer "inputs_count", default: 0
    t.integer "input_lock_duration", default: 0
    t.string "input_lock_type", default: "team"
    t.index ["game_id"], name: "index_levels_on_game_id"
  end

  create_table "levels_bonuses", id: false, force: :cascade do |t|
    t.integer "bonus_id"
    t.integer "level_id"
    t.index ["bonus_id"], name: "index_levels_bonuses_on_bonus_id"
    t.index ["level_id", "bonus_id"], name: "index_levels_bonuses_on_level_id_and_bonus_id"
    t.index ["level_id"], name: "index_levels_bonuses_on_level_id"
  end

  create_table "logs", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.string "team", limit: 255
    t.string "level", limit: 255
    t.string "answer", limit: 255
    t.datetime "time"
    t.integer "user_id"
    t.integer "team_id"
    t.integer "level_id"
    t.integer "answer_type", default: 0
    t.index ["game_id", "level_id", "team_id"], name: "index_logs_on_game_id_and_level_id_and_team_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "user_id"
    t.string "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages_levels", id: false, force: :cascade do |t|
    t.integer "message_id"
    t.integer "level_id"
    t.index ["level_id", "message_id"], name: "index_messages_levels_on_level_id_and_message_id"
    t.index ["level_id"], name: "index_messages_levels_on_level_id"
    t.index ["message_id"], name: "index_messages_levels_on_message_id"
  end

  create_table "penalty_hints", id: :serial, force: :cascade do |t|
    t.integer "level_id"
    t.string "name"
    t.text "text"
    t.integer "penalty"
    t.integer "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_delayed", default: false
    t.integer "delay_for"
    t.index ["level_id"], name: "index_penalty_hints_on_level_id"
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "level_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "position"
    t.integer "team_id"
    t.boolean "change_level_autocomplete", default: false
    t.integer "change_level_autocomplete_by", default: 0
  end

  create_table "results", id: :serial, force: :cascade do |t|
    t.integer "game_id"
    t.integer "team_id"
    t.integer "place"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", id: :serial, force: :cascade do |t|
    t.integer "level_id"
    t.text "text"
    t.integer "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["level_id"], name: "index_tasks_on_level_id"
  end

  create_table "team_requests", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "captain_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "team_type", default: "multy"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "nickname", limit: 255
    t.integer "team_id"
    t.string "phone_number", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "forem_admin", default: false
    t.string "forem_state", default: "pending_review"
    t.boolean "forem_auto_subscribe", default: false
    t.string "unique_session_id", limit: 20
    t.string "telegram"
    t.integer "single_team_id"
    t.string "provider"
    t.string "uid"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
