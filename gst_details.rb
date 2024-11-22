require 'selenium-webdriver'
require 'net/http'
require 'json'
require 'base64'
require 'open3'

API_KEY = '674cbe22709f6fbc18ec18b246280337'
MAX_RETRIES = 3
LOG_MEMORY = true

if ARGV.length < 1
  puts "Invalid GST Number\nUsage: ruby script.rb <GST Number>"
  exit(1)
end

GST_Number = ARGV[0]

def capture_captcha_image(driver, file_path)
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  captcha_element = wait.until { driver.find_element(xpath: '//*[@id="imgCaptcha"]') }
  captcha_image = captcha_element.screenshot_as(:png)
  File.open(file_path, 'wb') { |file| file.write(captcha_image) }
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
  return result['taskId'] if result['errorId'] == 0

  puts "Error creating task: #{result['errorDescription']}"
  nil
end

def get_task_result(task_id, retries = 10)
  uri = URI('https://freecaptchabypass.com/getTaskResult')
  request_payload = { clientKey: API_KEY, taskId: task_id }.to_json
  attempt = 0
  loop do
    attempt += 1
    response = Net::HTTP.post(uri, request_payload, 'Content-Type' => 'application/json')
    result = JSON.parse(response.body)
    return result['solution']['text'] if result['status'] == 'ready'

    puts "Waiting for CAPTCHA solution... (Attempt #{attempt})"
    sleep(5)
    break if attempt >= retries
  end
  puts "Failed to solve CAPTCHA after #{retries} attempts."
  nil
end

def log_memory_usage(pid)
  Thread.new do
    start_time = Time.now
    loop do
      elapsed_time = Time.now - start_time
      memory_usage = get_process_memory(pid)
      puts "[#{elapsed_time.round(1)}s] Memory Usage: #{memory_usage} MB"
      sleep(1)
    end
  end
end

def get_process_memory(pid)
  stdout, _stderr, _status = Open3.capture3("ps -o rss= -p #{pid}")
  memory_kb = stdout.strip.to_i
  (memory_kb / 1024.0).round(2)
end

def handle_retry(driver, wait, retries)
  captcha_file_path = "captcha_image_retry_#{Time.now.to_i}.png"
  retries.times do |attempt|
    puts "Retry attempt #{attempt + 1}..."
    begin
      capture_captcha_image(driver, captcha_file_path)
      task_id = create_task(captcha_file_path)
      if task_id
        solution = get_task_result(task_id)
        if solution
          captcha_field = wait.until { driver.find_element(xpath: '//input[@placeholder="Enter Characters shown below"]') }
          captcha_field.clear
          captcha_field.send_keys(solution)
          sleep(1)
          search_button = wait.until { driver.find_element(xpath: '//*[@id="lotsearch"]') }
          search_button.click
          sleep(3)
          error_element = driver.find_elements(xpath: '/html/body/div[2]/div[2]/div/div[2]/div/div[1]/form/div[2]/div/div/span')
          return true if error_element.empty?

          puts "Unexpected element detected. Retrying..."
        end
      end
    ensure
      File.delete(captcha_file_path) if File.exist?(captcha_file_path)
    end
  end
  puts "Exceeded maximum retry attempts."
  false
end

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('start-maximized')
options.add_argument('--disable-blink-features=AutomationControlled')

driver = Selenium::WebDriver.for :chrome, options: options
wait = Selenium::WebDriver::Wait.new(timeout: 10)

pid = Process.pid
memory_logger = log_memory_usage(pid) if LOG_MEMORY

login_url = 'https://services.gst.gov.in/services/searchtp'
driver.navigate.to login_url
sleep(2)

begin
  driver.find_element(xpath: '//*[@id="for_gstin"]').send_keys(GST_Number)
  sleep(2)
  captcha_file_path = "captcha_image_#{Time.now.to_i}.png"
  capture_captcha_image(driver, captcha_file_path)

  task_id = create_task(captcha_file_path)
  if task_id
    solution = get_task_result(task_id)
    if solution
      captcha_field = wait.until { driver.find_element(xpath: '//input[@placeholder="Enter Characters shown below"]') }
      captcha_field.send_keys(solution)
      sleep(1)
      search_button = wait.until { driver.find_element(xpath: '//*[@id="lotsearch"]') }
      search_button.click
      sleep(3)
      error_element = driver.find_elements(xpath: '/html/body/div[2]/div[2]/div/div[2]/div/div[1]/form/div[2]/div/div/span')
      if error_element.any?
        puts "Unexpected element detected. Initiating retry..."
        handle_retry(driver, wait, MAX_RETRIES)
      else
        name = driver.find_element(xpath: '//*[@id="lottable"]/div[2]/div[1]/div/div[1]/p[2]').text
        puts "Result found: #{name}"
      end
    else
      puts "Failed to solve CAPTCHA."
    end
  else
    puts "Failed to create CAPTCHA task."
  end
ensure
  File.delete(captcha_file_path) if File.exist?(captcha_file_path)
  driver.quit
  Thread.kill(memory_logger) if memory_logger
end