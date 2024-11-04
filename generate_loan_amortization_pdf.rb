require "prawn"
require "prawn/table"
require_relative "loan_amortization"

module ProjectReport
  class GenerateLoanAmortizationPdf
    def initialize(loan_amount, annual_interest_rate, loan_years)
      @loan_amortization = LoanAmortization.new(loan_amount, annual_interest_rate, loan_years)
    end

    def generate_pdf(output_path = "Loan_Amortization_Report.pdf")
      Prawn::Document.generate(output_path) do |pdf|
        pdf.font_families.update("Roboto" => {
          normal: "/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/web_app/src/assets/fonts/Roboto-Regular.ttf",
          bold: "/Users/krishnaprasath/Systemisers/Git_clone/systemisers_app/web_app/src/assets/fonts/Roboto-Bold.ttf"
        })

        pdf.font "Roboto"

        loan_summary = @loan_amortization.loan_summary

        pdf.move_down 20
        pdf.text "Loan Summary", size: 16, style: :bold
        pdf.move_down 10
        pdf.table([
          ["Monthly Payment", format_currency(loan_summary[:monthly_payment])],
          ["Total Interest Paid", format_currency(loan_summary[:total_interest_paid])],
          ["Total Payments Amount", format_currency(loan_summary[:total_payments_amount])],
        ], header: true, column_widths: [200, 250])

        pdf.move_down 20
        pdf.text "Amortization Schedule", size: 16, style: :bold
        amortization_schedule = @loan_amortization.generate_amortization_schedule

        pdf.move_down 10
        pdf.table(
          [["Period", "Payment", "Principal", "Interest", "Total Interest Paid", "New Payoff Amount"]] +
          amortization_schedule.map do |entry|
            [
              entry[:period],
              format_currency(entry[:payment]),
              format_currency(entry[:principal]),
              format_currency(entry[:interest]),
              format_currency(entry[:total_interest_paid]),
              format_currency(entry[:new_payoff_amount]),
            ]
          end,
          header: true
        )
      end
      output_path
    end

    private

    def format_currency(amount)
      "₹ #{amount}"
    end
  end
end
