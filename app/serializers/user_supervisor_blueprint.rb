class UserSupervisorBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :supervisor_id, :category, :level

  field :supervisor_name do |us, _opts|
    us.supervisor&.full_name
  end
end
