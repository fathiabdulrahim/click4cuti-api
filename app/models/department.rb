class Department < ApplicationRecord
  belongs_to :company
  has_many :users, dependent: :nullify

  validates :name, :company, presence: true

  scope :active, -> { where(is_active: true) }
end
