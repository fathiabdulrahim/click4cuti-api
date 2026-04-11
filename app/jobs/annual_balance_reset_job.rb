class AnnualBalanceResetJob < ApplicationJob
  queue_as :low

  def perform(year = Date.current.year)
    new_year = year + 1
    Rails.logger.info "AnnualBalanceResetJob: resetting balances for #{new_year}"

    User.active.find_each do |user|
      policy = user.user_leave_policies.current.first&.leave_policy
      next unless policy

      policy.leave_types.active.each do |leave_type|
        next if leave_type.shared_balance_with.present?

        prev_balance = LeaveBalance.find_by(user: user, leave_type: leave_type, year: year)
        calculator   = Leaves::BalanceCalculator.new(user, leave_type, new_year)
        cf = calculator.carried_forward_days(prev_balance)
        balance = calculator.build_balance(carried_forward: cf)

        existing = LeaveBalance.find_by(user: user, leave_type: leave_type, year: new_year)
        if existing
          existing.update!(
            total_entitled:  balance.total_entitled,
            carried_forward: balance.carried_forward,
            remaining_days:  balance.remaining_days
          )
        else
          balance.save!
        end
      end
    end
  end
end
