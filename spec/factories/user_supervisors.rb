FactoryBot.define do
  factory :user_supervisor do
    association :user
    association :supervisor, factory: :user
    category { "LEAVE" }
    level { 1 }
  end
end
