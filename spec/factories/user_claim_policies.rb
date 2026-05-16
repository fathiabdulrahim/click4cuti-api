FactoryBot.define do
  factory :user_claim_policy do
    association :user
    association :claim_type
    application_limit { 500.00 }
    annual_limit { 6000.00 }
    is_unlimited_application { false }
    is_unlimited_annual { false }
    is_included { true }
  end
end
