FactoryBot.define do
  factory :family_member do
    association :user
    relation { "CHILD" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    gender { "MALE" }
    date_of_birth { 5.years.ago.to_date }
    employment_status { "NOT_WORKING" }
    oku_status { false }

    trait :spouse do
      relation { "SPOUSE" }
      date_of_birth { 30.years.ago.to_date }
      employment_status { "WORKING" }
    end

    trait :parent do
      relation { "PARENT" }
      date_of_birth { 60.years.ago.to_date }
      employment_status { "RETIRED" }
    end
  end
end
