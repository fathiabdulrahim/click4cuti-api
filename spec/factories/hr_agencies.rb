FactoryBot.define do
  factory :hr_agency do
    name { Faker::Company.unique.name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    is_active { true }

    trait :inactive do
      is_active { false }
    end
  end
end
