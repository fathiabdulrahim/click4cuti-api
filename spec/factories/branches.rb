FactoryBot.define do
  factory :branch do
    name { Faker::Address.city }
    address { Faker::Address.full_address }
    state { Faker::Address.state }
    is_active { true }
    association :company
  end
end
