FactoryBot.define do
  factory :training do
    association :user
    title { Faker::Educator.course_name }
    start_date { 60.days.ago.to_date }
    end_date { 55.days.ago.to_date }
    description { Faker::Lorem.paragraph }
    received_date { 50.days.ago.to_date }
    expired_date { 2.years.from_now.to_date }
  end
end
