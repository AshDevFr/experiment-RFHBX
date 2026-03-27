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

ActiveRecord::Schema[8.1].define(version: 2026_03_27_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "artifacts", force: :cascade do |t|
    t.string "artifact_type", null: false
    t.bigint "character_id"
    t.boolean "corrupted", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "power"
    t.jsonb "stat_bonus", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_type"], name: "index_artifacts_on_artifact_type"
    t.index ["character_id"], name: "index_artifacts_on_character_id"
    t.index ["corrupted"], name: "index_artifacts_on_corrupted"
    t.index ["stat_bonus"], name: "index_artifacts_on_stat_bonus", using: :gin
  end

  create_table "characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "endurance", default: 5, null: false
    t.integer "level", default: 1, null: false
    t.string "name", null: false
    t.string "race", null: false
    t.string "realm"
    t.boolean "ring_bearer", default: false, null: false
    t.string "status", default: "idle", null: false
    t.integer "strength", default: 5, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "wisdom", default: 5, null: false
    t.integer "xp", default: 0, null: false
    t.index ["name"], name: "index_characters_on_name"
    t.index ["race"], name: "index_characters_on_race"
    t.index ["status"], name: "index_characters_on_status"
  end

  create_table "quest_events", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "event_type", null: false
    t.text "message"
    t.bigint "quest_id", null: false
    t.index ["created_at"], name: "index_quest_events_on_created_at"
    t.index ["data"], name: "index_quest_events_on_data", using: :gin
    t.index ["event_type"], name: "index_quest_events_on_event_type"
    t.index ["quest_id"], name: "index_quest_events_on_quest_id"
  end

  create_table "quest_memberships", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.bigint "quest_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["character_id", "quest_id"], name: "index_quest_memberships_on_character_id_and_quest_id", unique: true
    t.index ["character_id"], name: "index_quest_memberships_on_character_id"
    t.index ["quest_id"], name: "index_quest_memberships_on_quest_id"
  end

  create_table "quests", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.integer "campaign_order"
    t.datetime "created_at", null: false
    t.integer "danger_level", default: 1, null: false
    t.text "description"
    t.decimal "progress", precision: 5, scale: 4, default: "0.0", null: false
    t.string "quest_type", default: "campaign", null: false
    t.string "region"
    t.string "status", default: "pending", null: false
    t.decimal "success_chance", precision: 5, scale: 4
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_order"], name: "index_quests_on_campaign_order"
    t.index ["quest_type"], name: "index_quests_on_quest_type"
    t.index ["status"], name: "index_quests_on_status"
  end

  create_table "simulation_configs", force: :cascade do |t|
    t.integer "campaign_position", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "mode", default: "campaign", null: false
    t.decimal "progress_max", precision: 6, scale: 4, default: "0.1", null: false
    t.decimal "progress_min", precision: 6, scale: 4, default: "0.01", null: false
    t.boolean "running", default: false, null: false
    t.integer "tick_count", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "artifacts", "characters"
  add_foreign_key "quest_events", "quests"
  add_foreign_key "quest_memberships", "characters"
  add_foreign_key "quest_memberships", "quests"
end
