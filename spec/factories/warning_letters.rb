FactoryBot.define do
  factory :warning_letter do
    association :user
    association :company
    association :leave_type
    reason { Faker::Lorem.sentence }
    year { Date.current.year }
    issued_date { Date.current }
    acknowledged { false }
  end
end
