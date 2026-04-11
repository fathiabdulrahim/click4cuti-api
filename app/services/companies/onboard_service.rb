module Companies
  class OnboardService
    DEFAULT_DEPARTMENTS  = %w[Human\ Resources Finance Operations Technology Sales Marketing].freeze
    DEFAULT_DESIGNATIONS = [
      { title: "Manager",  is_manager: true },
      { title: "Executive", is_manager: false },
      { title: "Executive Director", is_manager: true },
      { title: "Staff",    is_manager: false }
    ].freeze

    MALAYSIA_MANDATORY_HOLIDAYS = [
      { name: "Hari Kebangsaan (National Day)", month: 8,  day: 31 },
      { name: "Hari Malaysia (Malaysia Day)",   month: 9,  day: 16 },
      { name: "Hari Buruh (Labour Day)",        month: 5,  day: 1  },
      { name: "Hari Merdeka",                   month: 8,  day: 31 },
      { name: "Hari Raja Perempuan",            month: 6,  day: 7  }
    ].freeze

    def initialize(company)
      @company = company
    end

    def call
      ActiveRecord::Base.transaction do
        @company.save! unless @company.persisted?

        create_default_departments!
        create_default_designations!
        create_default_leave_policy!
        create_default_work_schedule!
        seed_public_holidays!

        @company
      end
    end

    private

    def create_default_departments!
      DEFAULT_DEPARTMENTS.each do |name|
        @company.departments.find_or_create_by!(name: name)
      end
    end

    def create_default_designations!
      DEFAULT_DESIGNATIONS.each do |attrs|
        @company.designations.find_or_create_by!(title: attrs[:title]) do |d|
          d.is_manager = attrs[:is_manager]
        end
      end
    end

    def create_default_leave_policy!
      policy = @company.leave_policies.create!(
        name:               "Standard Leave Policy",
        description:        "Default EA 1955 compliant leave policy",
        advance_notice_days: 7
      )

      annual = policy.leave_types.create!(
        name:               "Annual Leave",
        category:           :mandatory,
        default_days_tier1: 8,
        default_days_tier2: 12,
        default_days_tier3: 16,
        max_consecutive_days: 3,
        allows_half_day:    true,
        allows_carry_forward: true,
        max_carry_forward_days: 8
      )

      policy.leave_types.create!(
        name:               "Sick Leave",
        category:           :mandatory,
        default_days_tier1: 14,
        default_days_tier2: 18,
        default_days_tier3: 22,
        requires_document:  true,
        allows_half_day:    false,
        allows_carry_forward: false
      )

      policy.leave_types.create!(
        name:               "Emergency Leave",
        category:           :mandatory,
        default_days_tier1: 0,
        default_days_tier2: 0,
        default_days_tier3: 0,
        max_times_per_year: 3,
        allows_half_day:    false,
        allows_carry_forward: false,
        shared_balance_with: annual.id
      )

      policy.leave_types.create!(
        name:               "Maternity Leave",
        category:           :mandatory,
        default_days_tier1: 60,
        default_days_tier2: 60,
        default_days_tier3: 60,
        allows_half_day:    false,
        allows_carry_forward: false
      )

      policy.leave_types.create!(
        name:               "Paternity Leave",
        category:           :mandatory,
        default_days_tier1: 7,
        default_days_tier2: 7,
        default_days_tier3: 7,
        max_times_per_year: 5,
        allows_half_day:    false,
        allows_carry_forward: false
      )
    end

    def create_default_work_schedule!
      @company.work_schedules.create!(
        name:       "Standard Office Hours",
        start_time: "09:00",
        end_time:   "18:00",
        break_start: "13:00",
        break_end:  "14:00",
        rest_days:  "Saturday,Sunday"
      )
    end

    def seed_public_holidays!
      year = Date.current.year
      MALAYSIA_MANDATORY_HOLIDAYS.each do |ph|
        date = Date.new(year, ph[:month], ph[:day])
        @company.public_holidays.find_or_create_by!(holiday_date: date) do |h|
          h.name         = ph[:name]
          h.year         = year
          h.is_mandatory = true
        end
      end
    end
  end
end
