FactoryBot.define do
  factory :public_holiday do
    sequence(:name) { |n| "Public Holiday #{n}" }
    association :company
    sequence(:holiday_date) { |n| Date.new(Date.current.year, 1, 1) + (n * 30).days }
    year { Date.current.year }
    is_mandatory { true }
    is_replacement { false }
  end
end
