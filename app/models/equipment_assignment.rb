class EquipmentAssignment < ApplicationRecord
  belongs_to :user
  has_one_attached :supporting_document

  validates :equipment_type, :equipment_details, :date_received, presence: true
  validate :return_after_received

  scope :returned,     -> { where.not(date_return: nil) }
  scope :outstanding,  -> { where(date_return: nil) }

  has_paper_trail meta: { company_id: ->(ea) { ea.user&.company_id } }

  private

  def return_after_received
    return if date_return.blank? || date_received.blank?
    errors.add(:date_return, "must be on or after date received") if date_return < date_received
  end
end
