require 'date'
require_relative '../../../app/lib/project_report_lib/depreciation_schedule'

RSpec.describe ProjectReportLib::DepreciationSchedule, type: :model do
  let(:projection_years) { 6 }
  subject { described_class.new(projection_years) }

  describe '#initialize' do
    it 'initializes with projection years and current year' do
      expect(subject.projection_years).to eq(6)
      expect(subject.current_year).to eq(2024)
    end
  end

  describe '#add_asset' do
    it 'adds an asset with the correct attributes' do
      subject.add_asset("Plant & Machinery", 15, 0, [500], 300, true)
      asset = subject.assets.first

      expect(asset[:name]).to eq("Plant & Machinery")
      expect(asset[:depreciation_percent]).to eq(15)
      expect(asset[:opening_balance]).to eq(0)
      expect(asset[:actual_additions]).to eq([500])
      expect(asset[:projected_addition]).to eq(300)
      expect(asset[:is_less_than_6_months]).to be(true)
      expect(asset[:yearly_data]).not_to be_empty
    end
  end

  describe '#generate_depreciation_schedule' do
    it 'generates a correct depreciation schedule for an asset' do
      schedule = subject.generate_depreciation_schedule("Plant & Machinery", 1000, [100, 200], 300, 15, true)
      expect(schedule).to be_an(Array)
      expect(schedule.size).to eq(8)

      first_year = schedule.first
      expect(first_year[:year]).to eq("2022-23")
      expect(first_year[:opening_balance]).to be_within(0.01).of(0)
      expect(first_year[:addition]).to be_within(5).of(100)
      expect(first_year[:depreciation]).to be_within(0.01).of(7.5)
    end
  end

  describe '#generate_totals' do
    before do
      subject.add_asset("Plant & Machinery", 15, 0, [50, 100, 200], 300, true)
      subject.add_asset("Building", 5, 0, [50], 150, true)
    end

    it 'calculates yearly totals correctly across all assets' do
      totals = subject.generate_totals

      expect(totals[:total_opening]).to be_an(Array)
      expect(totals[:total_opening].size).to eq(9)
      expect(totals[:total_addition].size).to eq(9)
      expect(totals[:total_balance].size).to eq(9)
      expect(totals[:total_depreciation].size).to eq(9)
      expect(totals[:total_closing].size).to eq(9)

      expect(totals[:total_opening][0]).to be_within(0.01).of(0)
    end
  end

  describe '#generate_totals' do
    before do
      subject.add_asset("Plant & Machinery", 15, 0, [], 300, true)
      subject.add_asset("Building", 5, 0, [], 150, true)
    end

    it 'calculates yearly totals correctly across all assets for no actual_additons' do
      totals = subject.generate_totals

      expect(totals[:total_opening]).to be_an(Array)
      expect(totals[:total_opening].size).to eq(projection_years)
      expect(totals[:total_addition].size).to eq(projection_years)
      expect(totals[:total_balance].size).to eq(projection_years)
      expect(totals[:total_depreciation].size).to eq(projection_years)
      expect(totals[:total_closing].size).to eq(projection_years)

      expect(totals[:total_opening][0]).to be_within(0.01).of(0)
    end
  end

  describe '#yearly_summary' do
    before do
      subject.add_asset("Plant & Machinery", 15, 0, [], 300, true)
      subject.add_asset("Building", 5, 0, [], 150, true)
    end
    it 'returns a summary with yearly closing balances for each asset' do
      summary = subject.yearly_summary

      expect(summary.size).to eq(2)

      plant_machinery = summary.find { |asset| asset[:name] == "Plant & Machinery" }
      buildings = summary.find { |asset| asset[:name] == "Building" }

      expect(plant_machinery[:yearly_data]).to be_an(Array)
      expect(plant_machinery[:yearly_data].first[:year]).to eq("2024-25")
      expect(plant_machinery[:yearly_data].first[:closing_balance]).to be_a(Float)
      expect(buildings[:yearly_data].first[:closing_balance]).to be_a(Float)
    end
  end

  describe '#display_schedule' do
    before do
      subject.add_asset("Plant & Machinery", 15, 0, [], 32.00, true)
      subject.add_asset("Interiors", 15, 0, [], 1.25, true)
    end
    it 'returns the correct yearly data for each asset' do
      result = subject.display_schedule

      expect(result[:assets].size).to eq(2)

      plant_data = result[:assets].find { |asset| asset[:name] == "Plant & Machinery" }[:yearly_data]
      expect(plant_data[0][:opening_balance]).to eq(0)
      expect(plant_data[0][:addition]).to eq(32.0)
      expect(plant_data[0][:depreciation]).to eq(2.4)
      expect(plant_data[0][:closing_balance]).to eq(29.6)
      expect(plant_data[1][:closing_balance]).to eq(25.16)
      expect(plant_data[5][:closing_balance]).to eq(13.13367725)

      interiors_data = result[:assets].find { |asset| asset[:name] == "Interiors" }[:yearly_data]
      expect(interiors_data[0][:opening_balance]).to eq(0)
      expect(interiors_data[0][:addition]).to eq(1.25)
      expect(interiors_data[0][:depreciation]).to eq(0.09375)
      expect(interiors_data[0][:closing_balance]).to eq(1.15625)
      expect(interiors_data[1][:closing_balance]).to eq(0.9828125)
      expect(interiors_data[5][:closing_balance]).to eq(0.513034267578125)
    end

    it 'returns correct totals across all assets' do
      result = subject.display_schedule
      totals = result[:totals]

      expect(totals[:total_opening]).to eq([0.0, 30.75625, 26.1428125, 22.221390624999998, 18.88818203125, 16.0549547265625])
      expect(totals[:total_addition]).to eq([33.25, 0.0, 0.0, 0.0, 0.0, 0.0])
      expect(totals[:total_balance]).to eq([33.25, 30.75625, 26.1428125, 22.221390624999998, 18.88818203125, 16.0549547265625])
      expect(totals[:total_depreciation]).to eq([2.49375, 4.613437500000001, 3.921421875, 3.33320859375, 2.8332273046875, 2.408243208984375])
      expect(totals[:total_closing]).to eq([30.75625, 26.1428125, 22.221390624999998, 18.88818203125, 16.0549547265625, 13.646711517578124])
    end
  end

  describe 'Yearly balance continuity' do
    it 'ensures each year\'s closing balance matches the following year\'s opening balance' do
      subject.assets.each do |asset|
        yearly_data = asset[:yearly_data]

        yearly_data.each_cons(2) do |prev_year, next_year|
          expect(prev_year[:closing_balance]).to eq(next_year[:opening_balance]),
                                                 "Failed for asset #{asset[:name]} between years #{prev_year[:year]} and #{next_year[:year]}"
        end
      end
    end
  end

  describe 'Yearly balance continuity' do
    it 'ensures each years closing balance matches the following years opening balance' do
      subject.assets.each do |asset|
        yearly_data = asset[:yearly_data]

        yearly_data.each_cons(2) do |prev_year, next_year|
          expect(prev_year[:closing_balance]).to eq(next_year[:opening_balance])
        end
      end
    end
  end

  describe '#add_asset' do
    it 'adds multiple assets correctly' do
      subject.add_asset("Plant & Machinery", 15, 0, [500], 300, true)
      subject.add_asset("Building", 5, 0, [50], 150, true)

      expect(subject.assets.size).to eq(2)

      plant_asset = subject.assets.find { |a| a[:name] == "Plant & Machinery" }
      expect(plant_asset).not_to be_nil
      expect(plant_asset[:yearly_data]).not_to be_empty

      building_asset = subject.assets.find { |a| a[:name] == "Building" }
      expect(building_asset).not_to be_nil
      expect(building_asset[:yearly_data]).not_to be_empty
    end
  end
end
