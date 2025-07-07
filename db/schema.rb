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

ActiveRecord::Schema[7.0].define(version: 2025_07_06_080731) do
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

  create_table "credit_cards", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.decimal "current_amount"
    t.decimal "limit_amount"
    t.decimal "debt_amount"
    t.date "payday"
    t.date "cutting_day"
    t.bigint "budget_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.decimal "amount"
    t.text "description"
    t.integer "transaction_type"
    t.bigint "category_id", null: false
    t.bigint "user_id", null: false
    t.bigint "currency_id", null: false
    t.integer "frequency"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_recurring_transactions_on_category_id"
    t.index ["currency_id"], name: "index_recurring_transactions_on_currency_id"
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

  create_table "transactions", force: :cascade do |t|
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "active", default: true
    t.decimal "amount"
    t.text "description"
    t.integer "transaction_type"
    t.bigint "category_id", null: false
    t.bigint "user_id", null: false
    t.bigint "currency_id", null: false
    t.date "transaction_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "budget_id"
    t.index ["budget_id"], name: "index_transactions_on_budget_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["currency_id"], name: "index_transactions_on_currency_id"
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
  add_foreign_key "budgets", "catalogs", column: "budget_type_id", name: "fk_budgets_budget_type"
  add_foreign_key "budgets", "catalogs", column: "color_id", name: "fk_budgets_color"
  add_foreign_key "budgets", "catalogs", column: "icon_id", name: "fk_budgets_icon"
  add_foreign_key "budgets", "users", name: "fk_budgets_user"
  add_foreign_key "catalogs", "group_catalogs", name: "fk_catalogs_group_catalog"
  add_foreign_key "categories", "categories", column: "parent_category_id", name: "fk_categories_parent"
  add_foreign_key "credit_cards", "budgets", name: "fk_credit_cards_budget"
  add_foreign_key "recurring_transactions", "categories", name: "fk_recurring_transactions_category"
  add_foreign_key "recurring_transactions", "currencies", name: "fk_recurring_transactions_currency"
  add_foreign_key "recurring_transactions", "users", name: "fk_recurring_transactions_user"
  add_foreign_key "transactions", "budgets", name: "fk_transactions_budget"
  add_foreign_key "transactions", "categories", name: "fk_transactions_category"
  add_foreign_key "transactions", "currencies", name: "fk_transactions_currency"
  add_foreign_key "transactions", "users", name: "fk_transactions_user"
  add_foreign_key "users", "roles", column: "currency_id", name: "fk_users_currency"
  add_foreign_key "users", "roles", name: "fk_users_role"
end
