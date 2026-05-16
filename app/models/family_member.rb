class FamilyMember < ApplicationRecord
  belongs_to :user

  enum :relation, {
    spouse: "SPOUSE",
    child:  "CHILD",
    parent: "PARENT"
  }, prefix: :relation

  enum :employment_status, {
    working:     "WORKING",
    not_working: "NOT_WORKING",
    studying:    "STUDYING",
    retired:     "RETIRED"
  }, prefix: :employment

  validates :first_name, :gender, :date_of_birth, presence: true

  scope :children, -> { relation_child }
  scope :spouses,  -> { relation_spouse }
  scope :parents,  -> { relation_parent }
  scope :under_18, -> { where("date_of_birth > ?", 18.years.ago.to_date) }

  has_paper_trail meta: { company_id: ->(fm) { fm.user&.company_id } }
end
