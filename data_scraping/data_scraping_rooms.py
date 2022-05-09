# drugi krok scrapowania danych - ściąganie danych dla każdego ER

from selenium import webdriver
from selenium.webdriver.common.by import By
import pandas as pd
import time
import random
import json
from copy import deepcopy
from datetime import datetime
from icecream import ic
def time_format():
    return f'{datetime.now()}|> '
ic.configureOutput(prefix=time_format)


##### tworzy słownik wszystkich xpaths

ic('creating xpaths dictionary')

xpaths_section1 = { # sekcja 1 jest ogólnie stała dla wszystkich er
    'nazwa' : '/html/body/main/section[1]/section[1]/div[1]/div/h1',
    'miasto' : '/html/body/main/section[1]/section[1]/div[2]/div/a[1]',
    'firma' : '/html/body/main/section[1]/section[1]/div[2]/div/a[2]',
    'liczba_graczy' : '/html/body/main/section[1]/section[2]/div/div[1]/p',
    'czas_gry' : '/html/body/main/section[1]/section[2]/div/div[2]/p',
    'kategoria' : '/html/body/main/section[1]/section[2]/div/div[3]/p',
    'poziom_trudnosci' : '/html/body/main/section[1]/section[2]/div/div[4]/p',
    'liczba_ocen' : '/html/body/main/section[1]/section[2]/div/div[5]/p',
    'miejsce_w_polsce' : '/html/body/main/section[1]/section[2]/div/div[6]/p'
}
# dla pozostałych sekcji trzeba znaleźć w każdym przypadku tytuł sekcji i na tej podstawie zadecydować co dalej
# section2 = '/html/body/main/section[2]/div/section[2]/h2'
# section3 = '/html/body/main/section[2]/div/section[3]/h2' # itd.
# problem z ocenami

##### dla każdego wiersza z links.txt
# otwiera przeglądarkę i stronę ER
# pobiera dane do słownika
# zamienia na data frame i dodaje do listy

all_rooms_data = {}

with open('links.txt', 'r') as file:
    k = 0
    for line in file:
        room_url = line
        xpaths = deepcopy(xpaths_section1)
        driver = webdriver.Chrome()
        driver.get(room_url)
        ic('open in chrome')
        ic(room_url)
        time.sleep(random.randint(5,15))
        ic('getting data...')
        for j in range(1,6): # szuka sekcji z podstawowymi informacjami żeby wygenerować resztę słownika xpaths
            # section = f'/html/body/main/section[2]/div/section[{j}]/h2'
            try:
                section_text = driver.find_element(by=By.XPATH, value=f'/html/body/main/section[2]/div/section[{j}]/h2').text
                if section_text == 'Ważne informacje':
                    xpaths_wazne1 = dict(zip(
                        [f'wazne1_{i}' for i in range(1, 21)],
                        [f'/html/body/main/section[2]/div/section[{j}]/div/section[1]/p[{i}]' for i in range(1, 21)]
                    ))
                    xpaths.update(xpaths_wazne1)
                    xpaths_wazne2 = dict(zip(
                        [f'wazne2_{i}' for i in range(1, 21)],
                        [f'/html/body/main/section[2]/div/section[{j}]/div/section[2]/p[{i}]' for i in range(1, 21)]
                    ))
                    xpaths.update(xpaths_wazne2)
                    xpaths_wazne3 = dict(zip(
                        [f'wazne3_{i}' for i in range(1, 21)],
                        [f'/html/body/main/section[2]/div/section[{j}]/div/section[3]/p[{i}]' for i in range(1, 21)]
                    ))
                    xpaths.update(xpaths_wazne3) # wygeneruje dużo więcej kolumn niż byłoby optymalnie ale:
                    # a. nie zawsze numeracja sekcji i atrybuty pokoju są takie same więc trudno dobrać odpowiednie range
                    # b. celem jest raczej względnie szybkie ściągnięcie danych, sprzątanie w kolejnym etapie
            except:
                pass
        for j in range(1,10): # szuka sekcji z ocenami użytkowników - tutaj trzeba ściągać od razu całą sekcję, inaczej jest problem ze średnią oceną
            try:
                section_text = driver.find_element(by=By.XPATH, value=f'/html/body/main/section[2]/div/section[{j}]/section').text
                xpaths_oceny = {
                        'oceny' : f'/html/body/main/section[2]/div/section[{j}]/section'
                    }
                xpaths.update(xpaths_oceny)
            except:
                pass
        room_data = {}
        for (key, value) in xpaths.items():
            try:
                room_data.update(
                    {key: driver.find_element(by=By.XPATH, value=value).text}
                )
            except:
                room_data.update(
                    {key: 'NAN'}
                )
        ic(room_data)
        with open(f'data_part/{k}.json', 'w') as d:
            json.dump(room_data, d)
        all_rooms_data.update({k: room_data})
        k+=1
        driver.quit()

df_all_rooms_data = pd.DataFrame(all_rooms_data).transpose()
ic(df_all_rooms_data)
df_all_rooms_data.to_csv('data.csv')