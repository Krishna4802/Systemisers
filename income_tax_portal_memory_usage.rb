require 'selenium-webdriver'
require 'fileutils'
require 'sys/proctable'
include Sys

def log_memory_usage
  process = ProcTable.ps.find { |p| p.pid == Process.pid }
  if process
    memory_usage_mb = process.rss / (1024 * 1024) 
    puts "Memory usage: #{memory_usage_mb} MB"
  else
    puts "Could not retrieve memory usage."
  end
end

def log_memory_periodically(interval = 1)
  loop do
    log_memory_usage
    sleep(interval)
  end
end

memory_thread = Thread.new { log_memory_periodically(1) }


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
begin
  pan_error = driver.find_element(xpath: "//*[@id='mat-error-0']/div")
  if pan_error.displayed?
    puts 'Error: Invalid PAN Number.'
    driver.quit
    exit
  end
rescue Selenium::WebDriver::Error::NoSuchElementError
end
driver.find_element(class: 'mat-checkbox-inner-container').click
password_field = driver.find_element(id: 'loginPasswordField')
password_field.send_keys(password)
continue_button_xpath = "//span[text()='Continue']"
wait = Selenium::WebDriver::Wait.new(timeout: 10)
max_attempts = 4
attempts = 0
error_detected = false
while attempts < max_attempts
  begin
    expected_option = driver.find_element(xpath: continue_button_xpath)
    wait.until { expected_option.displayed? }
    expected_option.click
    attempts += 1
    sleep(2)
    begin
      password_error = driver.find_element(xpath: "//span[text()=' Invalid Password, Please retry. ']")
      if password_error.displayed?
        puts 'Error: Invalid Password, Please retry.'
        error_detected = true
        break 
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    break
  end
end
if error_detected || attempts >= max_attempts
  driver.quit
  exit
end
puts driver.title
driver.navigate.to download_url
sleep(2)
driver.find_element(xpath: "//button[text()='  No  ']").click
sleep(2)
pdf_file_path = File.join(download_directory, 'form.pdf')
json_file_path = File.join(download_directory, 'json_data.json')
FileUtils.rm_f(pdf_file_path)
FileUtils.rm_f(json_file_path)
driver.find_element(xpath: "//button[text()=' Download Form ']").click
sleep(20)
driver.find_element(xpath: "//button[text()=' Download JSON ']").click
sleep(5)
begin
  latest_json_file = Dir.glob(File.join(download_directory, '*.json')).max_by { |f| File.mtime(f) }
  if latest_json_file
    FileUtils.mv(latest_json_file, json_file_path)
    puts "Renamed JSON file to: #{json_file_path}"
  end
  latest_pdf_file = Dir.glob(File.join(download_directory, '*.pdf')).max_by { |f| File.mtime(f) }
  if latest_pdf_file
    FileUtils.mv(latest_pdf_file, pdf_file_path)
    puts "Renamed PDF file to: #{pdf_file_path}"
  end
rescue => e
  puts "Error renaming files: #{e.message}"
end
driver.find_element(class: 'profileMenubtn').click
sleep(3)
menu_items = driver.find_elements(class: 'mat-menu-item')
menu_items.each do |item|
  if item.text == 'Log Out'
    item.click
  end
end
sleep(5)

memory_thread.kill
driver.quit