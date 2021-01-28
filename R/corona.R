library(readr)
library(dplyr)
library(tidyr)
library(scales)

einwohnerZahl <- 24404

fallzahlenRaw <- read_delim(
  file = "../data/lra-ebe-corona/fallzahlenVat.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    kumulativ = col_integer(),
    aktuell = col_integer()
  )
)

fallzahlen <- fallzahlenRaw %>%
  mutate(neuinfektionen = kumulativ - lag(kumulativ, 1)) %>%
  complete(datum = seq(min(datum), max(datum), "days"), fill = list(neuinfektionen = 0)) %>%
  mutate(inzidenz7 = lag(cumsum(neuinfektionen) - lag(cumsum(neuinfektionen), 7)) / einwohnerZahl * 100000)

ui <- function(request, id) {
  ns <- NS(id)
  tagList(
    h2("Corona-Fallzahlen in Vaterstetten"),

    fluidRow(
      box(
        title = "Disclaimer",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("<strong>Alle Angaben ohne Gewähr.</strong> Bitte halten Sie sich an die Vorgaben des zuständigen Gesundheitsamts. Die hier veröffentliche 7-Tage-Inzidenz ist <u>nicht</u> relevant für lokale Corona-Beschränkungen wie etwa die 15km-Regel. Geringe Zahlen in Vaterstetten sind nicht automatisch ein Beweis für eine geringe Infektionsgefahr in Vaterstetten."))
        )
      )
    ),

    fluidRow(
      valueBoxOutput(ns("valueBoxAktuell")),
      valueBoxOutput(ns("valueBoxInzidenz")),
      valueBoxOutput(ns("valueBoxStand"))
    ),

    flowLayout(
      dateRangeInput(ns("dateRange"),
        label = NULL,
        start = max(fallzahlen$datum) - 28,
        end = max(fallzahlen$datum),
        min = min(fallzahlen$datum),
        max = max(fallzahlen$datum),
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
        title = "Neuinfektionen (absolut)",
        plotOutput(ns("neuinfektionen"), height = 300)
      ),
      box(
        title = "7-Tages-Inzidenz pro 100.000 Einwohner",
        plotOutput(ns("inzidenz7"), height = 300)
      ),
      box(
        title = "Aktuelle Fälle (absolut)",
        plotOutput(ns("aktuell"), height = 300)
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage und Methodik",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage sind die SARS-CoV-2-Fallzahlen des <a href = \"https://lra-ebe.de/\">Landratsamts Ebersberg</a> (<a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/\">2020</a>, <a href=\"https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0121/\">2021</a>). Das Gesundheitsamt veröffentlicht an jedem Werktag die kumulativen Fallzahlen und aktuellen Fälle, aufgeschlüsselt nach Kommune. Da die Zahlen nur in Form einer Grafik und nicht in einem maschinenlesbaren Format vorliegen, müssen diese händisch für dieses Projekt eingetragen werden. Auch wenn auf eine größtmögliche Sorgfalt geachtet wird, besteht daher beim Übertragen natürlich die Gefahr von Tippfehlern."))
        ),
      ),
    ),
  )
}

getDateScale <- function() {
  list(
    scale_x_date(
      name = NULL,
      breaks = breaks_pretty(8),
      date_minor_breaks = "1 days",
      date_labels = "%-d.%-m.",
      expand = expansion(add = 0.5)
    )
  )
}

getYScale <- function() {
  scale_y_continuous(
    name = NULL,
    breaks = breaks_pretty(5),
    expand = expansion(mult = c(0, 0.1))
  )
}


# Define the server logic for a module
server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      setBookmarkExclude(c("dateRange"))

      fallzahlenInTimeRange <- reactive({
        fallzahlen %>%
          filter(input$dateRange[1] <= datum) %>%  # the logical and (&&) doesn't allow element-wise operations, so we split them
          filter(datum <= input$dateRange[2])
      })

      output$valueBoxAktuell <- renderValueBox({
        valueBox(
          tail(fallzahlen$aktuell, n = 1),
          "Aktuelle Fälle",
          color = "purple",
          icon = icon("user-check")
        )
      })

      output$valueBoxInzidenz <- renderValueBox({
        valueBox(
          format(round(tail(fallzahlen$inzidenz7, n = 1), 1), nsmall = 1),
          "7-Tages-Inzidenz",
          color = "purple",
          icon = icon("chart-line")
        )
      })

      output$valueBoxStand <- renderValueBox({
        valueBox(
          format(tail(fallzahlen$datum, n = 1), "%d. %b %Y"),
          "Stand",
          color = "purple",
          icon = icon("calendar-day")
        )
      })

      output$neuinfektionen <- renderPlot({
        ggplot(fallzahlenInTimeRange(), mapping = aes(x = datum, y = neuinfektionen, label = neuinfektionen)) + list(
          geom_col(alpha = 0.5),
          if (input$showNumbers) geom_text(vjust = "bottom", hjust = "middle", nudge_y = 0.5, check_overlap = TRUE, size = 3.4) else list(),
          getDateScale(),
          getYScale()
        )
      }, res = 96)

      output$inzidenz7 <- renderPlot({
        ggplot(fallzahlenInTimeRange(), mapping = aes(x = datum, y = inzidenz7)) + list(
          geom_line(na.rm = TRUE, alpha = 0.5),
          geom_point(na.rm = TRUE),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)

      output$aktuell <- renderPlot({
        ggplot(fallzahlenInTimeRange(), mapping = aes(x = datum, y = aktuell, label = aktuell)) + list(
          geom_line(data = filter(fallzahlenInTimeRange(), !is.na(aktuell)), alpha = 0.5),
          geom_point(na.rm = TRUE),
          if (input$showNumbers) geom_text(vjust = "bottom", hjust = "middle", nudge_y = 2.5, check_overlap = TRUE, size = 3.4, na.rm = TRUE) else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
    }
  )
}
