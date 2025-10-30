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

ActiveRecord::Schema[8.0].define(version: 2025_10_30_160357) do
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

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "description"
    t.json "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
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

  add_foreign_key "patient_joins", "patient_records", column: "from_patient_record_id"
  add_foreign_key "patient_joins", "patient_records", column: "to_patient_record_id"
end
