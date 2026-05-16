FactoryBot.define do
  factory :user_tax_relief do
    association :user
    spouse_is_working { false }
    spouse_is_disabled { false }
    spouse_gender { nil }
    contributes_to_sip { true }
    tax_category { "REGULAR" }
  end
end
