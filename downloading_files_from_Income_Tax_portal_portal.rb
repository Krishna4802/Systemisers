# Ruby code for downloading the files from the Income Tax portal portal with name and password as parameters

# Sample Calling 
#     ruby web_download.rb <Pan_number> <password>


require 'selenium-webdriver'
require 'fileutils'

if ARGV.length < 2
  puts 'Usage: ruby web_download.rb <PAN_NUMBER> <PASSWORD>'
  exit
end

pan_num = ARGV[0]
password = ARGV[1]

download_directory = '/Users/krishnaprasath/Systemisers/Learnings/download'

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('start-maximized')
options.add_argument('disable-infobars')
options.add_argument('disable-blink-features=AutomationControlled')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')

prefs = {
  'download.default_directory' => download_directory,
  'download.prompt_for_download' => false,
  'download.directory_upgrade' => true,
  'plugins.always_open_pdf_externally' => true
}

prefs.each { |key, value| options.add_preference(key, value) }

driver = Selenium::WebDriver.for :chrome, options: options

login_url = 'https://eportal.incometax.gov.in/'
download_url = 'https://eportal.incometax.gov.in/iec/foservices/#/dashboard/itrStatus'

driver.navigate.to login_url

sleep(1)

pan_field = driver.find_element(name: 'panAdhaarUserId')
pan_field.send_keys(pan_num)
pan_field.send_keys(:return)

sleep(2)

driver.find_element(class: 'mat-checkbox-inner-container').click

password_field = driver.find_element(id: 'loginPasswordField')
password_field.send_keys(password)

continue_button_xpath = "//span[text()='Continue']"
wait = Selenium::WebDriver::Wait.new(timeout: 10)

3.times do
  begin
    expected_option = driver.find_element(xpath: continue_button_xpath)
    wait.until { expected_option.displayed? }
    expected_option.click
    sleep(2)
  rescue Selenium::WebDriver::Error::NoSuchElementError
    break
  end
end

sleep(5)

puts driver.title

driver.navigate.to download_url

sleep(2)
driver.find_element(xpath: "//button[text()='  No  ']").click
sleep(2)

pdf_file_path = File.join(download_directory, 'Form_pdf_541346040300624.pdf')
json_file_path = File.join(download_directory, '541346040300624.json')

FileUtils.rm_f(pdf_file_path)
FileUtils.rm_f(json_file_path)

driver.find_element(xpath: "//button[text()=' Download Form ']").click
sleep(20)
driver.find_element(xpath: "//button[text()=' Download JSON ']").click
sleep(5)

driver.find_element(class: 'profileMenubtn').click

sleep(3)

menu_items = driver.find_elements(class: 'mat-menu-item')
menu_items.each do |item|
  if item.text == 'Log Out'
    item.click
  end
end

sleep(5)

driver.quit
