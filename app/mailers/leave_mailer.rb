class LeaveMailer < ApplicationMailer
  def application_submitted(application)
    @application = application
    @user        = application.user
    @leave_type  = application.leave_type

    mail(
      to:      @user.email,
      subject: "Leave Application Submitted — #{@leave_type.name}"
    ) do |format|
      format.html { render_html_email }
      format.text { render_text_email }
    end
  end

  def manager_notification(application)
    @application = application
    @user        = application.user
    @manager     = @user.manager
    @leave_type  = application.leave_type

    return unless @manager&.email

    mail(
      to:      @manager.email,
      subject: "New Leave Request from #{@user.full_name} — #{@leave_type.name}"
    ) do |format|
      format.text do
        render plain: "#{@user.full_name} has applied for #{@leave_type.name} from #{@application.start_date} to #{@application.end_date} (#{@application.total_days} days). Reason: #{@application.reason}"
      end
    end
  end

  def application_approved(application)
    @application = application
    @user        = application.user
    @leave_type  = application.leave_type

    mail(
      to:      @user.email,
      subject: "Leave Application Approved — #{@leave_type.name}"
    ) do |format|
      format.text do
        render plain: "Your #{@leave_type.name} application from #{@application.start_date} to #{@application.end_date} has been approved."
      end
    end
  end

  def application_rejected(application)
    @application = application
    @user        = application.user
    @leave_type  = application.leave_type

    mail(
      to:      @user.email,
      subject: "Leave Application Rejected — #{@leave_type.name}"
    ) do |format|
      format.text do
        remarks = @application.reviewer_remarks.present? ? " Remarks: #{@application.reviewer_remarks}" : ""
        render plain: "Your #{@leave_type.name} application from #{@application.start_date} to #{@application.end_date} has been rejected.#{remarks}"
      end
    end
  end

  private

  def render_html_email
    render plain: "<p>Your leave application for <strong>#{@leave_type.name}</strong> from #{@application.start_date} to #{@application.end_date} (#{@application.total_days} days) has been submitted.</p>"
  end

  def render_text_email
    render plain: "Your #{@leave_type.name} application from #{@application.start_date} to #{@application.end_date} (#{@application.total_days} days) has been submitted and is pending approval."
  end
end
