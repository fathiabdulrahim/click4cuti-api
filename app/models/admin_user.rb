class AdminUser < ApplicationRecord
  devise :database_authenticatable, :recoverable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  SCOPES = %w[SUPER_ADMIN AGENCY COMPANY].freeze

  enum :scope, { super_admin: "SUPER_ADMIN", agency: "AGENCY", company: "COMPANY" },
       prefix: false

  belongs_to :hr_agency, optional: true, foreign_key: :agency_id
  belongs_to :company,   optional: true

  before_validation :set_jti, on: :create

  validates :full_name, :email, :scope, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :agency_id,  presence: true, if: :agency?
  validates :company_id, presence: true, if: :company?

  scope :active, -> { where(is_active: true) }

  has_paper_trail

  def jwt_payload
    { scope: scope_before_type_cast }
  end

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
