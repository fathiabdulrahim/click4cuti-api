FactoryBot.define do
  factory :user_bank_detail do
    association :user
    bank_name { "Maybank" }
    account_number { Faker::Bank.account_number(digits: 12) }
    account_type { "SAVING" }
    branch { Faker::Address.city }
    account_status { "ACTIVE" }
  end
end
