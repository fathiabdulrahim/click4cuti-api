class Designation < ApplicationRecord
  belongs_to :company
  has_many :users, dependent: :nullify

  validates :title, :company, presence: true

  scope :active, -> { where(is_active: true) }
end
