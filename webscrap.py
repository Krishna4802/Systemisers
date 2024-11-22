import time

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from selenium_stealth import stealth

options = webdriver.ChromeOptions()
options.add_argument("start-maximized")

options.add_experimental_option("excludeSwitches", ["enable-automation"])
options.add_experimental_option('useAutomationExtension', False)

driver = webdriver.Chrome(options=options)

stealth(
    driver,
    languages=["en-US", "en"],
    vendor="Google Inc.",
    platform="Win32",
    webgl_vendor="Intel Inc.",
    renderer="Intel Iris OpenGL Engine",
    fix_hairline=True,
)


login_url = 'https://eportal.incometax.gov.in/'
pan_num = 'BXXPT7832A'
password = 'Krishna@7832a'

driver.get(login_url)

time.sleep(3)

pan_field = driver.find_element(By.NAME, 'panAdhaarUserId')
pan_field.send_keys(pan_num)
pan_field.send_keys(Keys.RETURN)

time.sleep(2)

driver.find_element(By.CLASS_NAME, 'mat-checkbox-inner-container').click()
time.sleep(2)

password_field = driver.find_element(By.ID, 'loginPasswordField')

password_field.send_keys(password)
# password_field.send_keys(Keys.RETURN)
expected_option = (By.XPATH,f"//span[text()='Continue']")
WebDriverWait(driver, 10).until(EC.visibility_of_element_located(expected_option)).click()


time.sleep(2)
expected_option = (By.XPATH,f"//button[text()=' Login Here ']")
WebDriverWait(driver, 10).until(EC.visibility_of_element_located(expected_option)).click()


time.sleep(5)
expected_option = (By.XPATH,f"//span[text()=' Dashboard ']")
WebDriverWait(driver, 10).until(EC.visibility_of_element_located(expected_option)).click()

time.sleep(5)

print(driver.title)
driver.find_element(By.CLASS_NAME,'mat-button-wrapper').click()

print(driver.find_element(By.CLASS_NAME, 'welcomeHeading').text)

time.sleep(3)
driver.find_element(By.CLASS_NAME, 'profileMenubtn').click()

menu_items = driver.find_elements(By.CLASS_NAME, 'mat-menu-item ng-star-inserted')
for item in menu_items:
    if item.text == 'Log Out':
        item.click()

time.sleep(5)

driver.quit()