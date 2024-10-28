require 'selenium-webdriver'
require 'open-uri'

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('start-maximized')
options.add_argument('disable-infobars')
options.add_argument('disable-blink-features=AutomationControlled')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')

driver = Selenium::WebDriver.for :chrome, options: options

login_url = 'https://services.gst.gov.in/services/login'
driver.navigate.to login_url

wait = Selenium::WebDriver::Wait.new(timeout: 10)

username = 'test'
username_field = wait.until { driver.find_element(name: 'user_name') }
username_field.send_keys(username)

password = 'test'
password_field = wait.until { driver.find_element(xpath: '//input[@placeholder="Enter Password"]') }
password_field.send_keys(password)

captcha_image = wait.until { driver.find_element(id: 'imgCaptcha') }
captcha_image_url = captcha_image.attribute('src')

base_url = URI(login_url).scheme + '://' + URI(login_url).host
full_captcha_url = URI.join(base_url, captcha_image_url).to_s
puts full_captcha_url

captcha_image_path = 'captcha.png'
File.open(captcha_image_path, 'wb') do |file|
  file.write(URI.open(full_captcha_url).read)
end

puts "Please solve the captcha (saved as #{captcha_image_path}) and enter the text:"
solved_captcha = gets.chomp


captcha_field = wait.until { driver.find_element(xpath: '//input[@placeholder="Enter Characters shown below"]') }
captcha_field.send_keys(solved_captcha)

login_button = wait.until { driver.find_element(xpath: '//button[@type="submit"]') }
login_button.click

sleep(5)

driver.quit
