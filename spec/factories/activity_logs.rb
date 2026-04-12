FactoryBot.define do
  factory :activity_log do
    actor_id { SecureRandom.uuid }
    actor_type { "AdminUser" }
    action { "TEST_ACTION" }
    association :company
  end
end
