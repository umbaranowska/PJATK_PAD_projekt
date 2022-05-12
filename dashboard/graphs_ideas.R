library(tidyverse)
# library(shiny)

data = readr::read_csv("~/PJATK_PAD_projekt/data_exploration/data_clean.csv")%>%
  filter(poziom_trudnosci != 'brak informacji') %>%
  mutate(poziom_trudnosci = factor(poziom_trudnosci, 
                                   levels = c('na pierwszy raz',
                                              'początkujący',
                                              'śr. zaawansowani',
                                              'doświadczony',
                                              'eksperci')))
# brak informacji o poziomie trudności dla 1 escape roomu !

data %>%
  group_by(miasto) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  head(15) %>%
  ggplot(., aes(x = n, y = reorder(miasto, n))) +
  geom_bar(stat = 'identity') +
  theme_minimal() +
  xlab('liczba escape roomów') +
  ylab('miasto') +
  ggtitle('Miasta z największą liczbą escape roomów')
# miasta raczej na mapę niż słupkowy

data %>%
  group_by(kategoria) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  # head(10) %>%
  ggplot(., aes(x = n, y = reorder(kategoria, n))) +
  geom_bar(stat = 'identity') +
  theme_minimal() +
  xlab('liczba escape roomów') +
  ylab('kategoria') +
  ggtitle('Kategorie escape roomów')

data %>%
  group_by(poziom_trudnosci) %>%
  summarise(n = n())  %>%
  ggplot(., aes(x = poziom_trudnosci, y = n)) +
  geom_bar(stat = 'identity') +
  theme_minimal() +
  xlab('poziom trudności') +
  ylab('liczba escape roomóW') +
  ggtitle('Poziom trudności escape roomów')

for(kat in c('Przygodowy', 'Thriller', 'Fabularny', 'Kryminalny')){
  plot_data = data %>%
    filter(kategoria == kat) %>%
    group_by(kategoria, poziom_trudnosci) %>%
    summarise(n = n()) %>% 
    ungroup()
  if(!'na pierwszy raz' %in% plot_data$poziom_trudnosci){
    plot_data = plot_data %>%
      add_row(kategoria = kat, poziom_trudnosci = 'na pierwszy raz', n = 0)
  }
  if(!'początkujący' %in% plot_data$poziom_trudnosci){
    plot_data = plot_data %>%
      add_row(kategoria = kat, poziom_trudnosci = 'początkujący', n = 0)
  }
  if(!'śr. zaawansowani' %in% plot_data$poziom_trudnosci){
    plot_data = plot_data %>%
      add_row(kategoria = kat, poziom_trudnosci = 'śr. zaawansowani', n = 0)
  }
  if(!'doświadczony' %in% plot_data$poziom_trudnosci){
    plot_data = plot_data %>%
      add_row(kategoria = kat, poziom_trudnosci = 'doświadczony', n = 0)
  }
  if(!'eksperci' %in% plot_data$poziom_trudnosci){
    plot_data = plot_data %>%
      add_row(kategoria = kat, poziom_trudnosci = 'eksperci', n = 0)
  }
  plot_data = plot_data %>%
    mutate(poziom_trudnosci = factor(poziom_trudnosci, 
                                     levels = c('na pierwszy raz',
                                                'początkujący',
                                                'śr. zaawansowani',
                                                'doświadczony',
                                                'eksperci')))
  plot = ggplot(plot_data, aes(x = poziom_trudnosci, y = n)) +
    geom_bar(stat = 'identity') +
    theme_minimal() +
    xlab('liczba escape roomów') +
    ylab('kategoria') +
    ggtitle(paste0('Poziom trudności wg. kategorii ', kat))
  print(plot)
}

data %>%
  group_by(miasto, kategoria) %>%
  filter(miasto %in% c('Warszawa', 'Poznań', 'Wrocław',
                       'Kraków', 'Bydgoszcz', 'Gdańsk')) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  # head(10) %>%
  ggplot(., aes(x = n, y = reorder(kategoria, n))) +
  geom_bar(stat = 'identity') +
  theme_minimal() +
  xlab('liczba escape roomów') +
  ylab('kategoria') +
  ggtitle('Popularne kategorie w 6 najpopularniejszych miastach') +
  facet_wrap(~miasto, ncol=2)

