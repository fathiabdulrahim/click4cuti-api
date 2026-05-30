require "rails_helper"

RSpec.describe Leaves::UpdateService do
  let(:company)      { create(:company) }
  let(:leave_policy) { create(:leave_policy, company: company, advance_notice_days: 0) }
  let(:leave_type) do
    create(:leave_type,
           leave_policy:         leave_policy,
           max_consecutive_days: 3,
           is_active:            true)
  end
  let(:user) { create(:user, :employee, company: company) }
  let!(:user_leave_policy) do
    create(:user_leave_policy, user: user, leave_policy: leave_policy)
  end
  let!(:leave_balance) do
    create(:leave_balance,
           user:           user,
           leave_type:     leave_type,
           year:           Date.current.year,
           total_entitled: 12.0,
           remaining_days: 10.0,
           used_days:      0.0,
           pending_days:   2.0)
  end
  let(:work_schedule) do
    create(:work_schedule, company: company, rest_days: "Saturday,Sunday")
  end
  let!(:user_work_schedule) do
    create(:user_work_schedule, user: user, work_schedule: work_schedule)
  end

  # Existing pending leave (Mon-Tue, 2 working days)
  let!(:leave) do
    create(:leave_application,
           user:       user,
           leave_type: leave_type,
           start_date: Date.parse("2026-04-13"),
           end_date:   Date.parse("2026-04-14"),
           total_days: 2.0,
           status:     "PENDING",
           reason:     "Original reason")
  end

  let(:params) do
    {
      leave_type_id: leave_type.id,
      start_date:    "2026-04-13",
      end_date:      "2026-04-15",
      reason:        "Updated reason"
    }
  end

  subject { described_class.new(leave, user, params).call }

  before do
    allow(LeaveNotificationJob).to receive(:perform_later)
  end

  describe "#call" do
    context "happy path — extending the date range by one day" do
      it "returns the updated leave application" do
        result = subject

        expect(result).to eq(leave)
        expect(result.start_date).to eq(Date.parse("2026-04-13"))
        expect(result.end_date).to eq(Date.parse("2026-04-15"))
        expect(result.reason).to eq("Updated reason")
      end

      it "recalculates total_days for the new date range" do
        subject

        expect(leave.reload.total_days).to eq(3.0)
      end

      it "releases the old pending_days and holds the new amount" do
        subject

        leave_balance.reload
        # Was 2.0 pending, now 3.0 pending (released 2, held 3)
        expect(leave_balance.pending_days).to eq(3.0)
        expect(leave_balance.remaining_days).to eq(9.0)
      end

      it "enqueues a leave notification with 'updated' action" do
        result = subject

        expect(LeaveNotificationJob).to have_received(:perform_later)
          .with(result.id, "updated")
      end
    end

    context "when only reason changes (dates unchanged)" do
      let(:params) { { reason: "New reason" } }

      it "updates reason and keeps total_days the same" do
        subject

        leave.reload
        expect(leave.reason).to eq("New reason")
        expect(leave.total_days).to eq(2.0)
      end

      it "releases old pending and re-holds same amount" do
        subject

        leave_balance.reload
        expect(leave_balance.pending_days).to eq(2.0)
        expect(leave_balance.remaining_days).to eq(10.0)
      end
    end

    context "when changing to a shorter date range" do
      let(:params) do
        {
          start_date: "2026-04-13",
          end_date:   "2026-04-13",
          reason:     "Just one day"
        }
      end

      it "sets total_days to 1.0" do
        subject
        expect(leave.reload.total_days).to eq(1.0)
      end

      it "frees up balance" do
        subject

        leave_balance.reload
        expect(leave_balance.pending_days).to eq(1.0)
        expect(leave_balance.remaining_days).to eq(11.0)
      end
    end

    context "when leave is not pending" do
      %w[APPROVED REJECTED CANCELLED].each do |bad_status|
        it "raises Error for #{bad_status} status" do
          leave.update_column(:status, bad_status)

          expect { subject }.to raise_error(
            Leaves::UpdateService::Error,
            "Only pending leave applications can be updated"
          )
        end
      end

      it "does not touch the balance" do
        leave.update_column(:status, "APPROVED")

        expect {
          begin; subject; rescue Leaves::UpdateService::Error; end
        }.not_to change { leave_balance.reload.pending_days }
      end
    end

    context "when the leave type is inactive" do
      before { leave_type.update!(is_active: false) }

      it "raises an error and rolls back the released balance" do
        expect { subject }.to raise_error(
          Leaves::UpdateService::Error, "Leave type is not available"
        )

        # Balance must be restored by transaction rollback
        leave_balance.reload
        expect(leave_balance.pending_days).to eq(2.0)
        expect(leave_balance.remaining_days).to eq(10.0)
      end
    end

    context "when no headroom exists even after releasing old balance" do
      before do
        # entitled=2, used=2, pending=2 → remaining=0
        # After release: pending=0, remaining = 2-2-0 = 0 → balance check raises
        leave_balance.update!(
          total_entitled: 2.0,
          used_days:      2.0,
          pending_days:   2.0,
          remaining_days: 0.0
        )
      end

      it "raises insufficient balance and rolls back" do
        expect { subject }.to raise_error(
          Leaves::UpdateService::Error, /Insufficient leave balance/
        )
      end
    end

    context "when releasing old balance frees up enough headroom" do
      before do
        # entitled=12, used=10, pending=2 → remaining=0
        # After release: pending=0, remaining = 12-10-0 = 2 > 0 → balance check passes
        leave_balance.update!(
          total_entitled: 12.0,
          used_days:      10.0,
          pending_days:   2.0,
          remaining_days: 0.0
        )
      end

      it "allows the update" do
        result = subject
        expect(result).to be_persisted
      end
    end

    context "overlap validation excludes self" do
      it "allows updating dates that overlap with itself" do
        # The update uses the same date range as the existing leave — should not raise
        params_same_dates = {
          start_date: leave.start_date.to_s,
          end_date:   leave.end_date.to_s,
          reason:     "No date change"
        }

        result = described_class.new(leave, user, params_same_dates).call
        expect(result).to be_persisted
      end

      it "raises when dates overlap with a DIFFERENT application" do
        create(:leave_application,
               user:       user,
               leave_type: leave_type,
               start_date: Date.parse("2026-04-20"),
               end_date:   Date.parse("2026-04-22"),
               status:     "APPROVED",
               total_days: 3.0)

        overlapping_params = {
          start_date: "2026-04-20",
          end_date:   "2026-04-21",
          reason:     "Conflicts with approved"
        }

        expect {
          described_class.new(leave, user, overlapping_params).call
        }.to raise_error(
          Leaves::UpdateService::Error, /leave application overlapping these dates/
        )
      end
    end

    context "advance notice validation" do
      let(:strict_policy) { create(:leave_policy, company: company, advance_notice_days: 7) }
      let(:strict_type) do
        create(:leave_type, leave_policy: strict_policy, max_consecutive_days: nil, is_active: true)
      end
      let!(:strict_balance) do
        create(:leave_balance,
               user:           user,
               leave_type:     strict_type,
               year:           Date.current.year,
               total_entitled: 12.0,
               remaining_days: 10.0,
               pending_days:   2.0)
      end
      let!(:strict_leave) do
        create(:leave_application,
               user:       user,
               leave_type: strict_type,
               start_date: (Date.current + 14).to_date,
               end_date:   (Date.current + 15).to_date,
               total_days: 2.0,
               status:     "PENDING")
      end

      it "raises when new start_date violates advance notice" do
        too_soon = {
          leave_type_id: strict_type.id,
          start_date:    (Date.current + 2).to_s,
          end_date:      (Date.current + 3).to_s,
          reason:        "Too soon"
        }

        expect {
          described_class.new(strict_leave, user, too_soon).call
        }.to raise_error(
          Leaves::UpdateService::Error, /at least 7 day\(s\) in advance/
        )
      end

      it "allows update when start_date satisfies advance notice" do
        ok_params = {
          leave_type_id: strict_type.id,
          start_date:    (Date.current + 7).to_s,
          end_date:      (Date.current + 13).to_s,
          reason:        "Well ahead"
        }

        result = described_class.new(strict_leave, user, ok_params).call
        expect(result).to be_persisted
      end
    end

    context "when total_days exceed max_consecutive_days" do
      let(:params) do
        {
          start_date:      "2026-04-13",
          end_date:        "2026-04-17",
          reason:          "Long holiday",
          extended_reason: "Family event"
        }
      end

      it "sets requires_ceo_approval to true" do
        result = subject

        expect(result.requires_ceo_approval).to be true
        expect(result.total_days).to eq(5.0)
      end
    end

    context "when extended_reason is missing for a CEO-approval-required update" do
      let(:params) do
        {
          start_date: "2026-04-13",
          end_date:   "2026-04-17",
          reason:     "Long holiday"
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          Leaves::UpdateService::Error,
          /Extended reason is required/
        )
      end
    end

    context "when existing extended_reason satisfies the requirement (not re-sent in params)" do
      before { leave.update!(extended_reason: "Pre-existing justification") }

      let(:params) do
        {
          start_date: "2026-04-13",
          end_date:   "2026-04-17",
          reason:     "Still long"
        }
      end

      it "keeps the existing extended_reason and approves CEO flag" do
        result = subject

        expect(result.requires_ceo_approval).to be true
        expect(result.extended_reason).to eq("Pre-existing justification")
      end
    end

    context "day details rebuild" do
      let(:params) do
        {
          start_date: "2026-04-13",
          end_date:   "2026-04-14",
          reason:     "Half-day update",
          leave_day_details_attributes: [
            { leave_date: "2026-04-13", day_type: "FULL_DAY" },
            { leave_date: "2026-04-14", day_type: "HALF_DAY_AM" }
          ]
        }
      end

      before do
        # Seed an existing day detail that should be replaced
        create(:leave_day_detail, leave_application: leave, leave_date: "2026-04-13", day_type: "FULL_DAY")
      end

      it "destroys old day details and creates new ones" do
        subject

        leave.reload
        expect(leave.leave_day_details.count).to eq(2)
        types = leave.leave_day_details.pluck(:day_type)
        expect(types).to contain_exactly("FULL_DAY", "HALF_DAY_AM")
      end

      it "calculates total_days from day details" do
        subject
        expect(leave.reload.total_days).to eq(1.5)
      end

      it "adjusts pending balance based on day-detail total" do
        subject

        leave_balance.reload
        expect(leave_balance.pending_days).to eq(1.5)
        expect(leave_balance.remaining_days).to eq(10.5)
      end
    end

    context "shared balance (emergency → annual)" do
      let(:annual_type) do
        create(:leave_type, leave_policy: leave_policy, max_consecutive_days: 3)
      end
      let(:emergency_type) do
        create(:leave_type, :emergency_leave,
               leave_policy:   leave_policy,
               shared_balance: annual_type,
               is_active:      true)
      end
      let!(:annual_balance) do
        create(:leave_balance,
               user:           user,
               leave_type:     annual_type,
               year:           Date.current.year,
               total_entitled: 12.0,
               remaining_days: 10.0,
               pending_days:   2.0)
      end
      let!(:emergency_leave) do
        create(:leave_application,
               user:       user,
               leave_type: emergency_type,
               start_date: Date.parse("2026-04-13"),
               end_date:   Date.parse("2026-04-14"),
               total_days: 2.0,
               status:     "PENDING",
               reason:     "Emergency")
      end

      let(:update_params) do
        {
          leave_type_id: emergency_type.id,
          start_date:    "2026-04-13",
          end_date:      "2026-04-15",
          reason:        "Extended emergency"
        }
      end

      it "releases and holds on the shared (annual) balance" do
        described_class.new(emergency_leave, user, update_params).call

        annual_balance.reload
        expect(annual_balance.pending_days).to eq(3.0)
        expect(annual_balance.remaining_days).to eq(9.0)
      end

      context "when shared balance is exhausted after release" do
        before do
          annual_balance.update!(
            total_entitled: 2.0,
            used_days:      2.0,
            pending_days:   2.0,
            remaining_days: 0.0
          )
        end

        it "raises insufficient balance and rolls back" do
          expect {
            described_class.new(emergency_leave, user, update_params).call
          }.to raise_error(
            Leaves::UpdateService::Error, /Insufficient leave balance/
          )

          annual_balance.reload
          expect(annual_balance.pending_days).to eq(2.0)
        end
      end
    end

    context "when selected dates contain no working days" do
      let(:params) do
        {
          start_date: "2026-04-11",
          end_date:   "2026-04-12",
          reason:     "Weekend"
        }
      end

      it "raises an error and rolls back" do
        expect { subject }.to raise_error(
          Leaves::UpdateService::Error, "Selected dates contain no working days"
        )
      end

      it "does not modify the leave application or balance" do
        expect {
          begin; subject; rescue Leaves::UpdateService::Error; end
        }.not_to change { leave.reload.end_date }

        expect(leave_balance.reload.pending_days).to eq(2.0)
      end
    end

    context "max_times_per_year excludes self when leave type unchanged" do
      let(:em_policy) { create(:leave_policy, company: company, advance_notice_days: 0) }
      let(:em_type) do
        create(:leave_type, :emergency_leave,
               leave_policy:       em_policy,
               max_times_per_year: 2,
               is_active:          true)
      end
      let!(:em_balance) do
        create(:leave_balance,
               user:           user,
               leave_type:     em_type,
               year:           Date.current.year,
               total_entitled: 12.0,
               remaining_days: 10.0,
               pending_days:   2.0)
      end
      let!(:em_leave) do
        create(:leave_application,
               user:       user,
               leave_type: em_type,
               start_date: Date.parse("2026-04-13"),
               end_date:   Date.parse("2026-04-13"),
               total_days: 1.0,
               status:     "PENDING")
      end

      before do
        # One other approved emergency leave this year — brings count to 1 (+ self = 2 but self excluded)
        create(:leave_application, :approved,
               user:       user,
               leave_type: em_type,
               start_date: Date.new(Date.current.year, 1, 6),
               end_date:   Date.new(Date.current.year, 1, 6),
               total_days: 1.0)
      end

      it "allows the update because self is excluded from max_times count" do
        result = described_class.new(em_leave, user, { leave_type_id: em_type.id, start_date: "2026-04-14", end_date: "2026-04-14", reason: "Update" }).call
        expect(result).to be_persisted
      end
    end
  end
end