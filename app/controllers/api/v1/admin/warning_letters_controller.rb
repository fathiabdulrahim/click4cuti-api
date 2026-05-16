module Api
  module V1
    module Admin
      class WarningLettersController < BaseController
        def index
          letters = policy_scope(WarningLetter).includes(:user, :leave_type).order(created_at: :desc)
          render json: WarningLetterBlueprint.render(letters)
        end

        def show
          letter = policy_scope(WarningLetter).find(params[:id])
          authorize letter
          render json: WarningLetterBlueprint.render(letter, view: :detail)
        end

        def create
          user = User.find(params.require(:warning_letter).require(:user_id))
          @letter = user.warning_letters.new(create_params.merge(
            source:     "MANUAL",
            company_id: user.company_id,
            issued_by:  current_admin_user,
            year:       Date.current.year
          ))
          @letter.supporting_document.attach(params[:supporting_document]) if params[:supporting_document].present?
          authorize @letter
          if @letter.save
            log_activity("warning_letter.create", @letter)
            render json: WarningLetterBlueprint.render(@letter), status: :created
          else
            render json: { errors: @letter.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          @letter = policy_scope(WarningLetter).find(params[:id])
          authorize @letter
          if @letter.source_manual?
            @letter.assign_attributes(update_params)
            @letter.supporting_document.attach(params[:supporting_document]) if params[:supporting_document].present?
            if @letter.save
              log_activity("warning_letter.update", @letter)
              render json: WarningLetterBlueprint.render(@letter)
            else
              render json: { errors: @letter.errors.full_messages }, status: :unprocessable_entity
            end
          else
            # legacy AUTO behaviour: just acknowledge
            @letter.update!(acknowledged: true, acknowledged_at: Time.current)
            render json: WarningLetterBlueprint.render(@letter)
          end
        end

        private

        def create_params
          params.require(:warning_letter).permit(:reason, :details, :action_taken, :issued_date)
        end

        def update_params
          params.require(:warning_letter).permit(:reason, :details, :action_taken, :issued_date, :acknowledged)
        end
      end
    end
  end
end
