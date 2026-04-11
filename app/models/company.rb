class Company < ApplicationRecord
  belongs_to :hr_agency, optional: true, foreign_key: :agency_id

  has_many :departments,          dependent: :destroy
  has_many :designations,         dependent: :destroy
  has_many :users,                dependent: :destroy
  has_many :admin_users,          dependent: :destroy
  has_many :leave_policies,       dependent: :destroy
  has_many :work_schedules,       dependent: :destroy
  has_many :public_holidays,      dependent: :destroy
  has_many :warning_letters,      dependent: :destroy
  has_many :email_notifications,  dependent: :destroy
  has_many :activity_logs,        dependent: :nullify

  validates :name, :hr_email, presence: true
  validates :hr_email, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active, -> { where(is_active: true) }

  has_paper_trail
end
