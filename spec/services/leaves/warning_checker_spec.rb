require "rails_helper"

RSpec.describe Leaves::WarningChecker do
  let(:company)      { create(:company) }
  let(:leave_policy) { create(:leave_policy, company: company) }
  let(:leave_type)   { create(:leave_type, :emergency_leave, leave_policy: leave_policy) }
  let(:user)         { create(:user, :employee, company: company) }

  before do
    allow(WarningLetterJob).to receive(:perform_later)
  end

  describe "#check!" do
    context "when emergency leave count is at or below the threshold (3)" do
      before do
        3.times do |i|
          create(:leave_application, :approved,
                 user:       user,
                 leave_type: leave_type,
                 start_date: Date.new(Date.current.year, 1, 5 + i),
                 end_date:   Date.new(Date.current.year, 1, 5 + i),
                 total_days: 1.0)
        end
      end

      it "does not create a warning letter" do
        expect {
          described_class.new(user, leave_type).check!
        }.not_to change(WarningLetter, :count)
      end
    end

    context "when emergency leave count exceeds the threshold" do
      before do
        4.times do |i|
          create(:leave_application, :approved,
                 user:       user,
                 leave_type: leave_type,
                 start_date: Date.new(Date.current.year, 2, 2 + i),
                 end_date:   Date.new(Date.current.year, 2, 2 + i),
                 total_days: 1.0)
        end
      end

      it "creates a WarningLetter" do
        expect {
          described_class.new(user, leave_type).check!
        }.to change(WarningLetter, :count).by(1)
      end

      it "creates the warning letter with correct attributes" do
        described_class.new(user, leave_type).check!

        letter = WarningLetter.last
        expect(letter.user).to eq(user)
        expect(letter.company).to eq(company)
        expect(letter.leave_type).to eq(leave_type)
        expect(letter.year).to eq(Date.current.year)
        expect(letter.reason).to include("Exceeded 3 emergency leaves")
        expect(letter.reason).to include("Current count: 4")
        expect(letter.acknowledged).to be false
      end

      it "enqueues a WarningLetterJob" do
        described_class.new(user, leave_type).check!

        expect(WarningLetterJob).to have_received(:perform_later)
          .with(user.id, leave_type.id, Date.current.year)
      end
    end

    context "when leave type is not emergency leave" do
      let(:leave_type) { create(:leave_type, leave_policy: leave_policy, name: "Annual Leave") }

      it "does not create a warning letter regardless of count" do
        5.times do |i|
          create(:leave_application, :approved,
                 user:       user,
                 leave_type: leave_type,
                 start_date: Date.new(Date.current.year, 3, 2 + i),
                 end_date:   Date.new(Date.current.year, 3, 2 + i),
                 total_days: 1.0)
        end

        expect {
          described_class.new(user, leave_type).check!
        }.not_to change(WarningLetter, :count)
      end
    end
  end
end
