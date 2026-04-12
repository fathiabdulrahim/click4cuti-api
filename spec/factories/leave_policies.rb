FactoryBot.define do
  factory :leave_policy do
    name { "Standard Leave Policy" }
    description { "Company leave policy" }
    advance_notice_days { 7 }
    is_active { true }
    association :company
  end
end
