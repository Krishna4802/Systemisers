class CompanyDocument < ApplicationRecord
  has_one_attached :file
  enum :doc_type, { itr: 0, gstr_1: 1, gstr_3b: 2 }

  def self.store_document(params, file)
    if params[:doc_type] == "itr"
      json_data = JSON.parse(file.read)
      parser = GenerateProjectReport::ItrJsonParser.new(json_data)
      unless parser.validate_file
        return false
      end
    end
    company_document_store = create(check_file_params(params))
    company_document_store.file.attach(file)
    true
  end

  def self.check_file_params(params)
    {
      doc_type: params[:doc_type],
      financial_year: params[:financial_year],
      doc_date: params[:doc_date],
      org_id: User.organization_id,
      company_id: User.company_id,
    }
  end
end
