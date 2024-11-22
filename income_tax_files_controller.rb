class IncomeTaxFilesController < ApplicationController
  require 'selenium-webdriver'
  require 'fileutils'

  def download_files
    pan_num = params[:pan_number]
    password = params[:password]

    if pan_num.blank? || password.blank?
      render json: { error: 'PAN number and password are required' }, status: :bad_request
      return
    end

    download_directory = Rails.root.join('tmp', 'downloads').to_s
    FileUtils.mkdir_p(download_directory)

    options = Selenium::WebDriver::Chrome::Options.new
    # options.add_argument('--headless')
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

    begin
      login_url = 'https://eportal.incometax.gov.in/'
      driver.navigate.to login_url

      pan_field = driver.find_element(name: 'panAdhaarUserId')
      pan_field.send_keys(pan_num)
      pan_field.send_keys(:return)
      return unless check_invalid_pan(driver)

      driver.find_element(class: 'mat-checkbox-inner-container').click

      password_field = driver.find_element(id: 'loginPasswordField')
      password_field.send_keys(password)
      # binding.pry
      if attempt_login(driver, download_directory)
        render json: {message: "Incorrect password"} and return
      end
      
      Rails.logger.info "Login successful"

      download_url = 'https://eportal.incometax.gov.in/iec/foservices/#/dashboard/itrStatus'
      driver.navigate.to download_url

      wait_for_duration(2)
      wait_until(driver, "//button[text()='  No  ']").click

      download_and_rename_files(driver, download_directory)

      logout(driver)

      render json: { message: 'Files downloaded successfully', download_directory: download_directory }, status: :ok
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    ensure
      driver.quit
    end
  end

  private

  def wait_for_duration(duration)
    start_time = Process.clock_gettime(Process::CLOCK_REALTIME)
    while Process.clock_gettime(Process::CLOCK_REALTIME) - start_time < duration
    end
    # Rails.logger.info "#{duration} seconds have passed."
  end

  def wait_until(driver, xpath, timeout = 10)
    wait = Selenium::WebDriver::Wait.new(timeout: timeout)
    wait.until { driver.find_element(xpath: xpath).displayed? }
    driver.find_element(xpath: xpath)
  end

  def check_invalid_pan(driver)
    begin
      small_wait = Selenium::WebDriver::Wait.new(timeout: 1)
      pan_error = small_wait.until { driver&.find_element(xpath: "//*[@id='mat-error-0']/div") }
      if pan_error.displayed?
        Rails.logger.error 'Invalid PAN Number'
        render json: { error: 'Invalid PAN Number' }, status: :unprocessable_entity
        return false
      else
        return true
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      true
    end
  end

  def attempt_login(driver, download_directory)
    continue_button_xpath = "//span[text()='Continue']"
    max_attempts = 4
    attempts = 0
    error_detected = false

    while attempts < max_attempts
      begin
        expected_option = driver.find_element(xpath: continue_button_xpath)
        wait_until(driver, continue_button_xpath).click
        attempts += 1
        wait_for_duration(2)

        handle_login_popup(driver)
        if check_invalid_password(driver)
          error_detected = true
          break
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        # Rails.logger.error "Continue button not found or has disappeared."
        break
      end
    end
    if error_detected || attempts >= max_attempts
      true
    else
      false
    end
  end

  def handle_login_popup(driver)
    popup_button_xpath = "//*[@id='loginMaxAttemptsPopup']/div/div/div[3]/button[2]"
    begin
      popup_button = driver.find_element(xpath: popup_button_xpath)
      if popup_button.displayed?
        popup_button.click
        wait_for_duration(5)
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
      Rails.logger.info "No popup appeared after 3 attempts."
    end
  end

  def check_invalid_password(driver)
    password_error_xpath = "//span[text()=' Invalid Password, Please retry. ']"
    begin
      password_error = driver.find_element(xpath: password_error_xpath)
      if password_error.displayed?
        Rails.logger.error 'Error: Invalid Password, Please retry.'
        return true
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
      false
    end
  end

  def download_and_rename_files(driver, download_directory)
    pdf_file_path = File.join(download_directory, 'form.pdf')
    json_file_path = File.join(download_directory, 'json_data.json')
    FileUtils.rm_f(pdf_file_path)
    FileUtils.rm_f(json_file_path)

    wait_until(driver, "//button[text()=' Download Form ']").click
    Rails.logger.info "Downloading PDF."
    wait_for_duration(20)
    Rails.logger.info "Download PDF Done."
    wait_until(driver, "//button[text()=' Download JSON ']").click
    Rails.logger.info "Downloading Json."
    wait_for_duration(5)
    Rails.logger.info "Download Json Done."


    rename_downloaded_files(download_directory, '*.json', json_file_path)
    rename_downloaded_files(download_directory, '*.pdf', pdf_file_path)
  end

  def rename_downloaded_files(directory, pattern, new_path)
    latest_file = Dir.glob(File.join(directory, pattern)).max_by { |f| File.mtime(f) }
    if latest_file
      FileUtils.mv(latest_file, new_path)
      # Rails.logger.info "Renamed file to: #{new_path}"
    else
      Rails.logger.error "No files found matching pattern: #{pattern}"
    end
  end

  def logout(driver)
    driver.find_element(class: 'profileMenubtn').click
    wait_for_duration(1)
    menu_items = driver.find_elements(class: 'mat-menu-item')
    menu_items.each do |item|
      if item.text == 'Log Out'
        item.click
        break
      end
    end
    wait_for_duration(2)
  end
end



