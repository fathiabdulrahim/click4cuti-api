class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  enum :role,   { admin: "ADMIN", manager: "MANAGER", employee: "EMPLOYEE" }
  enum :gender, { male: "MALE", female: "FEMALE" }
  enum :employee_type, {
    permanent:    "PERMANENT",
    contract:     "CONTRACT",
    probation:    "PROBATION",
    internship:   "INTERNSHIP",
    freelance:    "FREELANCE",
    part_time:    "PART_TIME",
    ojt:          "OJT",
    sl1m_ojt:     "SL1M_OJT"
  }, prefix: :employee_type

  enum :nric_color,      { blue: "BLUE", red: "RED" }, prefix: :nric_color
  enum :race,            { malay: "MALAY", chinese: "CHINESE", indian: "INDIAN", others: "OTHERS" }, prefix: :race
  enum :religion,        { islam: "ISLAM", buddhism: "BUDDHISM", hindu: "HINDU", christian: "CHRISTIAN", others: "OTHERS" }, prefix: :religion
  enum :blood_type,      { a: "A", b: "B", ab: "AB", o: "O" }, prefix: :blood_type
  enum :education_level, {
    pre_school: "PRE_SCHOOL",
    primary_school: "PRIMARY_SCHOOL",
    secondary_school: "SECONDARY_SCHOOL",
    college: "COLLEGE",
    diploma: "DIPLOMA",
    degree: "DEGREE",
    master: "MASTER",
    phd: "PHD"
  }, prefix: :education
  enum :marital_status,  { single: "SINGLE", married: "MARRIED", divorced: "DIVORCED", widowed: "WIDOWED" }, prefix: :marital
  enum :nationality,     { citizen: "CITIZEN", non_citizen: "NON_CITIZEN", permanent_resident: "PERMANENT_RESIDENT" }, prefix: :nationality
  enum :bumi_status,     { bumiputera: "BUMIPUTERA", non_bumiputera: "NON_BUMIPUTERA" }, prefix: :bumi

  belongs_to :company
  belongs_to :department,  optional: true
  belongs_to :designation, optional: true
  belongs_to :branch,      optional: true
  belongs_to :manager, class_name: "User", optional: true, foreign_key: :manager_id

  belongs_to :ea_person_in_charge, class_name: "User", optional: true, foreign_key: :ea_person_in_charge_id

  has_many :subordinates, class_name: "User", foreign_key: :manager_id, dependent: :nullify
  has_many :work_experiences, dependent: :destroy
  has_many :family_members, dependent: :destroy
  has_many :career_progresses, dependent: :destroy
  has_many :user_documents, dependent: :destroy
  has_many :equipment_assignments, dependent: :destroy
  has_many :trainings, dependent: :destroy

  has_one :bank_detail,      class_name: "UserBankDetail",      dependent: :destroy
  has_one :statutory_detail, class_name: "UserStatutoryDetail", dependent: :destroy
  has_one :tax_relief,       class_name: "UserTaxRelief",       dependent: :destroy
  accepts_nested_attributes_for :bank_detail, :statutory_detail, :tax_relief, update_only: true

  has_many :user_claim_policies, dependent: :destroy
  has_many :claim_types, through: :user_claim_policies
  has_many :claim_applications, dependent: :destroy
  has_many :approved_claims, class_name: "ClaimApplication", as: :approver, dependent: :nullify
  has_many :claim_balances, dependent: :destroy
  has_many :supervisor_assignments, class_name: "UserSupervisor", dependent: :destroy
  has_many :supervisors, through: :supervisor_assignments, source: :supervisor

  has_many :supervisor_for_assignments,
           class_name: "UserSupervisor", foreign_key: :supervisor_id, dependent: :destroy
  has_many :supervisor_for, through: :supervisor_for_assignments, source: :user
  has_many :leave_applications,  dependent: :destroy
  has_many :approved_leaves, class_name: "LeaveApplication", as: :approver, dependent: :nullify
  has_many :leave_balances,      dependent: :destroy
  has_many :user_leave_policies, dependent: :destroy
  has_many :leave_policies, through: :user_leave_policies
  has_many :user_work_schedules, dependent: :destroy
  has_many :work_schedules, through: :user_work_schedules
  has_many :warning_letters,     dependent: :destroy

  has_many :leave_approver_assignments,
           class_name: "UserLeaveApprover", dependent: :destroy
  has_many :leave_approvers, through: :leave_approver_assignments, source: :approver

  has_many :approver_for_assignments,
           class_name: "UserLeaveApprover", foreign_key: :approver_id, dependent: :destroy
  has_many :approver_for, through: :approver_for_assignments, source: :user

  before_validation :set_jti, on: :create

  validates :full_name, :email, :role, :join_date, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :employee_id, uniqueness: { scope: :company_id }, allow_blank: true

  scope :active,   -> { where(is_active: true) }
  scope :for_company, ->(company_id) { where(company_id: company_id) }

  has_paper_trail meta: { company_id: :company_id }

  def managed_user_ids
    subordinates.pluck(:id)
  end

  # Returns supervisor User(s) for a given category + level.
  # Falls back to legacy leave_approvers when no user_supervisors row exists for LEAVE.
  def supervisors_for(category:, level: 1)
    matches = supervisor_assignments.where(category: category, level: level).map(&:supervisor)
    return matches if matches.any?
    return leave_approvers if category == "LEAVE" && level == 1
    []
  end

  def years_of_service
    ((Date.current - join_date).to_f / 365).floor
  end

  def leave_entitlement_tier
    yos = years_of_service
    if yos < 2
      1
    elsif yos < 5
      2
    else
      3
    end
  end

  def jwt_payload
    { role: role, company_id: company_id }
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
