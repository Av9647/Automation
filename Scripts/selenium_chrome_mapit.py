
# Run in cmd : pip install pyperclip
# Run in cmd : pip install selenium
# Download and place geckodriver.exe in path : "C:\Users\Anagha Vinod\AppData\Local\Programs\Python\Python310\"
import webbrowser, sys, time, pyperclip

# Import webdriver module.
from selenium import webdriver
from selenium.webdriver.common.by import By

# Import GeckoDriverManager module for firefox.
from webdriver_manager.firefox import GeckoDriverManager

sys.argv # ['mapit.py', 'Lulu', 'Kochi']

# Check if command line arguments were passed
if len(sys.argv) > 1:
    address = ' '.join(sys.argv[1:]) # ['mapit.py', 'Lulu', 'Kochi'] -> 'Lulu Kochi'
else:
    address = pyperclip.paste()

browser = webdriver.Firefox()
browser.get('https://www.google.com/maps/place/' + address)
browser.find_element(By.XPATH, '//*[@id="searchbox-searchbutton"]').click()

# Usage : 

# 1. Run mapit.bat present in "C:\Users\Anagha Vinod\AppData\Local\Programs\Python\Python310\" having below code,
# @py "C:\Users\Anagha Vinod\AppData\Local\Programs\Python\Python310\Python Scripts\mapit.py" %*
# @pause

# 2. Open Run by pressing "Windows key + R"
# 3. Type and enter : mapit <ADDRESS>   
