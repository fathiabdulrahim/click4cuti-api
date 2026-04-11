class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :full_name, :role, :company_id, :employee_id, :is_active, :is_confirmed, :join_date

  association :department,  blueprint: DepartmentBlueprint
  association :designation, blueprint: DesignationBlueprint

  view :detail do
    fields :phone, :address, :gender, :number_of_children, :manager_id,
           :department_id, :designation_id, :created_at, :updated_at

    association :manager, blueprint: UserBlueprint do |user, _options|
      user.manager
    end
  end

  view :admin do
    include_view :detail
    fields :sign_in_count, :last_sign_in_at, :last_sign_in_ip
  end
end
