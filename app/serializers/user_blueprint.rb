class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :full_name, :first_name, :last_name, :role, :company_id,
         :employee_id, :is_active, :is_confirmed, :join_date, :expo_push_token

  association :department,  blueprint: DepartmentBlueprint
  association :designation, blueprint: DesignationBlueprint

  view :detail do
    fields :phone, :mobile_phone, :personal_email, :address, :mailing_address,
           :emergency_contact_name, :emergency_contact_phone,
           :gender, :number_of_children, :manager_id,
           :department_id, :designation_id, :branch_id,
           :nric, :nric_old, :nric_color, :date_of_birth, :place_of_birth,
           :race, :religion, :blood_type, :education_level,
           :marital_status, :nationality, :bumi_status,
           :driving_license_number, :driving_license_class, :driving_license_expiry,
           :date_of_sign, :employee_type, :probation_period_days, :oku_status,
           :ea_person_in_charge_id,
           :notifications_enabled, :clock_in_selfie_enabled,
           :early_late_indicator_enabled, :attendance_confirmation_enabled,
           :created_at, :updated_at

    association :manager, blueprint: UserBlueprint do |user, _options|
      user.manager
    end

    field :leave_approver_ids do |user, _options|
      user.leave_approver_ids
    end

    association :leave_approvers, blueprint: UserBlueprint

    association :leave_supervisor_l1, blueprint: UserBlueprint do |user, _options|
      user.leave_supervisor_l1
    end

    association :leave_supervisor_l2, blueprint: UserBlueprint do |user, _options|
      user.leave_supervisor_l2
    end
  end

  view :admin do
    include_view :detail
    fields :sign_in_count, :last_sign_in_at, :last_sign_in_ip
  end
end