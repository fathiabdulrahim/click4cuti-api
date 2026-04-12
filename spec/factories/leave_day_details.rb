FactoryBot.define do
  factory :leave_day_detail do
    association :leave_application
    leave_date { 1.week.from_now.to_date }
    day_type { "FULL_DAY" }

    trait :half_day_am do
      day_type { "HALF_DAY_AM" }
    end

    trait :half_day_pm do
      day_type { "HALF_DAY_PM" }
    end
  end
end
