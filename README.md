# PJATK_PAD_projekt

Programowanie dla Analityki Danych PJATK 2022 - projekt zaliczeniowy.

## Pobieranie danych - web scraping ze strony lockme.pl
- **data_scraping_links.py** - pierwszy krok pobierania danych - na stronie lockme.pl znajduje bezpośrednie url do podstron każdego ER i zapisuje do pliku .txt
- **data_scraping_rooms.py** - drugi krok pobierania danych - odwiedza każdą ze stron znalezionych w pierwszym kroku, znajduje wszystkie potrzebne informacje i zapisuje do pliku .csv
