module Users
  class OnboardService
    Error = Class.new(StandardError)

    def initialize(params, admin_user)
      @params     = params.to_h.with_indifferent_access
      @admin_user = admin_user
    end

    def call
      ActiveRecord::Base.transaction do
        company_id = resolve_company_id
        password   = @params.delete(:password) || SecureRandom.hex(8)

        user = User.create!(
          company_id:         company_id,
          full_name:          @params[:full_name],
          email:              @params[:email],
          phone:              @params[:phone],
          address:            @params[:address],
          role:               @params[:role] || :employee,
          join_date:          @params[:join_date],
          gender:             @params[:gender],
          number_of_children: @params[:number_of_children] || 0,
          is_confirmed:       @params[:is_confirmed] || false,
          department_id:      @params[:department_id],
          designation_id:     @params[:designation_id],
          manager_id:         @params[:manager_id],
          employee_id:        @params[:employee_id],
          password:           password,
          password_confirmation: password
        )

        assign_leave_policy!(user)
        initialize_balances!(user)

        user
      end
    end

    private

    def resolve_company_id
      if @admin_user.is_a?(AdminUser) && @admin_user.company?
        @admin_user.company_id
      else
        @params[:company_id] || raise(Error, "company_id is required")
      end
    end

    def assign_leave_policy!(user)
      policy_id = @params[:leave_policy_id]
      policy = policy_id ? LeavePolicy.find(policy_id) : LeavePolicy.where(company_id: user.company_id).active.first
      return unless policy

      UserLeavePolicy.create!(
        user:           user,
        leave_policy:   policy,
        effective_from: user.join_date
      )
    end

    def initialize_balances!(user)
      policy = user.leave_policies.active.first
      return unless policy

      year = Date.current.year
      policy.leave_types.active.each do |leave_type|
        next if leave_type.shared_balance_with.present?

        calculator = Leaves::BalanceCalculator.new(user, leave_type, year)
        balance = calculator.build_balance
        balance.save!
      end
    end
  end
end
