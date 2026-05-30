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
end