require "rails_helper"

RSpec.describe LeaveNotificationJob do
  let(:company)      { create(:company) }
  let(:leave_policy) { create(:leave_policy, company: company) }
  let(:leave_type)   { create(:leave_type, leave_policy: leave_policy) }
  let(:employee)     { create(:user, :employee, company: company) }
  let(:manager)      { create(:user, :manager, company: company, expo_push_token: "ExpoPushToken123") }

  let(:application) do
    create(:leave_application, user: employee, leave_type: leave_type,
           status: :pending, company: company, approver: manager)
  end

  before do
    allow(LeaveMailer).to receive_message_chain(:notification, :deliver_now)
    allow(LeaveMailer).to receive_message_chain(:application_cancelled, :deliver_now)
  end

  describe "push notifications" do
    it "sends push to approver when leave is applied" do
      expect(Net::HTTP).to receive(:new).and_wrap_original do |method, *args|
        http = method.call(*args)
        expect(http).to receive(:request) do |req|
          body = JSON.parse(req.body)
          expect(body["to"]).to eq("ExpoPushToken123")
          expect(body["title"]).to eq("New leave request")
          Net::HTTPSuccess.new("1.1", "200", "OK")
        end
        http
      end

      described_class.perform_now(application.id, "applied")
    end

    it "sends push to employee when leave is approved" do
      employee.update!(expo_push_token: "ExpoPushToken456")

      expect(Net::HTTP).to receive(:new).and_wrap_original do |method, *args|
        http = method.call(*args)
        expect(http).to receive(:request) do |req|
          body = JSON.parse(req.body)
          expect(body["to"]).to eq("ExpoPushToken456")
          expect(body["title"]).to eq("Leave approved")
          Net::HTTPSuccess.new("1.1", "200", "OK")
        end
        http
      end

      described_class.perform_now(application.id, "approved")
    end

    it "does not send push when token is blank" do
      expect(Net::HTTP).not_to receive(:new)
      described_class.perform_now(application.id, "applied")
    end

    it "does not raise when push fails" do
      manager.update!(expo_push_token: "ExpoPushToken123")
      allow(Net::HTTP).to receive(:new).and_raise(Errno::ECONNREFUSED)

      expect { described_class.perform_now(application.id, "applied") }.not_to raise_error
    end
  end

  describe "email notifications" do
    it "sends manager_notification when leave is applied" do
      mail_double = double(deliver_now: nil)
      expect(LeaveMailer).to receive(:notification).with(manager, application, :applied).and_return(mail_double)
      described_class.perform_now(application.id, "applied")
    end

    it "sends application_approved when leave is approved" do
      mail_double = double(deliver_now: nil)
      expect(LeaveMailer).to receive(:notification).with(employee, application, :approved).and_return(mail_double)
      described_class.perform_now(application.id, "approved")
    end

    it "sends application_rejected when leave is rejected" do
      mail_double = double(deliver_now: nil)
      expect(LeaveMailer).to receive(:notification).with(employee, application, :rejected).and_return(mail_double)
      described_class.perform_now(application.id, "rejected")
    end

    it "sends application_cancelled when leave is cancelled" do
      mail_double = double(deliver_now: nil)
      expect(LeaveMailer).to receive(:notification).with(manager, application, :cancelled).and_return(mail_double)
      described_class.perform_now(application.id, "cancelled")
    end

    it "does not send email when manager is not present" do
      application.update!(approver: nil)
      expect(LeaveMailer).not_to receive(:notification)
      described_class.perform_now(application.id, "cancelled")
    end
  end
end