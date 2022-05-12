# Analiza rynku escape roomów w Polsce i przewidywanie średniej oceny graczy na podstawie danych z portalu lockme.pl
projekt zaliczeniowy z Programowania dla Analityki Danych (PJATK, 2022)

## Cel projektu
Celem projektu jest sprawdzenie czy na podstawie informacji o escape roomach w Polsce znalezionych na stronie lockme.pl można przewidywać średnią ocenę escape roomu wystawioną przez użytkowników portalu.  
Na stronie lockme.pl można znaleźć informacje o escape roomach w Polsce i na świecie, na potrzeby tego projektu wybrano tylko ranking dla Polski. Oprócz takich informacji jak tematyka pokoju czy liczba graczy, na stronie znajdziemy też informacje m.in. o tym czy pokój jest przyjazny osobom w ciązy lub niepełnosprawnym, w jakich językach dostępna jest gra oraz jakie środki bezpieczeństwa są dostępne w pokoju (np. przycisk bezpieczeństwa). Te dane zostaną wykorzystane w projekcie.  
Strona daje także możliwość zarezerwowania pokoju poprzez widget rezerwacyjny. W większości przypadków cena pojawia się dopiero po kliknięciu w wybraną datę, godzinę i wybraniu liczby graczy. W projekcie pominięto dane dotyczące cen z dwóch powodów: (1) zdobycie danych z widgetu rezerwacyjnego przy użyciu prostego web scrapingu jest zbyt skomplikowane oraz (2) cena zależy od liczby graczy, miasta - te zmienne są już uwzględnione w zbiorze, oraz w dużej mierze od dnia tygodnia oraz pory dnia - ta cykliczność jest bardzo charakterystyczna dla całego rynku ER.

## Pobieranie danych - web scraping ze strony lockme.pl - folder data_scraping
- **data_scraping_links.py** - pierwszy krok pobierania danych - na stronie lockme.pl znajduje bezpośrednie url do podstron każdego ER i zapisuje do pliku .txt
- **links.txt** - linki znalezione w pierwszym kroku
- **data_scraping_rooms.py** - drugi krok pobierania danych - odwiedza każdą ze stron znalezionych w pierwszym kroku, znajduje wszystkie potrzebne informacje, zapisuje do .json, na koniec łączy wszystko do pd.DataFrame zapisuje do pliku .csv - dla niektórych sekcji z informacjami XPATH jest niezmienny, dla innych trzeba najpierw znaleźć numer sekcji, ostatecznie generuje się dużo więcej kolumn niż potrzeba, ale celem było względnie sprawne pobranie wszyskich danych, czyszczenie dopiero w kolejnym kroku
- **/data_part** - folder zawiera dane dla każdego ER w plikach .json
- **data.csv** - surowe dane dla wszystkich ER ściągnięte w drugim kroku

## Czyszczenie danych - folder data_cleaning
Ta część zawiera kilka ważnych kroków, które dla lepszej organizacji pracy są podzielone na kolejne foldery.
### 01
- skupia się na kolumnach z podstawowymi informacjami: 'nazwa', 'miasto', 'firma', 'liczba_graczy', 'czas_gry', 'kategoria', 'poziom_trudnosci', 'liczba_ocen', 'miejsce_w_polsce'
- w tym kroku ze zbioru danych usunięto 3 wiersze - (1) pokój, który rzeczywiście nie ma przypisanej kategorii, (2) pokój oznaczony jako 'dostępny wkrótce', ale jednocześnie z recenzjami użytkowników z 2020 roku - prawdopodobnie pomyłka / pokój nieczynny, (3) szablon strony ER znaleziony dzięki nietypowej wartości w kolumnie z nazwą miasta (Escape City)
### 02
- skupia się na kolumnach z informacjami z sekcji "Ważne informacje" - każdemu atrybutowi odpowiada jedna kolumna z wartościami 0 (nie było w opisie pokoju) - 1 (był w opisie pokoju), dodatkowo nazwy kolumn zawierają prefiksy informujące o tym czy to informacje podstawowe, o bezpieczeństwie, językach czy inne (zgodnie z tym jak są one pogrupowane na stronie lockme)
### 03
- skupia się na kolumnie z ocenami użytkowników - kolumna została podzielona na średnią ocenę, ocenę za klimat, ocenę za obsługę oraz poziom trudności wg. użytkowników
### 04
- w tym kroku z kolumn 'liczba_graczy', 'czas_gry', 'liczba_ocen', 'miejsce_w_polsce' został usunięty niepotrzebny tekst (np. '60' zamiast '60 minut')
- dodatkowo kolumna 'liczba_graczy' została podzielona na kolumny 'min_liczba_graczy' i 'max_liczba_graczy'

## Eksploracja danych - folder data_exploration
W tym etapie skupiono się na sprawdzeniu czy dane zostały dobrze zebranie i wyczyszczone, sprawdzeniu rozkładów zamiennych, braków danych, decyzji które obserwacje odrzucić (np. ze względu na brak ocen). Sprawdzono też korelacje między zmiennymi, żeby ostatecznie wybrać które zależności będą przedstawione na dashboardzie, które zmienne można pogrupować albo pominąć. 
Podczas tego kroku znaleziono jeden pominięty wcześniej wiersz dla którego brakuje danych o poziomie trudności. Ponieważ jest to pojedynczy przypadek spośród ponad 450 obserwacji, został on usunięty z dalszej analizy.
