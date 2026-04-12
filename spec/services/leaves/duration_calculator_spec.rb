require "rails_helper"

RSpec.describe Leaves::DurationCalculator do
  let(:company)       { create(:company) }
  let(:user)          { create(:user, :employee, company: company) }
  let(:work_schedule) do
    create(:work_schedule, company: company, rest_days: "Saturday,Sunday")
  end
  let!(:user_work_schedule) do
    create(:user_work_schedule, user: user, work_schedule: work_schedule)
  end

  describe "#calculate" do
    context "weekdays only (Mon-Fri)" do
      # 2026-04-13 (Mon) to 2026-04-17 (Fri) = 5 weekdays
      subject { described_class.new(user, "2026-04-13", "2026-04-17").calculate }

      it "returns 5.0 days" do
        expect(subject).to eq(5.0)
      end
    end

    context "range spanning a weekend (Mon-Sun)" do
      # 2026-04-13 (Mon) to 2026-04-19 (Sun) = 7 calendar days, 5 working days
      subject { described_class.new(user, "2026-04-13", "2026-04-19").calculate }

      it "excludes Saturday and Sunday rest days and returns 5.0" do
        expect(subject).to eq(5.0)
      end
    end

    context "with a public holiday on a weekday" do
      # 2026-04-15 (Wed) is a public holiday
      let!(:public_holiday) do
        create(:public_holiday,
               company:      company,
               holiday_date: Date.new(2026, 4, 15),
               year:         2026)
      end

      # Mon-Fri but Wed is PH = 4 working days
      subject { described_class.new(user, "2026-04-13", "2026-04-17").calculate }

      it "excludes the public holiday and returns 4.0" do
        expect(subject).to eq(4.0)
      end
    end

    context "with explicit day details (including half days)" do
      let(:day_details) do
        [
          { leave_date: "2026-04-13", day_type: "FULL_DAY" },
          { leave_date: "2026-04-14", day_type: "HALF_DAY_AM" },
          { leave_date: "2026-04-15", day_type: "HALF_DAY_PM" }
        ]
      end

      subject do
        described_class.new(user, "2026-04-13", "2026-04-15", day_details).calculate
      end

      it "sums day values correctly (1.0 + 0.5 + 0.5 = 2.0)" do
        expect(subject).to eq(2.0)
      end
    end

    context "single day leave" do
      subject { described_class.new(user, "2026-04-13", "2026-04-13").calculate }

      it "returns 1.0 for a single weekday" do
        expect(subject).to eq(1.0)
      end
    end

    context "leave on a rest day only" do
      # 2026-04-18 (Sat) to 2026-04-19 (Sun)
      subject { described_class.new(user, "2026-04-18", "2026-04-19").calculate }

      it "returns 0.0" do
        expect(subject).to eq(0.0)
      end
    end
  end
end
