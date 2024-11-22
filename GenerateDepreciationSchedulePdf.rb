require 'prawn'
require 'prawn/table'
require_relative 'DepreciationSchedule'

module ProjectReport
  class GenerateDepreciationSchedulePdf
    def initialize(company_name:, location:, projection_years: 5)
      @company_name = company_name
      @location = location
      @schedule = DepreciationSchedule.new(projection_years: projection_years)
    end

    def add_asset(name, depreciation_percent:, opening_balance: 0, addition: 0, is_less_than_6_months: false)
      @schedule.add_asset(name, depreciation_percent: depreciation_percent, opening_balance: opening_balance, addition: addition, is_less_than_6_months: is_less_than_6_months)
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

        pdf.bounding_box([pdf.bounds.right - 200, pdf.cursor], width: 100) do
          pdf.text "Rs. in Lakhs", size: 12, align: :right
        end
        pdf.move_down 10

        totals = @schedule.generate_totals
        years = (2024..(2024 + @schedule.projection_years - 1)).to_a

        puts "Total Opening: #{totals[:total_opening]}"
        puts "Total Additions: #{totals[:total_addition]}"
        puts "Total Depreciation: #{totals[:total_depreciation]}"
        puts "Total Closing: #{totals[:total_closing]}"

        table_data = []
        headers = ["Projected Period"] + years.map { |year| "#{year}-#{year + 1}" }
        table_data << headers

        @schedule.assets.each do |asset|
          yearly_data = asset[:yearly_data]

          table_data << [asset[:name]]
          table_data << ["Opening bal"] + yearly_data.map { |data| format_currency(data[:opening_balance]) }
          table_data << ["Less: Deletions"] + ["-"] * @schedule.projection_years
          table_data << ["Add: Additions"] + yearly_data.map { |data| format_currency(data[:addition]) }
          table_data << ["Total"] + yearly_data.map { |data| format_currency(data[:opening_balance] + data[:addition]) }
          table_data << ["Less Depreciation"] + yearly_data.map { |data| format_currency(data[:depreciation]) }
          table_data << ["Closing Balance"] + yearly_data.map { |data| format_currency(data[:closing_balance]) }
        end
        table_data << [] 
        table_data << ["Total Opening balance"] + totals[:total_opening].map { |value| format_currency(value) }
        table_data << ["Total Additions"] + totals[:total_addition].map { |value| format_currency(value) }
        table_data << ["Total Depreciation"] + totals[:total_depreciation].map { |value| format_currency(value) }
        table_data << ["Total Closing balance"] + totals[:total_closing].map { |value| format_currency(value) }
        table_data << ["Test"] 

        puts "Table Data Structure: #{table_data.inspect}"

        pdf.move_down 10
        pdf.table(table_data, header: true, row_colors: ["F0F0F0", "FFFFFF"], column_widths: [150] + [50] * @schedule.projection_years)
      end
      output_path
    end

    private

    def format_currency(amount)
      "₹ #{'%.2f' % amount}"
    end
  end
end
