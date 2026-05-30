require "net/http"

class LeaveNotificationJob < ApplicationJob
  queue_as :default

  EXPO_PUSH_URL = "https://exp.host/--/api/v2/push/send"

  def perform(application_id, event)
    application = LeaveApplication.includes(:user, :leave_type, :approver).find(application_id)

    case event
    when "applied"
      notify_managers(application)
      notify_admins(application, event)
      push_to_approver(application, "New Leave Request", "#{application.user.full_name} requested #{application.leave_type.name}")
    when "approved"
      notify_employee(application, :approved)
      push_to_employee(application, "Leave Approved", "Your #{application.leave_type.name} has been approved")
    when "rejected"
      notify_employee(application, :rejected)
      push_to_employee(application, "Leave Rejected", "Your #{application.leave_type.name} has been rejected")
    when "cancelled"
      notify_approver(application)
      notify_admins(application, event)
      push_to_approver(application, "Leave Cancelled", "#{application.user.full_name} cancelled their #{application.leave_type.name} request")
    end
  end

  private

  # --- Email notifications ---

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

  def notify_admins(application, event)
    admin_recipients(application).each do |admin|
      LeaveMailer.admin_leave_notification(application, admin, event).deliver_now
      push_to_admin(admin, event, application)
    end
  end

  def admin_recipients(application)
    company_id = application.user.company_id
    AdminUser.active.where(
      "scope = ? OR (scope = ? AND company_id = ?)",
      AdminUser.scopes[:super_admin],
      AdminUser.scopes[:company],
      company_id
    )
  end

  # --- Push notifications ---

  def push_to_employee(application, title, body)
    token = application.user.expo_push_token
    send_expo_push(token, title, body, { leave_id: application.id, status: application.status })
  end

  def push_to_approver(application, title, body)
    return unless application.approver
    token = application.approver.expo_push_token
    send_expo_push(token, title, body, { leave_id: application.id, status: application.status })
  end

  def push_to_admin(admin, event, application)
    token = admin.expo_push_token
    return if token.blank?

    title = case event
            when "applied" then "New Leave Request"
            when "cancelled" then "Leave Cancelled"
            else return
            end

    body = "#{application.user.full_name} #{event} #{application.leave_type.name}"
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