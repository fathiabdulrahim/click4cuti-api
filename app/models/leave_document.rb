class LeaveDocument < ApplicationRecord
  belongs_to :leave_application

  has_one_attached :file

  validates :file_name, presence: true

  ALLOWED_CONTENT_TYPES = %w[application/pdf image/jpeg image/png image/jpg].freeze
  MAX_FILE_SIZE = 10.megabytes

  validate :file_type_and_size, if: :file_attached?

  private

  def file_attached?
    file.attached?
  end

  def file_type_and_size
    unless file.content_type.in?(ALLOWED_CONTENT_TYPES)
      errors.add(:file, "must be a PDF, JPG, or PNG")
    end

    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "must be less than 10MB")
    end
  end
end
