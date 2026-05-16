class UserTaxReliefBlueprint < Blueprinter::Base
  identifier :id
  fields :user_id, :spouse_is_working, :spouse_is_disabled, :spouse_gender,
         :contributes_to_sip, :tax_category

  # Derived from family_members
  field :children_under_18 do |t, _opts|
    t.children_under_18
  end
  field :children_studying do |t, _opts|
    t.children_studying
  end
  field :children_disabled do |t, _opts|
    t.children_disabled
  end
end
