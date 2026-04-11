# Seeds for Click4Cuti
# Run: rails db:seed

puts "Seeding database..."

# SuperAdmin
super_admin = AdminUser.find_or_initialize_by(email: "superadmin@click4cuti.com")
super_admin.assign_attributes(
  full_name: "Super Admin",
  scope:     :super_admin,
  password:  "Password123!",
  is_active: true
)
super_admin.save!
puts "  SuperAdmin: #{super_admin.email}"


super_admin = AdminUser.find_or_initialize_by(email: "[EMAIL_ADDRESS]")
super_admin.assign_attributes(
  full_name: "Fathi Abdul Rahim",
  scope:     :super_admin,
  password:  "fathi123",
  is_active: true
)
super_admin.save!
puts "  SuperAdmin: #{super_admin.email}"

# Sample Agency
agency = HrAgency.find_or_create_by!(email: "agency@thepeople.com.my") do |a|
  a.name    = "The People Department"
  a.phone   = "+60312345678"
  a.address = "Kuala Lumpur, Malaysia"
end
puts "  Agency: #{agency.name}"

# Agency Admin
agency_admin = AdminUser.find_or_initialize_by(email: "agency_admin@thepeople.com.my")
agency_admin.assign_attributes(
  full_name: "Agency Admin",
  scope:     :agency,
  agency_id: agency.id,
  password:  "Password123!",
  is_active: true
)
agency_admin.save!
puts "  Agency Admin: #{agency_admin.email}"

# Sample Company
company = Company.find_or_initialize_by(hr_email: "hr@acme.com.my")
if company.new_record?
  company.assign_attributes(
    name:                "Acme Sdn Bhd",
    registration_number: "123456-A",
    address:             "Petaling Jaya, Selangor",
    state:               "Selangor",
    agency_id:           agency.id
  )
  Companies::OnboardService.new(company).call
  puts "  Company: #{company.name} (with default policies, departments, schedules, public holidays)"
end

# Company Admin
company_admin = AdminUser.find_or_initialize_by(email: "admin@acme.com.my")
company_admin.assign_attributes(
  full_name:  "Company Admin",
  scope:      :company,
  company_id: company.id,
  password:   "Password123!",
  is_active:  true
)
company_admin.save!
puts "  Company Admin: #{company_admin.email}"

# Sample Employee
dept  = company.departments.find_by(name: "Human Resources")
desig = company.designations.find_by(title: "Executive")

unless User.exists?(email: "employee@acme.com.my")
  Users::OnboardService.new({
    full_name:      "Ahmad Faiz",
    email:          "employee@acme.com.my",
    phone:          "+60123456789",
    role:           :employee,
    join_date:      3.years.ago.to_date,
    gender:         :male,
    employee_id:    "EMP001",
    department_id:  dept&.id,
    designation_id: desig&.id,
    company_id:     company.id,
    password:       "Password123!"
  }, company_admin).call
  puts "  Employee: employee@acme.com.my"
end

puts "\nDone! Credentials:"
puts "  SuperAdmin:    superadmin@click4cuti.com / Password123!"
puts "  Agency Admin:  agency_admin@thepeople.com.my / Password123!"
puts "  Company Admin: admin@acme.com.my / Password123!"
puts "  Employee:      employee@acme.com.my / Password123!"
