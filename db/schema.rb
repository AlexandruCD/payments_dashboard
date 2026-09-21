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

ActiveRecord::Schema[8.1].define(version: 2026_09_21_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id", null: false
    t.string "auditable_type", null: false
    t.datetime "created_at", null: false
    t.string "details"
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
  end

  create_table "merchants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "name"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "customer_phone"
    t.bigint "merchant_id", null: false
    t.string "notification_url"
    t.integer "referenced_transaction_id"
    t.string "status"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["merchant_id"], name: "index_transactions_on_merchant_id"
    t.index ["uuid"], name: "index_transactions_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.bigint "merchant_id"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["merchant_id"], name: "index_users_on_merchant_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["type"], name: "index_users_on_type"
    t.check_constraint "type::text = 'MerchantUser'::text AND merchant_id IS NOT NULL OR type::text = 'AdminUser'::text AND merchant_id IS NULL", name: "users_merchant_link_matches_type"
    t.check_constraint "type::text = ANY (ARRAY['AdminUser'::character varying, 'MerchantUser'::character varying]::text[])", name: "users_type_allowed"
  end

  add_foreign_key "transactions", "merchants"
  add_foreign_key "users", "merchants"
end
