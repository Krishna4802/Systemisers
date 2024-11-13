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
      generate_profitability_statement(pdf)
      balance_sheet(pdf)
      add_depreciation_schedule(pdf)
      generate_cash_flow(pdf)
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
    pdf.start_new_page
    draw_page_border(pdf)
    table_data = build_depreciation_table_data(@depreciation_schedule.display_schedule)
    setup_pdf_header(pdf)
    pdf.draw_text DEPRECIATION_SCHEDULE_TITLE, at: [5, pdf.cursor], style: :bold, size: 10
    pdf.move_down 10
    table = build_table(pdf, table_data)
    highlight_closing_balance_rows(table_data, table)
    highlight_total_opening_balance_row(table_data, table)
    table.draw
    # pdf.start_new_page if pdf.cursor < 100
  end


  def generate_profitability_statement(pdf)
    draw_page_border(pdf)
    pdf.move_down 5
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
      ["Preliminary Expenses", "-", "-", "4.00", "4.00", "4.00"]
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

    
    # pdf.text "M/S ROYAL SEEDS PRIVATE LIMITED", style: :bold, size: 12
    # pdf.text "Plot No. 7, Balaji Nagar, Sahara Road,\n Mansoorabad, Hyderabad, \nTelangana - 500068", size: 10
    # pdf.move_down 20
    # pdf.draw_text "PROFITABILITY STATEMENT:", at: [0, pdf.cursor], style: :bold, size: 10
    # # pdf.stroke_line([0, pdf.cursor - 2], [pdf.width_of("PROFITABILITY STATEMENT:"), pdf.cursor - 2])
    # pdf.draw_text "In Lakhs", at: [pdf.bounds.width - pdf.width_of("In Lakhs"), pdf.cursor], size: 8
    # pdf.move_down 5
    
    setup_pdf_header(pdf)
    pdf.draw_text "PROFITABILITY STATEMENT:", at: [5, pdf.cursor], style: :bold, size: 10
    # pdf.stroke_line([0, pdf.cursor - 2], [pdf.width_of("PROFITABILITY STATEMENT:"), pdf.cursor - 2])
    pdf.draw_text "In Lakhs", at: [pdf.bounds.width - pdf.width_of("In Lakhs"), pdf.cursor], size: 8
    pdf.move_down 5


    table_width = pdf.bounds.width - 20 
    pdf.table(data, header: 2, width: table_width, cell_style:{size:9}) do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"
      cells.padding = [3, 1.5, 3, 1.5]  
      cells.border_width = 0.5
      cells.align = :center
      columns(0).align = :left
      (0..10).each { |i| column(i).borders = [:left, :right] }
    
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
  

  def balance_sheet(pdf)
    pdf.start_new_page
    draw_page_border(pdf)
    pdf.move_down 5

    # pdf.text "M/S ROYAL SEEDS PRIVATE LIMITED", style: :bold, size: 12
    # pdf.text "Plot No. 7, Balaji Nagar, Sahara Road, Mansoorabad, Hyderabad, Telangana - 500068", size: 10
    # pdf.move_down 20
    # pdf.draw_text "PROJECTED BALANCE SHEETS", at: [0, pdf.cursor], style: :bold, size: 10
    # # pdf.stroke_line([0, pdf.cursor - 2], [pdf.width_of("PROJECTED BALANCE SHEETS"), pdf.cursor - 2])
    # pdf.move_down 5
  
    setup_pdf_header(pdf)
    pdf.draw_text "PROJECTED BALANCE SHEETS", at: [5, pdf.cursor], style: :bold, size: 10
    # pdf.stroke_line([0, pdf.cursor - 2], [pdf.width_of("PROJECTED BALANCE SHEETS"), pdf.cursor - 2])
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
      ["TOTAL", "203.13", "543.66", "1,058.70", "1,802.54", "2,560.88"]
    ]
  
    pdf.table(data, header: 2, width: pdf.bounds.width, cell_style:{size:9}) do |table|
      table.row(0).font_style = :bold
      table.row(0).background_color = "DDDDDD"
      table.cells.padding = [2, 1, 2, 1]
      table.cells.borders = []
      table.cells.align = :center
      table.columns(0).align = :left
  
      (0..10).each { |i| table.columns(i).borders = [:left, :right] }
  
      bold_rows = ["LIABILITIES", "Share Holders Funds", "Reserves and Surplus", "Non Current Liabilities", "Assets", "Current Assets", "Less: Current Liabilities"]
      data.each_with_index do |row, index|
        table.row(index).font_style = :bold if bold_rows.include?(row[0])
      end
  
      table.row(0).background_color = "CECECE"
      table.row(1).background_color = "E8E8E8"
      table.row(17).background_color = "CECECE"
      table.row(-1).background_color = "CECECE"
  
      [0, 1, 17, -1].each do |i|
        table.row(i).borders = [:left, :right, :top, :bottom]
      end
  
      data.each_with_index do |row, index|
        if row[0] == "Closing Reserve and Surplus"
          table.row(index).columns(1..-1).each do |cell|
            cell.borders = [:top, :left, :right]
          end
        end
      end
  
      data.each_with_index do |row, index|
        if row[0] == "Cash and Bank" || row[0] == "Working Capital Loan"
          table.row(index).columns(1..-1).each do |cell|
            cell.borders = [:bottom, :left, :right]
          end
        end
      end
    end
  end
  
  def generate_cash_flow(pdf)
    pdf.start_new_page
    draw_page_border(pdf)
    pdf.move_down 5

    # pdf.text "M/S ROYAL SEEDS PRIVATE LIMITED", style: :bold, size: 12
    # pdf.text "Plot No. 7, Balaji Nagar, Sahara Road, Mansoorabad, Hyderabad, Telangana - 500068", size: 10
    # pdf.move_down 20
    # pdf.draw_text "Cash Flow", at: [0, pdf.cursor], style: :bold, size: 10
    # pdf.move_down 5
    # 
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
      ["Repayment of other current liabilities","", "", "-", "-", "-"],
      ["Repayment of Manjeera finance","", "", "-", "-", "-"],
      ["Repayment of Term loan from UBI", "", "", "-", "-", "-"],
      ["Increase in Other Current assets", "", "-", "-", "13.70", "14.38"],
      ["Increase in short advances", "", "", "-", "12.29", "3.69"],
      ["Increase in Inventory", "", "-", "-", "-", "-"],
      ["Increase in Sundry Debtors","", "-", "-", "237.45", "269.78"],
      ["Increase in advance from customer", "", "", "-", "677.62", "622.73"],
      ["Dividend Payout", "", "", "", "", "72.00"],
      ["TOTAL", "-", "-", "-", "1,076.02", "1,111.41"],
      ["", "", "", "", "", ""],
      ["Opening balance", "","", "", "404.62", "463.82"],
      ["Surplus/Deficit", "", "", "", "59.19", "48.46"],
      ["Non Cash Items", "-", "-", "-", "-", "-"],
      ["Closing balance", "-", "", "404.62", "463.82", "512.28"]
    ]
  
    pdf.table(data, header: 2, width: pdf.bounds.width,cell_style:{size:9}) do |table|
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
      data.each_with_index do |row, index|
        table.row(index).font_style = :bold if bold_particulars.include?(row[0])
      end
  
      table.row(0).background_color = "CECECE"
      table.row(1).background_color = "E8E8E8"
      table.row(-1).background_color = "CECECE"
  
      [0, 1, 17, -1, -6].each do |i|
        table.row(i).borders = [:left, :right, :top, :bottom]
        table.row(i).align = :center
      end
    end
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
    ["Period"] + years&.map { |year| "FY #{year - 1}-#{(year) % 100}" }
  end

  def build_asset_data(asset)
    yearly_data = asset[:yearly_data]
    data = []
    asset_name_with_percentage = "#{asset[:name]} (#{asset[:depreciation_percent]}%)"
    data << [{ content: asset_name_with_percentage, font_style: :bold }] + Array.new(@depreciation_schedule.projection_years + @actual_years_count, "")
    data << ["Opening Balance"] + yearly_data&.map { |entry| format_depreciation_currency(entry[:opening_balance]) }
    data << ["Additions"] + yearly_data&.map { |entry| format_depreciation_currency(entry[:addition]) }
    data << ["Total"] + yearly_data&.map { |entry| format_depreciation_currency(entry[:total]) }
    data << ["Depreciation"] + yearly_data&.map { |entry| format_depreciation_currency(entry[:depreciation]) }
    data << ["Closing Balance"] + yearly_data&.map { |entry| format_depreciation_currency(entry[:closing_balance]) }
    data << [" "] + Array.new(@depreciation_schedule.projection_years + @actual_years_count, "")
    data
  end

  def build_totals_data(totals)
    [
      ["Total Opening Balance"] + totals[:total_opening]&.map { |value| format_depreciation_currency(value) },
      ["Total Additions"] + totals[:total_addition]&.map { |value| format_depreciation_currency(value) },
      ["Total Depreciation"] + totals[:total_depreciation]&.map { |value| format_depreciation_currency(value) },
      ["Total Closing Balance"] + totals[:total_closing]&.map { |value| format_depreciation_currency(value) },
    ]
  end

  def setup_pdf_header(pdf)
    left_margin = 5
    pdf.move_down 10
    pdf.font_size = 8
  
    pdf.draw_text @company_name, at: [left_margin, pdf.cursor], style: :bold, size: 12
    pdf.move_down 15
  
    pdf.text_box @location, 
                 at: [left_margin, pdf.cursor], 
                 width: pdf.bounds.width - 2 * left_margin,
                 size: 10,
                 overflow: :truncate  
    pdf.move_down 40
  end

  def build_table(pdf, table_data)
    pdf.make_table(table_data, header: true, width: pdf.bounds.width) do
      cells.border_color = "0a0a0a"
      cells.border_width = 0.5
      cells.padding = 1.5

      (0..10)&.each { |i| column(i).borders = [:left, :right] }
      (1..table_data[0].size - 1)&.each { |col| column(col).align = :center }
      row(0).borders = [:left, :right, :top, :bottom]
      row(1).borders = [:left, :right, :top, :bottom]
      row(-1).borders = [:left, :right, :top, :bottom]
      row(0).background_color = "CECECE"
      row(1).background_color = "E8E8E8"
      row(-1).background_color = "CECECE"
    end
  end

  def highlight_closing_balance_rows(table_data, table)
    table_data&.each_with_index do |row, index|
      if row[0] == "Closing Balance"
        table.row(index).columns(1..-1)&.each do |cell|
          cell.borders = [:top, :left, :right]
        end
      end
    end
  end

  def highlight_total_opening_balance_row(table_data, table)
    total_opening_balance_row = table_data.length - 4
    table.row(total_opening_balance_row)&.each_with_index do |cell, _col_index|
      cell.borders = [:top, :left, :right]
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

  def update_actual_years_count(actual_additions)
    @actual_years_count = [@actual_years_count, actual_additions.size].max
  end

  def draw_page_border(pdf)
    pdf.stroke_bounds
  end

  def format_currency(amount)
    "#{amount}"
  end

  def format_depreciation_currency(amount)
    if amount == 0.0 || amount.nil? || amount == "-"
      "-"
    else
      "#{'%.2f' % amount}"
    end
  end
end
