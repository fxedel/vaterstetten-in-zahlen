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
        plotOutput(ns("geimpfte"), height = 300),
        textOutput(ns("geimpfteText"))
      ),
      box(
        title = "7-Tage-Impfidenz",
        plotOutput(ns("impfidenzPlot"), height = 300),
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
        plotOutput(ns("impfdosen"), height = 300),
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
          p(HTML("Datengrundlage sind die Corona-Pressemeldungen des <a href=\"https://lra-ebe.de/\">Landratsamts Ebersberg</a> (<a href=\"https://lra-ebe.de/aktuelles/aktuelle-meldungen/\">Aktuelle Pressemeldungen</a>, <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/\">Corona-Pressearchiv</a>). Dort wird (teils in unregelmäßigen Abständen) die Zahl der verabreichten Erst- und Zweitimpfungen sowie die Anzahl der über das <a href=\"https://impfzentren.bayern/citizen\">Online-Portal</a> registrierten Landkreisbürger*innen veröffentlicht. Außerdem wird auf der Seite des <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/\">Impfzentrums Ebersberg</a> die tagesaktuelle Zahl an Erst- und Zweitimpfungen dargestellt.")),
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
          paste0(format(round(lastRow$erstimpfungen / einwohnerZahlLkEbe * 100, 1), nsmall = 1), "%"),
          paste0("Erstimpfquote (absolut: ", lastRow$erstimpfungen, ")"),
          color = "purple",
          icon = icon("star-half-alt")
        )
      })

      output$valueBox2 <- renderValueBox({
        lastRow <- impfungenMerged %>% filter(!is.na(zweitimpfungen)) %>% slice_tail()
        valueBox(
          paste0(format(round(lastRow$zweitimpfungen / einwohnerZahlLkEbe * 100, 1), nsmall = 1), "%"),
          paste0("Zweitimpfquote (absolut: ", lastRow$zweitimpfungen, ")"),
          color = "purple",
          icon = icon("star")
        )
      })

      output$valueBox3 <- renderValueBox({
        lastRow <- impfungenMerged %>% filter(!is.na(impfidenz)) %>% slice_tail()
        valueBox(
          format(round(lastRow$impfidenz, 1), nsmall = 1),
          paste("7-Tage-Impfidenz (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("tachometer-alt")
        )
      })

      output$geimpfte <- renderPlot({
        ggplot(personenNachStatus, mapping = aes(x = datum, y = value, group = status)) + list(
          geom_area(aes(alpha = status), position = "identity", size = 0, fill = "#0088dd"),
          geom_line(color = "#0088dd", alpha = 0.5),
          geom_point(color = "#0088dd", alpha = 0.6, size = 1),
          if (input$showNumbers) list(
            geom_text(aes(label = value), vjust = "bottom", hjust = "middle", nudge_y = 1500, check_overlap = TRUE, size = 3.4, color = "#004b7a")
          ) else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale(),
          scale_alpha_manual(values = c(0.2, 0.5, 1), labels = c("Erstimpfung", "Zweitimpfung", "Drittimpfung")),
          theme(legend.justification = c(0, 1), legend.position = c(0, 1), legend.title = element_blank(), legend.background = element_rect(fill = alpha("#ffffff", 0.5)), legend.key.size = unit(16, "pt"))
        )
      }, res = 96)
      output$geimpfteText <- renderText({
        lastRow <- impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        paste("Aktuell (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") haben ", lastRow$erstimpfungen, " Menschen mindestens eine Erstimpfung erhalten, davon ", lastRow$zweitimpfungen, " auch schon eine Zweitimpfung.", sep = "")
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
        paste("Aktuell (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") haben ", lastRow$erstimpfungenAb80, " der ca. ", buergerAb80LkEbe ," Landkreisbürger*innen ab 80 Jahren mindestens eine Erstimpfung erhalten, davon ", lastRow$zweitimpfungenAb80, " auch schon eine Zweitimpfung.", sep = "")
      })

      output$impfdosen <- renderPlot({
        ggplot(filter(impfungenMerged, !is.na(impfdosen)), mapping = aes(x = datum, y = impfdosen)) + list(
          geom_line(alpha = 0.5, size = 1.2),
          geom_point(alpha = 1, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = impfdosen), vjust = "bottom", hjust = "middle", nudge_y = 1500, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
      output$impfdosenText <- renderText({
        lastRow <- impfungenMerged %>% filter(!is.na(impfdosen)) %>% slice_tail()
        paste("Bislang (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden im Landkreis Ebersberg ", lastRow$impfdosen, " Impfdosen verabreicht.", sep = "")
      })

      output$impfidenzPlot <- renderPlot({
        ggplot(filter(impfungenMerged, !is.na(impfidenz)), mapping = aes(x = datum, y = impfidenz)) + list(
          geom_line(alpha = 0.5, size = 1.2),
          geom_point(alpha = 1, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = round(impfidenz)), vjust = "bottom", hjust = "middle", nudge_y = 300, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
      output$impfidenzText <- renderText({
        lastRow <- impfungenMerged %>% filter(!is.na(impfidenz)) %>% slice_tail()
        paste0("Die 7-Tage-Impfidenz (Anzahl verimpfter Dosen in den letzten 7 Tagen pro 100.000 Einwohner) liegt zum ", format(lastRow$datum, "%d.%m.%Y"), " bei ", round(lastRow$impfidenz, 1), ".")
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
        paste0("Zuletzt (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden ", round(lastRow$impfdosenNeuProTag), " Impfdosen pro Tag verabreicht. Die schwarze Linie gibt das 7-Tage-Mittel an.")
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

        paste0("In den letzen 7 Tagen (Stand:\u00A0", format(impfdosen7Tage$datum, "%d.%m.%Y"), ") wurden ", round(impfdosen7Tage$Impfzentrum), " Impfdosen im Impfzentrum, ", round(impfdosen7Tage$Praxis), " Impfdosen in Arztpraxen und ", round(impfdosen7Tage$Kreisklinik), " Impfdosen in der Kreisklinik verabreicht.")
      })
    }
  )
}
