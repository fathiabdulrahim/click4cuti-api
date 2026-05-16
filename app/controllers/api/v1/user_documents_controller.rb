module Api
  module V1
    class UserDocumentsController < BaseController
      before_action :set_doc, only: [ :show, :update, :destroy ]

      def index
        records = policy_scope(UserDocument).where(user_id: current_user.id).order(created_at: :desc)
        render json: UserDocumentBlueprint.render(records)
      end

      def show
        authorize @doc
        render json: UserDocumentBlueprint.render(@doc, view: :detail)
      end

      def create
        @doc = current_user.user_documents.new(remarks: params[:remarks])
        @doc.file.attach(params[:file]) if params[:file].present?
        authorize @doc
        if @doc.save
          log_activity("user_document.create", @doc)
          render json: UserDocumentBlueprint.render(@doc), status: :created
        else
          render json: { errors: @doc.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @doc
        @doc.assign_attributes(remarks: params[:remarks]) if params[:remarks].present?
        @doc.file.attach(params[:file]) if params[:file].present?
        if @doc.save
          log_activity("user_document.update", @doc)
          render json: UserDocumentBlueprint.render(@doc)
        else
          render json: { errors: @doc.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @doc
        @doc.destroy!
        log_activity("user_document.destroy", @doc)
        head :no_content
      end

      private

      def set_doc
        @doc = UserDocument.find(params[:id])
      end
    end
  end
end
