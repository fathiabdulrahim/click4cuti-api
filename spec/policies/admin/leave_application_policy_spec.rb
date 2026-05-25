require "rails_helper"

RSpec.describe Admin::LeaveApplicationPolicy do
  let(:company) { create(:company) }
  let(:ceo_required_app) do
    create(:leave_application,
           requires_ceo_approval: true,
           status:                "PENDING_CEO")
  end

  permissions :ceo_approve? do
    context "when admin is company-scoped" do
      let(:admin_user) { build(:admin_user, :company, company: company) }

      it "grants access for pending_ceo status with ceo_approval flag" do
        expect(described_class).to permit(admin_user, ceo_required_app)
      end

      it "denies when requires_ceo_approval is false" do
        app = build(:leave_application, requires_ceo_approval: false)
        expect(described_class).not_to permit(admin_user, app)
      end

      it "denies when status is not pending_ceo" do
        app = build(:leave_application, :pending,
                    requires_ceo_approval: true)
        expect(described_class).not_to permit(admin_user, app)
      end
    end

    context "when admin is super_admin" do
      let(:admin_user) { build(:admin_user, :super_admin) }

      it "denies access" do
        expect(described_class).not_to permit(admin_user, ceo_required_app)
      end
    end

    context "when admin is agency-scoped" do
      let(:admin_user) { build(:admin_user, :agency) }

      it "denies access" do
        expect(described_class).not_to permit(admin_user, ceo_required_app)
      end
    end
  end
end
