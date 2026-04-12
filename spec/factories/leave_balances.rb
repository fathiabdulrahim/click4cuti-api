FactoryBot.define do
  factory :leave_balance do
    association :user
    association :leave_type
    year { Date.current.year }
    total_entitled { 12.0 }
    carried_forward { 0.0 }
    used_days { 0.0 }
    pending_days { 0.0 }
    remaining_days { 12.0 }
  end
end
