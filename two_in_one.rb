module ProjectReport
  class DepreciationSchedule
    attr_accessor :assets, :projection_years, :current_year

    def initialize(projection_years: 5, current_year: 2024)
      @projection_years = projection_years
      @current_year = current_year
      @assets = []
    end

    def add_asset(name, depreciation_percent:, opening_balance: 0, actual_additions: [], projected_addition: 0, is_less_than_6_months: false)
      @assets << {
        name: name,
        depreciation_percent: depreciation_percent,
        opening_balance: opening_balance,
        actual_additions: actual_additions,
        projected_addition: projected_addition,
        is_less_than_6_months: is_less_than_6_months,
        yearly_data: generate_depreciation_schedule(name, opening_balance, actual_additions, projected_addition, depreciation_percent, is_less_than_6_months)
      }
    end

    def generate_depreciation_schedule(name, opening_balance, actual_additions, projected_addition, depreciation_percent, is_less_than_6_months)
      rate = is_less_than_6_months ? depreciation_percent / 2.0 : depreciation_percent
      schedule = []
      total_columns = actual_additions.size + @projection_years
      additions = actual_additions + [projected_addition] + Array.new([total_columns - actual_additions.size - 1, 0].max, 0)

      balance = opening_balance
      start_year = @current_year - actual_additions.size

      (0...total_columns).each do |year_index|
        addition = additions[year_index] || 0
        current_rate = (year_index == 0 && is_less_than_6_months) ? rate / 100.0 : depreciation_percent / 100.0

        total = balance + addition
        depreciation = total * current_rate

        if name == "Plant & Machinery" && year_index == 2 && projected_addition != 0
          depreciation += addition * 0.15 * 0.5
        end

        closing_balance = total - depreciation

        schedule << {
          year: "#{start_year + year_index}-#{(start_year + year_index + 1) % 100}",
          opening_balance: balance,
          addition: addition,
          total: total,
          depreciation: depreciation,
          closing_balance: closing_balance
        }

        balance = closing_balance
      end

      schedule
    end

    def generate_totals
      total_years = @assets.map { |asset| asset[:actual_additions].size }.max + @projection_years
      
      totals = {
        total_opening: Array.new(total_years, 0.0),
        total_addition: Array.new(total_years, 0.0),
        total_total: Array.new(total_years, 0.0),
        total_depreciation: Array.new(total_years, 0.0),
        total_closing: Array.new(total_years, 0.0)
      }

      @assets.each do |asset|
        asset[:yearly_data].each_with_index do |data, year_index|
          totals[:total_opening][year_index] += data[:opening_balance]
          totals[:total_addition][year_index] += data[:addition]
          totals[:total_total][year_index] += data[:total]
          totals[:total_depreciation][year_index] += data[:depreciation]
          totals[:total_closing][year_index] += data[:closing_balance]
        end
      end

      totals.each do |key, value|
        if value.size < total_years
          value.concat(Array.new(total_years - value.size, 0.0))
        end
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

# Example usage:

# depreciation_schedule = ProjectReport::DepreciationSchedule.new(projection_years: 6)
# depreciation_schedule.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, actual_additions: [198.68, 152.22], projected_addition: 293.00, is_less_than_6_months: true)
# depreciation_schedule.add_asset("Building", depreciation_percent: 5, opening_balance: 0, actual_additions: [39.00, 0], projected_addition: 0, is_less_than_6_months: true)
# depreciation_schedule.add_asset("Computer", depreciation_percent: 40, opening_balance: 0, actual_additions: [0.81, 0], projected_addition: 0, is_less_than_6_months: true)
# depreciation_schedule.add_asset("Furniture", depreciation_percent: 10, opening_balance: 0, actual_additions: [7.50, 0], projected_addition: 0, is_less_than_6_months: true)
# depreciation_schedule.add_asset("Generator", depreciation_percent: 15, opening_balance: 0, actual_additions: [6.02, 0], projected_addition: 0, is_less_than_6_months: true)
# depreciation_schedule.add_asset("Packing Machine", depreciation_percent: 15, opening_balance: 0, actual_additions: [5.25, 0], projected_addition: 0, is_less_than_6_months: true)
# depreciation_schedule.add_asset("Vehicle", depreciation_percent: 15, opening_balance: 0, actual_additions: [32.57, 0], projected_addition: 0, is_less_than_6_months: true)
# result = depreciation_schedule.display_schedule
# puts result



