class FamilyMemberBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :relation, :first_name, :last_name, :gender,
         :nric_or_passport, :date_of_birth, :phone, :email, :address,
         :employment_status, :oku_status

  view :detail do
    fields :created_at, :updated_at
  end
end
