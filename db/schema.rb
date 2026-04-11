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

ActiveRecord::Schema[8.1].define(version: 2026_04_01_000022) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.uuid "actor_id", null: false
    t.string "actor_type", null: false
    t.uuid "company_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "details"
    t.uuid "entity_id"
    t.string "entity_type"
    t.string "ip_address"
    t.index ["actor_id", "actor_type"], name: "index_activity_logs_on_actor_id_and_actor_type"
    t.index ["company_id"], name: "index_activity_logs_on_company_id"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
  end

  create_table "admin_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "agency_id"
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name", null: false
    t.boolean "is_active", default: true, null: false
    t.string "jti", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "phone"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "scope", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_admin_users_on_agency_id"
    t.index ["company_id"], name: "index_admin_users_on_company_id"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["jti"], name: "index_admin_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.uuid "agency_id"
    t.datetime "created_at", null: false
    t.string "hr_email", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "registration_number"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_companies_on_agency_id"
    t.index ["registration_number"], name: "index_companies_on_registration_number", unique: true, where: "(registration_number IS NOT NULL)"
  end

  create_table "departments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.index ["company_id"], name: "index_departments_on_company_id"
  end

  create_table "designations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_manager", default: false, null: false
    t.string "title", null: false
    t.index ["company_id"], name: "index_designations_on_company_id"
  end

  create_table "email_notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body", null: false
    t.uuid "company_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "delivery_status", default: "PENDING", null: false
    t.string "notification_type", null: false
    t.string "recipient_email", null: false
    t.uuid "recipient_id", null: false
    t.string "recipient_type", null: false
    t.uuid "reference_id"
    t.string "reference_type"
    t.datetime "sent_at"
    t.string "subject", null: false
    t.index ["company_id"], name: "index_email_notifications_on_company_id"
    t.index ["delivery_status"], name: "index_email_notifications_on_delivery_status"
    t.index ["recipient_id", "recipient_type"], name: "index_email_notifications_on_recipient_id_and_recipient_type"
  end

  create_table "hr_agencies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_hr_agencies_on_email", unique: true
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["exp"], name: "index_jwt_denylist_on_exp"
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "leave_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "approved_by"
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.text "extended_reason"
    t.uuid "leave_type_id", null: false
    t.text "reason", null: false
    t.boolean "requires_ceo_approval", default: false, null: false
    t.text "reviewer_remarks"
    t.date "start_date", null: false
    t.string "status", default: "PENDING", null: false
    t.decimal "total_days", precision: 8, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["approved_by"], name: "index_leave_applications_on_approved_by"
    t.index ["leave_type_id"], name: "index_leave_applications_on_leave_type_id"
    t.index ["user_id", "created_at"], name: "index_leave_applications_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_leave_applications_on_user_id_and_status"
  end

  create_table "leave_balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "carried_forward", precision: 8, scale: 2, default: "0.0", null: false
    t.uuid "leave_type_id", null: false
    t.decimal "pending_days", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "remaining_days", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "total_entitled", precision: 8, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "used_days", precision: 8, scale: 2, default: "0.0", null: false
    t.uuid "user_id", null: false
    t.integer "year", null: false
    t.index ["leave_type_id"], name: "index_leave_balances_on_leave_type_id"
    t.index ["user_id", "leave_type_id", "year"], name: "index_leave_balances_on_user_id_and_leave_type_id_and_year", unique: true
  end

  create_table "leave_day_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "day_type", null: false
    t.uuid "leave_application_id", null: false
    t.date "leave_date", null: false
    t.index ["leave_application_id", "leave_date"], name: "index_leave_day_details_on_leave_application_id_and_leave_date", unique: true
    t.index ["leave_application_id"], name: "index_leave_day_details_on_leave_application_id"
  end

  create_table "leave_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content_type"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "file_name", null: false
    t.string "file_path"
    t.integer "file_size"
    t.uuid "leave_application_id", null: false
    t.index ["leave_application_id"], name: "index_leave_documents_on_leave_application_id"
  end

  create_table "leave_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "advance_notice_days", default: 7, null: false
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_leave_policies_on_company_id"
  end

  create_table "leave_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "allows_carry_forward", default: false, null: false
    t.boolean "allows_half_day", default: true, null: false
    t.string "category", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "default_days_tier1", default: 0, null: false
    t.integer "default_days_tier2", default: 0, null: false
    t.integer "default_days_tier3", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.uuid "leave_policy_id", null: false
    t.integer "max_carry_forward_days"
    t.integer "max_consecutive_days"
    t.integer "max_times_per_year"
    t.string "name", null: false
    t.boolean "requires_document", default: false, null: false
    t.uuid "shared_balance_with"
    t.index ["leave_policy_id"], name: "index_leave_types_on_leave_policy_id"
    t.index ["shared_balance_with"], name: "index_leave_types_on_shared_balance_with"
  end

  create_table "public_holidays", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.date "holiday_date", null: false
    t.boolean "is_mandatory", default: false, null: false
    t.boolean "is_replacement", default: false, null: false
    t.string "name", null: false
    t.integer "year", null: false
    t.index ["company_id", "holiday_date"], name: "index_public_holidays_on_company_id_and_holiday_date", unique: true
    t.index ["company_id", "year"], name: "index_public_holidays_on_company_id_and_year"
  end

  create_table "user_leave_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.uuid "leave_policy_id", null: false
    t.uuid "user_id", null: false
    t.index ["leave_policy_id"], name: "index_user_leave_policies_on_leave_policy_id"
    t.index ["user_id", "leave_policy_id"], name: "index_user_leave_policies_on_user_id_and_leave_policy_id"
  end

  create_table "user_work_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.uuid "user_id", null: false
    t.uuid "work_schedule_id", null: false
    t.index ["user_id", "work_schedule_id"], name: "index_user_work_schedules_on_user_id_and_work_schedule_id"
    t.index ["work_schedule_id"], name: "index_user_work_schedules_on_work_schedule_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.uuid "department_id"
    t.uuid "designation_id"
    t.string "email", null: false
    t.string "employee_id"
    t.string "encrypted_password", default: "", null: false
    t.string "full_name", null: false
    t.string "gender"
    t.boolean "is_active", default: true, null: false
    t.boolean "is_confirmed", default: false, null: false
    t.date "join_date", null: false
    t.string "jti", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.uuid "manager_id"
    t.integer "number_of_children", default: 0, null: false
    t.string "phone"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "is_active"], name: "index_users_on_company_id_and_is_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_id", "company_id"], name: "index_users_on_employee_id_and_company_id", unique: true, where: "(employee_id IS NOT NULL)"
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.string "event", null: false
    t.uuid "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "request_ip"
    t.string "status_change"
    t.string "whodunnit"
    t.index ["company_id", "created_at"], name: "index_versions_on_company_id_and_created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "warning_letters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "acknowledged", default: false, null: false
    t.datetime "acknowledged_at"
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.date "issued_date", null: false
    t.uuid "leave_type_id", null: false
    t.string "reason", null: false
    t.uuid "user_id", null: false
    t.integer "year", null: false
    t.index ["company_id"], name: "index_warning_letters_on_company_id"
    t.index ["user_id", "year"], name: "index_warning_letters_on_user_id_and_year"
    t.index ["user_id"], name: "index_warning_letters_on_user_id"
  end

  create_table "work_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.time "break_end"
    t.time "break_start"
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.time "end_time", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "rest_days", null: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_work_schedules_on_company_id"
  end
end
