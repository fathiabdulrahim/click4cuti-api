class ClaimApplicationBlueprint < Blueprinter::Base
  identifier :id
  fields :user_id, :claim_type_id, :amount, :claim_date, :reason, :status,
         :approver_id, :approver_type, :reviewer_remarks

  association :claim_type, blueprint: ClaimTypeBlueprint

  view :detail do
    fields :created_at, :updated_at
  end
end
