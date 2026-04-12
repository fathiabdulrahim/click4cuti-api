FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "Password123!" }
    role { "EMPLOYEE" }
    join_date { 1.year.ago.to_date }
    gender { "MALE" }
    number_of_children { 0 }
    is_active { true }
    association :company

    trait :admin do
      role { "ADMIN" }
    end

    trait :manager do
      role { "MANAGER" }
    end

    trait :employee do
      role { "EMPLOYEE" }
    end

    trait :inactive do
      is_active { false }
    end
  end
end
