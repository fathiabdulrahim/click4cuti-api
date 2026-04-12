FactoryBot.define do
  factory :leave_application do
    association :user
    association :leave_type
    start_date { 1.week.from_now.to_date }
    end_date { 1.week.from_now.to_date + 1.day }
    reason { Faker::Lorem.sentence }
    status { "PENDING" }
    total_days { 2.0 }
    requires_ceo_approval { false }

    trait :approved do
      status { "APPROVED" }
    end

    trait :rejected do
      status { "REJECTED" }
    end

    trait :cancelled do
      status { "CANCELLED" }
    end
  end
end
