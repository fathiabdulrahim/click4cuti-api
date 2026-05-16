class Training < ApplicationRecord
  belongs_to :user
  has_one_attached :certification

  validates :title, :start_date, :end_date, :description, :received_date, :expired_date, presence: true
  validate :end_after_start
  validate :expired_after_received

  scope :active,  -> { where("expired_date >= ?", Date.current) }
  scope :expired, -> { where("expired_date < ?", Date.current) }

  has_paper_trail meta: { company_id: ->(t) { t.user&.company_id } }

  private

  def end_after_start
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end

  def expired_after_received
    return if received_date.blank? || expired_date.blank?
    errors.add(:expired_date, "must be on or after received date") if expired_date < received_date
  end
end
