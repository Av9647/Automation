
import pyautogui
import webbrowser, sys, time, pyperclip
from selenium import webdriver
from selenium.webdriver.common.by import By
from webdriver_manager.firefox import GeckoDriverManager

# size(1366, 768)
pyautogui.click(202,750) # Opens firefox from taskbar
pyautogui.click(252,420) # Opens youtube in firefox
pyautogui.click(1269,139) # Sign In
pyautogui.click(641, 382) # Clicks on form
pyautogui.typewrite('athulvinod9647@gmail.com') # Enters email
pyautogui.click(822, 582) # Clicks on next
