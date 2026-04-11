class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  enum :role,   { admin: "ADMIN", manager: "MANAGER", employee: "EMPLOYEE" }
  enum :gender, { male: "MALE", female: "FEMALE" }

  belongs_to :company
  belongs_to :department,  optional: true
  belongs_to :designation, optional: true
  belongs_to :manager, class_name: "User", optional: true, foreign_key: :manager_id

  has_many :subordinates, class_name: "User", foreign_key: :manager_id, dependent: :nullify
  has_many :leave_applications,  dependent: :destroy
  has_many :approved_leaves, class_name: "LeaveApplication", foreign_key: :approved_by, dependent: :nullify
  has_many :leave_balances,      dependent: :destroy
  has_many :user_leave_policies, dependent: :destroy
  has_many :leave_policies, through: :user_leave_policies
  has_many :user_work_schedules, dependent: :destroy
  has_many :work_schedules, through: :user_work_schedules
  has_many :warning_letters,     dependent: :destroy

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
