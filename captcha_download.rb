require 'selenium-webdriver'

def capture_captcha_image(driver, file_path)
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  captcha_element = wait.until { driver.find_element(xpath: '//*[@id="imgCaptcha"]') }
  captcha_image = captcha_element.screenshot_as(:png)
  File.open(file_path, 'wb') do |file|
    file.write(captcha_image)
  end
  puts "CAPTCHA image downloaded and saved to #{file_path}"
end

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('start-maximized')
options.add_argument('--disable-blink-features=AutomationControlled')

driver = Selenium::WebDriver.for :chrome, options: options

login_url = 'https://services.gst.gov.in/services/login'
driver.navigate.to login_url

wait = Selenium::WebDriver::Wait.new(timeout: 10)
username = 'test'
username_field = wait.until { driver.find_element(name: 'user_name') }
username_field.send_keys(username)

begin
  sleep(2)

  captcha_file_path = "captcha_image_#{Time.now.to_i}.png"
  capture_captcha_image(driver, captcha_file_path)

rescue => e
  puts "An error occurred: #{e.message}"
ensure
  driver.quit
end
