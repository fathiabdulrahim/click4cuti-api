module Leaves
  # Calculates leave entitlement per EA 1955 based on years of service
  class BalanceCalculator
    # EA 1955 defaults per tier (fallback if leave type tiers not configured)
    ANNUAL_LEAVE   = { tier1: 8,  tier2: 12, tier3: 16 }.freeze
    SICK_LEAVE     = { tier1: 14, tier2: 18, tier3: 22 }.freeze

    def initialize(user, leave_type, year = Date.current.year)
      @user       = user
      @leave_type = leave_type
      @year       = year
    end

    def entitled_days
      tier = @user.leave_entitlement_tier
      case tier
      when 1 then @leave_type.default_days_tier1
      when 2 then @leave_type.default_days_tier2
      else        @leave_type.default_days_tier3
      end
    end

    def carried_forward_days(previous_balance)
      return 0 unless @leave_type.allows_carry_forward?
      return 0 unless previous_balance

      remaining = previous_balance.remaining_days
      max = @leave_type.max_carry_forward_days
      max.present? ? [remaining, max].min : remaining
    end

    def build_balance(carried_forward: 0)
      entitled = entitled_days
      LeaveBalance.new(
        user:             @user,
        leave_type:       @leave_type,
        year:             @year,
        total_entitled:   entitled,
        carried_forward:  carried_forward,
        used_days:        0,
        pending_days:     0,
        remaining_days:   entitled + carried_forward
      )
    end
  end
end
