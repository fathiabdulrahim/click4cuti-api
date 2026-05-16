FactoryBot.define do
  factory :career_progress do
    association :user
    company { user.company }
    job_title { Faker::Job.title }
    effective_date { 1.year.ago.to_date }
    job_type { "PERMANENT" }
    description { Faker::Lorem.paragraph }
  end
end
