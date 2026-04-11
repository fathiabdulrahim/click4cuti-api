class Version < PaperTrail::Version
  self.table_name = :versions

  # Scoped by company for tenant isolation
  scope :for_company, ->(company_id) { where(company_id: company_id) }
end
