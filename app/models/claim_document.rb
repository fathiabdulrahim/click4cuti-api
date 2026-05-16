class ClaimDocument < ApplicationRecord
  belongs_to :claim_application
  has_one_attached :file

  validates :file_name, presence: true
end
