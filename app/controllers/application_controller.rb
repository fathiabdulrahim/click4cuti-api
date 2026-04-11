class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :set_paper_trail_whodunnit

  rescue_from Pundit::NotAuthorizedError,         with: :forbidden
  rescue_from ActiveRecord::RecordNotFound,       with: :not_found
  rescue_from ActiveRecord::RecordInvalid,        with: :unprocessable
  rescue_from ActionController::ParameterMissing, with: :bad_request

  def user_for_paper_trail
    current_user&.id&.to_s || current_admin_user&.id&.to_s
  end

  def info_for_paper_trail
    { request_ip: request.remote_ip }
  end

  private

  def forbidden(e)
    render json: { error: "Forbidden", message: e.message }, status: :forbidden
  end

  def not_found
    render json: { error: "Not Found" }, status: :not_found
  end

  def unprocessable(e)
    render json: { error: "Unprocessable Entity", messages: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

  def bad_request(e)
    render json: { error: "Bad Request", message: e.message }, status: :bad_request
  end
end
