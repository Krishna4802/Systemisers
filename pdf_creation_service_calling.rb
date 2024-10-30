require './app/lib/project_report/generate_loan_amortization_pdf'
loan_amount = 100000
annual_interest_rate = 10
loan_years = 5
pdf_service = ProjectReport::GenerateLoanAmortizationPdf.new(loan_amount, annual_interest_rate, loan_years)
output_path = pdf_service.generate_pdf("/Users/krishnaprasath/Desktop/Loan_Amortization_Report.pdf")
