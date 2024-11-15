require Rails.root.join("config/constants/detailed_report_constant.rb").to_s

class DetailedReport
  def initialize(company_name, location, loan_amount, annual_interest_rate, loan_years, projection_years = DEFAULT_PROJECTION_YEARS, moratorium_type = DEFAULT_MORATORIUM_TYPE, moratorium_month = DEFAULT_MORATORIUM_MONTH, start_date = Time.zone.today)
    @loan_amortization_report = GenerateProjectReport::LoanAmortizationReport.new(company_name, location, loan_amount, annual_interest_rate, loan_years, moratorium_type, moratorium_month, start_date)
    @depreciation_schedule_report = GenerateProjectReport::DepreciationScheduleReport.new(company_name, location, projection_years)
    @profitability_statement_report = GenerateProjectReport::ProfitabilityStatementGenerator.new(company_name, location, projection_years)
    @balance_sheet_generator = GenerateProjectReport::BalanceSheetGenerator.new(company_name, location)
    @cash_flow_generator = GenerateProjectReport::CashFlowGenerator.new(company_name, location)
    @actual_years_count = 0
  end

  def add_asset_to_depreciation_schedule(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
    @depreciation_schedule_report.add_depreciation_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
    @profitability_statement_report.add_depreciation_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
  end

  def generate_pdf(output_path = DETAILED_REPORT_OUTPUT_PATH)
    Prawn::Document.generate(output_path) do |pdf|
      set_font(pdf)
      add_company_details(pdf)
      @loan_amortization_report.add_loan_amortization_report(pdf)
      @loan_amortization_report.add_amortization_schedule(pdf)
      @profitability_statement_report.generate_profitability_statement(pdf)
      @depreciation_schedule_report.add_depreciation_schedule(pdf)
      @balance_sheet_generator.balance_sheet(pdf)
      @cash_flow_generator.generate_cash_flow(pdf)
    end
    output_path
  end

  private

  def set_font(pdf)
    pdf.font_families.update("Roboto" => ROBOTO_FONT_PATH)
    pdf.font "Roboto"
  end

  def add_company_details(pdf)
    pdf.text @company_name, size: 14, style: :bold
    pdf.text @location, size: 8
    pdf.move_down 20
  end

  def add_currency_label(pdf)
    pdf.bounding_box([pdf.bounds.right - 100, pdf.cursor], width: 100) do
      pdf.text CURRENCY_LABEL, size: 12, align: :right
    end
  end

  def update_actual_years_count(actual_additions)
    @actual_years_count = [@actual_years_count, actual_additions.size].max
  end
end
