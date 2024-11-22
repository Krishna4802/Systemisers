require "prawn"
require "prawn/table"
require_relative "two_in_one"
require_relative "loan_amortization"
require 'active_support/core_ext/object/blank'

module ProjectReport
    class GenerateCombinedReportPdf
      def initialize(company_name:, location:, loan_amount:, annual_interest_rate:, loan_years:, projection_years: 6)
        @company_name = company_name
        @location = location
        @depreciation_schedule = DepreciationSchedule.new(projection_years: projection_years)
        @loan_amortization = LoanAmortization.new(loan_amount, annual_interest_rate, loan_years)
        @actual_years_count = 0
      end
  
      def add_depreciation_asset(name, depreciation_percent:, opening_balance: 0, actual_additions: [], projected_addition: 0, is_less_than_6_months: false)
        @depreciation_schedule.add_asset(
          name,
          depreciation_percent: depreciation_percent,
          opening_balance: opening_balance,
          actual_additions: actual_additions,
          projected_addition: projected_addition,
          is_less_than_6_months: is_less_than_6_months
        )
        @actual_years_count = [@actual_years_count, actual_additions.size].max
      end
  
      def generate_pdf(output_path = "Combined_Report.pdf")
        Prawn::Document.generate(output_path) do |pdf|
          pdf.font_families.update("Roboto" => {
            normal: "/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/web_app/src/assets/fonts/Roboto-Regular.ttf",
            bold: "/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/web_app/src/assets/fonts/Roboto-Bold.ttf",
          })
  
          pdf.font "Roboto"
  
          pdf.text @company_name, size: 16, style: :bold
          pdf.text @location, size: 12
          pdf.move_down 20
  
          pdf.text "Loan Amortization Report", size: 16, style: :bold
          pdf.move_down 10
          loan_summary = @loan_amortization.loan_summary
          pdf.table([
            ["Monthly Payment", format_currency(loan_summary[:monthly_payment])],
            ["Total Interest Paid", format_currency(loan_summary[:total_interest_paid])],
            ["Total Payments Amount", format_currency(loan_summary[:total_payments_amount])],
          ], header: true, column_widths: [200, 250])
  
          pdf.move_down 20
          pdf.text "Amortization Schedule", size: 16, style: :bold
          amortization_schedule = @loan_amortization.generate_amortization_schedule
          pdf.move_down 10
          pdf.table(
            [["Period", "Payment", "Principal", "Interest", "Total Interest Paid", "New Payoff Amount"]] +
            amortization_schedule.map do |entry|
              [
                entry[:period],
                format_currency(entry[:payment]),
                format_currency(entry[:principal]),
                format_currency(entry[:interest]),
                format_currency(entry[:total_interest_paid]),
                format_currency(entry[:new_payoff_amount])
              ]
            end,
            header: true,
            column_widths: calculate_column_widths(6, pdf.bounds.width),
            width: pdf.bounds.width
          )
  
          pdf.start_new_page
  
          pdf.text "Depreciation Schedule", size: 16, style: :bold
          pdf.move_down 10
  
          depreciation_data = @depreciation_schedule.display_schedule
          actual_years_count = @actual_years_count
          projected_years_count = @depreciation_schedule.projection_years
          # puts "Actual years: #{actual_years_count}" 
          # puts "Projected years: #{projected_years_count}" 
  
          pdf.move_down 20
  
          header_row_1 = ["Particulars"]
          header_row_1 += ["Actual"] * actual_years_count if actual_years_count > 0
          header_row_1 += ["Projected"] * projected_years_count
  
          years = (@depreciation_schedule.current_year - actual_years_count + 1..@depreciation_schedule.current_year + projected_years_count).to_a
          header_row_2 = ["Period"] + years.map { |year| "#{year - 1}-#{year}" }
  
          table_data = [header_row_1, header_row_2]
  
          depreciation_data[:assets].each do |asset|
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
          table = pdf.make_table(table_data, header: true, row_colors: ["F0F0F0", "FFFFFF"])
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
  
      def calculate_column_widths(num_columns, total_width)
        min_width_per_column = 100
        column_widths = Array.new(num_columns, total_width / num_columns)
  
        column_widths.map! { |width| [width, min_width_per_column].max }
  
        total_adjusted_width = column_widths.sum
        if total_adjusted_width > total_width
          scale_factor = total_width / total_adjusted_width.to_f
          column_widths.map! { |width| width * scale_factor }
        end
  
        column_widths
      end
    end
  end
  

# sample calling

# loan_amount = 100000
# annual_interest_rate = 10
# loan_years = 5
# projection_years = 6

# depreciation_schedule = ProjectReport::GenerateCombinedReportPdf.new(
#   company_name: "ABC Corp",
#   location: "Mumbai",
#   loan_amount: loan_amount,
#   annual_interest_rate: annual_interest_rate,
#   loan_years: loan_years,
#   projection_years: projection_years
# )

# # depreciation_schedule.add_depreciation_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_additions: [198.68, 152.22], projected_addition: 293.00, is_less_than_6_months: true)
# # depreciation_schedule.add_depreciation_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_additions: [39.00, 0], projected_addition: 0, is_less_than_6_months: true)
# # depreciation_schedule.add_depreciation_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_additions: [0.81, 0], projected_addition: 0, is_less_than_6_months: true)
# # depreciation_schedule.add_depreciation_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_additions: [7.50, 0], projected_addition: 0, is_less_than_6_months: true)
# # depreciation_schedule.add_depreciation_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_additions: [6.02, 0], projected_addition: 0, is_less_than_6_months: true)
# # depreciation_schedule.add_depreciation_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_additions: [5.25, 0], projected_addition: 0, is_less_than_6_months: true)
# # depreciation_schedule.add_depreciation_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_additions: [32.57, 0], projected_addition: 0, is_less_than_6_months: true)

# depreciation_schedule.add_depreciation_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_additions: [], projected_addition: 32.00, is_less_than_6_months: true)
# depreciation_schedule.add_depreciation_asset("Interiors", depreciation_percent: 15, opening_balance: 0, actual_additions: [], projected_addition: 1.25, is_less_than_6_months: true)

# output_file = depreciation_schedule.generate_pdf("/Users/krishnaprasath/Desktop/Combined_Loan_Depreciation_Report.pdf")
