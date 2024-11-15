DEFAULT_MORATORIUM_MONTH = 5
DEFAULT_PROJECTION_YEARS = 6
DEFAULT_MORATORIUM_TYPE = "interest_capitalization"

DETAILED_REPORT_OUTPUT_PATH = "/Combined_Loan_Depreciation_Report.pdf"

PROJECT_ROOT = Pathname.new(File.dirname(__FILE__)).join("..", "..").realpath

ROBOTO_FONT_PATH = {
  normal: PROJECT_ROOT.join("app/assets/fonts/Roboto-Regular.ttf").to_s,
  bold: PROJECT_ROOT.join("app/assets/fonts/Roboto-Bold.ttf").to_s
}

COMPANY_NAME = "Company Name"
LOCATION = "Location"

LOAN_AMORTIZATION_TITLE = "Loan Amortization Report"
LOAN_AMORTIZATION_TABLE_HEADERS = ["Monthly Payment", "Total Interest Paid", "Total Payments Amount"]

AMORTIZATION_SCHEDULE_TITLE = "Amortization Schedule"
AMORTIZATION_SCHEDULE_HEADERS = ["Period", "Payment Date", "Payment", "Principal", "Interest", "Total Interest Paid", "New Payoff Amount"]

DEPRECIATION_SCHEDULE_TITLE = "Depreciation Schedule"
CURRENCY_LABEL = "Rs. in Lakhs"
END_OF_PDF = "End of the PDF file"
