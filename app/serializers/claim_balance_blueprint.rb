class ClaimBalanceBlueprint < Blueprinter::Base
  identifier :id
  fields :user_id, :claim_type_id, :year, :annual_limit,
         :pending_amount, :used_amount, :remaining_amount

  association :claim_type, blueprint: ClaimTypeBlueprint
end
