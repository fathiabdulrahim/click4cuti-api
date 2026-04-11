module Api
  module V1
    module Admin
      class WorkSchedulesController < BaseController
        def index
          schedules = policy_scope(WorkSchedule).order(:name)
          render json: WorkScheduleBlueprint.render(schedules)
        end

        def show
          schedule = policy_scope(WorkSchedule).find(params[:id])
          authorize schedule
          render json: WorkScheduleBlueprint.render(schedule)
        end

        def create
          authorize WorkSchedule
          schedule = WorkSchedule.create!(schedule_params)
          render json: WorkScheduleBlueprint.render(schedule), status: :created
        end

        def update
          schedule = policy_scope(WorkSchedule).find(params[:id])
          authorize schedule
          schedule.update!(schedule_params)
          render json: WorkScheduleBlueprint.render(schedule)
        end

        def destroy
          schedule = policy_scope(WorkSchedule).find(params[:id])
          authorize schedule
          schedule.update!(is_active: false)
          render json: { message: "Work schedule deactivated." }
        end

        private

        def schedule_params
          params.require(:work_schedule).permit(
            :name, :start_time, :end_time, :break_start, :break_end, :rest_days, :is_active, :company_id
          )
        end
      end
    end
  end
end
