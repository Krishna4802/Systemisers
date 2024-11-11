module ProjectReportLib
  class DepreciationSchedule
    attr_accessor :assets, :projection_years, :current_year

    def initialize(projection_years, current_year = Time.new.year)
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
      additions = actual_additions + [projected_addition] + Array.new([total_years - actual_additions.size - 1, 0].max, 0)
      start_year = @current_year - actual_additions.size

      previous_year = nil

      Array.new(total_years) do |year_index|
        opening_balance = year_index.zero? ? 0 : previous_year[:closing_balance]
        addition = additions[year_index] || 0
        applicable_rate = year_index.zero? && is_less_than_6_months ? initial_rate : depreciation_percent / 100.0
        total = opening_balance + addition
        depreciation = total * applicable_rate
        depreciation += addition * 0.15 * 0.5 if name == "Plant & Machinery" && year_index == 2 && projected_addition != 0
        closing_balance = total - depreciation

        previous_year = { year: "#{start_year + year_index}-#{(start_year + year_index + 1) % 100}", opening_balance: opening_balance, addition: addition, total: total, depreciation: depreciation, closing_balance: closing_balance }
      end
    end

    def generate_totals
      total_years = @assets.map { |asset| asset[:actual_additions].size }.max + @projection_years
      totals = Hash.new { |hash, key| hash[key] = Array.new(total_years, 0.0) }

      @assets&.each do |asset|
        asset[:yearly_data]&.each_with_index do |data, year_index|
          totals[:total_opening][year_index] += data[:opening_balance]
          totals[:total_addition][year_index] += data[:addition]
          totals[:total_balance][year_index] += data[:total]
          totals[:total_depreciation][year_index] += data[:depreciation]
          totals[:total_closing][year_index] += data[:closing_balance]
        end
      end
      totals
    end

    def yearly_summary
      @assets&.map do |asset|
        {
          name: asset[:name],
          yearly_data: asset[:yearly_data]&.map { |data| { year: data[:year], closing_balance: data[:closing_balance] } }
        }
      end
    end

    def display_schedule
      asset_details = @assets&.map { |asset| { name: asset[:name], depreciation_percent: asset[:depreciation_percent], yearly_data: asset[:yearly_data] } }
      { assets: asset_details, totals: generate_totals }
    end
  end
end
