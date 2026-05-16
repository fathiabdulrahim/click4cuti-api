FactoryBot.define do
  factory :claim_type do
    association :company
    sequence(:name) { |n| "Claim Type #{n}" }
    code { name.upcase.gsub(/\s+/, "_") }
    description { Faker::Lorem.sentence }
    default_application_limit { 500.00 }
    default_annual_limit { 6000.00 }
    requires_document { false }
    is_active { true }
  end
end
