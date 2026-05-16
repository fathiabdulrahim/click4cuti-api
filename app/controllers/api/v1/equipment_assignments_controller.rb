module Api
  module V1
    class EquipmentAssignmentsController < BaseController
      before_action :set_assignment, only: [ :show, :update, :destroy ]

      def index
        records = policy_scope(EquipmentAssignment).where(user_id: current_user.id).order(date_received: :desc)
        render json: EquipmentAssignmentBlueprint.render(records)
      end

      def show
        authorize @assignment
        render json: EquipmentAssignmentBlueprint.render(@assignment, view: :detail)
      end

      def create
        @assignment = current_user.equipment_assignments.new(assignment_params)
        @assignment.supporting_document.attach(params[:supporting_document]) if params[:supporting_document].present?
        authorize @assignment
        if @assignment.save
          log_activity("equipment_assignment.create", @assignment)
          render json: EquipmentAssignmentBlueprint.render(@assignment), status: :created
        else
          render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @assignment
        @assignment.assign_attributes(assignment_params)
        @assignment.supporting_document.attach(params[:supporting_document]) if params[:supporting_document].present?
        if @assignment.save
          log_activity("equipment_assignment.update", @assignment)
          render json: EquipmentAssignmentBlueprint.render(@assignment)
        else
          render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @assignment
        @assignment.destroy!
        log_activity("equipment_assignment.destroy", @assignment)
        head :no_content
      end

      private

      def set_assignment
        @assignment = EquipmentAssignment.find(params[:id])
      end

      def assignment_params
        params.permit(:equipment_type, :equipment_details, :date_received, :date_return)
      end
    end
  end
end
