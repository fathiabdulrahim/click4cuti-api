require "rails_helper"

RSpec.describe LeaveApplicationPolicy do
  subject { described_class.new(reviewer, application) }

  let(:company)       { create(:company) }
  let(:other_company) { create(:company) }
  let(:leave_policy)  { create(:leave_policy, company: company) }
  let(:leave_type)    { create(:leave_type, leave_policy: leave_policy) }

  let(:applicant)     { create(:user, :employee, company: company) }
  let(:application)   { create(:leave_application, user: applicant, leave_type: leave_type) }

  describe "#approve?" do
    context "when reviewer is the applicant" do
      let(:reviewer) { applicant }

      it "denies (no self-approval)" do
        expect(subject.approve?).to be(false)
      end
    end

    context "when reviewer is a company admin (User#admin?)" do
      let(:reviewer) { create(:user, :admin, company: company) }

      it "allows" do
        expect(subject.approve?).to be(true)
      end

      context "in a different company" do
        let(:reviewer) { create(:user, :admin, company: other_company) }

        it "denies (cross-tenant block)" do
          expect(subject.approve?).to be(false)
        end
      end
    end

    context "when applicant has explicit leave_approvers configured" do
      let(:explicit_approver) { create(:user, :manager, company: company) }
      let(:other_manager)     { create(:user, :manager, company: company) }

      before do
        create(:user_leave_approver, user: applicant, approver: explicit_approver)
      end

      context "and reviewer is in the explicit list" do
        let(:reviewer) { explicit_approver }

        it "allows" do
          expect(subject.approve?).to be(true)
        end
      end

      context "and reviewer is the applicant's manager but NOT in the list" do
        let(:reviewer) { other_manager }

        before { applicant.update!(manager: other_manager) }

        it "denies (explicit list overrides manager fallback)" do
          expect(subject.approve?).to be(false)
        end
      end
    end

    context "when applicant has NO explicit approvers (manager fallback)" do
      let(:manager) { create(:user, :manager, company: company) }
      let(:other)   { create(:user, :manager, company: company) }

      before { applicant.update!(manager: manager) }

      context "and reviewer is the applicant's reporting manager" do
        let(:reviewer) { manager }

        it "allows via fallback" do
          expect(subject.approve?).to be(true)
        end
      end

      context "and reviewer is some other manager in the company" do
        let(:reviewer) { other }

        it "denies" do
          expect(subject.approve?).to be(false)
        end
      end
    end
  end

  describe "Scope" do
    let(:applicant_2)   { create(:user, :employee, company: company) }
    let!(:application)  { create(:leave_application, user: applicant, leave_type: leave_type) }
    let!(:application_2) { create(:leave_application, user: applicant_2, leave_type: leave_type) }

    subject { described_class::Scope.new(reviewer, LeaveApplication.all).resolve }

    context "as company admin" do
      let(:reviewer) { create(:user, :admin, company: company) }

      it "sees all applications in the same company" do
        expect(subject).to include(application, application_2)
      end

      it "does not leak applications from another company" do
        foreign_user = create(:user, :employee, company: other_company)
        foreign_policy = create(:leave_policy, company: other_company)
        foreign_type = create(:leave_type, leave_policy: foreign_policy)
        foreign_app = create(:leave_application, user: foreign_user, leave_type: foreign_type)
        expect(subject).not_to include(foreign_app)
      end
    end

    context "as a manager with explicit approver assignments" do
      let(:reviewer) { create(:user, :manager, company: company) }

      before do
        create(:user_leave_approver, user: applicant, approver: reviewer)
      end

      it "sees own applications + those of users who assigned them as approver" do
        own_app = create(:leave_application, user: reviewer, leave_type: leave_type)
        expect(subject).to include(own_app, application)
      end

      it "does not see applicants who did NOT assign them" do
        expect(subject).not_to include(application_2)
      end
    end

    context "as a manager with manager-fallback subordinates only" do
      let(:reviewer) { create(:user, :manager, company: company) }

      before { applicant.update!(manager: reviewer) }

      it "sees the subordinate's applications via fallback" do
        expect(subject).to include(application)
      end

      it "stops seeing them once the subordinate has explicit approvers configured" do
        third_party = create(:user, :manager, company: company)
        create(:user_leave_approver, user: applicant, approver: third_party)
        expect(subject).not_to include(application)
      end
    end

    context "as a regular employee" do
      let(:reviewer) { applicant }

      it "sees only their own applications" do
        expect(subject).to include(application)
        expect(subject).not_to include(application_2)
      end
    end
  end
end
