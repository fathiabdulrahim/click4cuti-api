FactoryBot.define do
  factory :user_leave_policy do
    association :user
    association :leave_policy
    effective_from { Date.current }
  end
end
