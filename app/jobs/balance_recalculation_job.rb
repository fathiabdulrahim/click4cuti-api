class BalanceRecalculationJob < ApplicationJob
  queue_as :low

  def perform(leave_policy_id, year = Date.current.year)
    policy = LeavePolicy.find(leave_policy_id)

    UserLeavePolicy.where(leave_policy: policy).active_on(Date.current).each do |ulp|
      user = ulp.user

      policy.leave_types.active.each do |leave_type|
        next if leave_type.shared_balance_with.present?

        balance = LeaveBalance.find_by(user: user, leave_type: leave_type, year: year)
        next unless balance

        calculator = Leaves::BalanceCalculator.new(user, leave_type, year)
        new_entitled = calculator.entitled_days

        balance.update!(
          total_entitled: new_entitled,
          remaining_days: new_entitled + balance.carried_forward - balance.used_days - balance.pending_days
        )
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "BalanceRecalculationJob: #{e.message}"
  end
end
