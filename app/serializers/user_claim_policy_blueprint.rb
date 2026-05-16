class UserClaimPolicyBlueprint < Blueprinter::Base
  identifier :id
  fields :user_id, :claim_type_id, :application_limit, :annual_limit,
         :is_unlimited_application, :is_unlimited_annual, :is_included, :remarks

  association :claim_type, blueprint: ClaimTypeBlueprint
end
