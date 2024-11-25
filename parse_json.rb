require 'json'
require 'aws-sdk-s3'
require 'yaml'
require 'optparse'

def load_aws_credentials(config_file)
  config = YAML.load_file(config_file)
  {
    access_key_id: config['aws_access_key_id'],
    secret_access_key: config['aws_secret_access_key'],
    region: config['region'],
    bucket_name: config['bucket_name']
  }
end

def fetch_s3_data(bucket_name, object_key, aws_credentials)
  s3 = Aws::S3::Client.new(
    region: aws_credentials[:region],
    access_key_id: aws_credentials[:access_key_id],
    secret_access_key: aws_credentials[:secret_access_key]
  )
  
  begin
    response = s3.get_object(bucket: bucket_name, key: object_key)
    file_content = response.body.read
    JSON.parse(file_content)
  rescue Aws::S3::Errors::ServiceError => e
    puts "Error fetching file from S3: #{e.message}"
    exit
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby script.rb [options]"

  opts.on("-f", "--file FILE", "JSON file name") do |v|
    options[:file] = v
  end

  opts.on("-c", "--config CONFIG", "AWS credentials config file") do |v|
    options[:config] = v
  end
end.parse!

unless options[:file] && options[:config]
  puts "Both JSON file name and AWS config file must be provided."
  exit
end

aws_credentials = load_aws_credentials(options[:config])
bucket_name = aws_credentials[:bucket_name] 

object_key = options[:file] 

json_data = fetch_s3_data(bucket_name, object_key, aws_credentials)

itr_key = json_data['ITR']&.keys&.first

if itr_key

  operations = [
    { description: 'sales', paths: [['TradingAccount', 'TotRevenueFrmOperations']]},
    { description: 'other_income', paths: [['PARTA_PL', 'CreditsToPL', 'OthIncome', 'TotOthIncome']]},
    { description: 'opening_stock', paths: [['ManufacturingAccount', 'OpeningInventory', 'OpngInvntryTotal'], ['TradingAccount', 'OpngStckOfFinishedStcks']]},
    { description: 'purchases_consumables', paths: [['TradingAccount', 'Purchases']]},
    { description: 'closing_stock', paths: [['ManufacturingAccount', 'ClosingStock', 'ClsngStckTotal'], ['TradingAccount', 'ClsngStckOfFinishedStcks']]},
    { description: 'direct_expenses', paths: [['ManufacturingAccount', 'OpeningInventory', 'DirectExpenses'], ['TradingAccount', 'DirectExpensesTotal']]},
    { description: 'rates_and_taxes', paths: [['TradingAccount', 'DutyTaxPay', 'ExciseCustomsVAT', 'TotExciseCustomsVAT']]},
    { description: 'salaries_and_wages', paths: [['PARTA_PL', 'DebitsToPL', 'EmployeeComp', 'TotEmployeeComp']]},
    { description: 'operating_expenses', paths: [['PARTA_PL', 'DebitsToPL'],['PARTA_PL', 'DebitsToPL', 'EmployeeComp', 'TotEmployeeComp'],['PARTA_PL', 'DebitsToPL', 'SalePromoExp'],['PARTA_PL', 'DebitsToPL', 'Advertisement']],subtract: [['PARTA_PL', 'DebitsToPL', 'EmployeeComp', 'TotEmployeeComp'],['PARTA_PL', 'DebitsToPL', 'SalePromoExp'],['PARTA_PL', 'DebitsToPL', 'Advertisement']]},
    { description: 'selling_and_distribution_expenses', paths: [['PARTA_PL', 'DebitsToPL', 'SalePromoExp'], ['PARTA_PL', 'DebitsToPL', 'Advertisement']]},
    { description: 'depreciation', paths: [['PARTA_PL', 'DebitsToPL', 'DepreciationAmort']]
    }
  ]

  profitability_statement = {}
  operations.each do |operation|
    description = operation[:description]
    paths = operation[:paths]
    subtract = operation[:subtract] || []

    total = 0
    paths.each do |path|
      value = json_data.dig('ITR', itr_key, *path)
      total += value.to_f if value && !value.is_a?(Hash)
    end

    subtract.each do |path|
      value = json_data.dig('ITR', itr_key, *path)
      total -= value.to_f if value && !value.is_a?(Hash)
    end

    profitability_statement[description.to_sym] = total
  end

  balance_sheet_operations = [
    { description: 't1_closing_capital',paths: [['PARTA_BS', 'FundSrc', 'PropFund', 'PropCap']]},
    { description: 'reserves_and_surplus',paths: [['PARTA_BS', 'FundSrc', 'PropFund', 'ResrNSurp', 'RevResr']]},
    { description: 'capital_reserves',paths: [['PARTA_BS', 'FundSrc', 'PropFund', 'ResrNSurp', 'CapResr']]},
    { description: 'statutory_reserves',paths: [['PARTA_BS', 'FundSrc', 'PropFund', 'ResrNSurp', 'StatResr']]},
    { description: 'other_reserves',paths: [['PARTA_BS', 'FundSrc', 'PropFund', 'ResrNSurp', 'OthResr']]},
    { description: 'loans',paths: [['PARTA_BS', 'FundSrc', 'LoanFunds', 'SecrLoan', 'ForeignCurrLoan']]},
    { description: 'other_loans_and_advances',paths: [['PARTA_BS', 'FundSrc', 'Advances']]},
    { description: 'fixed_assets',paths: [['PARTA_BS', 'FundApply', 'FixedAsset', 'TotFixedAsset']]},
    { description: 'deposits_investments',paths: [['PARTA_BS', 'FundApply', 'Investments', 'TotInvestments']]},
    { description: 'sundry_debtors',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrAsset', 'SndryDebtors']]},
    { description: 'closing_stock',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrAsset', 'Inventories', 'TotInventries']]},
    { description: 'loans_and_advances',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'LoanAdv', 'TotLoanAdv']]},
    { description: 'other_current_assets',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrAsset', 'OthCurrAsset']]},
    { description: 'cash_and_bank',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrAsset', 'CashOrBankBal', 'TotCashOrBankBal']]},
    { description: 'sundry_creditors',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrLiabilitiesProv', 'CurrLiabilities', 'SundryCred']]},
    { description: 'other_payables',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrLiabilitiesProv', 'Provisions', 'ELSuperAnnGratProvision'],['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrLiabilitiesProv', 'Provisions', 'OthProvision']]},
    { description: 'provision_for_income_tax',paths: [['PARTA_BS', 'FundApply', 'CurrAssetLoanAdv', 'CurrLiabilitiesProv', 'Provisions', 'ITProvision']]},
    { description: 'deferred_tax',paths: [['PARTA_BS', 'FundApply', 'MiscAdjust', 'TotMiscAdjust'],['PARTA_BS', 'FundSrc', 'DeferredTax']],subtract: [['PARTA_BS', 'FundSrc', 'DeferredTax']]}
    ]

  balance_sheet = {}
  balance_sheet_operations.each do |operation|
    description = operation[:description]
    paths = operation[:paths]
    subtract = operation[:subtract] || []

    total = 0
    paths.each do |path|
      value = json_data.dig('ITR', itr_key, *path)
      total += value.to_f if value && !value.is_a?(Hash)
    end

    subtract.each do |path|
      value = json_data.dig('ITR', itr_key, *path)
      total -= value.to_f if value && !value.is_a?(Hash)
    end

    balance_sheet[description.to_sym] = total
  end


  output = {
    profitability_statement: profitability_statement,
    balance_sheet: balance_sheet
  }

  puts JSON.pretty_generate(output)
else
  puts "Error: 'ITR' key or its first-level content not found in the JSON data."
end
