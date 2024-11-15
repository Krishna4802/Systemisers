require Rails.root.join("config/constants/detailed_report_constant.rb").to_s

module GenerateProjectReport
  class BalanceSheetGenerator
    def initialize(company_name, location)
      @company_name = company_name
      @location = location
    end

    def balance_sheet(pdf)
      pdf.start_new_page
      draw_page_border(pdf)
      pdf.move_down 5

      setup_pdf_header(pdf)
      pdf.draw_text "PROJECTED BALANCE SHEETS", at: [5, pdf.cursor], style: :bold, size: 10
      pdf.move_down 5

      data = [
        ["Particulars", "Audited", "Audited", "Provisional", "Projected", "Projected"],
        ["Period", "FY 2020-21", "FY 2021-22", "FY 2022-23", "FY 2023-24", "FY 2024-25"],
        ["LIABILITIES", "", "", "", "", ""],
        ["Share Holders Funds", "", "", "", "", ""],
        ["Share Capital", "1.00", "69.00", "139.00", "139.00", "189.00"],
        ["Reserves and Surplus", "", "", "", "", ""],
        ["Opening Balance", "57.76", "40.18", "39.20", "317.11", "1,070.87"],
        ["Add: Current Year Profit", "17.58", "79.38", "277.91", "753.76", "896.64"],
        ["Less: Dividend Payout", "-", "-", "-", "-", "72.00"],
        ["Closing Reserve and Surplus", "(40.18)", "39.20", "317.11", "1,070.87", "1,895.51"],
        ["", "", "", "", "", ""],
        ["Share application money pending allotment", "-", "70.00", "-", "50.00", ""],
        ["", "", "", "", "", ""],
        ["Non Current Liabilities", "", "", "", "", ""],
        ["Term Loan from UBI", "401.71", "363.63", "308.54", "", ""],
        ["Manjeera Finance", "-", "-", "-", "-", ""],
        ["Long Term Borrowings", "20.97", "54.31", "46.74", "24.92", "13.68"],
        ["Loan from related parties", "68.00", "151.00", "154.15", "154.15", "154.15"],
        ["Unsecured Loans - Other", "153.35", "160.15", "-", "-", "-"],
        ["TOTAL", "203.14", "543.66", "1,058.70", "1,802.55", "2,560.88"],
        ["", "", "", "", "", ""],
        ["Assets", "", "", "", "", ""],
        ["Fixed Assets", "206.65", "260.67", "581.21", "507.20", "443.84"],
        ["Deferred Tax Asset", "-", "-", "-", "-", "-"],
        ["", "", "", "", "", ""],
        ["Capital Work in Progress", "232.81", "232.81", "232.81", "", ""],
        ["", "", "", "", "", ""],
        ["Current Assets", "", "", "", "", ""],
        ["Sundry Debtors", "-", "362.05", "599.51", "869.28", ""],
        ["Inventory", "-", "-", "-", "-", "-"],
        ["Advance to Suppliers", "526.34", "1,005.56", "1,936.06", "2,613.67", "3,236.41"],
        ["Short Term Loans and Advances", "75.79", "54.46", "61.44", "73.73", "77.42"],
        ["Other Current Assets", "54.12", "273.93", "287.62", "302.00", ""],
        ["Cash and Bank", "128.13", "78.04", "404.62", "463.82", "512.28"],
        ["", "730.26", "1,192.17", "3,038.10", "4,038.35", "4,997.39"],
        ["", "", "", "", "", ""],
        ["Less: Current Liabilities", "", "", "", "", ""],
        ["Payable in next 12 Months", "-", "-", "-", "-", ""],
        ["Trade Payables", "-", "-", "35.07", "36.82", "38.66"],
        ["Advances from Customers", "733.3", "908.25", "2,488.70", "1,617.65", "1,698.54"],
        ["Provisions", "0.48", "0.93", "110.55", "251.25", "298.88"],
        ["Other Current Liabilities", "66.76", "70.10", "77.11", "", ""],
        ["Bank OD", "92.36", "1,000.00", "1,000.00", "", ""],
        ["Working Capital Loan", "-", "-", "-", "-", ""],
        ["", "733.78", "909.18", "2,793.43", "2,975.82", "3,113.19"],
        ["Net Current Assets", "-3.52", "282.99", "244.66", "1,062.53", "1,884.21"],
        ["", "", "", "", "", ""],
        ["TOTAL", "203.13", "543.66", "1,058.70", "1,802.54", "2,560.88"],
      ]

      pdf.table(data, header: 2, width: pdf.bounds.width, cell_style: { size: 9 }) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = "DDDDDD"
        table.cells.padding = [2, 1, 2, 1]
        table.cells.borders = []
        table.cells.align = :center
        table.columns(0).align = :left

        (0..10)&.each { |i| table.columns(i).borders = [:left, :right] }

        bold_rows = ["LIABILITIES", "Share Holders Funds", "Reserves and Surplus", "Non Current Liabilities", "Assets", "Current Assets", "Less: Current Liabilities"]
        data&.each_with_index do |row, index|
          table.row(index).font_style = :bold if bold_rows.include?(row[0])
        end

        table.row(0).background_color = "CECECE"
        table.row(1).background_color = "E8E8E8"
        table.row(17).background_color = "CECECE"
        table.row(-1).background_color = "CECECE"

        [0, 1, 17, -1]&.each do |i|
          table.row(i).borders = [:left, :right, :top, :bottom]
        end

        data&.each_with_index do |row, index|
          if row[0] == "Closing Reserve and Surplus"
            table.row(index).columns(1..-1)&.each do |cell|
              cell.borders = [:top, :left, :right]
            end
          end
        end

        data&.each_with_index do |row, index|
          if row[0] == "Cash and Bank" || row[0] == "Working Capital Loan"
            table.row(index).columns(1..-1)&.each do |cell|
              cell.borders = [:bottom, :left, :right]
            end
          end
        end
      end
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

    def draw_page_border(pdf)
      pdf.stroke_bounds
    end
  end
end
