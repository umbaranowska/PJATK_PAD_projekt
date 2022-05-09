# PJATK_PAD_projekt

Programowanie dla Analityki Danych PJATK 2022 - projekt zaliczeniowy.

## Pobieranie danych - web scraping ze strony lockme.pl - folder data_scraping
- **data_scraping_links.py** - pierwszy krok pobierania danych - na stronie lockme.pl znajduje bezpośrednie url do podstron każdego ER i zapisuje do pliku .txt
- **links.txt** - linki znalezione w pierwszym kroku
- **data_scraping_rooms.py** - drugi krok pobierania danych - odwiedza każdą ze stron znalezionych w pierwszym kroku, znajduje wszystkie potrzebne informacje, zapisuje do .json, na koniec łączy wszystko do pd.DataFrame zapisuje do pliku .csv - dla niektórych sekcji z informacjami XPATH jest niezmienny, dla innych trzeba najpierw znaleźć numer sekcji, ostatecznie generuje się dużo więcej kolumn niż potrzeba, ale celem było względnie sprawne pobranie wszyskich danych, czyszczenie dopiero w kolejnym kroku
- **/data_part** - folder zawiera dane dla każdego ER w plikach .json
- **data.csv** - surowe dane dla wszystkich ER ściągnięte w drugim kroku
