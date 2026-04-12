FactoryBot.define do
  factory :work_schedule do
    name { "Standard Schedule" }
    association :company
    start_time { "09:00" }
    end_time { "18:00" }
    break_start { "13:00" }
    break_end { "14:00" }
    rest_days { "SATURDAY,SUNDAY" }
    is_active { true }
  end
end
