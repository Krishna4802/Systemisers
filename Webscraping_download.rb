require 'selenium-webdriver'

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
  'safebrowsing.enabled' => true,
  'plugins.always_open_pdf_externally' => true,
  'download.extensions_to_open' => 'applications/pdf',
  'profile.default_content_setting_values.automatic_downloads' => 1
}

prefs.each { |key, value| options.add_preference(key, value) }

driver = Selenium::WebDriver.for :chrome, options: options

login_url = 'https://eportal.incometax.gov.in/'
download_url = 'https://eportal.incometax.gov.in/iec/foservices/#/dashboard/itrStatus'
pan_num = ''
password = ''

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

sleep(10)

puts driver.title

driver.navigate.to download_url

sleep(2)
driver.find_element(xpath: "//button[text()='  No  ']").click
sleep(2)
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
