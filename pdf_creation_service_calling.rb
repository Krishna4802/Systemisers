# generate_loan_amortization_pdf calling

require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_loan_amortization_pdf.rb'
loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
pdf_service = ProjectReport::GenerateLoanAmortizationPdf.new(loan_amount, annual_interest_rate, loan_years)
output_path = pdf_service.generate_pdf("/Users/krishnaprasath/Desktop/Loan_Amortization_Report.pdf")

# DepreciationSchedule calling

require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/depreciation_schedule.rb'
schedule = ProjectReport::DepreciationSchedule.new(projection_years: 6)
schedule.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, addition: 32.00, is_less_than_6_months: true)
schedule.add_asset("Interiors", depreciation_percent: 15, opening_balance: 0, addition: 1.25, is_less_than_6_months: true)
result = schedule.display_schedule
puts result



# DepreciationSchedule_pdf calling

require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_depreciation_schedule_pdf.rb'
pdf_generator = ProjectReport::GenerateDepreciationSchedulePdf.new(company_name:"Diddi Computer Trading",location:"Hydrabad",projection_years: 6)
pdf_generator.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, addition: 32.00, is_less_than_6_months: true)
pdf_generator.add_asset("Interiors", depreciation_percent: 15, opening_balance: 0, addition: 1.25, is_less_than_6_months: true)
output_path = pdf_generator.generate_pdf("/Users/krishnaprasath/Desktop/Depreciation_Schedule_Report_v1.pdf")



# Depreciation_schedule_actual calling

require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/depreciation_schedule_actual.rb'
depreciation_schedule = ProjectReport::DepreciationScheduleActual.new(projection_years: 6)
depreciation_schedule.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 198.68, actual_addition_2: 152.22, projected_addition: 293.00, is_less_than_6_months: true)
depreciation_schedule.add_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_addition_1: 39.00, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_addition_1: 0.81, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_addition_1: 7.50, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 6.02, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 5.25, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 32.57, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)

result = depreciation_schedule.display_schedule
puts result



# depreciation_schedule_actual pdf download

require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_depreciation_schedule_actual_pdf.rb'
pdf_generator = ProjectReport::GenerateDepreciationSchedulePdf.new(company_name: "ABC Pvt Ltd", location: "New Delhi", projection_years: 6)
pdf_generator.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 198.68, actual_addition_2: 152.22, projected_addition: 293.00, is_less_than_6_months: true)
pdf_generator.add_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_addition_1: 39.00, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_addition_1: 0.81, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_addition_1: 7.50, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 6.02, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 5.25, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 32.57, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.generate_pdf("/Users/krishnaprasath/Desktop/Depreciation_Schedule_Report_actual.pdf")




# Combined Report actual pdf

require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_loan_amortization_pdf'
require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_depreciation_schedule_actual_pdf.rb'
require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/combine_pdf_reports.rb'

loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
company_name = "Diddi Computer Trading"
location = "Hydrabad"
projection_years = 6

pdf_service = ProjectReport::GenerateLoanAmortizationPdf.new(loan_amount, annual_interest_rate, loan_years)
loan_amortization_pdf_path = "/Users/krishnaprasath/Desktop/Loan_Amortization_Report.pdf"
pdf_service.generate_pdf(loan_amortization_pdf_path)

company_name = "Diddi Computer Trading"
location = "Hydrabad"
projection_years = 6
depreciation_schedule_pdf_path = "/Users/krishnaprasath/Desktop/Depreciation_Schedule_Report_actual.pdf"
pdf_generator = ProjectReport::GenerateDepreciationSchedulePdf.new(company_name: company_name, location: location, projection_years: projection_years)
pdf_generator.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 198.68, actual_addition_2: 152.22, projected_addition: 293.00, is_less_than_6_months: true)
pdf_generator.add_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_addition_1: 39.00, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_addition_1: 0.81, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_addition_1: 7.50, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 6.02, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 5.25, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.add_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_addition_1: 32.57, actual_addition_2: 0, projected_addition: 0, is_less_than_6_months: true)
pdf_generator.generate_pdf(depreciation_schedule_pdf_path)

combined_pdf_service = ProjectReport::CombinePdfReports.new([loan_amortization_pdf_path, depreciation_schedule_pdf_path])
combined_output_path = "/Users/krishnaprasath/Desktop/combined_report_actual.pdf"
combined_pdf_service.combine_and_generate(combined_output_path)

puts "Combined PDF created at: #{combined_output_path}"



# Combined Report pdf


require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_loan_amortization_pdf'
require_relative '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/generate_depreciation_schedule_pdf.rb'
require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/combine_pdf_reports.rb'

loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
company_name = "Diddi Computer Trading"
location = "Hydrabad"
projection_years = 6

pdf_service = ProjectReport::GenerateLoanAmortizationPdf.new(loan_amount, annual_interest_rate, loan_years)
loan_amortization_pdf_path = "/Users/krishnaprasath/Desktop/Loan_Amortization_Report.pdf"
pdf_service.generate_pdf(loan_amortization_pdf_path)

company_name = "Diddi Computer Trading"
location = "Hydrabad"
projection_years = 6
depreciation_schedule_pdf_path = "/Users/krishnaprasath/Desktop/Depreciation_Schedule_Report_v1.pdf"
pdf_generator = ProjectReport::GenerateDepreciationSchedulePdf.new(company_name:"Diddi Computer Trading",location:"Hydrabad",projection_years: 6)
pdf_generator.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, addition: 32.00, is_less_than_6_months: true)
pdf_generator.add_asset("Interiors", depreciation_percent: 15, opening_balance: 0, addition: 1.25, is_less_than_6_months: true)
pdf_generator.generate_pdf(depreciation_schedule_pdf_path)

combined_pdf_service = ProjectReport::CombinePdfReports.new([loan_amortization_pdf_path, depreciation_schedule_pdf_path])
combined_output_path = "/Users/krishnaprasath/Desktop/combined_report_new.pdf"
combined_pdf_service.combine_and_generate(combined_output_path)

puts "Combined PDF created at: #{combined_output_path}"
