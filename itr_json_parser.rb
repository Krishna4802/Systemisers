module GenerateProjectReport
  class ItrJsonParser
    PROFITABILITY_STATEMENT_PATHS = [
      { description: "sales", paths: [["TradingAccount", "TotRevenueFrmOperations"]] },
      { description: "other_income", paths: [["PARTA_PL", "CreditsToPL", "OthIncome", "TotOthIncome"]] },
      { description: "opening_stock", paths: [["ManufacturingAccount", "OpeningInventory", "OpngInvntryTotal"], ["TradingAccount", "OpngStckOfFinishedStcks"]] },
      { description: "purchases_consumables", paths: [["TradingAccount", "Purchases"]] },
      { description: "closing_stock", paths: [["ManufacturingAccount", "ClosingStock", "ClsngStckTotal"], ["TradingAccount", "ClsngStckOfFinishedStcks"]] },
      { description: "direct_expenses", paths: [["ManufacturingAccount", "OpeningInventory", "DirectExpenses"], ["TradingAccount", "DirectExpensesTotal"]] },
      { description: "rates_and_taxes", paths: [["TradingAccount", "DutyTaxPay", "ExciseCustomsVAT", "TotExciseCustomsVAT"]] },
      { description: "salaries_and_wages", paths: [["PARTA_PL", "DebitsToPL", "EmployeeComp", "TotEmployeeComp"]] },
      { description: "operating_expenses", paths: [["PARTA_PL", "DebitsToPL"]], subtract: [["PARTA_PL", "DebitsToPL", "EmployeeComp", "TotEmployeeComp"], ["PARTA_PL", "DebitsToPL", "SalePromoExp"], ["PARTA_PL", "DebitsToPL", "Advertisement"]] },
      { description: "selling_and_distribution_expenses", paths: [["PARTA_PL", "DebitsToPL", "SalePromoExp"], ["PARTA_PL", "DebitsToPL", "Advertisement"]] },
      { description: "depreciation", paths: [["PARTA_PL", "DebitsToPL", "DepreciationAmort"]] },
    ]

    BALANCE_SHEET_PATHS = [
      { description: "closing_capital", paths: [["PARTA_BS", "FundSrc", "PropFund", "PropCap"]] },
      { description: "reserves_and_surplus", paths: [["PARTA_BS", "FundSrc", "PropFund", "ResrNSurp", "RevResr"]] },
      { description: "capital_reserves", paths: [["PARTA_BS", "FundSrc", "PropFund", "ResrNSurp", "CapResr"]] },
      { description: "statutory_reserves", paths: [["PARTA_BS", "FundSrc", "PropFund", "ResrNSurp", "StatResr"]] },
      { description: "other_reserves", paths: [["PARTA_BS", "FundSrc", "PropFund", "ResrNSurp", "OthResr"]] },
      { description: "loans", paths: [["PARTA_BS", "FundSrc", "LoanFunds", "SecrLoan", "ForeignCurrLoan"]] },
      { description: "fixed_assets", paths: [["PARTA_BS", "FundApply", "FixedAsset", "TotFixedAsset"]] },
      { description: "deposits_investments", paths: [["PARTA_BS", "FundApply", "Investments", "TotInvestments"]] },
      { description: "sundry_debtors", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrAsset", "SndryDebtors"]] },
      { description: "closing_stock", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrAsset", "Inventories", "TotInventries"]] },
      { description: "loans_and_advances", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "LoanAdv", "TotLoanAdv"]] },
      { description: "other_current_assets", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrAsset", "OthCurrAsset"]] },
      { description: "cash_and_bank", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrAsset", "CashOrBankBal", "TotCashOrBankBal"]] },
      { description: "sundry_creditors", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrLiabilitiesProv", "CurrLiabilities", "SundryCred"]] },
      { description: "other_payables", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrLiabilitiesProv", "Provisions", "ELSuperAnnGratProvision"], ["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrLiabilitiesProv", "Provisions", "OthProvision"]] },
      { description: "provision_for_income_tax", paths: [["PARTA_BS", "FundApply", "CurrAssetLoanAdv", "CurrLiabilitiesProv", "Provisions", "ITProvision"]] },
      { description: "deferred_tax", paths: [["PARTA_BS", "FundApply", "MiscAdjust", "TotMiscAdjust"], ["PARTA_BS", "FundSrc", "DeferredTax"]], subtract: [["PARTA_BS", "FundSrc", "DeferredTax"]] },
    ]

    def initialize(json_data)
      @json_data = json_data.is_a?(Hash) ? json_data : load_json_data(json_data)
    end

    def parse
      itr_key = @json_data["ITR"]&.keys&.first
      if itr_key
        {
          profitability_statement: process_operations(PROFITABILITY_STATEMENT_PATHS, itr_key),
          balance_sheet: process_operations(BALANCE_SHEET_PATHS, itr_key),
        }
      else
        raise "Error: 'ITR' key or its first-level content not found in the JSON data."
      end
    end

    def validate_file
      itr_key = @json_data["ITR"]&.keys&.first
      raise "Error: 'ITR' key not found in the JSON data." if itr_key.nil?
      missing_paths = validate_paths(PROFITABILITY_STATEMENT_PATHS, itr_key) + validate_paths(BALANCE_SHEET_PATHS, itr_key)
      missing_paths.empty? ? true : false
    end

    private

    def load_json_data(file_path)
      file_content = File.read(file_path)
      JSON.parse(file_content)
    rescue Errno::ENOENT
      raise "Error: File not found at #{file_path}."
    rescue JSON::ParserError
      raise "Error: Invalid JSON format in the file."
    end

    def validate_paths(operations, itr_key)
      missing_paths = []
      operations&.each do |operation|
        operation[:paths]&.each { |path| missing_paths << path unless path_exists?("ITR", itr_key, *path) }
        (operation[:subtract] || [])&.each { |path| missing_paths << path unless path_exists?("ITR", itr_key, *path) }
      end
      missing_paths
    end

    def process_operations(operations, itr_key)
      results = {}

      operations&.each do |operation|
        description = operation[:description]
        paths = operation[:paths]
        subtract = operation[:subtract] || []

        total = 0
        paths&.each { |path| total += extract_value(path, itr_key) }
        subtract&.each { |path| total -= extract_value(path, itr_key) }

        results[description.to_sym] = total
      end
      results
    end

    def extract_value(path, itr_key)
      value = @json_data.dig("ITR", itr_key, *path)

      if value.nil?
        Rails.logger.debug "Warning: Path not available - #{path.inspect}"
        return 0
      end
      if value.is_a?(Hash)
        sum = value.values.select { |v| v.is_a?(Numeric) }.sum
        return sum
      end
      if value.is_a?(Numeric)
        value
      else
        Rails.logger.debug "Warning: Non-numeric value encountered at path - #{path.inspect}. Value: #{value.inspect}"
      end
    end

    def path_exists?(*path)
      !@json_data.dig(*path).nil?
    end
  end
end
