FactoryBot.define do
  factory :department do
    name { Faker::Commerce.unique.department }
    association :company
    is_active { true }
  end
end
