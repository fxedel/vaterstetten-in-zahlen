library(readr)
library(dplyr)
library(tidyr)
library(scales)

einwohnerZahlLkEbe <- 144091 # as of 2020-12-31, Bayerisches Landesamt für Statistik
buergerAb80LkEbe <- 9430 # as of 2021-01-08

impfungenRaw <- read_delim(
  file = "data/corona-impfungen/impfungenLandkreis.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    erstimpfungenAb80 = col_integer(),
    zweitimpfungenAb80 = col_integer(),
    registriert = col_integer()
  )
)

arcgisImpfungenRaw <- read_delim(
  file = "data/corona-impfungen/arcgisImpfungen.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    drittimpfungen = col_integer(),
    impfdosen = col_integer(),
    impfdosenNeu = col_integer()
  )
)

impfungenMerged <- bind_rows(
  impfungenRaw %>%
    filter(datum < min(arcgisImpfungenRaw$datum)) %>%
    transmute(
      datum,
      erstimpfungen,
      zweitimpfungen,
      drittimpfungen = 0,
      impfdosen = erstimpfungen + zweitimpfungen
    ),
  arcgisImpfungenRaw %>%
    transmute(
      datum,
      erstimpfungen,
      zweitimpfungen,
      drittimpfungen,
      impfdosen
    )
) %>%
  complete(datum = seq(min(datum), max(datum), "days"), fill = list()) %>%
  mutate(
    impfdosen7tageMittel = (impfdosen - lag(impfdosen, 7)) / 7,
    impfidenz = (impfdosen - lag(impfdosen, 7)) / einwohnerZahlLkEbe * 100000
  ) %>%
  mutate(
    impfdosenFilled = impfdosen,
    impfdosenLast = lag(impfdosen)
  ) %>%
  fill(impfdosenFilled, .direction = "up") %>%
  fill(impfdosenLast, .direction = "down") %>%
  add_count(impfdosenFilled, impfdosenLast, name = "impfdosenDays") %>%
  mutate(
    impfdosenNeuProTag = (impfdosenFilled - impfdosenLast) / impfdosenDays,
    impfdosenFilled = NULL,
    impfdosenLast = NULL,
    impfdosenDays = NULL
  )


personenNachStatus <- impfungenMerged %>%
  transmute(
    datum = datum,
    erst = erstimpfungen,
    zweit = zweitimpfungen,
    dritt = drittimpfungen
  ) %>%
  pivot_longer(
    cols = c(erst, zweit, dritt),
    names_to = "status",
    names_ptypes = list(status = factor(levels = c("erst", "zweit", "dritt")))
  ) %>%
  filter(!is.na(value))

arcgisImpfungenNachEinrichtungRaw <- read_delim(
  file = "data/corona-impfungen/arcgisImpfungenNachEinrichtung.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    einrichtung = readr::col_factor(levels = c("Impfzentrum", "Praxis", "Kreisklinik")),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    drittimpfungen = col_integer(),
    impfdosen = col_integer()
  )
)
arcgisImpfungenNachEinrichtung <- arcgisImpfungenNachEinrichtungRaw %>%
  group_by(einrichtung) %>%
  complete(datum = seq(min(arcgisImpfungenNachEinrichtungRaw$datum), max(arcgisImpfungenNachEinrichtungRaw$datum), "days"), fill = list()) %>%
  fill(erstimpfungen, zweitimpfungen, drittimpfungen, impfdosen, .direction = "down") %>%
  mutate(
    impfdosenNeu = impfdosen - lag(impfdosen)
  )

maxDatum = max(impfungenMerged$datum, arcgisImpfungenNachEinrichtung$datum)
minDatum = min(impfungenMerged$datum, arcgisImpfungenNachEinrichtung$datum)

ui <- function(request, id) {
  ns <- NS(id)
  tagList(
    h2("Corona-Impfungen im Landkreis Ebersberg"),

    fluidRow(
      valueBoxOutput(ns("valueBox1")),
      valueBoxOutput(ns("valueBox2")),
      valueBoxOutput(ns("valueBox3"))
    ),

    flowLayout(
      dateRangeInput(ns("dateRange"),
        label = NULL,
        start = maxDatum - 90,
        end = maxDatum,
        min = minDatum,
        max = maxDatum,
        format = "d. M yyyy",
        weekstart = 1,
        language = "de",
        separator = "bis"
      ),
      checkboxInput(ns("showNumbers"),
        label = "Zahlenwerte anzeigen",
        value = FALSE
      )
    ),

    fluidRow(
      box(
        title = "Geimpfte Personen",
        plotlyOutput(ns("geimpftePlotly"), height = 350),
        textOutput(ns("geimpfteText"))
      ),
      box(
        title = "7-Tage-Impfidenz",
        plotlyOutput(ns("impfidenzPlotly"), height = 350),
        textOutput(ns("impfidenzText"))
      ),
    ),

    fluidRow(
      box(
        title = "Verabreichte Impfdosen pro Tag",
        plotOutput(ns("impfdosenProTagPlot"), height = 300),
        textOutput(ns("impfdosenProTagText"))
      ),
      box(
        title = "Verabreichte Impfdosen pro Tag nach Einrichtung",
        plotOutput(ns("impfdosenProTagNachEinrichtungPlot"), height = 300),
        textOutput(ns("impfdosenProTagNachEinrichtungText"))
      ),
    ),

    fluidRow(
      box(
        title = "Geimpfte Über-80-Jährige (Erst-/Zweitgeimpfte)",
        plotOutput(ns("geimpfte80"), height = 300),
        textOutput(ns("geimpfte80Text"))
      ),
      box(
        title = "Verabreichte Impfdosen insgesamt",
        plotlyOutput(ns("impfdosenPlotly"), height = 350),
        textOutput(ns("impfdosenText"))
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage und Methodik",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage ist seit dem 21. April 2021 die <a href=\"https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services\">ArcGIS-API</a>, die für das <a href=\"https://experience.arcgis.com/experience/dc7f97a7874b47aebf1a75e74749c047\">COVID-19 Dashboard Ebersberg</a> verwendet wird. Diese Daten stammen vom Landratsamt Ebersberg, welches wiederum die Daten von Impfzentrum, Arztpraxen und Kreisklinik bereitstellt. Die Daten werden automatisch abgerufen und dargestellt. Werden auf dieser Seite offensichtlich falsche Daten (z.&nbsp;B. negative Zahl an verabreichter Impfdosen) angezeigt, liegt dies häufig an fehlerhaften Originaldaten, die automatisch verwendet werden.")),
          p(HTML("Zuvor wurden die Daten der Homepage des <a href = \"https://lra-ebe.de/\">Landratsamts Ebersberg</a> (<a href=\"https://lra-ebe.de/aktuelles/aktuelle-meldungen/\">Aktuelle Pressemeldungen</a>, <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/\">Corona-Pressearchiv</a>) sowie der Seite des <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/\">Impfzentrums Ebersberg</a> entnommen. Diese Daten wurden vorrangig händisch und teils auch automatisiert bis zum 13. Juli 2021 gesammelt; diese Daten werden jedoch zugunst der ArcGIS-Daten nur bis zum 20. April 2021 verwendet.")),
        ),
      ),
    ),
  )
}


# Define the server logic for a module
server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      getDateScale <- function() {
        list(
          scale_x_date(
            name = NULL,
            breaks = breaks_pretty(8),
            date_minor_breaks = "1 days",
            date_labels = "%-d.%-m.",
            expand = expansion(add = c(0.5, 1))
          ),
          coord_cartesian(xlim = c(input$dateRange[1], input$dateRange[2]))
        )
      }

      getYScale <- function() {
        scale_y_continuous(
          name = NULL,
          breaks = breaks_pretty(5),
          expand = expansion(mult = c(0.02, 0.1)),
          labels = number_format()
        )
      }

      output$valueBox1 <- renderValueBox({
        lastRow <- impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        valueBox(
          paste0(format(round(lastRow$erstimpfungen / einwohnerZahlLkEbe * 100, 1), nsmall = 1, decimal.mark = ",", big.mark = "."), "%"),
          paste0("Erstimpfquote (absolut: ", lastRow$erstimpfungen, ")"),
          color = "purple",
          icon = icon("star-half-alt")
        )
      })

      output$valueBox2 <- renderValueBox({
        lastRow <- impfungenMerged %>% filter(!is.na(zweitimpfungen)) %>% slice_tail()
        valueBox(
          paste0(format(round(lastRow$zweitimpfungen / einwohnerZahlLkEbe * 100, 1), nsmall = 1, decimal.mark = ",", big.mark = "."), "%"),
          paste0("Zweitimpfquote (absolut: ", lastRow$zweitimpfungen, ")"),
          color = "purple",
          icon = icon("star")
        )
      })

      output$valueBox3 <- renderValueBox({
        lastRow <- impfungenMerged %>% filter(!is.na(impfidenz)) %>% slice_tail()
        valueBox(
          format(round(lastRow$impfidenz, 1), nsmall = 1, decimal.mark = ",", big.mark = "."),
          paste0("7-Tage-Impfidenz (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")"),
          color = "purple",
          icon = icon("tachometer-alt")
        )
      })

      output$geimpftePlotly = renderPlotly({
        plot_ly(impfungenMerged, x = ~datum, size = I(8), yhoverformat = ",d") %>%
          add_trace(y = ~erstimpfungen, type = "scatter", mode = "lines", fill = 'tozeroy', color = I("#0088dd"), fillcolor = "#0088dd33", name = "Erstimpfungen") %>%
          add_trace(y = ~zweitimpfungen, type = "scatter", mode = "lines", fill = 'tozeroy', color = I("#0088dd"), fillcolor = "#0088dd80", name = "Zweitimpfungen") %>%
          add_trace(y = ~drittimpfungen, type = "scatter", mode = "lines", fill = 'tozeroy', color = I("#0088dd"), fillcolor = "#0088ddff", name = "Drittimpfungen") %>%
          plotly_default_config() %>%
          plotly_time_range(input) %>%
          plotly_hide_axis_titles()
      })

      output$geimpfteText <- renderText({
        lastRow <- impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        paste0("Aktuell (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") haben ", format(lastRow$erstimpfungen, decimal.mark = ",", big.mark = "."), " Menschen mindestens eine Erstimpfung erhalten, davon ", format(lastRow$zweitimpfungen, decimal.mark = ",", big.mark = "."), " auch schon eine Zweitimpfung.")
      })

      output$geimpfte80 <- renderPlot({
        dataErst <- filter(impfungenRaw, !is.na(erstimpfungenAb80))
        dataZweit <- filter(impfungenRaw, !is.na(zweitimpfungenAb80))
        ggplot(mapping = aes(x = datum)) + list(
          geom_area(aes(y = erstimpfungenAb80), dataErst, alpha = 0.2, fill = "#ff6600", color = "#ff6600"),
          geom_point(aes(y = erstimpfungenAb80), dataErst, alpha = 0.5, size = 1, color = "#ff6600"),
          geom_area(aes(y = zweitimpfungenAb80), dataZweit, alpha = 0.4, fill = "#ff6600", color = "#ff6600"),
          geom_point(aes(y = zweitimpfungenAb80), dataZweit, alpha = 0.5, size = 1, color = "#ff6600"),
          if (input$showNumbers) list(
            geom_text(aes(y = erstimpfungenAb80, label = erstimpfungenAb80), dataErst, vjust = "bottom", hjust = "middle", nudge_y = 150, check_overlap = TRUE, size = 3.4, color = "#963c00"),
            geom_text(aes(y = zweitimpfungenAb80, label = zweitimpfungenAb80), dataZweit, vjust = "bottom", hjust = "middle", nudge_y = 150, check_overlap = TRUE, size = 3.4, color = "#963c00")
          ) else list(),
          geom_hline(yintercept = buergerAb80LkEbe, linetype = "dashed", color = "#ff3300", size = 0.6),
          annotate("label", x = input$dateRange[1] + 1, y = buergerAb80LkEbe, label = paste(buergerAb80LkEbe, "Ü80-Landkreisbürger*innen"), vjust = "middle", hjust = "left", size = 3, fill = "#ff3300", color = "#ffffff", fontface = "bold"),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
      output$geimpfte80Text <- renderText({
        lastRow <- impfungenRaw %>% filter(!is.na(erstimpfungenAb80)) %>% slice_tail()
        paste0("Aktuell (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") haben ", format(lastRow$erstimpfungenAb80, decimal.mark = ",", big.mark = "."), " der ca. ", format(buergerAb80LkEbe, decimal.mark = ",", big.mark = ".") ," Landkreisbürger*innen ab 80 Jahren mindestens eine Erstimpfung erhalten, davon ", format(lastRow$zweitimpfungenAb80, decimal.mark = ",", big.mark = "."), " auch schon eine Zweitimpfung.")
      })

      output$impfdosenPlotly <- renderPlotly({
        plot_ly(filter(impfungenMerged, !is.na(impfdosen)), x = ~datum) %>%
          add_trace(y = ~impfdosen, type = "scatter", mode = "lines", name = "Impfdosen", size = I(2), yhoverformat = ",d") %>%
          plotly_default_config() %>%
          plotly_time_range(input) %>%
          plotly_hide_axis_titles()
      })
      output$impfdosenText <- renderText({
        lastRow <- impfungenMerged %>% filter(!is.na(impfdosen)) %>% slice_tail()
        paste0("Bislang (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden im Landkreis Ebersberg ", format(lastRow$impfdosen, decimal.mark = ",", big.mark = "."), " Impfdosen verabreicht.")
      })

      output$impfidenzPlotly <- renderPlotly({
        plot_ly(filter(impfungenMerged, !is.na(impfidenz)), x = ~datum) %>%
          add_trace(y = ~ impfidenz, type = "scatter", mode = "lines", name = "Impfidenz", size = I(2), yhoverformat = ",.1f") %>%
          plotly_default_config() %>%
          plotly_time_range(input) %>%
          plotly_hide_axis_titles()
      })
      output$impfidenzText <- renderText({
        lastRow <- impfungenMerged %>% filter(!is.na(impfidenz)) %>% slice_tail()
        paste0("Die 7-Tage-Impfidenz (Anzahl verimpfter Dosen in den letzten 7 Tagen pro 100.000 Einwohner) liegt zum ", format(lastRow$datum, "%d.%m.%Y"), " bei ", format(lastRow$impfidenz, nsmall = 1, decimal.mark = ",", big.mark = "."), ".")
      })

      output$impfdosenProTagPlot <- renderPlot({
        ggplot(filter(impfungenMerged, !is.na(impfdosenNeuProTag)), mapping = aes(x = datum)) + list(
          geom_col(aes(y = impfdosenNeuProTag), alpha = 0.5, width = 1, position = position_nudge(x = -0.5)),
          geom_line(data = filter(impfungenMerged, !is.na(impfdosen7tageMittel)), aes(y = impfdosen7tageMittel), alpha = 0.6, color = "#000000", size = 1.2),
          if (input$showNumbers)
            geom_text(
              aes(y = impfdosenNeuProTag, label = round(impfdosenNeuProTag)),
              vjust = "bottom", hjust = "middle", nudge_y = 100, check_overlap = TRUE, size = 3.4, na.rm = TRUE
            )
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
      output$impfdosenProTagText <- renderText({
        lastRow <- impfungenMerged %>% filter(!is.na(impfdosenNeuProTag)) %>% slice_tail()
        paste0("Zuletzt (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden ", format(round(lastRow$impfdosenNeuProTag), decimal.mark = ",", big.mark = "."), " Impfdosen pro Tag verabreicht. Die schwarze Linie gibt das 7-Tage-Mittel an.")
      })

      output$impfdosenProTagNachEinrichtungPlot <- renderPlot({
        ggplot(filter(arcgisImpfungenNachEinrichtung, !is.na(impfdosenNeu)), mapping = aes(x = datum)) + list(
          geom_col(aes(y = impfdosenNeu, fill = einrichtung), width = 1, position = "stack"),
          expand_limits(y = 0),
          getDateScale(),
          getYScale(),
          theme(legend.justification = c(0, 1), legend.position = c(0, 1), legend.title = element_blank(), legend.background = element_rect(fill = alpha("#ffffff", 0.5)), legend.key.size = unit(16, "pt"))
        )
      }, res = 96)
      output$impfdosenProTagNachEinrichtungText <- renderText({
        impfdosen7Tage <- arcgisImpfungenNachEinrichtung %>%
          filter(!is.na(impfdosenNeu)) %>%
          slice_tail(n = 7) %>%
          summarise(impfdosen7Tage = sum(impfdosenNeu), datum = max(datum)) %>%
          pivot_wider(names_from = einrichtung, values_from = impfdosen7Tage)

        paste0("In den letzen 7 Tagen (Stand:\u00A0", format(impfdosen7Tage$datum, "%d.%m.%Y"), ") wurden ", format(round(impfdosen7Tage$Impfzentrum), decimal.mark = ",", big.mark = "."), " Impfdosen im Impfzentrum, ", format(round(impfdosen7Tage$Praxis), decimal.mark = ",", big.mark = "."), " Impfdosen in Arztpraxen und ", format(round(impfdosen7Tage$Kreisklinik), decimal.mark = ",", big.mark = "."), " Impfdosen in der Kreisklinik verabreicht.")
      })
    }
  )
}

plotly_default_config <- function(p) {
  return(
    p %>%
      config(displayModeBar = FALSE) %>%
      config(locale = "de") %>%
      layout(dragmode = FALSE) %>%
      layout(hovermode = "x")
  )
}

plotly_time_range <- function(p, input) {
  return(
    p %>%
      # legend above plot
      layout(legend = list(bgcolor = "#ffffffaa", orientation = 'h', y = 1.2, yanchor = "bottom")) %>%
      # default time selection
      layout(xaxis = list(range = list(input$dateRange[1], input$dateRange[2]))) %>%
      layout(xaxis = list(
        rangeselector = list(
          buttons = list(
            list(count = 1, label = "1 Monat", step = "month", stepmode = "backward"),
            list(count = 3, label = "3 Monate", step = "month", stepmode = "backward"),
            list(count = 6, label = "6 Monate", step = "month", stepmode = "backward"),
            list(step = "all", label = "Gesamt")
          )
        ),
        rangeslider = list(type = "date")
      )) %>%
      config(doubleClick = FALSE)
  )
}

plotly_hide_axis_titles <- function(p) {
  return(
    p %>%
      layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(margin = list(r = 0, l = 0, t = 0, b = 4, pad = 0))
  )
}