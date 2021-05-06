library(readr)
library(dplyr)
library(tidyr)
library(scales)

einwohnerZahlLkEbe <- 143649
buergerAb80LkEbe <- 9430 # as of 2021-01-08

impfungenRaw <- read_delim(
  file = "data/lra-ebe-corona/impfungenLkEbe.csv",
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

impfungen <- impfungenRaw %>%
  mutate(
    impfdosen = erstimpfungen + zweitimpfungen,
    registriertOderGeimpft = registriert + erstimpfungen
  ) %>%
  mutate (
    impfdosenLast = impfdosen,
    impfdosenUpdated = ifelse(!is.na(impfdosen), datum, NA)
  ) %>%
  fill(impfdosenLast, impfdosenUpdated) %>%
  mutate(
    impfdosenNeuProTag = (impfdosen - lag(impfdosenLast, default = 0)) / (as.integer(datum) - lag(impfdosenUpdated))
  ) %>%
  select(-impfdosenLast, -impfdosenUpdated)

personenNachStatus <- impfungenRaw %>%
  transmute(
    datum = datum,
    erst = erstimpfungen,
    zweit = zweitimpfungen,
    registriertOderGeimpft = registriert + erstimpfungen
  ) %>%
  pivot_longer(
    cols = c(erst, zweit, registriertOderGeimpft),
    names_to = "status",
    names_ptypes = list(status = factor(levels = c("registriertOderGeimpft", "erst", "zweit")))
  ) %>%
  filter(!is.na(value))


ui <- function(request, id) {
  ns <- NS(id)
  tagList(
    h2("Corona-Impfungen im Landkreis Ebersberg"),

    fluidRow(
      valueBoxOutput(ns("valueBoxErstimpfungen")),
      valueBoxOutput(ns("valueBoxImpfquote")),
      valueBoxOutput(ns("valueBoxStand"))
    ),

    flowLayout(
      dateRangeInput(ns("dateRange"),
        label = NULL,
        start = min(impfungenRaw$datum),
        end = max(impfungenRaw$datum),
        min = min(impfungenRaw$datum),
        max = max(impfungenRaw$datum),
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
        title = "Geimpfte Personen (Erst-/Zweitgeimpfte)",
        plotOutput(ns("geimpfte"), height = 300),
        textOutput(ns("geimpfteText"))
      ),
      box(
        title = "Geimpfte Über-80-Jährige (Erst-/Zweitgeimpfte)",
        plotOutput(ns("geimpfte80"), height = 300),
        textOutput(ns("geimpfte80Text"))
      ),
    ),

    fluidRow(
      box(
        title = "Registrierte / Geimpfte",
        plotOutput(ns("registrierteGeimpftePlot"), height = 300),
        htmlOutput(ns("registrierteGeimpfteText"))
      ),
      box(
        title = "Verabreichte Impfdosen",
        plotOutput(ns("impfdosen"), height = 300),
        textOutput(ns("impfdosenText"))
      ),
    ),

    fluidRow(
      box(
        title = "Verabreichte Impfdosen pro Tag",
        plotOutput(ns("impfdosenProTagPlot"), height = 300),
        textOutput(ns("impfdosenProTagText"))
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
          expand = expansion(mult = c(0.02, 0.1))
        )
      }

      output$valueBoxErstimpfungen <- renderValueBox({
        lastRow <- impfungenRaw %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        valueBox(
          lastRow$erstimpfungen,
          paste("Geimpfte (mind. Erstimpfung, Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("user-check")
        )
      })

      output$valueBoxImpfquote <- renderValueBox({
        lastRow <- impfungenRaw %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        valueBox(
          paste(format(round(lastRow$erstimpfungen / einwohnerZahlLkEbe * 100, 1), nsmall = 1), "%", sep = ""),
          paste("der Bevölkerung ist geimpft (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("percent")
        )
      })

      output$valueBoxStand <- renderValueBox({
        lastRow <- impfungenRaw %>% filter(!is.na(registriert)) %>% slice_tail()
        valueBox(
          paste(format(round(lastRow$registriert / einwohnerZahlLkEbe * 100, 1), nsmall = 1), "%", sep = ""),
          paste("der Bevölkerung ist online registriert (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("laptop")
        )
      })

      output$geimpfte <- renderPlot({
        ggplot(personenNachStatus %>% filter(status != "registriertOderGeimpft"), mapping = aes(x = datum, y = value, group = status)) + list(
          geom_area(aes(alpha = status), position = "identity", size = 0, fill = "#0088dd"),
          geom_line(color = "#0088dd", alpha = 0.5),
          geom_point(color = "#0088dd", alpha = 0.6, size = 1),
          if (input$showNumbers) list(
            geom_text(aes(label = value), vjust = "bottom", hjust = "middle", nudge_y = 400, check_overlap = TRUE, size = 3.4, color = "#004b7a")
          ) else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale(),
          scale_alpha_manual(values = c(0.2, 0.5), labels = c("Erstimpfung", "Zweitimpfung")),
          theme(legend.justification = c(0, 1), legend.position = c(0, 1), legend.title = element_blank(), legend.background = element_rect(fill = alpha("#ffffff", 0.5)), legend.key.size = unit(16, "pt"))
        )
      }, res = 96)
      output$geimpfteText <- renderText({
        lastRow <- impfungen %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
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
        lastRow <- impfungenRaw %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        paste("Aktuell (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") haben ", lastRow$erstimpfungenAb80, " der ca. ", buergerAb80LkEbe ," Landkreisbürger*innen ab 80 Jahren mindestens eine Erstimpfung erhalten, davon ", lastRow$zweitimpfungenAb80, " auch schon eine Zweitimpfung.", sep = "")
      })

      output$impfdosen <- renderPlot({
        ggplot(filter(impfungenRaw, !is.na(zweitimpfungen)), mapping = aes(x = datum, y = erstimpfungen + zweitimpfungen)) + list(
          geom_line(alpha = 0.5),
          geom_point(alpha = 0.5, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = erstimpfungen + zweitimpfungen), vjust = "bottom", hjust = "middle", nudge_y = 500, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
      output$impfdosenText <- renderText({
        lastRow <- impfungenRaw %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        paste("Bislang (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden im Landkreis Ebersberg ", lastRow$erstimpfungen + lastRow$zweitimpfungen, " Impfdosen verabreicht.", sep = "")
      })

      output$registrierteGeimpftePlot <- renderPlot({
        ggplot(personenNachStatus, mapping = aes(x = datum, y = value, group = status)) + list(
          geom_area(aes(alpha = status), position = "identity", size = 0, fill = "#0088dd"),
          geom_line(color = "#0088dd", alpha = 0.5),
          geom_point(color = "#0088dd", alpha = 0.6, size = 1),
          if (input$showNumbers) list(
            geom_text(aes(label = value), vjust = "bottom", hjust = "middle", nudge_y = 1000, check_overlap = TRUE, size = 3.4, color = "#004b7a")
          ) else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale(),
          scale_alpha_manual(values = c(0.1, 0.3, 0.5), labels = c("Registriert", "Erstimpfung", "Zweitimpfung")),
          theme(legend.justification = c(0, 1), legend.position = c(0, 1), legend.title = element_blank(), legend.background = element_rect(fill = alpha("#ffffff", 0.5)), legend.key.size = unit(16, "pt"))
        )
      }, res = 96)
      output$registrierteGeimpfteText <- renderUI({
        lastRow <- impfungen %>% filter(!is.na(registriert)) %>% slice_tail()
        HTML(paste("Aktuell (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") sind ", lastRow$registriert, " Menschen für eine Impfung registriert, ", lastRow$registriertOderGeimpft," sind registriert oder bereits geimpft. Der Landkreis Ebersberg hat ", einwohnerZahlLkEbe, " Einwohner. Noch nicht angemeldet? Hier geht's zur bayerischen Impfregistrierung: <a href=\"https://impfzentren.bayern/citizen\">https://impfzentren.bayern/citizen</a>", sep = ""))
      })

      output$impfdosenProTagPlot <- renderPlot({
        ggplot(filter(impfungen, !is.na(impfdosenNeuProTag)), mapping = aes(x = datum, y = impfdosenNeuProTag)) + list(
          geom_step(alpha = 0.5, direction = "vh"),
          if (input$showNumbers)
            geom_text(aes(x = as.Date((as.integer(datum) + as.integer(lag(datum))) / 2, origin = "1970-01-01"), label = round(impfdosenNeuProTag)), vjust = "bottom", hjust = "middle", nudge_y = 15, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
      output$impfdosenProTagText <- renderText({
        lastRow <- impfungen %>% filter(!is.na(impfdosenNeuProTag)) %>% slice_tail()
        paste("Zuletzt (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ") wurden ", round(lastRow$impfdosenNeuProTag), " Impfdosen pro Tag verabreicht.", sep = "")
      })
    }
  )
}
