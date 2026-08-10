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

ActiveRecord::Schema[8.1].define(version: 2026_08_10_014711) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

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
    t.string "external_ref"
    t.string "external_source"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id", "external_source", "external_ref"], name: "index_clients_on_external_ref", unique: true, where: "(external_ref IS NOT NULL)"
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
    t.string "currency", default: "GMD", null: false
    t.date "due_date"
    t.string "external_ref"
    t.string "external_source"
    t.decimal "fx_rate", precision: 18, scale: 6, default: "1.0", null: false
    t.string "invoice_number"
    t.date "issue_date"
    t.text "notes"
    t.datetime "paid_date"
    t.string "payment_method"
    t.string "public_token"
    t.bigint "recurring_invoice_id"
    t.string "status"
    t.decimal "subtotal"
    t.decimal "tax_amount"
    t.decimal "tax_rate"
    t.decimal "total_amount"
    t.datetime "updated_at", null: false
    t.uuid "uuid", null: false
    t.index ["account_id", "external_source", "external_ref"], name: "index_invoices_on_external_ref", unique: true, where: "(external_ref IS NOT NULL)"
    t.index ["account_id"], name: "index_invoices_on_account_id"
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["public_token"], name: "index_invoices_on_public_token", unique: true
    t.index ["recurring_invoice_id"], name: "index_invoices_on_recurring_invoice_id"
    t.index ["uuid"], name: "index_invoices_on_uuid", unique: true
  end

  create_table "noticed_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.jsonb "params"
    t.bigint "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "read_at", precision: nil
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "amount"
    t.string "client_reference"
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "invoice_id"
    t.jsonb "metadata"
    t.string "note"
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

  create_table "qr_scans", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.bigint "step", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "step"], name: "index_qr_scans_on_account_id_and_step", unique: true
    t.index ["account_id"], name: "index_qr_scans_on_account_id"
  end

  create_table "recurring_invoice_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "position", default: 0
    t.decimal "quantity", default: "1.0"
    t.bigint "recurring_invoice_id", null: false
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index ["recurring_invoice_id"], name: "index_recurring_invoice_items_on_recurring_invoice_id"
  end

  create_table "recurring_invoices", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "auto_send", default: false, null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "GMD", null: false
    t.integer "due_in_days", default: 14, null: false
    t.date "end_date"
    t.string "frequency", default: "monthly", null: false
    t.decimal "fx_rate", precision: 18, scale: 6, default: "1.0", null: false
    t.integer "interval", default: 1, null: false
    t.date "last_run_on"
    t.integer "max_occurrences"
    t.date "next_run_on"
    t.text "notes"
    t.integer "occurrences_count", default: 0, null: false
    t.date "start_date", null: false
    t.string "status", default: "active", null: false
    t.decimal "tax_rate", default: "0.0"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_recurring_invoices_on_account_id"
    t.index ["client_id"], name: "index_recurring_invoices_on_client_id"
    t.index ["status", "next_run_on"], name: "index_recurring_invoices_on_status_and_next_run_on"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.boolean "platform_admin", default: false, null: false
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

  create_table "wave_imports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "committed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "kind"
    t.string "original_filename"
    t.jsonb "preview", default: {}, null: false
    t.datetime "previewed_at"
    t.jsonb "result", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id", "created_at"], name: "index_wave_imports_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_wave_imports_on_account_id"
    t.index ["user_id"], name: "index_wave_imports_on_user_id"
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
  add_foreign_key "invoices", "recurring_invoices"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payouts", "accounts"
  add_foreign_key "products", "accounts"
  add_foreign_key "qr_scans", "accounts"
  add_foreign_key "recurring_invoice_items", "recurring_invoices"
  add_foreign_key "recurring_invoices", "accounts"
  add_foreign_key "recurring_invoices", "clients"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "wave_imports", "accounts"
  add_foreign_key "wave_imports", "users"
end
