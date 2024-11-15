require Rails.root.join("config/constants/detailed_report_constant.rb").to_s

module GenerateProjectReport
  class LoanAmortizationReport
    def initialize(company_name, location, loan_amount, annual_interest_rate, loan_years, moratorium_type = DEFAULT_MORATORIUM_TYPE, moratorium_month = DEFAULT_MORATORIUM_MONTH, start_date = Time.zone.today)
      @company_name = company_name
      @location = location
      @loan_amortization = ProjectReportLib::LoanAmortization.new(loan_amount, annual_interest_rate, loan_years, moratorium_type, moratorium_month, start_date)
      @actual_years_count = 0
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

    def format_depreciation_currency(amount)
      if amount == 0.0 || amount.nil? || amount == "-"
        "-"
      else
        "#{'%.2f' % amount}"
      end
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

    def format_currency(amount)
      "#{amount}"
    end
  end
end
