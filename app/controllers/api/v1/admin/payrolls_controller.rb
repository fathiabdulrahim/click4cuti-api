module Api
  module V1
    module Admin
      class PayrollsController < BaseController
        skip_after_action :verify_policy_scoped
        before_action :set_user

        def show
          authorize :payroll, :show?
          render json: payroll_payload
        end

        def update
          authorize :payroll, :update?
          ActiveRecord::Base.transaction do
            update_one(@user.bank_detail || @user.build_bank_detail,           bank_params)
            update_one(@user.statutory_detail || @user.build_statutory_detail, statutory_params)
            update_one(@user.tax_relief || @user.build_tax_relief,             tax_relief_params)
          end
          log_activity("payroll.update", @user)
          render json: payroll_payload
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def update_one(record, attrs)
          return if attrs.blank?
          record.assign_attributes(attrs)
          record.save!
        end

        def bank_params
          nested = params.dig(:payroll, :bank_detail)
          return {} if nested.blank?
          nested.permit(:bank_name, :account_number, :account_type, :branch, :account_status)
        end

        def statutory_params
          nested = params.dig(:payroll, :statutory_detail)
          return {} if nested.blank?
          nested.permit(
            :epf_number, :epf_contribution_start, :socso_number, :socso_contribution_start_age,
            :eis_employee_rate, :eis_employer_rate, :income_tax_number, :vola_amount
          )
        end

        def tax_relief_params
          nested = params.dig(:payroll, :tax_relief)
          return {} if nested.blank?
          nested.permit(:spouse_is_working, :spouse_is_disabled, :spouse_gender,
                        :contributes_to_sip, :tax_category)
        end

        def payroll_payload
          {
            user_id:          @user.id,
            bank_detail:      @user.bank_detail      && UserBankDetailBlueprint.render_as_hash(@user.bank_detail),
            statutory_detail: @user.statutory_detail && UserStatutoryDetailBlueprint.render_as_hash(@user.statutory_detail),
            tax_relief:       @user.tax_relief       && UserTaxReliefBlueprint.render_as_hash(@user.tax_relief)
          }
        end
      end
    end
  end
end
