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

ActiveRecord::Schema[7.0].define(version: 2025_09_09_231547) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_reports", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.bigint "user_id", null: false
    t.bigint "report_type_id", null: false
    t.bigint "report_subtype_id"
    t.string "reportable_type"
    t.bigint "reportable_id"
    t.date "analysis_period_start"
    t.date "analysis_period_end"
    t.text "analysis_context"
    t.jsonb "ai_request_data"
    t.jsonb "ai_response_data"
    t.jsonb "parsed_insights"
    t.string "ai_model_used"
    t.string "tokens_used"
    t.decimal "processing_time", precision: 8, scale: 3
    t.boolean "processing_success", default: true
    t.text "error_message"
    t.datetime "expires_at"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_ai_reports_on_expires_at"
    t.index ["report_subtype_id"], name: "index_ai_reports_on_report_subtype_id"
    t.index ["report_type_id", "analysis_period_start", "analysis_period_end"], name: "index_ai_reports_on_type_and_period"
    t.index ["report_type_id"], name: "index_ai_reports_on_report_type_id"
    t.index ["reportable_type", "reportable_id"], name: "index_ai_reports_on_reportable"
    t.index ["user_id", "report_type_id", "created_at"], name: "index_ai_reports_on_user_id_and_report_type_id_and_created_at"
    t.index ["user_id", "reportable_type", "reportable_id"], name: "index_ai_reports_on_user_and_reportable"
    t.index ["user_id"], name: "index_ai_reports_on_user_id"
    t.index ["uuid"], name: "index_ai_reports_on_uuid", unique: true
  end

  create_table "budgets", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.decimal "current_amount", precision: 10, scale: 2, default: "0.0"
    t.bigint "budget_type_id", null: false
    t.bigint "color_id", null: false
    t.bigint "icon_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.boolean "personal", default: false
    t.bigint "user_id", null: false
    t.index ["budget_type_id"], name: "index_budgets_on_budget_type_id"
    t.index ["color_id"], name: "index_budgets_on_color_id"
    t.index ["icon_id"], name: "index_budgets_on_icon_id"
    t.index ["user_id"], name: "index_budgets_on_user_id"
    t.index ["uuid"], name: "index_budgets_on_uuid", unique: true
  end

  create_table "catalogs", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.string "value"
    t.string "code"
    t.bigint "group_catalog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_catalog_id"], name: "index_catalogs_on_group_catalog_id"
    t.index ["uuid"], name: "index_catalogs_on_uuid", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.string "name"
    t.text "description"
    t.bigint "parent_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
    t.index ["uuid"], name: "index_categories_on_uuid", unique: true
  end

  create_table "credit_card_cycle_transactions", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.bigint "transaction_id", null: false
    t.bigint "credit_card_cycle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_card_cycle_id"], name: "index_credit_card_cycle_transactions_on_credit_card_cycle_id"
    t.index ["transaction_id"], name: "index_credit_card_cycle_transactions_on_transaction_id"
    t.index ["uuid"], name: "index_credit_card_cycle_transactions_on_uuid", unique: true
  end

  create_table "credit_card_cycles", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.bigint "credit_card_id", null: false
    t.date "cutting_date"
    t.date "payment_due_date"
    t.decimal "current_balance", precision: 10, scale: 2, default: "0.0"
    t.decimal "minimum_payment", precision: 10, scale: 2, default: "0.0"
    t.decimal "interest_charges", precision: 10, scale: 2, default: "0.0"
    t.decimal "fees", precision: 10, scale: 2, default: "0.0"
    t.decimal "payments_received", precision: 10, scale: 2, default: "0.0"
    t.decimal "purchases_made", precision: 10, scale: 2, default: "0.0"
    t.bigint "status_id", null: false
    t.datetime "statement_generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "historical_balance", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "cycle_balance", precision: 15, scale: 2, default: "0.0", null: false
    t.index ["credit_card_id", "cutting_date"], name: "index_credit_card_cycles_on_credit_card_id_and_cutting_date", unique: true
    t.index ["credit_card_id"], name: "index_credit_card_cycles_on_credit_card_id"
    t.index ["cutting_date"], name: "index_credit_card_cycles_on_cutting_date"
    t.index ["payment_due_date"], name: "index_credit_card_cycles_on_payment_due_date"
    t.index ["status_id"], name: "index_credit_card_cycles_on_status_id"
    t.index ["uuid"], name: "index_credit_card_cycles_on_uuid", unique: true
  end

  create_table "credit_cards", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.decimal "limit_amount"
    t.bigint "budget_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cutting_day"
    t.integer "payment_due_days", default: 5
    t.decimal "initial_debt", precision: 10, scale: 2, default: "0.0"
    t.index ["budget_id"], name: "index_credit_cards_on_budget_id"
    t.index ["uuid"], name: "index_credit_cards_on_uuid", unique: true
  end

  create_table "currencies", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.string "name"
    t.string "code"
    t.string "symbol"
    t.decimal "exchange_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_currencies_on_uuid", unique: true
  end

  create_table "group_catalogs", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.string "name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_group_catalogs_on_uuid", unique: true
  end

  create_table "recurring_transactions", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.bigint "user_id", null: false
    t.integer "frequency"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "next_execution_date"
    t.integer "status", default: 0
    t.integer "execution_count", default: 0
    t.integer "max_executions"
    t.text "tags"
    t.boolean "auto_approve", default: true
    t.jsonb "transaction_options", default: {}
    t.index ["user_id"], name: "index_recurring_transactions_on_user_id"
    t.index ["uuid"], name: "index_recurring_transactions_on_uuid", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_roles_on_uuid", unique: true
  end

  create_table "savings_funds", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.decimal "goal_amount"
    t.date "target_date"
    t.decimal "monthly_contribution"
    t.decimal "interest_rate"
    t.bigint "compound_frequency_id", null: false
    t.decimal "minimum_balance"
    t.decimal "max_balance"
    t.string "account_number"
    t.bigint "account_type_id", null: false
    t.boolean "auto_transfer"
    t.integer "transfer_day"
    t.date "next_contribution_date"
    t.decimal "early_withdrawal_penalty"
    t.integer "withdrawal_limit"
    t.boolean "has_withdrawal_restrictions"
    t.date "maturity_date"
    t.date "last_interest_payment"
    t.decimal "low_balance_alert"
    t.boolean "goal_milestone_alerts"
    t.bigint "budget_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_type_id"], name: "index_savings_funds_on_account_type_id"
    t.index ["budget_id"], name: "index_savings_funds_on_budget_id"
    t.index ["compound_frequency_id"], name: "index_savings_funds_on_compound_frequency_id"
    t.index ["uuid"], name: "index_savings_funds_on_uuid", unique: true
  end

  create_table "statuses", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.string "code"
    t.string "name"
    t.string "color"
    t.bigint "group_catalog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_catalog_id"], name: "index_statuses_on_group_catalog_id"
    t.index ["uuid"], name: "index_statuses_on_uuid", unique: true
  end

  create_table "transaction_histories", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.bigint "transaction_id", null: false
    t.decimal "pre_amount"
    t.decimal "post_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transaction_id"], name: "index_transaction_histories_on_transaction_id"
    t.index ["uuid"], name: "index_transaction_histories_on_uuid", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.decimal "amount"
    t.text "description"
    t.bigint "category_id", null: false
    t.bigint "user_id", null: false
    t.bigint "currency_id", null: false
    t.date "transaction_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "budget_id"
    t.bigint "related_budget_id"
    t.bigint "related_transaction_id"
    t.bigint "icon_id"
    t.bigint "color_id"
    t.bigint "transaction_type_id", null: false
    t.bigint "recurring_transaction_id"
    t.index ["budget_id"], name: "index_transactions_on_budget_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["color_id"], name: "index_transactions_on_color_id"
    t.index ["currency_id"], name: "index_transactions_on_currency_id"
    t.index ["icon_id"], name: "index_transactions_on_icon_id"
    t.index ["recurring_transaction_id"], name: "index_transactions_on_recurring_transaction_id"
    t.index ["related_budget_id"], name: "index_transactions_on_related_budget_id"
    t.index ["related_transaction_id"], name: "index_transactions_on_related_transaction_id"
    t.index ["transaction_type_id"], name: "index_transactions_on_transaction_type_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
    t.index ["uuid"], name: "index_transactions_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.string "first_name"
    t.string "last_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.bigint "role_id", null: false
    t.bigint "currency_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["currency_id"], name: "index_users_on_currency_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_reports", "catalogs", column: "report_subtype_id", name: "fk_ai_reports_report_subtype"
  add_foreign_key "ai_reports", "catalogs", column: "report_type_id", name: "fk_ai_reports_report_type"
  add_foreign_key "ai_reports", "users", name: "fk_ai_reports_users"
  add_foreign_key "budgets", "catalogs", column: "budget_type_id", name: "fk_budgets_budget_type"
  add_foreign_key "budgets", "catalogs", column: "color_id", name: "fk_budgets_color"
  add_foreign_key "budgets", "catalogs", column: "icon_id", name: "fk_budgets_icon"
  add_foreign_key "budgets", "users", name: "fk_budgets_user"
  add_foreign_key "catalogs", "group_catalogs", name: "fk_catalogs_group_catalog"
  add_foreign_key "categories", "categories", column: "parent_category_id", name: "fk_categories_parent"
  add_foreign_key "credit_card_cycle_transactions", "credit_card_cycles", name: "fk_ccct_credit_card_cycles"
  add_foreign_key "credit_card_cycle_transactions", "transactions", name: "fk_ccct_transactions"
  add_foreign_key "credit_card_cycles", "credit_cards", name: "fk_credit_card_cycles_credit_card"
  add_foreign_key "credit_card_cycles", "statuses", name: "fk_credit_card_cycles_status"
  add_foreign_key "credit_cards", "budgets", name: "fk_credit_cards_budget"
  add_foreign_key "recurring_transactions", "users", name: "fk_recurring_transactions_user"
  add_foreign_key "savings_funds", "budgets", name: "fk_savings_funds_budget"
  add_foreign_key "savings_funds", "catalogs", column: "account_type_id", name: "fk_savings_funds_account_type"
  add_foreign_key "savings_funds", "catalogs", column: "compound_frequency_id", name: "fk_savings_funds_compound_frequency"
  add_foreign_key "statuses", "group_catalogs", name: "fk_statuses_group_catalog"
  add_foreign_key "transaction_histories", "transactions", name: "fk_transaction_histories_transactions"
  add_foreign_key "transactions", "budgets", column: "related_budget_id", name: "fk_transactions_related_budget"
  add_foreign_key "transactions", "budgets", name: "fk_transactions_budget"
  add_foreign_key "transactions", "catalogs", column: "color_id", name: "fk_transactions_color"
  add_foreign_key "transactions", "catalogs", column: "icon_id", name: "fk_transactions_icon"
  add_foreign_key "transactions", "catalogs", column: "transaction_type_id", name: "fk_transactions_transaction_type"
  add_foreign_key "transactions", "categories", name: "fk_transactions_category"
  add_foreign_key "transactions", "currencies", name: "fk_transactions_currency"
  add_foreign_key "transactions", "recurring_transactions", name: "fk_recurring_transaction_transactions"
  add_foreign_key "transactions", "transactions", column: "related_transaction_id", name: "fk_transactions_related_transaction"
  add_foreign_key "transactions", "users", name: "fk_transactions_user"
  add_foreign_key "users", "roles", column: "currency_id", name: "fk_users_currency"
  add_foreign_key "users", "roles", name: "fk_users_role"
end
