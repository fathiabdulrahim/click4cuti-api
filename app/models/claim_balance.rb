class ClaimBalance < ApplicationRecord
  belongs_to :user
  belongs_to :claim_type

  validates :year, presence: true
  validates :year, uniqueness: { scope: [ :user_id, :claim_type_id ] }

  scope :for_year, ->(year) { where(year: year) }
  scope :for_user, ->(uid) { where(user_id: uid) }

  has_paper_trail meta: { company_id: ->(b) { b.user&.company_id } }

  def recalculate_remaining!
    update!(remaining_amount: annual_limit - used_amount - pending_amount)
  end
end
