module ProjectReport
  class LoanAmortization
    attr_reader :loan_amount, :annual_interest_rate, :loan_years, :monthly_payment

    DEFAULT_MORATORIUM_MONTH = 5
    MORATORIUM_TYPES = {
      "interest_capitalization" => :interest_capitalization,
      "only_interest" => :only_interest
    }.freeze
    DEFAULT_FINANCIAL_YEAR_MONTH = 3 # March

    def initialize(loan_amount, annual_interest_rate, loan_years, moratorium_type = "", moratorium_month = DEFAULT_MORATORIUM_MONTH, start_date = Time.zone.today)
      @loan_amount = loan_amount
      @annual_interest_rate = annual_interest_rate
      @loan_years = loan_years
      @payments_per_year = 12 # Total months per year
      @total_periods = loan_years * @payments_per_year
      @monthly_payment = calculate_monthly_payment
      # Generate the amortization schedule globally within initialize
      @loan_schedule = generate_amortization_schedule(moratorium_type, moratorium_month, start_date)
    end

    def get_loan_schedule
      @loan_schedule
    end

    def yearly_amortization_summary
      periods = generate_periods(
        @loan_schedule[:period_data][:start_month],
        @loan_schedule[:period_data][:start_year],
        @loan_schedule[:period_data][:end_month],
        @loan_schedule[:period_data][:end_year],
        DEFAULT_FINANCIAL_YEAR_MONTH
      )

      periods&.map { |period| calculate_period_totals(period) }
    end

    def loan_summary
      total_payments_amount = @monthly_payment * @total_periods
      total_interest_paid = total_payments_amount - @loan_amount

      {
        monthly_payment: @monthly_payment,
        total_interest_paid: total_interest_paid,
        total_payments_amount: total_payments_amount
      }
    end

    private

    def generate_amortization_schedule(moratorium_type, moratorium_month, start_date)
      balance = @loan_amount
      total_interest_paid = 0.0
      schedule = []
      current_date = start_date
      moratorium_month = 0 if moratorium_type.empty?

      period = 1 # Initialize period counter

      while balance > 0
        interest, principal = calculate_payment_components(balance, period, moratorium_type, moratorium_month)
        total_interest_paid += interest

        principal = [ principal, balance ].min

        balance -= principal

        schedule << build_schedule_entry(
          period,
          interest,
          principal,
          total_interest_paid,
          balance,
          format_date(current_date)
        )

        current_date = current_date.next_month
        period += 1
        @total_periods += period
      end

      build_schedule_summary(schedule, start_date, current_date)
    end

    def format_date(date)
      date.strftime("%B %Y")
    end

    def build_schedule_summary(schedule, start_date, current_date)
      @loan_schedule = {
        schedule: schedule,
        period_data: {
          start_month: start_date.month,
          start_year: start_date.year,
          end_month: current_date.month,
          end_year: current_date.year
        }
      }
    end

    def build_schedule_entry(period, interest, principal, total_interest_paid, balance, date)
      {
        period: period,
        payment_date: date,
        payment: format_currency(@monthly_payment),
        principal: format_currency(principal),
        interest: format_currency(interest),
        total_interest_paid: format_currency(total_interest_paid),
        new_payoff_amount: format_currency(balance)
      }
    end

    def calculate_monthly_payment
      # Monthly payment calculation based on the amortization formula:
      # M = P * [ i * (1 + i)^n ] / [ (1 + i)^n - 1 ]
      # Where:
      # M = monthly payment
      # P = loan amount (principal)
      # i = monthly interest rate (annual interest rate / 12)
      # n = total number of payments (loan term in years * 12)
      return @loan_amount / total_periods if monthly_interest_rate.zero?

      numerator = @loan_amount * (monthly_interest_rate * (1 + monthly_interest_rate)**total_periods)
      denominator = (1 + monthly_interest_rate)**total_periods - 1

      (numerator / denominator)
    end

    def monthly_interest_rate
      (@annual_interest_rate / 100.0) / @payments_per_year
    end

    def total_periods
      @loan_years * @payments_per_year
    end

    def calculate_payment_components(balance, period, moratorium_type, moratorium_month)
      return calculate_regular_payment(balance) unless period <= moratorium_month

      case map_moratorium_type(moratorium_type)
      when :only_interest
        calculate_only_interest_payment(balance)
      when :interest_capitalization
        calculate_interest_capitalization_payment(balance)
      else
        calculate_regular_payment(balance)
      end
    end

    def calculate_period_totals(period)
      period_total_interest = 0.0
      period_total_principal = 0.0
      last_balance = 0.0

      # Access schedule from global variable @loan_schedule
      @loan_schedule[:schedule]&.each do |payment_entry|
        payment_month = Date.strptime(payment_entry[:payment_date], "%B %Y")
        if payment_in_period?(payment_month, period)
          period_total_interest += payment_entry[:interest]&.gsub(",", "")&.to_f
          period_total_principal += payment_entry[:principal]&.gsub(",", "")&.to_f
          last_balance = payment_entry[:new_payoff_amount]&.gsub(",", "")&.to_f
        end
      end
      build_period_total(period, period_total_principal, period_total_interest, last_balance)
    end

    def payment_in_period?(payment_month, period)
      (payment_month.year > period[:start_year] || (payment_month.year == period[:start_year] && payment_month.month >= period[:start_month])) &&
      (payment_month.year < period[:end_year] || (payment_month.year == period[:end_year] && payment_month.month <= period[:end_month]))
    end

    def build_period_total(period, principal, interest, balance)
      {
        name: period[:name],
        total_principal: principal&.to_f,
        total_interest: interest&.to_f,
        remaining_balance: balance&.to_f
      }
    end

    def generate_periods(start_month, start_year, end_month, end_year, default_mapping_month)
      periods = []
      validate_month_range(start_month, end_month, default_mapping_month)

      # Part 1: Start from current month to next year's default mapping month
      period_name = "#{Date::MONTHNAMES[start_month]} #{start_year} - #{Date::MONTHNAMES[default_mapping_month]} #{start_year + 1}"
      periods << build_period_entry(period_name, start_month, start_year, default_mapping_month, start_year + 1)

      # Part 2: Loop from the next year's default mapping month to the default mapping month of each following year
      current_year = start_year + 1
      while current_year < end_year
        period_name = "#{Date::MONTHNAMES[default_mapping_month]} #{current_year} - #{Date::MONTHNAMES[default_mapping_month]} #{current_year + 1}"
        periods << build_period_entry(period_name, default_mapping_month, current_year, default_mapping_month, current_year + 1)
        current_year += 1
      end

      # Part 3: From the final full year’s default mapping month to the ending month
      period_name = "#{Date::MONTHNAMES[default_mapping_month]} #{end_year} - #{Date::MONTHNAMES[end_month]} #{end_year}"
      periods << build_period_entry(period_name, default_mapping_month, end_year, end_month, end_year)

      periods
    end

    def build_period_entry(name, start_month, start_year, end_month, end_year)
      {
        name: name,
        start_month: start_month,
        start_year: start_year,
        end_month: end_month,
        end_year: end_year
      }
    end

    def validate_month_range(start_month, end_month, default_mapping_month)
      unless (1..12).include?(start_month) && (1..12).include?(end_month) && (1..12).include?(default_mapping_month)
        raise ArgumentError, "Month must be between 1 and 12"
      end
    end

    def calculate_only_interest_payment(balance)
      interest = balance * monthly_interest_rate
      [ interest, 0 ] # Only interest paid, no principal
    end

    def calculate_interest_capitalization_payment(balance)
      interest = balance * monthly_interest_rate
      principal = @monthly_payment - interest # Normal principal payment
      [ interest, principal ]
    end

    def calculate_regular_payment(balance)
      interest = balance * monthly_interest_rate
      principal = @monthly_payment - interest
      [ interest, principal ]
    end

    def map_moratorium_type(type)
      MORATORIUM_TYPES[type.downcase] || nil
    end

    def format_currency(amount)
      sprintf("%.2f", amount).gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
    end
  end
end
