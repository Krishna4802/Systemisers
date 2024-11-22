require 'selenium-webdriver'
require 'net/http'
require 'json'
require 'base64'

API_KEY = '674cbe22709f6fbc18ec18b246280337' 

if ARGV.length < 2
  puts "Invalid username and password \nUsage: ruby script.rb <username> <password>"
  exit(1)
end

username = ARGV[0]

def capture_captcha_image(driver, file_path)
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  captcha_element = wait.until { driver.find_element(xpath: '//*[@id="imgCaptcha"]') }
  captcha_image = captcha_element.screenshot_as(:png)
  File.open(file_path, 'wb') do |file|
    file.write(captcha_image)
  end
  puts "CAPTCHA image downloaded and saved to #{file_path}"
end

def create_task(image_path)
  image_data = Base64.strict_encode64(File.read(image_path))

  request_payload = {
    clientKey: API_KEY,
    task: {
      type: 'ImageToTextTask',
      body: image_data
    }
  }.to_json

  uri = URI('https://freecaptchabypass.com/createTask')
  response = Net::HTTP.post(uri, request_payload, 'Content-Type' => 'application/json')

  result = JSON.parse(response.body)

  if result['errorId'] != 0
    puts "Error creating task: #{result['errorDescription']}"
    return nil
  end

  result['taskId']
end

def get_task_result(task_id, retries = 10)
  uri = URI('https://freecaptchabypass.com/getTaskResult')
  request_payload = { clientKey: API_KEY, taskId: task_id }.to_json

  attempt = 0
  loop do
    attempt += 1
    response = Net::HTTP.post(uri, request_payload, 'Content-Type' => 'application/json')
    result = JSON.parse(response.body)

    if result['errorId'] != 0
      puts "Error getting task result: #{result['errorDescription']}"
      return nil
    end

    if result['status'] == 'ready'
      return result['solution']['text']
    end

    puts "Waiting for CAPTCHA solution... (Attempt #{attempt})"
    sleep(5)

    break if attempt >= retries
  end

  puts "Failed to solve CAPTCHA after #{retries} attempts."
  nil
end

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('start-maximized')
options.add_argument('--disable-blink-features=AutomationControlled')

driver = Selenium::WebDriver.for :chrome, options: options

login_url = 'https://services.gst.gov.in/services/login'
driver.navigate.to login_url
sleep(2)

begin
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  
  username = ARGV[0]
  username_field = wait.until { driver.find_element(name: 'user_name') }
  username_field.send_keys(username)

  password = ARGV[1]
  password_field = wait.until { driver.find_element(xpath: '//input[@placeholder="Enter Password"]') }
  password_field.send_keys(password)

  sleep(2) 
  captcha_file_path = "captcha_image_#{Time.now.to_i}.png"
  capture_captcha_image(driver, captcha_file_path)

  task_id = create_task(captcha_file_path)
  if task_id
    puts "Task created successfully with ID: #{task_id}"
    solution = get_task_result(task_id)

    if solution
      puts "CAPTCHA solved: #{solution}"
      captcha_field = wait.until { driver.find_element(xpath: '//input[@placeholder="Enter Characters shown below"]') }
      captcha_field.send_keys(solution)
      sleep(1) 

      login_button = wait.until { driver.find_element(xpath: '//button[@type="submit"]') }
      login_button.click
      puts "Login button clicked."
      
      sleep(3) 

      if driver.find_elements(name: 'user_name').any? || driver.find_elements(xpath: "//div[contains(text(), 'invalid') or contains(text(), 'error')]").any?
        puts "Login failed: Invalid username, password, or CAPTCHA."
      else
        puts "Login successful."
      end
    else
      puts "Failed to solve CAPTCHA."
    end
  else
    puts "Failed to create CAPTCHA task."
  end

begin
  File.delete(captcha_file_path)
  puts "CAPTCHA image deleted: #{captcha_file_path}"
rescue => e
  puts "Failed to delete CAPTCHA image: #{e.message}"
end

rescue => e
  puts "An error occurred: #{e.message}"
ensure
  driver.quit
end
