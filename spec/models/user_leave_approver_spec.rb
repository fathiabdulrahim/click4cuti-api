require "rails_helper"

RSpec.describe UserLeaveApprover, type: :model do
  let(:company)       { create(:company) }
  let(:other_company) { create(:company) }
  let(:user)          { create(:user, :employee, company: company) }
  let(:approver)      { create(:user, :manager, company: company) }

  describe "validations" do
    it "is valid with same-company user and approver" do
      record = described_class.new(user: user, approver: approver)
      expect(record).to be_valid
    end

    it "is invalid when approver is in a different company" do
      foreigner = create(:user, :manager, company: other_company)
      record = described_class.new(user: user, approver: foreigner)
      expect(record).not_to be_valid
      expect(record.errors[:approver]).to include("must belong to the same company")
    end

    it "is invalid when approver is the same user (model-level)" do
      record = described_class.new(user: user, approver: user)
      expect(record).not_to be_valid
      expect(record.errors[:approver]).to include("cannot be the user themselves")
    end

    it "is invalid when (user, approver) pair is duplicated" do
      create(:user_leave_approver, user: user, approver: approver)
      duplicate = described_class.new(user: user, approver: approver)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end

    it "allows the same approver to be assigned to different users" do
      another_user = create(:user, :employee, company: company)
      create(:user_leave_approver, user: user, approver: approver)
      record = described_class.new(user: another_user, approver: approver)
      expect(record).to be_valid
    end
  end

  describe "database constraints" do
    it "rejects self-assignment at the DB level even if model validations are skipped" do
      record = described_class.new(user_id: user.id, approver_id: user.id)
      expect {
        record.save(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid, /user_leave_approvers_no_self_assignment/)
    end
  end

  describe "associations" do
    it "links to a user and an approver (both Users)" do
      record = create(:user_leave_approver, user: user, approver: approver)
      expect(record.user).to eq(user)
      expect(record.approver).to eq(approver)
    end
  end
end
