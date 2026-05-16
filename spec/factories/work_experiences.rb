FactoryBot.define do
  factory :work_experience do
    company_name { Faker::Company.name }
    position { Faker::Job.title }
    start_date { 3.years.ago.to_date }
    end_date { 1.year.ago.to_date }
    association :user
  end
end
