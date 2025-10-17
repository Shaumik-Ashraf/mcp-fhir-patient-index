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

ActiveRecord::Schema[8.0].define(version: 2025_10_17_230332) do
  create_table "action_mcp_session_messages", force: :cascade do |t|
    t.string "session_id", null: false
    t.string "direction", default: "client", null: false
    t.string "message_type", null: false
    t.string "jsonrpc_id"
    t.json "message_json"
    t.boolean "is_ping", default: false, null: false
    t.boolean "request_acknowledged", default: false, null: false
    t.boolean "request_cancelled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_action_mcp_session_messages_on_session_id"
  end

  create_table "action_mcp_session_resources", force: :cascade do |t|
    t.string "session_id", null: false
    t.string "uri", null: false
    t.string "name"
    t.text "description"
    t.string "mime_type", null: false
    t.boolean "created_by_tool", default: false
    t.datetime "last_accessed_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_action_mcp_session_resources_on_session_id"
  end

  create_table "action_mcp_session_subscriptions", force: :cascade do |t|
    t.string "session_id", null: false
    t.string "uri", null: false
    t.datetime "last_notification_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_action_mcp_session_subscriptions_on_session_id"
  end

  create_table "action_mcp_sessions", id: :string, force: :cascade do |t|
    t.string "role", default: "server", null: false
    t.string "status", default: "pre_initialize", null: false
    t.datetime "ended_at"
    t.string "protocol_version"
    t.json "server_capabilities"
    t.json "client_capabilities"
    t.json "server_info"
    t.json "client_info"
    t.boolean "initialized", default: false, null: false
    t.integer "messages_count", default: 0, null: false
    t.integer "sse_event_counter", default: 0, null: false
    t.json "tool_registry", default: []
    t.json "prompt_registry", default: []
    t.json "resource_registry", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "consents", default: {}, null: false
  end

  create_table "action_mcp_sse_events", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "event_id", null: false
    t.text "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_action_mcp_sse_events_on_created_at"
    t.index ["session_id", "event_id"], name: "index_action_mcp_sse_events_on_session_id_and_event_id", unique: true
    t.index ["session_id"], name: "index_action_mcp_sse_events_on_session_id"
  end

  create_table "patient_joins", force: :cascade do |t|
    t.integer "from_patient_record_id", null: false
    t.integer "to_patient_record_id", null: false
    t.integer "qualifier"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_patient_record_id"], name: "index_patient_joins_on_from_patient_record_id"
    t.index ["to_patient_record_id"], name: "index_patient_joins_on_to_patient_record_id"
  end

  create_table "patient_records", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "administrative_gender"
    t.date "birth_date"
    t.string "email"
    t.string "phone_number"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_city"
    t.string "address_state"
    t.string "address_zip_code"
    t.string "social_security_number"
    t.string "passport_number"
    t.string "drivers_license_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_patient_records_on_uuid", unique: true
  end

  create_table "snapshot_items", force: :cascade do |t|
    t.integer "snapshot_id", null: false
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.json "object", null: false
    t.datetime "created_at", null: false
    t.string "child_group_name"
    t.index ["item_type", "item_id"], name: "index_snapshot_items_on_item"
    t.index ["snapshot_id", "item_id", "item_type"], name: "index_snapshot_items_on_snapshot_id_and_item_id_and_item_type", unique: true
    t.index ["snapshot_id"], name: "index_snapshot_items_on_snapshot_id"
  end

  create_table "snapshots", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "user_type"
    t.integer "user_id"
    t.string "identifier"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.index ["identifier", "item_id", "item_type"], name: "index_snapshots_on_identifier_and_item_id_and_item_type", unique: true
    t.index ["identifier"], name: "index_snapshots_on_identifier"
    t.index ["item_type", "item_id"], name: "index_snapshots_on_item"
    t.index ["user_type", "user_id"], name: "index_snapshots_on_user"
  end

  add_foreign_key "action_mcp_session_messages", "action_mcp_sessions", column: "session_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "action_mcp_session_resources", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_session_subscriptions", "action_mcp_sessions", column: "session_id", on_delete: :cascade
  add_foreign_key "action_mcp_sse_events", "action_mcp_sessions", column: "session_id"
  add_foreign_key "patient_joins", "from_patient_records"
  add_foreign_key "patient_joins", "to_patient_records"
end
