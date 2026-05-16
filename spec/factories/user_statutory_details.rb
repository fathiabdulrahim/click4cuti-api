FactoryBot.define do
  factory :user_statutory_detail do
    association :user
    epf_number { Faker::Number.number(digits: 8).to_s }
    epf_contribution_start { "AFTER_2001_AUG" }
    socso_number { Faker::Number.number(digits: 9).to_s }
    socso_contribution_start_age { 25 }
    eis_employee_rate { 0.002 }
    eis_employer_rate { 0.002 }
    income_tax_number { "SG#{Faker::Number.number(digits: 10)}" }
    vola_amount { 0 }
  end
end
