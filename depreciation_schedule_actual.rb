module ProjectReport
  class DepreciationScheduleActual
    attr_accessor :assets, :projection_years

    def initialize(projection_years: 6)
      @projection_years = projection_years
      @assets = []
    end

    def add_asset(name, depreciation_percent:, opening_balance: 0, actual_addition1: 0, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: false)
      @assets << {
        name: name,
        depreciation_percent: depreciation_percent.round(2),
        opening_balance: opening_balance.round(2),
        actual_addition1: actual_addition1.round(2),
        actual_addition2: actual_addition2.round(2),
        projected_addition: projected_addition.round(2),
        is_less_than_6_months: is_less_than_6_months,
        yearly_data: generate_depreciation_schedule(name, opening_balance, actual_addition1, actual_addition2, projected_addition, depreciation_percent, is_less_than_6_months)
      }
    end

    def generate_depreciation_schedule(name, opening_balance, actual_addition1, actual_addition2, projected_addition, depreciation_percent, is_less_than_6_months)
      rate = is_less_than_6_months ? depreciation_percent / 2.0 : depreciation_percent
      schedule = []
      additions = [actual_addition1, actual_addition2] + [projected_addition] + Array.new(@projection_years - 3, 0)

      balance = opening_balance.round(2)

      (0...@projection_years + 2).each do |year|
        addition = additions[year] || 0
        current_rate = (year == 0 && is_less_than_6_months) ? rate / 100.0 : depreciation_percent / 100.0

        total = (balance + addition).round(2)

        if name == "Plant & Machinery" && year == 2 && projected_addition != 0
          depreciation = ((total * current_rate) + (addition * 0.15 * 0.5)).round(2)
        else
          depreciation = (total * current_rate).round(2)
        end

        closing_balance = (total - depreciation).round(2)

        schedule << {
          year: 2022 + year,
          opening_balance: balance.round(2),
          addition: addition.round(2),
          total: total,
          depreciation: depreciation,
          closing_balance: closing_balance
        }

        balance = closing_balance
      end

      schedule
    end

    def generate_totals
      total_years = @projection_years + 2
      totals = {
        total_opening: Array.new(total_years, 0.0),
        total_addition: Array.new(total_years, 0.0),
        total_total: Array.new(total_years, 0.0),
        total_depreciation: Array.new(total_years, 0.0),
        total_closing: Array.new(total_years, 0.0)
      }

      @assets.each do |asset|
        asset[:yearly_data].each_with_index do |data, year|
          totals[:total_opening][year] += data[:opening_balance].round(2)
          totals[:total_addition][year] += data[:addition].round(2)
          totals[:total_total][year] += data[:total].round(2)
          totals[:total_depreciation][year] += data[:depreciation].round(2)
          totals[:total_closing][year] += data[:closing_balance].round(2)
        end
      end

      totals.each do |key, value|
        totals[key] = value.map { |v| v.round(2) }
      end

      totals
    end

    def display_schedule
      asset_details = []

      @assets.each do |asset|
        asset_details << {
          name: asset[:name],
          depreciation_percent: asset[:depreciation_percent],
          yearly_data: asset[:yearly_data]
        }
      end

      totals = generate_totals

      {
        assets: asset_details,
        totals: totals
      }
    end
  end
end




# Example usage

# pdf_generator = ProjectReport::DepreciationScheduleActual.new(projection_years: 6)
# pdf_generator.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_addition1: 198.68, actual_addition2: 152.22, projected_addition: 293.00, is_less_than_6_months: true)
# pdf_generator.add_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_addition1: 39.00, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: true)
# pdf_generator.add_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_addition1: 0.81, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: true)
# pdf_generator.add_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_addition1: 7.50, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: true)
# pdf_generator.add_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_addition1: 6.02, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: true)
# pdf_generator.add_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_addition1: 5.25, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: true)
# pdf_generator.add_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_addition1: 32.57, actual_addition2: 0, projected_addition: 0, is_less_than_6_months: true)

# result = pdf_generator.display_schedule
# puts result
