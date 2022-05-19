library(shiny)
library(tidyverse)
library(ggcorrplot)
library(plotly)
library(glue)

poziom_trudnosci_pad = function(plot_data){
  kat = unique(plot_data$kategoria)[1]
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
  return(plot_data)
}

data = readr::read_csv("data_clean.csv") %>%
  filter(poziom_trudnosci != 'brak informacji') %>%
  filter(języki_polski != 0) %>%
  mutate(poziom_trudnosci = factor(poziom_trudnosci, 
                                   levels = c('na pierwszy raz',
                                              'początkujący',
                                              'śr. zaawansowani',
                                              'doświadczony',
                                              'eksperci')))

wazne_informacje_procent = readRDS('wazne_informacje_procent.RDS')

##### UI #######################################################################
################################################################################
ui <- fluidPage(
  tabsetPanel(
    tabPanel(
      title = "Mapa + top ER",
      fluidRow(
        textOutput('intro_text'),
        textOutput('page1_text')
      ),
      fluidRow(
        selectInput(inputId = 'page1_miasto',
                    label = 'wybierz miasto',
                    choices = c(sort(unique(data$miasto)), 'cała Polska'),
                    selected = 'cała Polska')
      ),
      fluidRow(
        column(width = 6, plotlyOutput('out01_default')),
        conditionalPanel(
          condition = "input.page1_miasto == 'cała Polska'",
          column(width = 6, tableOutput('out02_default'))
        ),
        conditionalPanel(
          condition = "input.page1_miasto != 'cała Polska'",
          column(width = 6, tableOutput('out02'))
        )
      )
    ),
    
    tabPanel(
      title = 'kategorie',
      fluidRow(
        column(width = 6, plotlyOutput('out03')),
        column(width = 6, textOutput('page2_text'))
      ),
      fluidRow(
        column(width = 9,
               selectizeInput(
                 "page2_miasta",
                 label = "Wybierz max. 3 miasta do porównania",
                 choices = c(sort(unique(data$miasto))),
                 multiple = TRUE,
                 options = list(maxItems = 3)
               ),
               column(width = 4, plotlyOutput('out04_1')),
               column(width = 4, plotlyOutput('out04_2')),
               column(width = 4, plotlyOutput('out04_3'))
        )
      )
    ),
    
    tabPanel(
      title = 'poziom trudności',
      fluidRow(
        column(width = 6, plotlyOutput('out05')),
        column(width = 6, textOutput('page3_text'))
      ),
      fluidRow(
        column(width = 9,
               selectizeInput(
                 "page3_kategorie",
                 label = "Wybierz max. 3 kategorie do porównania",
                 choices = c(sort(unique(data$kategoria))),
                 multiple = TRUE,
                 options = list(maxItems = 3)
               ),
               column(width = 4, plotlyOutput('out06_1')),
               column(width = 4, plotlyOutput('out06_2')),
               column(width = 4, plotlyOutput('out06_3'))
        )
      )
    ),
    tabPanel(
      title = 'ważne informacje',
      fluidRow(textOutput('page4_text')),
      fluidRow(tableOutput('wazne_informacje'))
    ),
    tabPanel(
      title = 'średnia ocena',
      fluidRow(
        column(width = 6, plotlyOutput('out07', height = 750)),
        column(width = 6, textOutput('page5_text'))
      ),
      fluidRow(
        plotlyOutput('out07_1', height = 600),
        plotlyOutput('out07_2', height = 600)
      )
    ),
    tabPanel(
      title = 'korelacje',
      fluidRow(
        plotlyOutput('corr_podstawowe', height = 800)
      ),
      fluidRow(
        plotlyOutput('corr_bezpieczenstwo', height = 800)
      )
    )
  )
)

##### SERVER ###################################################################
################################################################################
server <- function(input, output) {
  
  output$intro_text = renderText(
    glue(
      'na samej górze pojawi się piękny opis projektu - cel, sposób zbierania danych, wielkość zbioru 
      (tutaj jest 458 ER, możliwe że jeszcze jakieś pojedyncze będą odrzucone), itp. +
      repozytorium z całym kodem dostępne tutaj: https://github.com/umbaranowska/PJATK_PAD_projekt'
    )
  )
  output$page1_text = renderText(
    glue(
      'w tej sekcji docelowo zamiast słupków będzie mapa na której wielkość bąbla oddaje liczbę ER;
       po najechaniu na mapę będzie się pokazywać ile dokładnie;
      można wybrać miasto - wtedy się podświetli kolorem a tabela pokaże tylko top ER w tym mieście,
      pod spodem krótki opis'
    )
  )
  output$page2_text = renderText(
    glue(
      'w tej sekcji będzie prosty wykres z liczbą ER per kategoria, opis 
      + możliwość porównania najpopularniejszych kategorii w miastach'
    )
  )
  output$page3_text = renderText(
    glue(
      'w tej sekcji będzie prosty wykres z liczbą ER per poziom trudności, opis 
      + możliwość porównania poziomu trudności w kategoriach'
    )
  )
  output$page4_text = renderText(
    glue(
      'tabelka z % er w których są dane oznaczenia'
    )
  )
  output$page5_text = renderText(
    glue(
      'w tej sekcji będzie pokazany rozkład ocen ogólnie, dla 6 największych miast
      i dla 6 najpopularniejszych kategorii'
    )
  )
  
  # miasta wg. liczności ER
  output$out01_default = renderPlotly({
    ggplotly(
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
    )
  })
  # output$out01 = renderPlotly({
  #   ggplotly(
  #     data %>%
  #       group_by(miasto) %>%
  #       filter(miasto == input$page1_miasto) %>%
  #       summarise(n = n()) %>%
  #       arrange(desc(n)) %>%
  #       head(15) %>%
  #       ggplot(., aes(x = n, y = reorder(miasto, n))) +
  #       geom_bar(stat = 'identity') +
  #       theme_minimal() +
  #       xlab('liczba escape roomów') +
  #       ylab('miasto') +
  #       ggtitle('Miasta z największą liczbą escape roomów')
  #   )
  # })
  
  # tabela top ER
  output$out02_default = renderTable({
    data %>%
      arrange(desc(srednia_ocena)) %>%
      select(nazwa, firma, miasto, kategoria, poziom_trudnosci, srednia_ocena) %>%
      head(10)
  })
  output$out02 = renderTable({
    data %>%
      filter(miasto == input$page1_miasto) %>%
      arrange(desc(srednia_ocena)) %>%
      select(nazwa, firma, miasto, kategoria, poziom_trudnosci, srednia_ocena) %>%
      head(10)
  })
  
  # kategorie
  
  output$out03 = renderPlotly(
    ggplotly(
      data %>%
        group_by(kategoria) %>%
        summarise(n = n()) %>%
        arrange(desc(n)) %>%
        ggplot(., aes(x = n, y = reorder(kategoria, n))) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        xlab('liczba escape roomów') +
        ylab('kategoria') +
        ggtitle('Kategorie escape roomów')
    )
  )
  
  reactive_dataout4_1 = reactiveVal(NULL)
  reactive_dataout4_2 = reactiveVal(NULL)
  reactive_dataout4_3 = reactiveVal(NULL)
  reactive_dataout4_maxx = reactiveVal(nullfile())
  observeEvent(input$page2_miasta,
               {dataout4 = data %>%
                 filter(miasto %in% input$page2_miasta) %>%
                 group_by(miasto, kategoria) %>%
                 summarise(n = n()) %>%
                 ungroup()
               reactive_dataout4_maxx(max(dataout4$n))
               dataout4 = dataout4 %>%
                 group_by(miasto) %>%
                 group_split()
                 reactive_dataout4_1(dataout4[[1]])
                 if(length(input$page2_miasta) > 1){
                   reactive_dataout4_2(dataout4[[2]])
                 }
                 if(length(input$page2_miasta) > 2){
                   reactive_dataout4_3(dataout4[[3]])
                 }}
  )
  output$out04_1 = renderPlotly(
    ggplotly(
      reactive_dataout4_1() %>%
        arrange(desc(n)) %>%
        head(3) %>%
        ungroup() %>%
        ggplot(., aes(x = n, y = reorder(kategoria, n))) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        xlab('liczba escape roomów') +
        ylab('kategoria') +
        ggtitle(unique(reactive_dataout4_1()$miasto)[1]) +
        xlim(0,reactive_dataout4_maxx()*1.25)
    )
  )
  output$out04_2 = renderPlotly(
    ggplotly(
      reactive_dataout4_2() %>%
        arrange(desc(n)) %>%
        head(3) %>%
        ungroup() %>%
        ggplot(., aes(x = n, y = reorder(kategoria, n))) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        xlab('liczba escape roomów') +
        ylab('kategoria') +
        ggtitle(unique(reactive_dataout4_2()$miasto)[1]) +
        xlim(0,reactive_dataout4_maxx()*1.25)
    )
  )
  output$out04_3 = renderPlotly(
    ggplotly(
      reactive_dataout4_3() %>%
        arrange(desc(n)) %>%
        head(3) %>%
        ungroup() %>%
        ggplot(., aes(x = n, y = reorder(kategoria, n))) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        xlab('liczba escape roomów') +
        ylab('kategoria') +
        ggtitle(unique(reactive_dataout4_3()$miasto)[1]) +
        xlim(0,reactive_dataout4_maxx()*1.25)
    )
  )
  
  # poziom trudności
  
  output$out05 = renderPlotly(
    ggplotly(
      data %>%
        group_by(poziom_trudnosci) %>%
        summarise(n = n())  %>%
        ggplot(., aes(x = poziom_trudnosci, y = n)) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        xlab('poziom trudności') +
        ylab('liczba escape roomóW') +
        ggtitle('Poziom trudności escape roomów')
    )
  )
  
  reactive_dataout6_1 = reactiveVal(NULL)
  reactive_dataout6_2 = reactiveVal(NULL)
  reactive_dataout6_3 = reactiveVal(NULL)
  reactive_dataout6_maxx = reactiveVal(nullfile())
  observeEvent(input$page3_kategorie,
               {dataout6 = data %>%
                 filter(kategoria %in% input$page3_kategorie) %>%
                 group_by(kategoria, poziom_trudnosci) %>%
                 summarise(n = n()) %>%
                 ungroup()
               reactive_dataout6_maxx(max(dataout6$n))
               dataout6 = dataout6 %>%
                 group_by(kategoria) %>%
                 group_split()
               reactive_dataout6_1(dataout6[[1]])
               if(length(input$page3_kategorie) > 1){
                 reactive_dataout6_2(dataout6[[2]])
               }
               if(length(input$page3_kategorie) > 2){
                 reactive_dataout6_3(dataout6[[3]])
               }}
  )
  output$out06_1 = renderPlotly(
    ggplotly(
      reactive_dataout6_1() %>%
        poziom_trudnosci_pad() %>%
        ggplot(., aes(x = poziom_trudnosci, y = n)) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        ggtitle(reactive_dataout6_1()$kategoria[1]) +
        ylim(0,reactive_dataout6_maxx()*1.15) + 
        theme(axis.text.x = element_text(angle = 30, vjust = 0.5, hjust=1))
    )
  )
  output$out06_2 = renderPlotly(
    ggplotly(
      reactive_dataout6_2() %>%
        poziom_trudnosci_pad() %>%
        ggplot(., aes(x = poziom_trudnosci, y = n)) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        ggtitle(reactive_dataout6_2()$kategoria[1]) +
      ylim(0,reactive_dataout6_maxx()*1.15) + 
        theme(axis.text.x = element_text(angle = 30, vjust = 0.5, hjust=1))
    )
    )
  
  output$out06_3 = renderPlotly(
    ggplotly(
      reactive_dataout6_3() %>%
        poziom_trudnosci_pad() %>%
        ggplot(., aes(x = poziom_trudnosci, y = n)) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        ggtitle(reactive_dataout6_3()$kategoria[1]) +
        ylim(0,reactive_dataout6_maxx()*1.15) + 
        theme(axis.text.x = element_text(angle = 30, vjust = 0.5, hjust=1))
    )
    )
  
  output$out07 = renderPlotly(
    ggplotly(
      data %>%
        select(srednia_ocena, ocena_obsluga, ocena_klimat) %>%
        pivot_longer(everything()) %>%
        mutate(name = factor(name,
                             levels = c('srednia_ocena', 'ocena_obsluga', 'ocena_klimat'))) %>%
        ggplot(., aes(x = name, y = value, color = name)) +
        geom_boxplot() +
        ggtitle('Rozkład średnich ocen escape roomów') +
        theme(
          legend.position = 'none',
          axis.title = element_blank()
        ) +
        scale_color_manual(values = c('srednia_ocena' = 'red'))
    )
  )
  
  output$out07_1 = renderPlotly(
    ggplotly(
      data %>%
        select(miasto, srednia_ocena, ocena_obsluga, ocena_klimat) %>%
        filter(miasto %in% c('Warszawa', 'Poznań', 'Wrocław',
                             'Kraków', 'Bydgoszcz', 'Gdańsk')) %>%
        pivot_longer(c(srednia_ocena, ocena_obsluga, ocena_klimat)) %>%
        mutate(name = factor(name,
                             levels = c('srednia_ocena', 'ocena_obsluga', 'ocena_klimat'))) %>%
        ggplot(., aes(x = name, y = value, color = name)) +
        geom_boxplot() +
        ggtitle('Rozkład średnich ocen escape roomów - 6 najpopularniejszych miast') +
        theme(
          legend.position = 'none',
          axis.title = element_blank()
        ) +
        scale_color_manual(values = c('srednia_ocena' = 'red')) +
        facet_wrap(~miasto, ncol = 3)
    )
  )
  
  output$out07_2 = renderPlotly(
    ggplotly(
      data %>%
        select(kategoria, srednia_ocena, ocena_obsluga, ocena_klimat) %>%
        filter(kategoria %in% c('Przygodowy', 'Thriller', 'Fabularny',
                                'Kryminalny', 'Fantasy', 'Horror')) %>%
        pivot_longer(c(srednia_ocena, ocena_obsluga, ocena_klimat)) %>%
        mutate(name = factor(name,
                             levels = c('srednia_ocena', 'ocena_obsluga', 'ocena_klimat'))) %>%
        ggplot(., aes(x = name, y = value, color = name)) +
        geom_boxplot() +
        ggtitle('Rozkład średnich ocen escape roomów - 6 najpopularniejszych kategorii') +
        theme(
          legend.position = 'none',
          axis.title = element_blank()
        ) +
        scale_color_manual(values = c('srednia_ocena' = 'red')) +
        facet_wrap(~kategoria, ncol = 3)
    )
  )
  
  output$wazne_informacje = renderTable({
    wazne_informacje_procent %>%
      arrange(desc(wartosc)) %>%
      mutate(wartosc = paste0(round(wartosc, 2), '%')) %>%
      select(subgroup, wartosc, zmienna) %>%
      rename(procent_er = wartosc) 
    })
  
  output$corr_bezpieczenstwo = renderPlotly({
    data %>% 
      select(starts_with('bezpieczeństwo_')) %>%
      rename_with(~str_remove(., 'bezpieczeństwo_')) %>%
      DescTools::PairApply(., DescTools::CramerV) %>%
      ggcorrplot::ggcorrplot(type = 'upper', lab = TRUE, show.legend = FALSE) %>%
      plotly::ggplotly()
  })
  
  output$corr_podstawowe = renderPlotly({
    data %>% 
      select(starts_with('podstawowe_')) %>%
      rename_with(~str_remove(., 'podstawowe_')) %>%
      DescTools::PairApply(., DescTools::CramerV) %>%
      ggcorrplot::ggcorrplot(type = 'upper', lab = TRUE, show.legend = FALSE) %>%
      plotly::ggplotly()
  })
}

# Run the application 
shinyApp(ui = ui, server = server)






# ##### dodatkowo - kod do stworzenia df z informacją jaki % er zawiera ważne informacje
# empty_df = data.frame(matrix(ncol = 3, nrow = 0))
# colnames(empty_df) = c('zmienna', 'wartosc', 'subgroup')
# for(i in c('podstawowe', 'bezpieczeństwo', 'języki')){
#   df = data %>%
#     select(contains(i)) %>%
#     summarise_all(~sum(.x)/nrow(data)*100)
#   colnames(df) = str_remove_all(colnames(df), paste0(i, '_'))
#   df = df %>% t() %>% data.frame()
#   colnames(df) = c('wartosc')
#   df$zmienna = rownames(df)
#   df = df %>% select(zmienna, wartosc) %>%
#     mutate(subgroup = i)
#   empty_df = empty_df %>% rbind(df)
# }
# rownames(empty_df) = seq(nrow(empty_df))
# saveRDS(empty_df, 'wazne_informacje_procent.RDS')