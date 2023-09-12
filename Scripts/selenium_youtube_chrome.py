
import webbrowser, sys, time, pyperclip

# Import webdriver module.
from selenium import webdriver
from selenium.webdriver.common.by import By

browser = webdriver.Chrome()
browser.get('https://www.youtube.com/')
browser.find_element(By.XPATH, '/html/body/ytd-app/div[1]/div/ytd-masthead/div[3]/div[3]/div[2]/ytd-button-renderer/a/tp-yt-paper-button/yt-icon').click()
browser.find_element(By.XPATH, '//*[@id="identifierId"]').send_keys('athulvinod9647@gmail.com')
browser.find_element(By.CSS_SELECTOR, '.VfPpkd-LgbsSe-OWXEXe-k8QpJ > span:nth-child(4)').click()
