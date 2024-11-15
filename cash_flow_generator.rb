require Rails.root.join("config/constants/detailed_report_constant.rb").to_s

module GenerateProjectReport
  class CashFlowGenerator
    def initialize(company_name, location)
      @company_name = company_name
      @location = location
    end

    def generate_cash_flow(pdf)
      pdf.start_new_page
      draw_page_border(pdf)
      pdf.move_down 5
      setup_pdf_header(pdf)
      pdf.draw_text "Cash Flow", at: [5, pdf.cursor], style: :bold, size: 10
      pdf.move_down 5


      data = [
        ["Particulars", "Audited", "Audited", "Provisional", "Projected", "Projected"],
        ["Period", "FY 2020-21", "FY 2021-22", "FY 2022-23", "FY 2023-24", "FY 2024-25"],
        ["", "", "", "", "", ""],
        ["Inflow", "", "", "", "", ""],
        ["Profit after tax but before interest", "", "", "-", "962.74", "1,088.83"],
        ["Increase in reserves and Surplus", "", "", "", "", ""],
        ["Capital addition", "", "", "-", "50.00", "-"],
        ["Term Loan UBI (including interest capitalised)", "", "-", "-", "(38.08)", "(55.09)"],
        ["Manjeera Finance", "", "", "-", "-", ""],
        ["Working Capital Loan", "", "-", "-", "907.64", "-"],
        ["Increase in Other Long Term Borrowings", "", "", "", "(21.83)", "(11.24)"],
        ["Increase in other current liabilities", "", "", "", "3.34", "7.01"],
        ["Increase in Trade Payables", "-", "-", "", "1.75", "1.84"],
        ["Increase in Repayments in next 12 months", "", "", "-", "-", ""],
        ["Increase in Advances from Customers", "-", "", "-", "(871.04)", "80.88"],
        ["Increase in provisions", "", "", "-", "140.70", "47.63"],
        ["", "", "", "", "", ""],
        ["TOTAL", "-", "-", "-", "1,135.22", "1,159.87"],
        ["", "", "", "", "", ""],
        ["Out Flow", "", "", "", "", ""],
        ["Investment in F.Assets", "", "", "-", "-", "-"],
        ["Deposits", "", "-", "-", "-", "-"],
        ["Interest on W/c UBI", "", "-", "-", "95.00", "95.00"],
        ["Interest on Term Loan UBI", "", "-", "-", "37.16", "32.19"],
        ["Interest on Vehicle Loans", "", "", "-", "2.81", "1.64"],
        ["Interest on Manjeera finance", "", "", "-", "-", "-"],
        ["Repayment of Vehicle loans", "", "", "-", "-", "-"],
        ["Repayment of other current liabilities", "", "", "-", "-", "-"],
        ["Repayment of Manjeera finance", "", "", "-", "-", "-"],
        ["Repayment of Term loan from UBI", "", "", "-", "-", "-"],
        ["Increase in Other Current assets", "", "-", "-", "13.70", "14.38"],
        ["Increase in short advances", "", "", "-", "12.29", "3.69"],
        ["Increase in Inventory", "", "-", "-", "-", "-"],
        ["Increase in Sundry Debtors", "", "-", "-", "237.45", "269.78"],
        ["Increase in advance from customer", "", "", "-", "677.62", "622.73"],
        ["Dividend Payout", "", "", "", "", "72.00"],
        ["TOTAL", "-", "-", "-", "1,076.02", "1,111.41"],
        ["", "", "", "", "", ""],
        ["Opening balance", "", "", "", "404.62", "463.82"],
        ["Surplus/Deficit", "", "", "", "59.19", "48.46"],
        ["Non Cash Items", "-", "-", "-", "-", "-"],
        ["Closing balance", "-", "", "404.62", "463.82", "512.28"],
      ]

      pdf.table(data, header: 2, width: pdf.bounds.width, cell_style: { size: 9 }) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = "DDDDDD"
        table.row(0).borders = [:left, :right, :top, :bottom]
        table.row(1).background_color = "E8E8E8"
        table.row(1).borders = [:left, :right, :top, :bottom]

        table.cells.padding = [2, 1, 2, 1]
        table.cells.borders = [:left, :right]
        table.cells.align = :center
        table.columns(0).align = :left

        bold_particulars = ["Inflow", "Out Flow", "Opening balance", "Surplus/Deficit", "Non Cash Items", "Closing balance"]
        data&.each_with_index do |row, index|
          table.row(index).font_style = :bold if bold_particulars.include?(row[0])
        end

        table.row(0).background_color = "CECECE"
        table.row(1).background_color = "E8E8E8"
        table.row(-1).background_color = "CECECE"

        [0, 1, 17, -1, -6]&.each do |i|
          table.row(i).borders = [:left, :right, :top, :bottom]
          table.row(i).align = :center
        end
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
