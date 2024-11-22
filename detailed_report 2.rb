class DetailedReport
  def initialize(company_name, location, loan_amount, annual_interest_rate, loan_years, projection_years = 6, moratorium_type = "", moratorium_month = DEFAULT_MORATORIUM_MONTH, start_date = Time.zone.today)
      @company_name = company_name
      @location = location
      @depreciation_schedule = ProjectReport::DepreciationSchedule.new(projection_years)
      @loan_amortization = ProjectReport::LoanAmortization.new(loan_amount, annual_interest_rate, loan_years, moratorium_type, moratorium_month, start_date)
      @actual_years_count = 0
  end

  def add_depreciation_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
      @depreciation_schedule.add_asset(
      name,
      depreciation_percent,
      opening_balance,
      actual_additions,
      projected_addition,
      is_less_than_6_months
      )
      @actual_years_count = [@actual_years_count, actual_additions.size].max
  end

  def generate_pdf(output_path = "Combined_Report.pdf")
    Prawn::Document.generate(output_path) do |pdf|
      pdf.font_families.update("Roboto" => {
        normal: "/systemisers_app/api/app/assets/fonts/Roboto-Regular.ttf",
        bold: "/systemisers_app/api/app/assets/fonts/Roboto-Bold.ttf"
      })

      pdf.font "Roboto"

      pdf.text @company_name, size: 16, style: :bold
      pdf.text @location, size: 12
      pdf.move_down 20

      pdf.text "Loan Amortization Report", size: 16, style: :bold
      pdf.move_down 10
      loan_summary = @loan_amortization.loan_summary

      pdf.table([
        ["Monthly Payment", format_depreciation_currency(loan_summary[:monthly_payment])],
        ["Total Interest Paid", format_depreciation_currency(loan_summary[:total_interest_paid])],
        ["Total Payments Amount", format_depreciation_currency(loan_summary[:total_payments_amount])],
      ], header: true, column_widths: [150, 200])

      pdf.move_down 20

      pdf.text "Amortization Schedule", size: 16, style: :bold
      amortization_schedule = @loan_amortization.get_loan_schedule
      pdf.move_down 10

      column_widths = calculate_column_widths(7, pdf.bounds.width, period_column_width: 45)

      pdf.table(
        [["Period", "payment_date", "Payment", "Principal", "Interest", "Total Interest Paid", "New Payoff Amount"]] +
        amortization_schedule[:schedule].map do |entry|
          [
            entry[:period],
            entry[:payment_date],
            format_currency(entry[:payment]),
            format_currency(entry[:principal]),
            format_currency(entry[:interest]),
            format_currency(entry[:total_interest_paid]),
            format_currency(entry[:new_payoff_amount]),
          ]
        end,
        header: true,
        column_widths: column_widths,
        width: pdf.bounds.width
      )
      pdf.start_new_page
      pdf.text "Depreciation Schedule", size: 16, style: :bold
      pdf.bounding_box([pdf.bounds.right - 100, pdf.cursor], width: 100) do
        pdf.text "Rs. in Lakhs", size: 12, align: :right
      end
      depreciation_data = @depreciation_schedule.display_schedule
      actual_years_count = @actual_years_count
      projected_years_count = @depreciation_schedule.projection_years

      pdf.move_down 20

      header_row_1 = ["Particulars"]
      header_row_1 += ["Actual"] * actual_years_count if actual_years_count > 0
      header_row_1 += ["Projected"] * projected_years_count

      years = (@depreciation_schedule.current_year - actual_years_count + 1..@depreciation_schedule.current_year + projected_years_count).to_a
      header_row_2 = ["Period"] + years.map { |year| "#{year - 1}-#{year}" }

      table_data = [header_row_1, header_row_2]

      depreciation_data[:assets]&.each do |asset|
        yearly_data = asset[:yearly_data]
        table_data << [{ content: asset[:name], font_style: :bold }]
        table_data << ["Opening Balance"] + yearly_data.map { |data| format_depreciation_currency(data[:opening_balance]) }
        table_data << ["Additions"] + yearly_data.map { |data| format_depreciation_currency(data[:addition]) }
        table_data << ["Total"] + yearly_data.map { |data| format_depreciation_currency(data[:total]) }
        table_data << ["Depreciation"] + yearly_data.map { |data| format_depreciation_currency(data[:depreciation]) }
        table_data << ["Closing Balance"] + yearly_data.map { |data| format_depreciation_currency(data[:closing_balance]) }
      end

      totals = depreciation_data[:totals]
      table_data << []
      table_data << ["Total Opening Balance"] + totals[:total_opening].map { |value| format_depreciation_currency(value) }
      table_data << ["Total Additions"] + totals[:total_addition].map { |value| format_depreciation_currency(value) }
      table_data << ["Total Depreciation"] + totals[:total_depreciation].map { |value| format_depreciation_currency(value) }
      table_data << ["Total Closing Balance"] + totals[:total_closing].map { |value| format_depreciation_currency(value) }
      table_data << ["End of the PDF file"]

      pdf.move_down 10
      table = pdf.make_table(table_data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: pdf.bounds.width)
      table.draw
    end
    output_path
  end

  private

  def format_currency(amount)
    "₹ #{amount}"
  end

  def format_depreciation_currency(amount)
    "₹ #{'%.2f' % amount}"
  end

  def calculate_column_widths(num_columns, total_width, period_column_width: 45)
    min_width_per_column = 20
    max_width = total_width - period_column_width
    remaining_columns = num_columns - 1

    column_widths = [period_column_width] + Array.new(remaining_columns, max_width / remaining_columns)

    column_widths.map! { |width| [width, min_width_per_column].max }
    total_adjusted_width = column_widths.sum

    if total_adjusted_width > total_width
      scale_factor = total_width / total_adjusted_width.to_f
      column_widths.map! { |width| width * scale_factor }
    end

    column_widths
  end
end
