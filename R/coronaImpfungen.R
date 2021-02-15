library(readr)
library(dplyr)
library(tidyr)
library(scales)

einwohnerZahlLkEbe <- 143649

impfungenRaw <- read_delim(
  file = "data/lra-ebe-corona/impfungenLkEbe.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    erstimpfungen = col_integer(),
    zweitimpfungen = col_integer(),
    onlineanmeldungen = col_integer()
  )
)

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
        plotOutput(ns("geimpfte"), height = 300)
      ),
      box(
        title = "Verabreichte Impfdosen",
        plotOutput(ns("impfdosen"), height = 300)
      ),
      box(
        title = "Online-Registrierungen",
        tagList(
          plotOutput(ns("onlineanmeldungen"), height = 300),
          HTML("Noch nicht angemeldet? Hier geht's zur bayerischen Impfregistrierung: <a href=\"https://impfzentren.bayern/citizen\">https://impfzentren.bayern/citizen</a>")
        )
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage und Methodik",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage sind die Corona-Pressemeldungen des <a href = \"https://lra-ebe.de/\">Landratsamts Ebersberg</a> (<a href=\"https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0121/\">Aktuelle Informationen</a>, <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/\">Corona-Pressearchiv</a>). Dort wird in unregelmäßigen Abständen die Zahl der verabreichten Erst- und Zweitimpfungen sowie die Anzahl der über das <a href=\"https://impfzentren.bayern/citizen\">Online-Portal</a> registrierten Landkreisbürger*innen veröffentlicht.")),
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
      setBookmarkExclude(c("dateRange"))

      getDateScale <- function() {
        list(
          scale_x_date(
            name = NULL,
            breaks = breaks_pretty(8),
            date_minor_breaks = "1 days",
            date_labels = "%d.%m.",
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
        lastRow <- impfungenRaw %>% filter(!is.na(onlineanmeldungen)) %>% slice_tail()
        valueBox(
          paste(format(round(lastRow$onlineanmeldungen / einwohnerZahlLkEbe * 100, 1), nsmall = 1), "%", sep = ""),
          paste("der Bevölkerung ist online registriert (Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("laptop")
        )
      })
  
      output$geimpfte <- renderPlot({
        ggplot(filter(impfungenRaw, !is.na(erstimpfungen)), mapping = aes(x = datum)) + list(
          geom_ribbon(aes(ymin = zweitimpfungen, ymax = erstimpfungen), alpha = 0.2, fill = "#0088dd", color = "#0088dd"),
          geom_point(aes(y = erstimpfungen), alpha = 0.5, size = 1, color = "#0088dd"),
          geom_area(aes(y = zweitimpfungen), alpha = 0.5, fill = "#0088dd", color = "#0088dd"),
          geom_point(aes(y = zweitimpfungen), alpha = 0.5, size = 1, color = "#0088dd"),
          if (input$showNumbers) list(
            geom_text(aes(y = erstimpfungen, label = erstimpfungen), vjust = "bottom", hjust = "middle", nudge_y = 120, check_overlap = TRUE, size = 3.4, color = "#004b7a"),
            geom_text(aes(y = zweitimpfungen, label = zweitimpfungen), vjust = "bottom", hjust = "middle", nudge_y = 120, check_overlap = TRUE, size = 3.4, color = "#004b7a")
          ) else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
  
      output$impfdosen <- renderPlot({
        ggplot(filter(impfungenRaw, !is.na(zweitimpfungen)), mapping = aes(x = datum, y = erstimpfungen + zweitimpfungen)) + list(
          geom_line(alpha = 0.5),
          geom_point(alpha = 0.5, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = erstimpfungen + zweitimpfungen), vjust = "bottom", hjust = "middle", nudge_y = 150, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)

      output$onlineanmeldungen <- renderPlot({
        ggplot(filter(impfungenRaw, !is.na(onlineanmeldungen)), mapping = aes(x = datum, y = onlineanmeldungen)) + list(
          geom_line(alpha = 0.5),
          geom_point(alpha = 0.5, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = onlineanmeldungen), vjust = "bottom", hjust = "middle", nudge_y = 800, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
    }
  )
}
