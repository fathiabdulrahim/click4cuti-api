FactoryBot.define do
  factory :company do
    name { Faker::Company.unique.name }
    hr_email { Faker::Internet.unique.email }
    registration_number { Faker::Company.unique.ein }
    address { Faker::Address.full_address }
    state { "Selangor" }
    is_active { true }

    trait :with_agency do
      association :hr_agency
    end

    trait :inactive do
      is_active { false }
    end
  end
end
