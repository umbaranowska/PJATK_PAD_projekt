import pandas as pd
import numpy as np
import statsmodels.formula.api as smf

import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.express as px

import streamlit as st
from streamlit_option_menu import option_menu
st.set_page_config(layout="wide")

# ukrywanie indexów przy wyświetlaniu tabel ALE nie dataframe pożyczone z:
# https://docs.streamlit.io/knowledge-base/using-streamlit/hide-row-indices-displaying-dataframe
hide_dataframe_row_index = """
            <style>
            .row_heading.level0 {display:none}
            .blank {display:none}
            </style>
            """
st.markdown(hide_dataframe_row_index, unsafe_allow_html=True)

df = pd.read_csv('data_final.csv').rename(columns = {'Unnamed: 0' : 'ind'})
top12_miast = list(df['miasto'].value_counts().reset_index().sort_values(by='miasto', ascending=False)['index'][:12])
wszystkie_kategorie = list(df.kategoria.value_counts().reset_index()['index'])
top3_kategorie = wszystkie_kategorie[:3]
poziomy_trudnosci = ['na pierwszy raz', 'początkujący', 'śr. zaawansowani', 'doświadczony', 'eksperci']
poziomy_trudnosci_wg_graczy = ['Bardzo łatwy', 'Łatwy', 'Średni', 'Trudny', 'Bardzo trudny']

df_wazne_informacje = pd.read_csv('dashboard_draft/wazne_informacje.csv', index_col='Unnamed: 0')
df_wazne_informacje = df_wazne_informacje[df_wazne_informacje['subgroup'] != 'języki']
df_wazne_informacje['zmienna'] = df_wazne_informacje['zmienna'].str.replace('_', ' ').str.capitalize()
df_wazne_informacje.sort_values('wartosc', ascending=False)
df_wazne_informacje['wartosc_do_pokazania'] = np.round(df_wazne_informacje['wartosc'], 2).astype('str') + '%'
df_wazne_informacje.rename(columns = {'zmienna' : 'Oznaczenie',
                                      'wartosc_do_pokazania' : 'Procent ER z oznaczeniem',
                                      'subgroup' : 'Typ oznaczenia'}, inplace = True)

# podstrony do struktury dashboardu
podstrony = ['Informacje ogólne', 'Kategorie ER', 'Poziom trudności ER', 'Dodatkowe informacje o ER', 'Średnia ocena',
             'Korelacje między zmiennymi', 'Predykcja średniej oceny - OLS']

# wybór zmiennych do regresji i do etykiet na niektórych wykresach
wybor_zmiennych = [colname.replace('bezpieczeństwo_', '')\
                       .replace('języki_', 'język ')\
                       .replace('podstawowe_', '')\
                       .replace('_', ' ')\
                       .replace('min', 'Minimalna')\
                       .replace('max', 'Maksymalna')\
                       .replace('trudnosci', 'trudności')\
                       .replace('trudnosc', 'trudność')\
                       .replace('srednia', 'średnia')\
                       .replace('obsluga', 'obsługa')\
                       .replace('wg', 'wg.')
                       .capitalize()
                   for colname in df.columns]
wybor_zmiennych = dict(zip(wybor_zmiennych, df.columns))
zmiana_etykiet = dict(zip(df.columns, wybor_zmiennych))
wybor_zmiennych_lista = list(wybor_zmiennych.keys())
wybor_zmiennych_lista.remove('Ind')
wybor_zmiennych_lista.remove('Miasto')
wybor_zmiennych_lista.remove('Firma')
wybor_zmiennych_lista.remove('Nazwa')
wybor_zmiennych_lista.remove('Miejsce w polsce')
wybor_zmiennych_lista.remove('Język polski')
wybor_zmiennych_lista.remove('Ocena obsługa')
wybor_zmiennych_lista.remove('Ocena klimat')
wybor_zmiennych_lista.remove('Średnia ocena')
wybor_zmiennych_lista.remove('Liczba ocen')

# df do wykresów
df_miasta = df['miasto'].value_counts().reset_index().sort_values(by='miasto').tail(11)

df_kategorie = df['kategoria'].value_counts().reset_index().sort_values(by='kategoria')

df_kategorie_02 = df[df['miasto'].isin(top12_miast)].\
    groupby(['miasto', 'kategoria'])['ind'].agg('count').reset_index().sort_values(by='ind')

df_trudnosci = df['poziom_trudnosci'].value_counts().reset_index().sort_values(by='poziom_trudnosci')

df_trudnosci_04 = df[df['kategoria'].isin(top3_kategorie)].\
    groupby(['kategoria', 'poziom_trudnosci'])['ind'].agg('count').reset_index().sort_values(by='ind').\
    append(pd.DataFrame([['Thriller', 'na pierwszy raz', 0]], columns=['kategoria', 'poziom_trudnosci', 'ind']))

df_trudnosci_05 = df['trudnosc_wg_graczy'].value_counts().reset_index()

df_trudnosci_06 = df[['poziom_trudnosci', 'trudnosc_wg_graczy']]
df_trudnosci_06['ones'] = [1 for x in range(len(df['poziom_trudnosci']))]
df_trudnosci_06 = pd.pivot_table(df_trudnosci_06,
                                 values = 'ones',
                                 index = 'poziom_trudnosci',
                                 columns = 'trudnosc_wg_graczy',
                                 aggfunc = 'count')
df_trudnosci_06 = df_trudnosci_06.reset_index().melt(id_vars = ['poziom_trudnosci'])

# df do sekcji z korelacjami
korelacje01 = df[['srednia_ocena', 'czas_gry', 'min_liczba_graczy', 'max_liczba_graczy', 'ocena_obsluga', 'ocena_klimat']]\
    .rename(columns = zmiana_etykiet).corr().reset_index().melt(id_vars = ['index'])

korelacje05 = df[['srednia_ocena'] + [colname for colname in df.columns if 'podstawowe_' in colname]]\
    .rename(columns = zmiana_etykiet).corr().reset_index().melt(id_vars = ['index'])

korelacje06 = df[['srednia_ocena'] + [colname for colname in df.columns if 'bezpieczeństwo_' in colname]]\
    .rename(columns = zmiana_etykiet).corr().reset_index().melt(id_vars = ['index'])

with st.sidebar:
    page = option_menu(
        'Projekt zaliczeniowy PAD',
        podstrony,
        menu_icon = '123',
        icons = ['arrow_right' for i in range(len(podstrony))]
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

    st.write('''Najwięcej ER znajduje się oczywiście w Warszawie, do top 3 miast trafiły jeszcze Poznań i Wrocław.
    W czołówce znalazł się też Kraków.''')

    fig00 = go.Figure()
    fig00.add_trace(go.Bar(y = df_miasta['index'], x = df_miasta['miasto'], orientation = 'h'))
    fig00.update_layout(title = 'Miasta z największą liczbą ER')
    st.plotly_chart(fig00, use_container_width = True)


    st.header('Najlepsze ER w Polsce')
    st.write('Wiele ER w Polsce może się pochwalić idealną oceną średnią odwiedzających. W poniższej tabeli znajduje się 15 z nich.')
    st.dataframe(df.sort_values(by = ['srednia_ocena'], ascending=False)\
                [['nazwa', 'firma', 'miasto', 'kategoria', 'poziom_trudnosci']]\
                .head(15)\
                .set_index(pd.Index(list(range(1,16))), drop=True)\
                .rename(columns = zmiana_etykiet))
    st.write('''Aktualny ranking można znaleźc na stronie https://lock.me/pl/polska/ranking-escape-room, 
             dlatego w tym projekcie skupmy się na tym, czego nie znajdziemy na lockme.pl :)''')
    st.write('Dane do tego projektu pobrane metodą web scrapingu w maju 2022 - od tamtego czasu oceny ER mogły się nieco zmienić.')
    st.write('''Co ciekawe, ranking nie jest układany jedynie na podstawie ocen:
    https://cyfrowa.rp.pl/biznes-ludzie-startupy/art36581091-algorytm-wskaze-najlepsze-pokoje-zagadek''')

if page == 'Kategorie ER':

    st.header('Kategorie ER')

    st.write(f'''Jak widać na polskim rynku escape roomów zdecydowanie przeważają pokoje z kategorii {df_kategorie["index"][0]},
    jest ich więcej niż kolejnych 3 kategorii ({df_kategorie["index"][1]}, {df_kategorie["index"][2]}, {df_kategorie["index"][3]}) łącznie!''')

    fig01 = go.Figure()
    fig01.add_trace(go.Bar(y = df_kategorie['index'], x = df_kategorie['kategoria'], orientation = 'h'))
    fig01.update_layout(title = 'Liczba ER w poszczególnych kategoriach')
    st.plotly_chart(fig01, use_container_width = True)

    st.write('''Co ciekawe nie we wszystkich miastach przeważają pokoje przygodowe. 
    W Katowicach większość ER należy do kategorii Fabularny, a w Gdyni przeważają pokoje z kategorii Thriller i Fantasy.
    Poniżej znajdują się wykresy dla 12 miast z największą liczbą ER.''')

    fig02 = make_subplots(rows=4, cols=3,
                          subplot_titles=top12_miast,
                          shared_xaxes=True)
    r = 1
    i = 0
    while r < 5:
        c = 1
        while c < 4:
            df_plot = df_kategorie_02[df_kategorie_02['miasto'] == top12_miast[i]]
            fig02.add_trace(go.Bar(x=df_plot['ind'], y=df_plot['kategoria'], orientation='h', showlegend=False),
                            col=c, row=r)
            c += 1
            i += 1
        r += 1
    fig02.update_layout(height = 1200,
                        title = 'Liczba ER w poszczególnych kategoriach dla najpopularniejszych miast')
    st.plotly_chart(fig02, use_container_width = True)

if page == 'Poziom trudności ER':

    st.header('Poziom trudności ER')

    st.write('''Poziom trudności ER ma rozkład bardzo symetryczny
    - najwięcej jest ER o średnim poziomie trudności''')

    fig03 = go.Figure()
    fig03.add_trace(go.Bar(x=df_trudnosci['index'], y=df_trudnosci['poziom_trudnosci'], orientation='v'))
    fig03.update_layout(xaxis={'categoryorder':'array',
                               'categoryarray':poziomy_trudnosci},
                        title = 'Poziom trudności ER wg. ich twórców')
    st.plotly_chart(fig03, use_container_width=True)

    st.write('Podobnie prezentuje się rozkład poziomu trudności w każdej kategorii, poniżej wykresy dla 3 najpopularniejszych.')

    fig04 = make_subplots(rows=1, cols=3,
                          subplot_titles=top3_kategorie,
                          shared_xaxes=True,
                          shared_yaxes=True)
    i = 0
    c = 1
    while c < 4:
        df_plot = df_trudnosci_04[df_trudnosci_04['kategoria'] == top3_kategorie[i]]
        fig04.add_trace(go.Bar(y=df_plot['ind'], x=df_plot['poziom_trudnosci'], orientation='v', showlegend=False),
                        col=c, row=1)
        c += 1
        i += 1
    fig04.update_layout(height = 400,
                        xaxis={'categoryorder': 'array',
                               'categoryarray': poziomy_trudnosci},
                        title='Poziom trudności ER wg. ich twórców dla najpopularniejszych kategorii')
    st.plotly_chart(fig04, use_container_width = True)

    st.write('Co ciekawe poziom trudności w ocenie graczy jest nieco inny - tutaj juz przeważają pokoje o poziomie Średnim i Trudnym')

    fig05 = go.Figure()
    fig05.add_trace(go.Bar(x=df_trudnosci_05['index'], y=df_trudnosci_05['trudnosc_wg_graczy'], orientation='v'))
    fig05.update_layout(xaxis={'categoryorder':'array',
                               'categoryarray':poziomy_trudnosci_wg_graczy},
                        title = 'Poziom trudności ER wg. graczy')
    st.plotly_chart(fig05, use_container_width=True)

    st.write('''Nasuwa się pytanie - które poziomy trudności są inaczej odbierane przez graczy niż wynikałoby to z opisu ER?
    Okazuje się, że ER na pierwszy raz i dla początkujących gracze oceniają jako nawet dwa poziomy trudniejsze niż twórcy,
    prawie połowa ER dla śr. zaawansowanych została przez graczy oceniona jako trudniejsze.
    Bardzo rzadko zdarza się, żeby ER został oceniony jako łatwiejszy.''')

    fig06 = go.Figure()
    fig06.add_trace(go.Heatmap(x=df_trudnosci_06['poziom_trudnosci'],
                               y=df_trudnosci_06['trudnosc_wg_graczy'],
                               z=df_trudnosci_06['value'],
                               colorscale=px.colors.sequential.OrRd))
    fig06.update_layout(xaxis={'categoryorder': 'array',
                               'categoryarray': poziomy_trudnosci},
                        yaxis={'categoryorder': 'array',
                               'categoryarray': poziomy_trudnosci_wg_graczy},
                        xaxis_title = 'Poziom trudności wg. twórców',
                        yaxis_title = 'Poziom trudności wg. graczy',
                        title = 'Zgodność w ocenie poziomu trudności ER miedzy twórcami a graczami')
    st.plotly_chart(fig06, use_container_width = True)

if page == 'Dodatkowe informacje o ER':

    st.header('Dodatkowe informacje o ER')

    st.write('''Dodatkowe informacje o ER obejmują 3 kategorie oznaczeń ER, które pomagają graczom podjąć dezycję o rezerwacji:
     podstawowe (np. czy pokój jest przyjazny dzieciom, czy jest klimatyzowany,
     bezpieczeństwo (np. czy w pokoju jest przycisk bezpieczeństwa, czy pokoje są dezynfekowane),
     dostępne języki.''')
    st.write('''Poczas eksploracji danych odrzucono z tej analizy oznaczenia, które pojawiały się w mniej niż 10% ER
     - zwykle były to oznaczenia, które pojawiły się tylko w pojedynczych ER 
     (np. język słowacki dostępny jedynie w pojedynczych ER przy granicy, pokoje eliminacyjne ER Champ to również jedynie kilka ER w Polsce).''')
    st.write('''Język polski jest dostępny we wszystkich ER, język angielski w 57%.
             Częstość występowania pozostałych oznaczeń została przedstawiona poniżej''')

    grupa_oznaczen = st.selectbox('Wybierz grupę oznaczeń', ('wszystkie', 'podstawowe', 'bezpieczeństwo'))

    if grupa_oznaczen == 'wszystkie':
        st.table(df_wazne_informacje.sort_values('wartosc', ascending = False)\
            [['Typ oznaczenia', 'Oznaczenie', 'Procent ER z oznaczeniem']])
    if grupa_oznaczen == 'podstawowe':
        st.table(df_wazne_informacje[df_wazne_informacje['Typ oznaczenia'] == 'podstawowe'].sort_values('wartosc', ascending=False)\
                 [['Typ oznaczenia', 'Oznaczenie', 'Procent ER z oznaczeniem']])
    if grupa_oznaczen == 'bezpieczeństwo':
        st.table(df_wazne_informacje[df_wazne_informacje['Typ oznaczenia'] == 'bezpieczeństwo'].sort_values('wartosc', ascending=False)\
                 [['Typ oznaczenia', 'Oznaczenie', 'Procent ER z oznaczeniem']])

if page == 'Średnia ocena':

    st.header('Średnia ocena')

    st.write('''Użytkownicy wystawiają raczej dobre oceny ER, rzadkością jest średnia ocena pokoju poniżej 6.
    Najczęściej ER uzyskują średnią ocenę użytkowników bliską 9 czy nawet 9.7''')

    fig07 = go.Figure()
    fig07.add_trace(go.Histogram(x=df['srednia_ocena'], nbinsx=100))
    fig07.update_layout(title = 'Rozkład średnich ocen ER')
    st.plotly_chart(fig07, use_container_width = True)

    st.write('A co ze średnią oceną za klimat i obsługę?')
    st.write('''Okazuje się, że średnie oceny za klimat oraz obsługę są nieco wyższe niż oceny ogólne,
    jednocześnie najniższe oceny za te dwa aspekty ER są niższe niż najniższa średnia ocena ogólna ER.
    W jednym przypadku średnia ocena za obsługę to tylko 2.3.
    Co ciekawe średnie oceny za obsługę mają nieco mniejszy rozrzut i są bardzo zbliżone do 9.7''')
    st.write('Podobne zależności można zaobserwować w poszczególnych miastach i kategoriach.')


    fig08 = go.Figure()
    fig08.add_trace(go.Box(y=df['srednia_ocena'], orientation='v', showlegend=False))
    fig08.add_trace(go.Box(y=df['ocena_klimat'], orientation='v', showlegend=False))
    fig08.add_trace(go.Box(y=df['ocena_obsluga'], orientation='v', showlegend=False))
    fig08.update_layout(xaxis = {'tickmode' : 'array',
                                 'tickvals' : ['trace 0', 'trace 1', 'trace 2'],
                                 'ticktext' : ['średnia', 'klimat', 'obsługa']},
                        title = 'Porównianie rozkładu średnich ocen ER oraz ocen za obsługę i ocen za klimat')
    st.plotly_chart(fig08, use_container_width=True)

if page == 'Korelacje między zmiennymi':

    st.header('Korelacje między zmiennymi')

    st.write('''Przyjrzyjmy się korelacjom pomiędzy poszczególnymi zmiennymi a średnią oceną ER.''')

    st.write('''Zacznijmy od ogólnych informacji o ER. Największa korelacja występuje tutaj z oceną wystawioną za klimat, 
    nieco niższa z oceną za obsługę. Co ciekawe oceny za klimat i za obsługę są między sobą średnio skorelowane. 
    Maksymalna i minimalna liczba graczy nie są skorelowane ze średnią oceną, zaś korelacja między czasem gry a średnią oceną jest mała.''')

    fig_korelacje01 = go.Figure()
    fig_korelacje01.add_trace(go.Heatmap(x=korelacje01['index'],
                               y=korelacje01['variable'],
                               z=korelacje01['value'],
                               colorscale=px.colors.sequential.OrRd))
    fig_korelacje01.update_layout(title = 'Korelacje pomiędzy podstawowymi zmiennymi opisującymi ER')
    st.plotly_chart(fig_korelacje01, use_container_width = True)

    st.write('''Nieco trudniej jest dokładnie przyjrzeć się zależnościom między zmiennymi kategorycznymi 
    (kategoria, poziom trudności) a średniej ocenie ER. Dla uproszczenia sięgamy po proste wykresy pudełkowe -
    wygląda na to, że średnia ocena dla poszczególnych kategorii jest raczej podobna.''')

    fig_korelacje02 = go.Figure()
    for kat in wszystkie_kategorie:
        fig_korelacje02.add_trace(go.Box(y=df[df['kategoria'] == kat]['srednia_ocena'], orientation='v', showlegend=False))
    fig_korelacje02.update_layout(xaxis = {'tickmode' : 'array',
                                           'tickvals' : [f'trace {n}' for n in range(len(wszystkie_kategorie))],
                                           'ticktext' : wszystkie_kategorie})
    fig_korelacje02.update_layout(title = 'Rozkład średnich ocen ER dla poszczególnych kategorii')
    st.plotly_chart(fig_korelacje02, use_container_width = True)

    fig_korelacje03 = go.Figure()
    for trud in poziomy_trudnosci:
        fig_korelacje03.add_trace(go.Box(y=df[df['poziom_trudnosci'] == trud]['srednia_ocena'], orientation='v', showlegend=False))
    fig_korelacje03.update_layout(xaxis = {'tickmode' : 'array',
                                           'tickvals' : [f'trace {n}' for n in range(len(poziomy_trudnosci))],
                                           'ticktext' : poziomy_trudnosci},
                                  title = 'Rozkład średnich ocen ER dla poszczególnych poziomów trudności')
    st.plotly_chart(fig_korelacje03, use_container_width = True)

    fig_korelacje04 = go.Figure()
    for trud in poziomy_trudnosci_wg_graczy:
        fig_korelacje04.add_trace(go.Box(y=df[df['trudnosc_wg_graczy'] == trud]['srednia_ocena'], orientation='v', showlegend=False))
    fig_korelacje04.update_layout(xaxis = {'tickmode' : 'array',
                                           'tickvals' : [f'trace {n}' for n in range(len(poziomy_trudnosci_wg_graczy))],
                                           'ticktext' : poziomy_trudnosci_wg_graczy},
                                  title = 'Rozkład średnich ocen ER dla poszczególnych poziomów trudności wg. graczy')
    st.plotly_chart(fig_korelacje04, use_container_width = True)

    st.write('''Korelacje między średnią oceną a zmiennymi z grupy podstawowych są ogólnie niewielkie,
    największa występuje z "Nie dla kobiet w ciąży", ale nawet w tym wypadku jest to jedynie 0.22.
    Ujemne korelacje wystąpiły jedynie z "Przyjazny dzieciom" i "Możliwość płatności kartą".''')
    st.write('''Warto natomiast zwrócić uwagę, na fakt, że niektóre zmienne z tej grupy są skorelowane między sobą,
    w szczególności "Przyjazny dzieciom" i "Od lat 16" (te dwie zmienne w pewnym sensie się wykluczają i warto wziąć to pod uwagę podczas prób modelowania),
    oraz oznaczenia dotyczące epilepsji, klaustrofobii, ciąży (warto rozważyć ich agregację).''')

    fig_korelacje05 = go.Figure()
    fig_korelacje05.add_trace(go.Heatmap(x=korelacje05['index'],
                               y=korelacje05['variable'],
                               z=korelacje05['value'],
                               colorscale=px.colors.sequential.OrRd))
    fig_korelacje05.update_layout(title = 'Korelacje pomiędzy średnią oceną a zmiennymi opisującymi ER',
                                  height = 500)
    st.plotly_chart(fig_korelacje05, use_container_width = True)

    st.write('''Podobnie w przypadku oznaczeń dotyczących bezpieczeństwa, korelacje ze średnią oceną są raczej małe,
    największa występuje dla "Dezynfekowane pokoje" i "Dostępny żel antybakteryjny".
    Natomiast jedyna zmienna, dla której korelacja ze średnią oceną jest ujemna to "Klucz bezpieczeństwa"''')
    st.write('''Podobnie jak w przypadku grupy oznaczeń podstawowych, tak i tutaj można pokusić się o agregację niektórych oznaczeń,
    które są ze sobą skorelowane, np. dotyczących dezynfekcji czy zabezpieczeń technicznych''')

    fig_korelacje06 = go.Figure()
    fig_korelacje06.add_trace(go.Heatmap(x=korelacje06['index'],
                               y=korelacje06['variable'],
                               z=korelacje06['value'],
                               colorscale=px.colors.sequential.OrRd))
    fig_korelacje06.update_layout(title = 'Korelacje pomiędzy średnią oceną a zmiennymi opisującymi bezpieczeństwo ER',
                                  height = 600)
    st.plotly_chart(fig_korelacje06, use_container_width = True)

if page == 'Predykcja średniej oceny - OLS':

    st.header('Predykcja średniej oceny - OLS')

    st.write('''Zmiennych, które możemy wziąć pod uwagę w tej analizie jest bardzo dużo, 
             większość z nich to zmienne kategorialne lub binarne.''')
    st.write('''Poniżej można sprawdzić jak różne zmienne pomagają lepiej (lub w niektórych przypadkach gorzej)
    dopasować model regresji liniowej do danych. 
    Zależnie od kombinacji zmiennych R-squared zdaje się jednak nie przekraczać 0.296.''')

    wybrane_zmienne = st.multiselect(label='Wybierz zmienne do uwzględnienia w modelu regresji liniowej:',
                                     options=wybor_zmiennych_lista,
                                     default=['Poziom trudności'])
    try:
        formula = 'srednia_ocena ~ ' + ' + '.join([wybor_zmiennych[key] for key in wybrane_zmienne])
        model = smf.ols(formula=formula, data=df).fit()
        st.write(model.summary())
    except:
        st.error('''Musisz wybrać przynajmniej jedną zmienną!''')