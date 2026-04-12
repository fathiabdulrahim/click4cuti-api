FactoryBot.define do
  factory :admin_user do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "Password123!" }
    is_active { true }

    trait :super_admin do
      scope { "SUPER_ADMIN" }
      company { nil }
      hr_agency { nil }
    end

    trait :agency do
      scope { "AGENCY" }
      association :hr_agency
      company { nil }
    end

    trait :company do
      scope { "COMPANY" }
      association :company
      hr_agency { nil }
    end
  end
end
