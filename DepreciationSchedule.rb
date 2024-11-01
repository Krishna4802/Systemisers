module ProjectReport
  class DepreciationSchedule
    attr_accessor :assets, :projection_years

    def initialize(projection_years: 5)
      @projection_years = projection_years
      @assets = []
    end

    def add_asset(name, depreciation_percent:, opening_balance: 0, addition: 0, is_less_than_6_months: false)
      @assets << {
        name: name,
        depreciation_percent: depreciation_percent, 
        opening_balance: opening_balance,
        addition: addition,
        is_less_than_6_months: is_less_than_6_months,
        yearly_data: generate_depreciation_schedule(opening_balance, addition, depreciation_percent, is_less_than_6_months)
      }
    end

    def generate_depreciation_schedule(opening_balance, addition, depreciation_percent, is_less_than_6_months)
      rate = is_less_than_6_months ? depreciation_percent / 2.0 : depreciation_percent
      schedule = []
      balance = addition.round(2) 

      @projection_years.times do |year|
        current_opening_balance = (year == 0 ? 0 : balance)  
        current_rate = (year == 0 && is_less_than_6_months) ? rate : depreciation_percent
        depreciation = (balance * current_rate / 100).round(2)
        closing_balance = (balance - depreciation).round(2)

        schedule << {
          year: 2024 + year, 
          opening_balance: current_opening_balance,
          addition: (year == 0 ? addition : 0),
          depreciation: depreciation,
          closing_balance: closing_balance
        }

        balance = closing_balance  
      end

      schedule
    end

    def generate_totals
      totals = {
        total_opening: Array.new(@projection_years, 0.0),
        total_addition: Array.new(@projection_years, 0.0),
        total_depreciation: Array.new(@projection_years, 0.0),
        total_closing: Array.new(@projection_years, 0.0)
      }

      @assets.each do |asset|
        asset[:yearly_data].each_with_index do |data, year|
          totals[:total_opening][year] += data[:opening_balance]
          totals[:total_addition][year] += data[:addition]
          totals[:total_depreciation][year] += data[:depreciation]
          totals[:total_closing][year] += data[:closing_balance]
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
# schedule = ProjectReport::DepreciationSchedule.new(projection_years: 6)
# schedule.add_asset("Plant & Machinery", depreciation_percent: 15, opening_balance: 0, addition: 32.00, is_less_than_6_months: true)
# schedule.add_asset("Interiors", depreciation_percent: 10, opening_balance: 0, addition: 1.25, is_less_than_6_months: true)
# result = schedule.display_schedule
# puts result
