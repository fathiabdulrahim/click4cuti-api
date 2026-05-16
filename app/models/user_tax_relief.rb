class UserTaxRelief < ApplicationRecord
  belongs_to :user

  enum :spouse_gender, { male: "MALE", female: "FEMALE" }, prefix: :spouse

  enum :tax_category, {
    regular:          "REGULAR",
    rep:              "REP",
    knowledge_worker: "KNOWLEDGE_WORKER"
  }, prefix: :tax

  validates :user_id, uniqueness: true

  has_paper_trail meta: { company_id: ->(t) { t.user&.company_id } }

  # Derived from family_members
  def children_under_18
    user.family_members.children.where("date_of_birth > ?", 18.years.ago.to_date).count
  end

  def children_studying
    user.family_members.children
      .where("date_of_birth <= ?", 18.years.ago.to_date)
      .where(employment_status: "STUDYING").count
  end

  def children_disabled
    user.family_members.children.where(oku_status: true).count
  end
end
