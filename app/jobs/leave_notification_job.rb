require "net/http"

class LeaveNotificationJob < ApplicationJob
  queue_as :default

  EXPO_PUSH_URL = "https://exp.host/--/api/v2/push/send"

  def perform(application_id, event)
    application = LeaveApplication.includes(:user, :leave_type, :approver).find(application_id)

    case event
    when "applied"
      notify_managers(application)
      push_to_approver(application, "New leave request", "#{application.user.full_name} requested #{application.leave_type.name}")
    when "approved"
      notify_employee(application, :approved)
      push_to_employee(application, "Leave approved", "Your #{application.leave_type.name} has been approved")
    when "rejected"
      notify_employee(application, :rejected)
      push_to_employee(application, "Leave rejected", "Your #{application.leave_type.name} has been rejected")
    when "cancelled"
      notify_approver(application)
      LeaveMailer.application_cancelled(application).deliver_now if application.user.manager.present?
      push_to_approver(application, "Leave cancelled", "#{application.user.full_name} cancelled their #{application.leave_type.name} request")
    end
  end

  private

  def notify_managers(application)
    approvers = [application.approver].compact
    approvers.each do |manager|
      LeaveMailer.notification(manager, application, :applied).deliver_now
    end
  end

  def notify_employee(application, status)
    LeaveMailer.notification(application.user, application, status).deliver_now
  end

  def notify_approver(application)
    return unless application.approver
    LeaveMailer.notification(application.approver, application, :cancelled).deliver_now
  end

  def push_to_employee(application, title, body)
    token = application.user.expo_push_token
    send_expo_push(token, title, body, { leave_id: application.id, status: application.status })
  end

  def push_to_approver(application, title, body)
    return unless application.approver
    token = application.approver.expo_push_token
    send_expo_push(token, title, body, { leave_id: application.id, status: application.status })
  end

  def send_expo_push(token, title, body, data)
    return if token.blank?

    uri = URI(EXPO_PUSH_URL)
    payload = { to: token, title: title, body: body, data: data }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = payload

    response = http.request(request)
    Rails.logger.info("[ExpoPush] #{response.code} #{response.body}") unless response.is_a?(Net::HTTPSuccess)
  rescue => e
    Rails.logger.warn("[ExpoPush] Failed: #{e.message}")
  end
end