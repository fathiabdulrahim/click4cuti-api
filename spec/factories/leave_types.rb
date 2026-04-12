FactoryBot.define do
  factory :leave_type do
    name { "Annual Leave" }
    category { "MANDATORY" }
    default_days_tier1 { 8 }
    default_days_tier2 { 12 }
    default_days_tier3 { 16 }
    max_consecutive_days { 3 }
    requires_document { false }
    allows_half_day { true }
    allows_carry_forward { true }
    max_carry_forward_days { 8 }
    is_active { true }
    association :leave_policy

    trait :sick_leave do
      name { "Sick Leave" }
      default_days_tier1 { 14 }
      default_days_tier2 { 18 }
      default_days_tier3 { 22 }
      requires_document { true }
      allows_half_day { false }
      allows_carry_forward { false }
      max_carry_forward_days { nil }
      max_consecutive_days { nil }
    end

    trait :emergency_leave do
      name { "Emergency Leave" }
      default_days_tier1 { 0 }
      default_days_tier2 { 0 }
      default_days_tier3 { 0 }
      max_times_per_year { 3 }
      allows_carry_forward { false }
      max_carry_forward_days { nil }
      max_consecutive_days { nil }
    end
  end
end
