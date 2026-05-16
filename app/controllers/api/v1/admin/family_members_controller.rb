module Api
  module V1
    module Admin
      class FamilyMembersController < BaseController
        before_action :set_user
        before_action :set_family_member, only: [ :show, :update, :destroy ]

        def index
          records = policy_scope(FamilyMember).where(user_id: @user.id).order(:relation, :date_of_birth)
          render json: FamilyMemberBlueprint.render(records)
        end

        def show
          authorize @family_member
          render json: FamilyMemberBlueprint.render(@family_member, view: :detail)
        end

        def create
          @family_member = @user.family_members.new(family_member_params)
          authorize @family_member
          if @family_member.save
            log_activity("family_member.create", @family_member)
            render json: FamilyMemberBlueprint.render(@family_member), status: :created
          else
            render json: { errors: @family_member.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          authorize @family_member
          if @family_member.update(family_member_params)
            log_activity("family_member.update", @family_member)
            render json: FamilyMemberBlueprint.render(@family_member)
          else
            render json: { errors: @family_member.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @family_member
          @family_member.destroy!
          log_activity("family_member.destroy", @family_member)
          head :no_content
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end

        def set_family_member
          @family_member = FamilyMember.find(params[:id])
        end

        def family_member_params
          params.require(:family_member).permit(
            :relation, :first_name, :last_name, :gender,
            :nric_or_passport, :date_of_birth, :phone, :email, :address,
            :employment_status, :oku_status
          )
        end
      end
    end
  end
end
