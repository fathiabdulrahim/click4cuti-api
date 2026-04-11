class ActivityLog < ApplicationRecord
  belongs_to :company, optional: true

  validates :actor_id, :actor_type, :action, presence: true

  scope :for_company, ->(company_id) { where(company_id: company_id) }
  scope :recent, -> { order(created_at: :desc) }
end
