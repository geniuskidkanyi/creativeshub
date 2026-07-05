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

ActiveRecord::Schema[8.1].define(version: 2026_07_05_032041) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.text "address"
    t.string "business_name"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "logo"
    t.string "modempay_sub_account_id"
    t.string "phone"
    t.string "qr_secret"
    t.string "qr_token"
    t.string "settlement_account_number"
    t.string "settlement_code"
    t.string "tax_id"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["qr_token"], name: "index_accounts_on_qr_token", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "address"
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_clients_on_account_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "invoice_id", null: false
    t.decimal "quantity"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "invoice_number"
    t.date "issue_date"
    t.text "notes"
    t.datetime "paid_date"
    t.string "payment_method"
    t.string "public_token"
    t.string "status"
    t.decimal "subtotal"
    t.decimal "tax_amount"
    t.decimal "tax_rate"
    t.decimal "total_amount"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_invoices_on_account_id"
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["public_token"], name: "index_invoices_on_public_token", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "amount"
    t.string "client_reference"
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "invoice_id"
    t.jsonb "metadata"
    t.datetime "paid_at"
    t.string "payment_method"
    t.string "status"
    t.string "transaction_reference"
    t.datetime "updated_at", null: false
    t.string "waychit_id"
    t.jsonb "webhook_data"
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "payouts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "account_number", null: false
    t.decimal "amount", null: false
    t.string "beneficiary_name", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "GMD", null: false
    t.text "error_message"
    t.decimal "fee"
    t.string "idempotency_key", null: false
    t.string "modempay_transfer_id"
    t.string "narration"
    t.string "network", null: false
    t.string "status", default: "pending", null: false
    t.string "transfer_reference"
    t.datetime "updated_at", null: false
    t.jsonb "webhook_data"
    t.index ["account_id"], name: "index_payouts_on_account_id"
    t.index ["idempotency_key"], name: "index_payouts_on_idempotency_key", unique: true
    t.index ["modempay_transfer_id"], name: "index_payouts_on_modempay_transfer_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_products_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_id"
    t.string "event_type"
    t.jsonb "payload"
    t.datetime "processed_at"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "clients", "accounts"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "accounts"
  add_foreign_key "invoices", "clients"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payouts", "accounts"
  add_foreign_key "products", "accounts"
end
