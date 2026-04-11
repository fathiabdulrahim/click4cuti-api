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

        def update
          letter = policy_scope(WarningLetter).find(params[:id])
          authorize letter
          letter.update!(acknowledged: true, acknowledged_at: Time.current)
          render json: WarningLetterBlueprint.render(letter)
        end
      end
    end
  end
end
