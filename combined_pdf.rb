require 'combine_pdf'
require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_loan_amortization_pdf'
require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/GenerateDepreciationSchedulePdf.rb'

module ProjectReport
  class CombinedReportPdfService
    def initialize(loan_amount, annual_interest_rate, loan_years, company_name, location, projection_years, assets)
      @loan_amount = loan_amount
      @annual_interest_rate = annual_interest_rate
      @loan_years = loan_years
      @company_name = company_name
      @location = location
      @projection_years = projection_years
      @assets = assets 
    end

    def generate_combined_pdf(output_path)
      loan_pdf_service = ProjectReport::GenerateLoanAmortizationPdf.new(@loan_amount, @annual_interest_rate, @loan_years)
      loan_pdf_path = "/Users/krishnaprasath/Desktop/Loan_Amortization_Report_v1.pdf"
      loan_pdf_service.generate_pdf(loan_pdf_path)

      depreciation_pdf_generator = ProjectReport::GenerateDepreciationSchedulePdf.new(company_name: @company_name, location: @location, projection_years: @projection_years)
      
      @assets.each do |asset|
        depreciation_pdf_generator.add_asset(
          asset[:name],
          depreciation_percent: asset[:depreciation_percent],
          opening_balance: asset[:opening_balance],
          addition: asset[:addition],
          is_less_than_6_months: asset[:is_less_than_6_months]
        )
      end

      depreciation_pdf_path = "/Users/krishnaprasath/Desktop/Depreciation_Schedule_Report_v1.pdf"
      depreciation_pdf_generator.generate_pdf(depreciation_pdf_path)

      combined_pdf = CombinePDF.new
      combined_pdf << CombinePDF.load(loan_pdf_path)
      combined_pdf << CombinePDF.load(depreciation_pdf_path)
      combined_pdf.save(output_path)

      puts "Combined PDF generated at #{output_path}"
    end
  end
end
