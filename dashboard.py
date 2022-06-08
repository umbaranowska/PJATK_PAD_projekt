import pandas as pd
import streamlit as st
from streamlit_option_menu import option_menu
import plotly.graph_objects as go
st.set_page_config(layout="wide")

df = pd.read_csv('data_final.csv')
top12_miast = list(df['miasto'].value_counts().reset_index().sort_values(by='miasto', ascending=False)['index'][:13])

with st.sidebar:
    page = option_menu(
        'Projekt',
        ['Informacje ogólne', 'Kategorie ER', 'Poziom trudności ER'],
        menu_icon = '123',
        icons = ['arrow_right' for i in range(3)]
    )

if page == 'Informacje ogólne':

    st.title('Analiza rynku escape roomów w Polsce i przewidywanie średniej oceny graczy na podstawie danych z portalu lockme.pl')

    st.write('''Celem projektu jest sprawdzenie czy na podstawie informacji o escape roomach w Polsce
     znalezionych na stronie lockme.pl można przewidywać średnią ocenę escape roomu wystawioną przez użytkowników portalu.''')
    st.write('''Na stronie lockme.pl można znaleźć informacje o escape roomach w Polsce i na świecie, 
    na potrzeby tego projektu wybrano tylko ranking dla Polski. 
    Oprócz takich informacji jak tematyka pokoju czy liczba graczy, 
    na stronie znajdziemy też informacje m.in. o tym czy pokój jest przyjazny osobom w ciązy lub niepełnosprawnym, 
    w jakich językach dostępna jest gra oraz jakie środki bezpieczeństwa są dostępne w pokoju 
    (np. przycisk bezpieczeństwa). Te dane zostały wykorzystane w projekcie.''')
    st.write('''Repozytorium z kodem i opisem całego procesu tworzenia tego dashboardu jest dostępne pod adresem
     https://github.com/umbaranowska/PJATK_PAD_projekt''')

    st.header('Miasta, w których znajdziemy najwięcej ER')

    st.header('Najlepsze ER w Polsce')
    st.write('Wiele ER w Polsce może się pochwalić idealną oceną średnią odwiedzających. W poniższej tabeli znajduje się 15 z nich.')
    st.dataframe(df.sort_values(by = ['srednia_ocena'], ascending=False)\
                [['nazwa', 'firma', 'miasto', 'kategoria', 'poziom_trudnosci']]\
                .head(15)\
                .set_index(pd.Index(list(range(1,16))), drop=True)\
                .rename(columns = {'nazwa' : 'Nazwa ER',
                                   'firma' : 'Firma',
                                   'miasto' : 'Miasto',
                                   'kategoria' : 'Kategoria',
                                   'poziom_trudnosci' : 'Poziom trudności'}))
    st.write('''Aktualny ranking można znaleźc na stronie https://lock.me/pl/polska/ranking-escape-room, 
             dlatego w tym projekcie skupmy się na tym, czego nie znajdziemy na lockme.pl :)''')

if page == 'Kategorie ER':

    st.header('Kategorie ER')
    df_kategorie = df['kategoria'].value_counts().reset_index().sort_values(by='kategoria')

    st.write(f'''Jak widać na polskim rynku escape roomów zdecydowanie przeważają pokoje z kategorii {df_kategorie["index"][0]},
    jest ich więcej niż kolejnych 3 kategorii ({df_kategorie["index"][1]}, {df_kategorie["index"][2]}, {df_kategorie["index"][3]}) łącznie!''')

    fig01 = go.Figure()
    fig01 = fig01.add_trace(go.Bar(y = df_kategorie['index'], x = df_kategorie['kategoria'], orientation = 'h'))
    st.plotly_chart(fig01)
    ### TODO hover % - do wszyskich wykresów

    st.write('''Co ciekawe nie we wszystkich miastach przeważają pokoje przygodowe''')
    ### TODO tekst i wykresy dla top12_miast

if page == 'Poziom trudności ER':
    pass