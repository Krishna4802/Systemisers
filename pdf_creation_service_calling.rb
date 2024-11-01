generate_loan_amortization_pdf calling

require './app/lib/project_report/generate_loan_amortization_pdf'
loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
pdf_service = ProjectReport::GenerateLoanAmortizationPdf.new(loan_amount, annual_interest_rate, loan_years)
output_path = pdf_service.generate_pdf("/Users/krishnaprasath/Desktop/Loan_Amortization_Report.pdf")

DepreciationSchedule calling

require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/DepreciationSchedule.rb'
schedule = ProjectReport::DepreciationSchedule.new(projection_years: 6)
schedule.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, addition: 32.00, is_less_than_6_months: true)
schedule.add_asset("Interiors", depreciation_percent: 15, opening_balance: 0, addition: 1.25, is_less_than_6_months: true)
result = schedule.display_schedule
puts result


require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/GenerateDepreciationSchedulePdf.rb'
pdf_generator = ProjectReport::GenerateDepreciationSchedulePdf.new(company_name:"Diddi Computer Trading",location:"Hydrabad",projection_years: 6)
pdf_generator.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, addition: 32.00, is_less_than_6_months: true)
pdf_generator.add_asset("Interiors", depreciation_percent: 15, opening_balance: 0, addition: 1.25, is_less_than_6_months: true)
output_path = pdf_generator.generate_pdf("/Users/krishnaprasath/Desktop/Depreciation_Schedule_Report_v1.pdf")


combine_pdf calling

require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/combined_pdf.rb'

loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
company_name = "Diddi Computer Trading"
location = "Hyderabad"
projection_years = 6

assets = [
  { name: "Plant & Machinery", depreciation_percent: 15, opening_balance: 0, addition: 32.00, is_less_than_6_months: true },
  { name: "Interiors", depreciation_percent: 15, opening_balance: 0, addition: 1.25, is_less_than_6_months: true }
]

combined_pdf_service = ProjectReport::CombinedReportPdfService.new(
  loan_amount, annual_interest_rate, loan_years, company_name, location, projection_years, assets
)

output_path = "/Users/krishnaprasath/Desktop/combined_report.pdf"
combined_pdf_service.generate_combined_pdf(output_path)
