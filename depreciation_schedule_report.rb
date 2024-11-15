require Rails.root.join("config/constants/detailed_report_constant.rb").to_s

module GenerateProjectReport
  class DepreciationScheduleReport
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
