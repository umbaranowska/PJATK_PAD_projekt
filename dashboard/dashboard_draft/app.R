library(shiny)
library(tidyverse)
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

data = readr::read_csv("~/PJATK_PAD_projekt/data_exploration/data_clean.csv")%>%
  filter(poziom_trudnosci != 'brak informacji') %>%
  mutate(poziom_trudnosci = factor(poziom_trudnosci, 
                                   levels = c('na pierwszy raz',
                                              'początkujący',
                                              'śr. zaawansowani',
                                              'doświadczony',
                                              'eksperci')))

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
        conditionalPanel(
          condition = "input.page1_miasto == 'cała Polska'",
          column(width = 6, plotlyOutput('out01_default')),
          column(width = 6, tableOutput('out02_default'))
        ),
        conditionalPanel(
          condition = "input.page1_miasto != 'cała Polska'",
          column(width = 6, plotlyOutput('out01')),
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
      'w tej sekcji będzie mapa na której wielkość bąbla oddaje liczbę ER;
      docelowo po najechaniu na mapę będzie się pokazywać ile dokładnie;
      można wybrać miasto - wtedy się podświetli kolorem a tabela pokaże tylko top ER w tym mieście,
      pod spodem krótki opis'
    )
  )
  output$page2_text = renderText(
    glue(
      'w tej sekcji będzie prosty wykres z liczbą ER per kategoria, opis 
      + możliwość porównania najpopularniejszych kategorii w max. 3 miastach'
    )
  )
  output$page3_text = renderText(
    glue(
      'w tej sekcji będzie prosty wykres z liczbą ER per poziom trudności, opis 
      + możliwość porównania poziomu trudności w max. 3 kategoriach'
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
  output$out01 = renderPlotly({
    ggplotly(
      data %>%
        group_by(miasto) %>%
        filter(miasto == input$page1_miasto) %>%
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
        xlab('liczba escape roomów') +
        ggtitle(reactive_dataout6_1()$kategoria[1]) +
        ylim(0,reactive_dataout6_maxx()*1.15)
    )
  )
  output$out06_2 = renderPlotly(
    ggplotly(
      reactive_dataout6_2() %>%
        poziom_trudnosci_pad() %>%
        ggplot(., aes(x = poziom_trudnosci, y = n)) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        xlab('liczba escape roomów') +
        ggtitle(reactive_dataout6_2()$kategoria[1]) +
      ylim(0,reactive_dataout6_maxx()*1.15)
    )
    )
  
  output$out06_3 = renderPlotly(
    ggplotly(
      reactive_dataout6_3() %>%
        poziom_trudnosci_pad() %>%
        ggplot(., aes(x = poziom_trudnosci, y = n)) +
        geom_bar(stat = 'identity') +
        theme_minimal() +
        xlab('liczba escape roomów') +
        ggtitle(reactive_dataout6_3()$kategoria[1]) +
        ylim(0,reactive_dataout6_maxx()*1.15)
    )
    )
}

# Run the application 
shinyApp(ui = ui, server = server)
