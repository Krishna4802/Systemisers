module GenerateProjectReport
  class ProfitabilityStatementGenerator
    def initialize(company_name, location, projection_years)
      @company_name = company_name
      @location = location
      @depreciation_schedule = ProjectReportLib::DepreciationSchedule.new(projection_years)
      @actual_years_count = 0
    end

    def add_depreciation_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
      @depreciation_schedule.add_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
      update_actual_years_count(actual_additions)
    end

    def generate_profitability_statement(pdf)
      draw_page_border(pdf)
      depreciation_data = @depreciation_schedule.display_schedule
      data = [
        ["Particulars", "Audited", "Audited", "Provisional", "Projected", "Projected"],
        ["Period", "FY 2020-21", "FY 2021-22", "FY 2022-23", "FY 2023-24", "FY 2024-25"],
        ["Income", "", "", "", "", ""],
        ["Gross Sales", "752.85", "2,144.00", "4,231.81", "7,194.07", "10,431.40"],
        ["Less: Sales Returns", "-", "-", "-", "-", "-"],
        ["Less: Discount Allowed", "-", "-", "-", "-", "-"],
        ["Net Sales", "752.85", "2,143.82", "4,231.81", "7,194.07", "10,431.40"],
        ["Less:Sales Returns", "", "", "", "", ""],
        ["Total :(Net Sales)", "752.85", "2,143.82", "4,231.81", "7,194.07", "10,431.40"],
        ["Expenses", "", "", "", "", ""],
        ["  Purchase of Seeds", "517.74", "1,207.90", "2,391.24", "4,065.10", "6,707.42"],
        ["  Packing Material", "2.39", "5.44", "20.40", "28.56", "31.42"],
        ["  Direct Expenses", "8.76", "164.34", "158.92", "238.38", "262.22"],
        ["Cost of Goods Sold", "528.89", "1,377.68", "2,570.56", "4,332.05", "7,001.06"],
        ["Salaries and Remuneration", "131.63", "287.96", "469.93", "657.90", "855.27"],
        ["Research and Development", "-", "48.97", "115.32", "161.45", "193.74"],
        ["Operating Expenses", "30.45", "206.56", "589.06", "824.68", "989.62"],
        ["Selling & Distribution Expenses", "20.74", "84.11", "-", "-", "-"],
        ["EBITDA", "41.14", "138.55", "486.93", "1,217.99", "1,391.71"],
        ["Interest on OD UBI", "-", "-", "1.20", "95.00", "95.00"],
        ["Interest on Term Loan UBI", "-", "-", "6.64", "37.16", "32.19"],
        ["Interest on Manjeera Finance", "-", "-", "24.63", "-", "-"],
        ["Interest on Vehicle loans", "2.23", "7.84", "4.27", "2.81", "1.64"],
        ["Preliminary Expenses", "-", "-", "4.00", "4.00", "4.00"],
      ]

      depreciation_row = ["Depreciation"]

      if depreciation_data && depreciation_data[:totals] && depreciation_data[:totals][:total_depreciation]
        depreciation_values = depreciation_data[:totals][:total_depreciation]

        expected_years = data[0].size - 1

        depreciation_values = depreciation_values.take(expected_years) + Array.new([0, expected_years - depreciation_values.size].max, "-")

        depreciation_row += depreciation_values&.map { |value| format_depreciation_currency(value) }
      else
        depreciation_row += Array.new(data[0].size - 1, "-")&.map { |value| format_depreciation_currency(value) }
      end
      data << depreciation_row

      data += [
        ["EBT", "24.14", "109.50", "388.47", "1,005.01", "1,195.53"],
        ["Provision for Tax", "6.56", "30.12", "110.55", "251.25", "298.88"],
        ["Profit after Tax", "17.58", "79.38", "277.91", "753.76", "896.64"],
        ["Previous Year", "(57.76)", "(40.18)", "39.20", "317.11", "1,070.87"],
        ["Carried to Balance Sheet", "(40.18)", "39.20", "317.11", "1,070.87", "1,967.51"],
      ]

      setup_pdf_header(pdf)
      pdf.draw_text "PROFITABILITY STATEMENT:", at: [5, pdf.cursor], style: :bold, size: 10
      pdf.draw_text "In Lakhs", at: [pdf.bounds.width - pdf.width_of("In Lakhs") - 50, pdf.cursor], size: 8
      pdf.move_down 5


      table_width = pdf.bounds.width - 20
      pdf.table(data, header: 2, width: table_width, cell_style: { size: 9 }) do
        row(0).font_style = :bold
        row(0).background_color = "DDDDDD"
        cells.padding = [3, 1.5, 3, 1.5]
        cells.border_width = 0.5
        cells.align = :center
        columns(0).align = :left
        (0..10)&.each { |i| column(i).borders = [:left, :right] }

        row(0).background_color = "CECECE"
        row(1).background_color = "E8E8E8"
        row(-1).background_color = "CECECE"

        row(-1).borders = [:left, :right, :top, :bottom]
        row(-2).borders = [:left, :right, :top, :bottom]
        row(-5).borders = [:left, :right, :top, :bottom]
        row(-12).borders = [:left, :right, :top]
        row(-17).borders = [:left, :right, :top]
        row(-22).borders = [:left, :right, :top, :bottom]
        row(1).borders = [:left, :right, :top, :bottom]
        row(0).borders = [:left, :right, :top, :bottom]
      end
    end

    def update_actual_years_count(actual_additions)
      @actual_years_count = [@actual_years_count, actual_additions.size].max
    end

    def format_depreciation_currency(amount)
      if amount == 0.0 || amount.nil? || amount == "-"
        "-"
      else
        "#{'%.2f' % amount}"
      end
    end

    def draw_page_border(pdf)
      pdf.stroke_bounds
    end

    def setup_pdf_header(pdf)
      left_margin = 5
      pdf.move_down 10
      pdf.font_size = 8
      pdf.draw_text @company_name, at: [left_margin, pdf.cursor], style: :bold, size: 12
      pdf.move_down 15
      pdf.text_box @location, at: [left_margin, pdf.cursor], width: pdf.bounds.width - 2 * left_margin, size: 10, overflow: :truncate
      pdf.move_down 40
    end
  end
end
