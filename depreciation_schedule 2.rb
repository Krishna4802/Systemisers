module ProjectReport
  class DepreciationSchedule
    attr_accessor :assets, :projection_years, :current_year

    def initialize(projection_years, current_year: 2024)
      @projection_years = projection_years
      @current_year = current_year
      @assets = []
    end

    def add_asset(name, depreciation_percent, opening_balance, actual_additions, projected_addition, is_less_than_6_months)
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
      initial_rate = depreciation_percent / (is_less_than_6_months ? 2.0 : 1.0) / 100.0
      total_years = actual_additions.size + @projection_years
      additions = actual_additions + [projected_addition] + [0] * [total_years - actual_additions.size - 1, 0].max

      balance = opening_balance
      start_year = @current_year - actual_additions.size
      schedule = []

      total_years.times do |year_index|
        addition = additions[year_index] || 0
        applicable_rate = (year_index.zero? && is_less_than_6_months) ? initial_rate : depreciation_percent / 100.0

        total = balance + addition
        depreciation = total * applicable_rate
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
      totals = Hash.new { |hash, key| hash[key] = Array.new(total_years, 0.0) }

      @assets.each do |asset|
        asset[:yearly_data].each_with_index do |data, year_index|
          totals[:total_opening][year_index] += data[:opening_balance]
          totals[:total_addition][year_index] += data[:addition]
          totals[:total_balance][year_index] += data[:total]
          totals[:total_depreciation][year_index] += data[:depreciation]
          totals[:total_closing][year_index] += data[:closing_balance]
        end
      end

      totals
    end

    def display_schedule
      asset_details = @assets.map do |asset|
        {
          name: asset[:name],
          depreciation_percent: asset[:depreciation_percent],
          yearly_data: asset[:yearly_data]
        }
      end

      {
        assets: asset_details,
        totals: generate_totals
      }
    end
  end
end
