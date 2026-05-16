class UserBankDetailBlueprint < Blueprinter::Base
  identifier :id
  fields :user_id, :bank_name, :account_number, :account_type, :branch, :account_status
end
