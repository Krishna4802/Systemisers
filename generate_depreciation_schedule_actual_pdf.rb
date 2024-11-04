require 'prawn'
require 'prawn/table'
require_relative 'depreciation_schedule_actual'

module ProjectReport
  class GenerateDepreciationSchedulePdf
    def initialize(company_name:, location:, projection_years: 7)
      @company_name = company_name
      @location = location
      @schedule = DepreciationScheduleActual.new(projection_years: projection_years)
    end

    def add_asset(name, depreciation_percent:, opening_balance: 0, actual_addition1: 0, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: false)
      @schedule.add_asset(
        name,
        depreciation_percent: depreciation_percent,
        opening_balance: opening_balance,
        actual_addition1: actual_addition1,
        actual_addition2: actual_addition2,
        projected_addition: projected_addition,
        is_less_than_6_months: is_less_than_6_months
      )
    end

    def generate_pdf(output_path = "Depreciation_Schedule_Report.pdf")
      Prawn::Document.generate(output_path) do |pdf|
        pdf.font_families.update("Roboto" => {
          normal: "/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/web_app/src/assets/fonts/Roboto-Regular.ttf",
          bold: "/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/web_app/src/assets/fonts/Roboto-Bold.ttf",
        })

        pdf.font "Roboto"

        pdf.text @company_name, size: 16, style: :bold
        pdf.text @location, size: 12
        pdf.move_down 20

        pdf.text "DEPRECIATION SCHEDULE", size: 16, style: :bold
        pdf.move_down 10

        pdf.bounding_box([pdf.bounds.right - 100, pdf.cursor], width: 100) do
          pdf.text "Rs. in Lakhs", size: 12, align: :right
        end
        pdf.move_down 10

        totals = @schedule.generate_totals
        years = (2022..(2022 + @schedule.projection_years + 1)).to_a 

        table_data = []
        header_row1 = ["Particulars"] + ["Actual"] * 2 + ["Projected"] * (@schedule.projection_years)
        header_row2 = ["Period"] + years.map { |year| "#{year}-#{year + 1}" }

        table_data << header_row1
        table_data << header_row2

        @schedule.assets.each do |asset|
          yearly_data = asset[:yearly_data]

          table_data << [asset[:name]]
          table_data << ["Opening Balance"] + yearly_data.map { |data| format_currency(data[:opening_balance]) }
          table_data << ["Less: Deletions"] + ["-"] * @schedule.projection_years
          table_data << ["Add: Additions"] + yearly_data.map { |data| format_currency(data[:addition]) }
          table_data << ["Total"] + yearly_data.map { |data| format_currency(data[:opening_balance] + data[:addition]) }
          table_data << ["Less Depreciation"] + yearly_data.map { |data| format_currency(data[:depreciation]) }
          table_data << ["Closing Balance"] + yearly_data.map { |data| format_currency(data[:closing_balance]) }
        end

        table_data << []
        table_data << ["Total Opening Balance"] + totals[:total_opening].map { |value| format_currency(value) }
        table_data << ["Total Additions"] + totals[:total_addition].map { |value| format_currency(value) }
        table_data << ["Total Depreciation"] + totals[:total_depreciation].map { |value| format_currency(value) }
        table_data << ["Total Closing Balance"] + totals[:total_closing].map { |value| format_currency(value) }
        table_data << ["Total Closing Balance"] + totals[:total_closing].map { |value| format_currency(value) }

        pdf.move_down 10

        pdf.table(table_data, header: true, row_colors: ["F0F0F0", "FFFFFF"], column_widths: [100] + [50] * @schedule.projection_years)
      end
      output_path
    end

    private

    def format_currency(amount)
      "₹ #{'%.2f' % amount}"
    end
  end
end
