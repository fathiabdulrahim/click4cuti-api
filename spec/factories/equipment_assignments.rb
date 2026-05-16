FactoryBot.define do
  factory :equipment_assignment do
    association :user
    equipment_type { "Laptop" }
    equipment_details { "MacBook Pro 14\" M3 — Serial: ABC123" }
    date_received { 6.months.ago.to_date }
  end
end
