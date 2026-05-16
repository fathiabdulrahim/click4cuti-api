class UserDocument < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :remarks, presence: true
  validate :file_attached

  has_paper_trail meta: { company_id: ->(ud) { ud.user&.company_id } }

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
