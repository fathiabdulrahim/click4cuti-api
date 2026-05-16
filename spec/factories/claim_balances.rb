FactoryBot.define do
  factory :claim_balance do
    association :user
    association :claim_type
    year { Date.current.year }
    annual_limit { 6000.00 }
    pending_amount { 0 }
    used_amount { 0 }
    remaining_amount { 6000.00 }
  end
end
