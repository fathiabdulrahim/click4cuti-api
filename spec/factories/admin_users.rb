FactoryBot.define do
  factory :admin_user do
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    scope { :super_admin }
    is_active { true }

    trait :super_admin do
      scope { :super_admin }
    end

    trait :agency do
      scope { :agency }
    end

    trait :company do
      scope { :company }
      association :company
    end

    trait :inactive do
      is_active { false }
    end

    trait :with_push_token do
      expo_push_token { "ExponentPushToken[#{Faker::Alphanumeric.alphanumeric(number: 20)}]" }
    end
  end
end