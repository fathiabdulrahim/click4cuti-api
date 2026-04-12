FactoryBot.define do
  factory :user_work_schedule do
    association :user
    association :work_schedule
    effective_from { Date.current }
  end
end
