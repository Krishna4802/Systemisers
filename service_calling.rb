
# two in one

require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/two_in_one.rb'
schedule = ProjectReport::DepreciationSchedule.new(projection_years: 6)
schedule.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_additions: [], projected_addition: 32.00, is_less_than_6_months: true)
schedule.add_asset("Interiors", depreciation_percent: 15, opening_balance: 0, actual_additions: [], projected_addition: 1.25, is_less_than_6_months: true)
result = schedule.display_schedule
puts result
  

require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/two_in_one.rb'
depreciation_schedule = ProjectReport::DepreciationSchedule.new(projection_years: 6)
depreciation_schedule.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_additions: [198.68, 152.22],  projected_addition: 293.00, is_less_than_6_months: true)
depreciation_schedule.add_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_additions: [39.00, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_additions: [0.81, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_additions: [7.50, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_additions: [6.02, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_additions: [5.25, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_additions: [32.57, 0], projected_addition: 0, is_less_than_6_months: true)
result = depreciation_schedule.display_schedule
puts result


# LoanAmortization

require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/loan_amortization.rb'
loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
loan_amortization = ProjectReport::LoanAmortization.new(loan_amount, annual_interest_rate, loan_years)
combined_results = {
  loan_summary: loan_amortization.loan_summary,
  amortization_schedule: loan_amortization.generate_amortization_schedule
}
puts combined_results



# PDF Generation

require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/two_in_one.rb'
require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/loan_amortization.rb'
require '/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/api/app/lib/project_report/pdf_create.rb'

loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
projection_years = 6

depreciation_schedule = ProjectReport::DetailedReport.new(
  company_name: "ABC Corp",
  location: "Mumbai",
  loan_amount: loan_amount,
  annual_interest_rate: annual_interest_rate,
  loan_years: loan_years,
  projection_years: projection_years
)

depreciation_schedule.add_depreciation_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_additions: [198.68, 152.22], projected_addition: 293.00, is_less_than_6_months: true)
depreciation_schedule.add_depreciation_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_additions: [39.00, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_depreciation_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_additions: [0.81, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_depreciation_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_additions: [7.50, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_depreciation_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_additions: [6.02, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_depreciation_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_additions: [5.25, 0], projected_addition: 0, is_less_than_6_months: true)
depreciation_schedule.add_depreciation_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_additions: [32.57, 0], projected_addition: 0, is_less_than_6_months: true)

# depreciation_schedule.add_depreciation_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_additions: [], projected_addition: 32.00, is_less_than_6_months: true)
# depreciation_schedule.add_depreciation_asset("Interiors", depreciation_percent: 15, opening_balance: 0, actual_additions: [], projected_addition: 1.25, is_less_than_6_months: true)

output_file = depreciation_schedule.generate_pdf("/Users/krishnaprasath/Desktop/Combined_Loan_Depreciation_Report_actual.pdf")







# rails c

# depreciation_schedule calling 


depreciation_schedule = ProjectReport::DepreciationSchedule.new(6)

depreciation_schedule.add_asset("Plant & Machinery", 15, 0, [198.68, 152.22], 293.00, true)
depreciation_schedule.add_asset("Building", 5, 0, [39.00, 0], 0, true)
depreciation_schedule.add_asset("Computer", 40, 0, [0.81, 0], 0, true)
depreciation_schedule.add_asset("Furniture", 10, 0, [7.50, 0], 0, true)
depreciation_schedule.add_asset("Generator", 15, 0, [6.02, 0], 0, true)
depreciation_schedule.add_asset("Packing Machine", 15, 0, [5.25, 0], 0, true)
depreciation_schedule.add_asset("Vehicle", 15, 0, [32.57, 0], 0, true)




depreciation_schedule = ProjectReport::DepreciationSchedule.new(6)

depreciation_schedule.add_asset("Plant & Machinery", 15,  0, [], 32.00, true)
depreciation_schedule.add_asset("Interiors", 15, 0, [], 1.25, true)

result = depreciation_schedule.display_schedule
yearly_summary_result = depreciation_schedule.yearly_summary
puts yearly_summary_result



# loan_amortization_schedule

js = ProjectReport::LoanAmortization.new(2400000,10,5,"interest_capitalization",5,Date.today)


# detailed_report generation calling 

com = "abv"
location="ast"
int = "interest_capitalization"
depreciation_schedule = DetailedReport.new(com,location,2400000,10,5,6,int,5,Date.today)
depreciation_schedule.add_depreciation_asset("Plant & Machinery", 15,  0, [], 32.00, true)
depreciation_schedule.add_depreciation_asset("Interiors", 15, 0, [], 1.25, true)
output_file = depreciation_schedule.generate_pdf("/Users/krishnaprasath/Desktop/Combined_Loan_Depreciation_Report.pdf")

# depreciation_schedule = DetailedReport.new(com,location,2400000,10,5,6)


com = "abv"
location="ast"
depreciation_schedule = DetailedReport.new(com,location,2400000,10,5,6)
depreciation_schedule.add_depreciation_asset("Plant & Machinery", 15,0, [198.68, 152.22],293.00,true)
depreciation_schedule.add_depreciation_asset("Building", 5, 0, [39.00, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Computer", 40, 0, [0.81, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Furniture", 10, 0, [7.50, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Generator", 15, 0, [6.02, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Packing Machine", 15, 0, [5.25, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Vehicle", 15, 0, [32.57, 0], 0, true)
output_file = depreciation_schedule.generate_pdf("/Users/krishnaprasath/Desktop/Combined_Loan_Depreciation_Report_actual.pdf")





com = "abv"
location="ast"
int = "interest_capitalization"

depreciation_schedule = DetailedReport.new("abv","ast",2400000,10,5,6,"interest_capitalization",5,Date.today)
depreciation_schedule.add_depreciation_asset("Plant & Machinery", 15,0, [198.68, 152.22],293.00,true)
depreciation_schedule.add_depreciation_asset("Building", 5, 0, [39.00, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Computer", 40, 0, [0.81, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Furniture", 10, 0, [7.50, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Generator", 15, 0, [6.02, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Packing Machine", 15, 0, [5.25, 0], 0, true)
depreciation_schedule.add_depreciation_asset("Vehicle", 15, 0, [32.57, 0], 0, true)
output_file = depreciation_schedule.generate_pdf("/Users/krishnaprasath/Desktop/Combined_Loan_Depreciation_Report.pdf")