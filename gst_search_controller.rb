require "selenium-webdriver"
require "net/http"
require "json"
require "base64"

class GstSearchController < ApplicationController
  API_KEY = "c84ca4253cdebaac77421e861e015e27"
  MAX_RETRIES = 3

  def search
    gst_number = params[:gst_number]
    return render json: { error: "GST Number is required" }, status: :bad_request if gst_number.blank?

    cached_data = GstSearch.find_by(gst_number: gst_number)
    if cached_data
      return render json: { data: JSON.parse(cached_data.data) }, status: :ok
    end

    result = fetch_gst_data(gst_number)
    if result[:error]
      render json: { error: result[:error] }, status: :bad_request
    else
      GstSearch.create!(gst_number: gst_number, name: result[:name], data: result[:data].to_json)
      render json: { data: result[:data] }, status: :ok
    end
  end

  private

  def fetch_gst_data(gst_number)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("start-maximized")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    driver = Selenium::WebDriver.for :chrome, options: options
    wait = Selenium::WebDriver::Wait.new(timeout: 20)

    login_url = "https://services.gst.gov.in/services/searchtp"
    driver.navigate.to login_url
    sleep(2)

    begin
      driver.find_element(xpath: '//*[@id="for_gstin"]').send_keys(gst_number)
      sleep(2)

      captcha_path = "captcha_image_#{Time.now.to_i}.png"
      capture_captcha_image(driver, captcha_path)

      task_id = create_task(captcha_path)
      if task_id
        solution = get_task_result(task_id)
        if solution
          captcha_field = wait.until { driver.find_element(xpath: '//input[@placeholder="Enter Characters shown below"]') }
          captcha_field.send_keys(solution)
          sleep(1)

          search_button = wait.until { driver.find_element(xpath: '//*[@id="lotsearch"]') }
          search_button.click
          sleep(3)

          begin
            error_element = driver.find_element(xpath: "/html/body/div[2]/div[2]/div/div[2]/div/div[1]/form/div[1]/div/span[1]")
            if error_element.displayed?
              driver.quit
              delete_captcha_image(captcha_path)
              return { error: "The GSTIN/UIN that you have entered is invalid. Please enter a valid GSTIN/UIN." }
            end
          rescue Selenium::WebDriver::Error::NoSuchElementError
          end

          begin
            name_element = wait.until { driver.find_element(xpath: '//*[@id="lottable"]/div[2]/div[1]/div/div[1]/p[2]') }
            name = name_element.text
          rescue Selenium::WebDriver::Error::NoSuchElementError
            driver.quit
            delete_captcha_image(captcha_path)
            return { error: "Element not found or page didn't load correctly" }
          end

          driver.quit
          delete_captcha_image(captcha_path)
          return { name: name, data: { gst_number: gst_number, name: name } }
        end
      end

      delete_captcha_image(captcha_path)
      { error: "Failed to solve CAPTCHA" }
    rescue StandardError => e
      driver.quit
      delete_captcha_image(captcha_path)
      { error: e.message }
    end
  end

  def capture_captcha_image(driver, file_path)
    captcha_element = driver.find_element(xpath: '//*[@id="imgCaptcha"]')
    File.open(file_path, "wb") { |file| file.write(captcha_element.screenshot_as(:png)) }
  end

  def delete_captcha_image(file_path)
    File.delete(file_path) if file_path && File.exist?(file_path)
  end

  def create_task(image_path)
    image_data = Base64.strict_encode64(File.read(image_path))
    request_payload = {
      clientKey: API_KEY,
      task: { type: "ImageToTextTask", body: image_data },
    }.to_json
    uri = URI("https://freecaptchabypass.com/createTask")
    response = Net::HTTP.post(uri, request_payload, "Content-Type" => "application/json")
    result = JSON.parse(response.body)
    result["taskId"] if result["errorId"] == 0
  end

  def get_task_result(task_id)
    uri = URI("https://freecaptchabypass.com/getTaskResult")
    request_payload = { clientKey: API_KEY, taskId: task_id }.to_json

    10.times do
      response = Net::HTTP.post(uri, request_payload, "Content-Type" => "application/json")
      result = JSON.parse(response.body)
      return result["solution"]["text"] if result["status"] == "ready"
      # sleep(5)
    end
    nil
  end
end
