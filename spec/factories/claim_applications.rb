FactoryBot.define do
  factory :claim_application do
    association :user
    association :claim_type
    amount { 150.00 }
    claim_date { Date.current }
    reason { Faker::Lorem.sentence }
    status { "PENDING" }
  end
end
