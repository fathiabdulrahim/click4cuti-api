FactoryBot.define do
  factory :designation do
    title { Faker::Job.unique.title }
    association :company
    is_active { true }
    is_manager { false }

    trait :manager do
      is_manager { true }
    end
  end
end
