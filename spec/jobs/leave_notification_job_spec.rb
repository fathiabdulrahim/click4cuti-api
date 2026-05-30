require "rails_helper"

RSpec.describe LeaveNotificationJob do
  let(:company)      { create(:company) }
  let(:leave_policy) { create(:leave_policy, company: company) }
  let(:leave_type)   { create(:leave_type, leave_policy: leave_policy) }
  let(:manager) do
    create(:user, :manager, company: company, expo_push_token: "ExponentPushToken[mgr123]")
  end
  let(:employee) do
    create(:user, :employee, company: company, manager: manager,
                             expo_push_token: "ExponentPushToken[emp456]")
  end
  let(:application) { create(:leave_application, user: employee, leave_type: leave_type) }

  before do
    allow(LeaveMailer).to receive_message_chain(:application_submitted, :deliver_now)
    allow(LeaveMailer).to receive_message_chain(:manager_notification, :deliver_now)
    allow(LeaveMailer).to receive_message_chain(:application_approved, :deliver_now)
    allow(LeaveMailer).to receive_message_chain(:application_rejected, :deliver_now)
    allow(LeaveMailer).to receive_message_chain(:application_cancelled, :deliver_now)
    allow(EmailNotification).to receive(:create!)
  end

  describe "email notifications" do
    let(:mail_double) { double("mail", deliver_now: nil) }

    describe "applied event" do
      it "sends application_submitted to the employee" do
        expect(LeaveMailer).to receive(:application_submitted).with(application).and_return(mail_double)
        described_class.new.perform(application.id, "applied")
      end

      it "sends manager_notification to the manager" do
        expect(LeaveMailer).to receive(:manager_notification).with(application).and_return(mail_double)
        described_class.new.perform(application.id, "applied")
      end

      context "when the employee has no manager" do
        let(:employee) { create(:user, :employee, company: company, expo_push_token: "ExponentPushToken[emp456]") }

        it "does not send manager_notification" do
          expect(LeaveMailer).not_to receive(:manager_notification)
          described_class.new.perform(application.id, "applied")
        end
      end
    end

    describe "approved event" do
      let(:application) { create(:leave_application, :approved, user: employee, leave_type: leave_type) }

      it "sends application_approved to the employee" do
        expect(LeaveMailer).to receive(:application_approved).with(application).and_return(mail_double)
        described_class.new.perform(application.id, "approved")
      end
    end

    describe "rejected event" do
      let(:application) { create(:leave_application, :rejected, user: employee, leave_type: leave_type) }

      it "sends application_rejected to the employee" do
        expect(LeaveMailer).to receive(:application_rejected).with(application).and_return(mail_double)
        described_class.new.perform(application.id, "rejected")
      end
    end

    describe "cancelled event" do
      let(:application) { create(:leave_application, :cancelled, user: employee, leave_type: leave_type) }

      it "sends application_cancelled to the manager" do
        expect(LeaveMailer).to receive(:application_cancelled).with(application).and_return(mail_double)
        described_class.new.perform(application.id, "cancelled")
      end

      context "when the employee has no manager" do
        let(:employee) { create(:user, :employee, company: company, expo_push_token: "ExponentPushToken[emp456]") }
        let(:application) { create(:leave_application, :cancelled, user: employee, leave_type: leave_type) }

        it "does not send application_cancelled" do
          expect(LeaveMailer).not_to receive(:application_cancelled)
          described_class.new.perform(application.id, "cancelled")
        end
      end
    end
  end

  describe "Expo push notifications" do
    let(:job) { described_class.new }

    describe "applied event" do
      it "sends push to the L1 approver" do
        expect(job).to receive(:send_expo_push).with(
          manager.expo_push_token,
          "New Leave Request",
          a_string_including(employee.full_name),
          hash_including(leave_id: application.id, status: "PENDING")
        )
        job.perform(application.id, "applied")
      end
    end

    describe "approved event" do
      let(:application) { create(:leave_application, :approved, user: employee, leave_type: leave_type) }

      it "sends push to the employee" do
        expect(job).to receive(:send_expo_push).with(
          employee.expo_push_token,
          "Leave Approved",
          a_string_including(leave_type.name),
          hash_including(leave_id: application.id, status: "APPROVED")
        )
        job.perform(application.id, "approved")
      end
    end

    describe "rejected event" do
      let(:application) { create(:leave_application, :rejected, user: employee, leave_type: leave_type) }

      it "sends push to the employee" do
        expect(job).to receive(:send_expo_push).with(
          employee.expo_push_token,
          "Leave Rejected",
          a_string_including(leave_type.name),
          hash_including(leave_id: application.id, status: "REJECTED")
        )
        job.perform(application.id, "rejected")
      end
    end

    describe "cancelled event" do
      let(:application) { create(:leave_application, :cancelled, user: employee, leave_type: leave_type) }

      it "sends push to the L1 approver" do
        expect(job).to receive(:send_expo_push).with(
          manager.expo_push_token,
          "Leave Cancelled",
          a_string_including(employee.full_name),
          hash_including(leave_id: application.id, status: "CANCELLED")
        )
        job.perform(application.id, "cancelled")
      end
    end

    describe "when recipient has no expo_push_token" do
      it "does not make an HTTP request" do
        employee.update!(expo_push_token: nil)
        approved_app = create(:leave_application, :approved, user: employee, leave_type: leave_type)
        expect(Net::HTTP).not_to receive(:new)
        job.perform(approved_app.id, "approved")
      end
    end

    describe "when Expo API is unreachable" do
      it "does not raise or crash the job" do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ECONNREFUSED)
        expect { job.perform(application.id, "applied") }.not_to raise_error
      end
    end

    context "when the L1 approver has a blank expo_push_token" do
      before { manager.update!(expo_push_token: nil) }

      it "does not make an HTTP request for applied" do
        expect(Net::HTTP).not_to receive(:new)
        job.perform(application.id, "applied")
      end

      it "does not make an HTTP request for cancelled" do
        cancelled_app = create(:leave_application, :cancelled, user: employee, leave_type: leave_type)
        expect(Net::HTTP).not_to receive(:new)
        job.perform(cancelled_app.id, "cancelled")
      end
    end

    context "when the L1 approver is an AdminUser" do
      let(:admin_approver) { create(:admin_user, :company, company: company) }

      it "does not send a push notification" do
        allow_any_instance_of(User).to receive(:leave_supervisor_l1).and_return(admin_approver)
        expect(Net::HTTP).not_to receive(:new)
        job.perform(application.id, "applied")
      end
    end
  end

  describe "when the application does not exist" do
    it "does not raise" do
      expect { described_class.new.perform(SecureRandom.uuid, "applied") }.not_to raise_error
    end
  end

  describe "unknown event" do
    it "sends no email" do
      expect(LeaveMailer).not_to receive(:application_submitted)
      expect(LeaveMailer).not_to receive(:manager_notification)
      expect(LeaveMailer).not_to receive(:application_approved)
      expect(LeaveMailer).not_to receive(:application_rejected)
      expect(LeaveMailer).not_to receive(:application_cancelled)
      described_class.new.perform(application.id, "bogus")
    end

    it "makes no HTTP request" do
      expect(Net::HTTP).not_to receive(:new)
      described_class.new.perform(application.id, "bogus")
    end
  end
end