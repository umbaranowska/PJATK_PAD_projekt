# PJATK_PAD_projekt

Programowanie dla Analityki Danych PJATK 2022 - projekt zaliczeniowy.

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
