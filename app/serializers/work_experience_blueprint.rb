class WorkExperienceBlueprint < Blueprinter::Base
  identifier :id

  fields :company_name, :position, :start_date, :end_date, :user_id

  field :period do |we, _opts|
    next nil unless we.start_date
    end_d = we.end_date || Date.current
    months = (end_d.year - we.start_date.year) * 12 + (end_d.month - we.start_date.month)
    years = months / 12
    rem = months % 12
    [ years.positive? ? "#{years}y" : nil, rem.positive? ? "#{rem}m" : nil ].compact.join(" ").presence || "<1m"
  end

  view :detail do
    fields :created_at, :updated_at
  end
end
