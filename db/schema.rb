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

ActiveRecord::Schema[8.1].define(version: 2026_05_16_094106) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "branches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "state"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["company_id"], name: "index_branches_on_company_id"
  end

  create_table "career_progresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "department_id"
    t.text "description"
    t.date "effective_date", null: false
    t.string "job_title", null: false
    t.string "job_type"
    t.uuid "manager_id"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["company_id"], name: "index_career_progresses_on_company_id"
    t.index ["user_id", "effective_date"], name: "index_career_progresses_on_user_id_and_effective_date"
    t.index ["user_id"], name: "index_career_progresses_on_user_id"
  end

  create_table "claim_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.uuid "approver_id"
    t.string "approver_type"
    t.date "claim_date", null: false
    t.uuid "claim_type_id", null: false
    t.datetime "created_at", null: false
    t.text "reason", null: false
    t.text "reviewer_remarks"
    t.string "status", default: "PENDING", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["approver_type", "approver_id"], name: "index_claim_applications_on_approver_type_and_approver_id"
    t.index ["claim_type_id"], name: "index_claim_applications_on_claim_type_id"
    t.index ["user_id", "status"], name: "index_claim_applications_on_user_id_and_status"
    t.index ["user_id"], name: "index_claim_applications_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'CANCELLED'::character varying]::text[])", name: "claim_applications_status_check"
  end

  create_table "claim_balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "annual_limit", precision: 12, scale: 2, default: "0.0", null: false
    t.uuid "claim_type_id", null: false
    t.decimal "pending_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "remaining_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "used_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.uuid "user_id", null: false
    t.integer "year", null: false
    t.index ["claim_type_id"], name: "index_claim_balances_on_claim_type_id"
    t.index ["user_id", "claim_type_id", "year"], name: "index_claim_balances_on_user_type_year", unique: true
  end

  create_table "claim_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "claim_application_id", null: false
    t.string "content_type"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "file_name", null: false
    t.integer "file_size"
    t.index ["claim_application_id"], name: "index_claim_documents_on_claim_application_id"
  end

  create_table "claim_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "default_annual_limit", precision: 12, scale: 2
    t.decimal "default_application_limit", precision: 12, scale: 2
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.boolean "requires_document", default: false, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["company_id", "name"], name: "index_claim_types_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_claim_types_on_company_id"
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

  create_table "equipment_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.date "date_received", null: false
    t.date "date_return"
    t.text "equipment_details", null: false
    t.string "equipment_type", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_equipment_assignments_on_user_id"
  end

  create_table "family_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.date "date_of_birth", null: false
    t.string "email"
    t.string "employment_status", null: false
    t.string "first_name", null: false
    t.string "gender", null: false
    t.string "last_name"
    t.string "nric_or_passport"
    t.boolean "oku_status", default: false, null: false
    t.string "phone"
    t.string "relation", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "relation"], name: "index_family_members_on_user_id_and_relation"
    t.index ["user_id"], name: "index_family_members_on_user_id"
    t.check_constraint "employment_status::text = ANY (ARRAY['WORKING'::character varying, 'NOT_WORKING'::character varying, 'STUDYING'::character varying, 'RETIRED'::character varying]::text[])", name: "family_members_employment_status_check"
    t.check_constraint "relation::text = ANY (ARRAY['SPOUSE'::character varying, 'CHILD'::character varying, 'PARENT'::character varying]::text[])", name: "family_members_relation_check"
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
    t.uuid "approver_id"
    t.string "approver_type"
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
    t.index ["approver_id"], name: "index_leave_applications_on_approver_id"
    t.index ["approver_type", "approver_id"], name: "index_leave_applications_on_approver_type_and_approver_id"
    t.index ["leave_type_id"], name: "index_leave_applications_on_leave_type_id"
    t.index ["user_id", "created_at"], name: "index_leave_applications_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_leave_applications_on_user_id_and_status"
  end

  create_table "leave_balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "carried_forward", precision: 8, scale: 2, default: "0.0", null: false
    t.boolean "is_included", default: true, null: false
    t.uuid "leave_type_id", null: false
    t.decimal "pending_days", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "remaining_days", precision: 8, scale: 2, default: "0.0", null: false
    t.text "remarks"
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

  create_table "trainings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "description", null: false
    t.date "end_date", null: false
    t.date "expired_date", null: false
    t.date "received_date", null: false
    t.date "start_date", null: false
    t.string "title", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "expired_date"], name: "index_trainings_on_user_id_and_expired_date"
    t.index ["user_id"], name: "index_trainings_on_user_id"
  end

  create_table "user_bank_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "account_number"
    t.string "account_status"
    t.string "account_type"
    t.string "bank_name"
    t.string "branch"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_user_bank_details_on_user_id", unique: true
    t.check_constraint "account_status IS NULL OR (account_status::text = ANY (ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying]::text[]))", name: "user_bank_details_account_status_check"
    t.check_constraint "account_type IS NULL OR (account_type::text = ANY (ARRAY['SAVING'::character varying, 'CURRENT'::character varying, 'FIXED'::character varying, 'OTHERS'::character varying]::text[]))", name: "user_bank_details_account_type_check"
  end

  create_table "user_claim_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "annual_limit", precision: 12, scale: 2
    t.decimal "application_limit", precision: 12, scale: 2
    t.uuid "claim_type_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "is_included", default: true, null: false
    t.boolean "is_unlimited_annual", default: false, null: false
    t.boolean "is_unlimited_application", default: false, null: false
    t.text "remarks"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "claim_type_id"], name: "index_user_claim_policies_on_user_id_and_claim_type_id", unique: true
  end

  create_table "user_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "remarks", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_user_documents_on_user_id"
  end

  create_table "user_leave_approvers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "approver_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["approver_id"], name: "index_user_leave_approvers_on_approver_id"
    t.index ["user_id", "approver_id"], name: "index_user_leave_approvers_on_user_id_and_approver_id", unique: true
    t.check_constraint "user_id <> approver_id", name: "user_leave_approvers_no_self_assignment"
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

  create_table "user_statutory_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "eis_employee_rate", precision: 5, scale: 4
    t.decimal "eis_employer_rate", precision: 5, scale: 4
    t.string "epf_contribution_start"
    t.string "epf_number"
    t.string "income_tax_number"
    t.integer "socso_contribution_start_age"
    t.string "socso_number"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.decimal "vola_amount", precision: 10, scale: 2
    t.index ["user_id"], name: "index_user_statutory_details_on_user_id", unique: true
    t.check_constraint "epf_contribution_start IS NULL OR (epf_contribution_start::text = ANY (ARRAY['BEFORE_1998_AUG'::character varying, 'AFTER_1998_AUG'::character varying, 'AFTER_2001_AUG'::character varying]::text[]))", name: "user_statutory_details_epf_start_check"
  end

  create_table "user_supervisors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "level", null: false
    t.uuid "supervisor_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["supervisor_id"], name: "index_user_supervisors_on_supervisor_id"
    t.index ["user_id", "category", "level"], name: "idx_user_supervisors_unique", unique: true
    t.check_constraint "category::text = ANY (ARRAY['LEAVE'::character varying, 'CLAIM'::character varying, 'OVERTIME'::character varying, 'TIMEOFF'::character varying]::text[])", name: "user_supervisors_category_check"
    t.check_constraint "level = ANY (ARRAY[1, 2])", name: "user_supervisors_level_check"
    t.check_constraint "user_id <> supervisor_id", name: "user_supervisors_no_self_assignment"
  end

  create_table "user_tax_reliefs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "contributes_to_sip", default: false, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "spouse_gender"
    t.boolean "spouse_is_disabled"
    t.boolean "spouse_is_working"
    t.string "tax_category"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_user_tax_reliefs_on_user_id", unique: true
    t.check_constraint "spouse_gender IS NULL OR (spouse_gender::text = ANY (ARRAY['MALE'::character varying, 'FEMALE'::character varying]::text[]))", name: "user_tax_reliefs_spouse_gender_check"
    t.check_constraint "tax_category IS NULL OR (tax_category::text = ANY (ARRAY['REGULAR'::character varying, 'REP'::character varying, 'KNOWLEDGE_WORKER'::character varying]::text[]))", name: "user_tax_reliefs_category_check"
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
    t.boolean "attendance_confirmation_enabled", default: false, null: false
    t.string "blood_type"
    t.uuid "branch_id"
    t.string "bumi_status"
    t.boolean "clock_in_selfie_enabled", default: false, null: false
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.date "date_of_birth"
    t.date "date_of_sign"
    t.uuid "department_id"
    t.uuid "designation_id"
    t.string "driving_license_class"
    t.date "driving_license_expiry"
    t.string "driving_license_number"
    t.uuid "ea_person_in_charge_id"
    t.boolean "early_late_indicator_enabled", default: false, null: false
    t.string "education_level"
    t.string "email", null: false
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "employee_id"
    t.string "employee_type"
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "full_name", null: false
    t.string "gender"
    t.boolean "is_active", default: true, null: false
    t.boolean "is_confirmed", default: false, null: false
    t.date "join_date", null: false
    t.string "jti", null: false
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.text "mailing_address"
    t.uuid "manager_id"
    t.string "marital_status"
    t.string "mobile_phone"
    t.string "nationality"
    t.boolean "notifications_enabled", default: true, null: false
    t.string "nric"
    t.string "nric_color"
    t.string "nric_old"
    t.integer "number_of_children", default: 0, null: false
    t.boolean "oku_status", default: false, null: false
    t.string "personal_email"
    t.string "phone"
    t.string "place_of_birth"
    t.integer "probation_period_days"
    t.string "race"
    t.string "religion"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_users_on_branch_id"
    t.index ["company_id", "is_active"], name: "index_users_on_company_id_and_is_active"
    t.index ["ea_person_in_charge_id"], name: "index_users_on_ea_person_in_charge_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_id", "company_id"], name: "index_users_on_employee_id_and_company_id", unique: true, where: "(employee_id IS NOT NULL)"
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["nric", "company_id"], name: "index_users_on_nric_and_company_id", unique: true, where: "(nric IS NOT NULL)"
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
    t.text "action_taken"
    t.uuid "company_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "details"
    t.uuid "issued_by_id"
    t.string "issued_by_type"
    t.date "issued_date", null: false
    t.uuid "leave_type_id"
    t.string "reason", null: false
    t.string "source", default: "AUTO", null: false
    t.uuid "user_id", null: false
    t.integer "year", null: false
    t.index ["company_id"], name: "index_warning_letters_on_company_id"
    t.index ["issued_by_id"], name: "index_warning_letters_on_issued_by_id"
    t.index ["issued_by_type", "issued_by_id"], name: "index_warning_letters_on_issued_by_type_and_issued_by_id"
    t.index ["user_id", "year"], name: "index_warning_letters_on_user_id_and_year"
    t.index ["user_id"], name: "index_warning_letters_on_user_id"
    t.check_constraint "source::text = ANY (ARRAY['AUTO'::character varying, 'MANUAL'::character varying]::text[])", name: "warning_letters_source_check"
  end

  create_table "work_experiences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "company_name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.date "end_date"
    t.string "position", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_work_experiences_on_user_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "branches", "companies"
  add_foreign_key "career_progresses", "companies"
  add_foreign_key "career_progresses", "departments"
  add_foreign_key "career_progresses", "users"
  add_foreign_key "career_progresses", "users", column: "manager_id"
  add_foreign_key "claim_applications", "claim_types"
  add_foreign_key "claim_applications", "users"
  add_foreign_key "claim_balances", "claim_types"
  add_foreign_key "claim_balances", "users"
  add_foreign_key "claim_documents", "claim_applications"
  add_foreign_key "claim_types", "companies"
  add_foreign_key "equipment_assignments", "users"
  add_foreign_key "family_members", "users"
  add_foreign_key "trainings", "users"
  add_foreign_key "user_bank_details", "users"
  add_foreign_key "user_claim_policies", "claim_types"
  add_foreign_key "user_claim_policies", "users"
  add_foreign_key "user_documents", "users"
  add_foreign_key "user_statutory_details", "users"
  add_foreign_key "user_supervisors", "users"
  add_foreign_key "user_supervisors", "users", column: "supervisor_id"
  add_foreign_key "user_tax_reliefs", "users"
  add_foreign_key "users", "branches"
  add_foreign_key "users", "users", column: "ea_person_in_charge_id"
  add_foreign_key "work_experiences", "users"
end
