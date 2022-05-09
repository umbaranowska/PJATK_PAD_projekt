# pierwszy krok scrapowania danych - szybkie wyszukiwanie adresów wszystkich stron ER

from selenium import webdriver
from selenium.webdriver.common.by import By
import time
import re
import random
from icecream import ic

# otwiera przeglądarkę i stronę lockme
driver = webdriver.Chrome()
driver.get('https://lock.me/pl/polska')
# akceptuje pliki cookies
driver.find_element(by=By.XPATH, value='//*[@id="cookiebox"]/button').click()
# przechodzi do listy wszystkich ER i czeka aż się załaduje
driver.find_element(by=By.XPATH, value='/html/body/main/section[3]/div/a[2]').click()
time.sleep(15)
# powoli scrolluje stronę do samego końca żeby załadować więcej informacji
for x in range(400):
    driver.execute_script('window.scrollBy(0,500)')
    time.sleep(random.randint(5,10))
time.sleep(60)
# tworzę listę wszystkich XPATH z linkiem do konkretnego ER
all_xpaths = \
    [f'/html/body/main/section[2]/div[2]/div/div/div[3]/div/article[{x}]/div/div/div[1]/header/a'\
     for x in range(1,477)]
# znajduje adresy stron dla wszystkich ER
all_links = []
failed_links = 0
for xpath in all_xpaths:
    try:
        link = driver.find_element(by=By.XPATH, value=xpath).get_attribute('href')
        all_links.append(link)
    except:
        failed_links+=1
# sprawdza czy się udało
ic(all_links)
ic(len(all_links))
ic(failed_links)
# zamyka przeglądarkę
driver.quit()

# zapisuje listę linków do pliku
with open('links.txt', 'w') as file:
    for link in all_links:
        file.write(link+'\n')