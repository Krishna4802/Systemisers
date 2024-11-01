module ProjectReport
    class DepreciationSchedule
      attr_accessor :assets, :depreciation_percent, :projection_years
  
      def initialize(depreciation_percent: 15, projection_years: 5)
        @depreciation_percent = depreciation_percent
        @projection_years = projection_years
        @assets = []
      end
  
      def add_asset(name, opening_balance: 0, addition: 0, is_less_than_6_months: false)
        @assets << {
          name: name,
          opening_balance: opening_balance,
          addition: addition,
          is_less_than_6_months: is_less_than_6_months,
          yearly_data: generate_depreciation_schedule(opening_balance, addition, is_less_than_6_months)
        }
      end
  
      def generate_depreciation_schedule(opening_balance, addition, is_less_than_6_months)
        rate = is_less_than_6_months ? @depreciation_percent / 2.0 : @depreciation_percent
        schedule = []
        balance = (opening_balance + addition).round(2)
  
        @projection_years.times do |year|
          # Apply half rate only for the first year if is_less_than_6_months is true
          current_rate = (year == 0 && is_less_than_6_months) ? rate : @depreciation_percent
          depreciation = (balance * current_rate / 100).round(2)
          closing_balance = (balance - depreciation).round(2)
  
          schedule << {
            opening_balance: balance,
            addition: (year == 0 ? addition : 0),
            depreciation: depreciation,
            closing_balance: closing_balance
          }
          
          balance = closing_balance
        end
  
        schedule
      end
  
      def display_schedule
        puts "PERIOD\t\t2024-25\t2025-26\t2026-27\t2027-28\t2028-29\t2029-30"
        puts "------------------------------------------------------"
        
        total_opening = Array.new(@projection_years, 0.0)
        total_addition = Array.new(@projection_years, 0.0)
        total_depreciation = Array.new(@projection_years, 0.0)
        total_closing = Array.new(@projection_years, 0.0)
  
        @assets.each do |asset|
          puts "\n#{asset[:name]}"
          print "Opening bal\t"
          asset[:yearly_data].each_with_index do |data, year|
            print "#{data[:opening_balance].round(2).to_s.ljust(8)}\t"
            total_opening[year] += data[:opening_balance].round(2)
          end
          puts
  
          print "Less: Deletions\t\t"
          asset[:yearly_data].each { |_| print "-\t" }
          puts
  
          print "Add: Additions\t\t"
          asset[:yearly_data].each_with_index do |data, year|
            print "#{data[:addition].round(2).to_s.ljust(8)}\t"
            total_addition[year] += data[:addition].round(2)
          end
          puts
  
          print "Total\t\t\t"
          asset[:yearly_data].each_with_index do |data, year|
            total = (data[:opening_balance] + data[:addition]).round(2)
            print "#{total.to_s.ljust(8)}\t"
          end
          puts
  
          print "Less Depreciation\t"
          asset[:yearly_data].each_with_index do |data, year|
            print "#{data[:depreciation].round(2).to_s.ljust(8)}\t"
            total_depreciation[year] += data[:depreciation].round(2)
          end
          puts
  
          print "Closing Balance\t\t"
          asset[:yearly_data].each_with_index do |data, year|
            print "#{data[:closing_balance].round(2).to_s.ljust(8)}\t"
            total_closing[year] += data[:closing_balance].round(2)
          end
          puts
        end
  
        # Print totals
        puts "\nTotal Opening balance\t"
        total_opening.each { |total| print "#{total.round(2).to_s.ljust(8)}\t" }
        puts
  
        puts "Total Additions\t\t"
        total_addition.each { |total| print "#{total.round(2).to_s.ljust(8)}\t" }
        puts
  
        puts "Total Depreciation\t"
        total_depreciation.each { |total| print "#{total.round(2).to_s.ljust(8)}\t" }
        puts
  
        puts "Total Closing balance\t"
        total_closing.each { |total| print "#{total.round(2).to_s.ljust(8)}\t" }
        puts
      end
    end
  end
  
  # Example usage:
  schedule = ProjectReport::DepreciationSchedule.new(depreciation_percent: 15, projection_years: 6)
  schedule.add_asset("Plant & Machinery", opening_balance: 0, addition: 32.00, is_less_than_6_months: true)
  schedule.add_asset("Interiors", opening_balance: 0, addition: 1.25, is_less_than_6_months: true)
  schedule.display_schedule
  