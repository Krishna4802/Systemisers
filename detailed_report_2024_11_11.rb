require Rails.root.join("config/constants/detailed_report_constant.rb").to_s

class DetailedReport
  def initialize(company_name, location, loan_amount, annual_interest_rate, loan_years, projection_years = DEFAULT_PROJECTION_YEARS, moratorium_type = DEFAULT_MORATORIUM_TYPE, moratorium_month = DEFAULT_MORATORIUM_MONTH, start_date = Time.zone.today)
    @company_name = company_name
    @location = location
    @depreciation_schedule = ProjectReportLib::DepreciationSchedule.new(projection_years)
    @loan_amortization = ProjectReportLib::LoanAmortization.new(loan_amount, annual_interest_rate, loan_years, moratorium_type, moratorium_month, start_date)
    @actual_years_count = 0
  end

  def add_depreciation_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
    @depreciation_schedule.add_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
    update_actual_years_count(actual_additions)
  end

  def generate_pdf(output_path = DETAILED_REPORT_OUTPUT_PATH)
    Prawn::Document.generate(output_path) do |pdf|
      set_font(pdf)
      add_company_details(pdf)
      add_loan_amortization_report(pdf)
      add_amortization_schedule(pdf)
      add_depreciation_schedule(pdf)
    end
    output_path
  end

  private

  def set_font(pdf)
    pdf.font_families.update("Roboto" => ROBOTO_FONT_PATH)
    pdf.font "Roboto"
  end

  def add_company_details(pdf)
    pdf.text @company_name, size: 16, style: :bold
    pdf.text @location, size: 12
    pdf.move_down 20
  end

  def add_loan_amortization_report(pdf)
    pdf.text LOAN_AMORTIZATION_TITLE, size: 16, style: :bold
    pdf.move_down 10
    loan_summary = @loan_amortization.loan_summary
    pdf.table(generate_loan_amortization_table_data(loan_summary), header: true, column_widths: [150, 200])
    pdf.move_down 20
  end

  def generate_loan_amortization_table_data(loan_summary)
    LOAN_AMORTIZATION_TABLE_HEADERS.zip(
      [
        format_depreciation_currency(loan_summary[:monthly_payment]),
        format_depreciation_currency(loan_summary[:total_interest_paid]),
        format_depreciation_currency(loan_summary[:total_payments_amount]),
      ]
    )
  end

  def add_amortization_schedule(pdf)
    pdf.text AMORTIZATION_SCHEDULE_TITLE, size: 16, style: :bold
    amortization_schedule = @loan_amortization.get_loan_schedule
    pdf.move_down 10
    column_widths = calculate_column_widths(7, pdf.bounds.width, period_column_width: 45)
    pdf.table(generate_amortization_schedule_table_data(amortization_schedule), header: true, column_widths: column_widths, width: pdf.bounds.width)
    pdf.start_new_page
  end

  def generate_amortization_schedule_table_data(amortization_schedule)
    [AMORTIZATION_SCHEDULE_HEADERS] +
    amortization_schedule[:schedule]&.map do |entry|
      [
        entry[:period],
        entry[:payment_date],
        format_currency(entry[:payment]),
        format_currency(entry[:principal]),
        format_currency(entry[:interest]),
        format_currency(entry[:total_interest_paid]),
        format_currency(entry[:new_payoff_amount]),
      ]
    end
  end

  def add_depreciation_schedule(pdf)
    pdf.text DEPRECIATION_SCHEDULE_TITLE, size: 16, style: :bold
    add_currency_label(pdf)
    depreciation_data = @depreciation_schedule.display_schedule
    table_data = build_depreciation_table_data(depreciation_data)
    pdf.move_down 10
    table = pdf.make_table(table_data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: pdf.bounds.width)
    table.draw
  end

  def add_currency_label(pdf)
    pdf.bounding_box([pdf.bounds.right - 100, pdf.cursor], width: 100) do
      pdf.text CURRENCY_LABEL, size: 12, align: :right
    end
  end

  def build_depreciation_table_data(depreciation_data)
    header_row_1 = build_header_row_1
    header_row_2 = build_header_row_2
    table_data = [header_row_1, header_row_2]
    depreciation_data[:assets]&.each do |asset|
      table_data += build_asset_data(asset)
    end
    table_data += build_totals_data(depreciation_data[:totals])
    table_data << [END_OF_PDF]
    table_data
  end

  def build_header_row_1
    header_row_1 = ["Particulars"]
    header_row_1 += ["Actual"] * @actual_years_count if @actual_years_count > 0
    header_row_1 += ["Projected"] * @depreciation_schedule.projection_years
    header_row_1
  end

  def build_header_row_2
    years = (@depreciation_schedule.current_year - @actual_years_count + 1..@depreciation_schedule.current_year + @depreciation_schedule.projection_years).to_a
    ["Period"] + years.map { |year| "#{year - 1}-#{year}" }
  end

  def build_asset_data(asset)
    yearly_data = asset[:yearly_data]
    data = []
    data << [{ content: asset[:name], font_style: :bold }]
    data << ["Opening Balance"] + yearly_data.map { |entry| format_depreciation_currency(entry[:opening_balance]) }
    data << ["Additions"] + yearly_data.map { |entry| format_depreciation_currency(entry[:addition]) }
    data << ["Total"] + yearly_data.map { |entry| format_depreciation_currency(entry[:total]) }
    data << ["Depreciation"] + yearly_data.map { |entry| format_depreciation_currency(entry[:depreciation]) }
    data << ["Closing Balance"] + yearly_data.map { |entry| format_depreciation_currency(entry[:closing_balance]) }
    data
  end

  def build_totals_data(totals)
    [
      [],
      ["Total Opening Balance"] + totals[:total_opening].map { |value| format_depreciation_currency(value) },
      ["Total Additions"] + totals[:total_addition].map { |value| format_depreciation_currency(value) },
      ["Total Depreciation"] + totals[:total_depreciation].map { |value| format_depreciation_currency(value) },
      ["Total Closing Balance"] + totals[:total_closing].map { |value| format_depreciation_currency(value) },
    ]
  end


  def calculate_column_widths(num_columns, total_width, period_column_width: 45)
    min_width_per_column = 20
    max_width = total_width - period_column_width
    remaining_columns = num_columns - 1
    column_widths = [period_column_width] + Array.new(remaining_columns, max_width / remaining_columns)
    column_widths&.map! { |width| [width, min_width_per_column].max }
    scale_column_widths(column_widths, total_width)
  end

  def scale_column_widths(column_widths, total_width)
    total_adjusted_width = column_widths.sum
    return column_widths if total_adjusted_width <= total_width
    scale_factor = total_width / total_adjusted_width.to_f
    column_widths&.map { |width| width * scale_factor }
  end

  def update_actual_years_count(actual_additions)
    @actual_years_count = [@actual_years_count, actual_additions.size].max
  end

  def format_currency(amount)
    "₹ #{amount}"
  end

  def format_depreciation_currency(amount)
    "₹ #{'%.2f' % amount}"
  end
end
