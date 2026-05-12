FactoryBot.define do
  factory :user_leave_approver do
    association :user
    association :approver, factory: :user

    after(:build) do |ula|
      if ula.user&.company_id && ula.approver && ula.approver.company_id != ula.user.company_id
        ula.approver.update!(company_id: ula.user.company_id)
      end
    end
  end
end
