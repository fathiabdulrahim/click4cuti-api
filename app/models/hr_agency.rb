class HrAgency < ApplicationRecord
  has_many :companies, foreign_key: :agency_id, dependent: :nullify
  has_many :admin_users, foreign_key: :agency_id, dependent: :nullify

  validates :name, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true

  scope :active, -> { where(is_active: true) }

  has_paper_trail
end
