module Api
  module V1
    class TrainingsController < BaseController
      before_action :set_training, only: [ :show, :update, :destroy ]

      def index
        records = policy_scope(Training).where(user_id: current_user.id).order(start_date: :desc)
        render json: TrainingBlueprint.render(records)
      end

      def show
        authorize @training
        render json: TrainingBlueprint.render(@training, view: :detail)
      end

      def create
        @training = current_user.trainings.new(training_params)
        @training.certification.attach(params[:certification]) if params[:certification].present?
        authorize @training
        if @training.save
          log_activity("training.create", @training)
          render json: TrainingBlueprint.render(@training), status: :created
        else
          render json: { errors: @training.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @training
        @training.assign_attributes(training_params)
        @training.certification.attach(params[:certification]) if params[:certification].present?
        if @training.save
          log_activity("training.update", @training)
          render json: TrainingBlueprint.render(@training)
        else
          render json: { errors: @training.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @training
        @training.destroy!
        log_activity("training.destroy", @training)
        head :no_content
      end

      private

      def set_training
        @training = Training.find(params[:id])
      end

      def training_params
        params.permit(:title, :start_date, :end_date, :description, :received_date, :expired_date)
      end
    end
  end
end
