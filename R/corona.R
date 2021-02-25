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
  complete(datum = seq(min(datum), max(datum) + 1, "days"), fill = list(neuinfektionen = 0)) %>%
  mutate(neuinfektionen = c(neuinfektionen[-n()], NA)) %>%
  mutate(inzidenz7 = lag(cumsum(neuinfektionen) - lag(cumsum(neuinfektionen), 7)) / einwohnerZahl * 100000) %>%
  mutate(neuinfektionen = c(NA, neuinfektionen[-1]))

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
          p(HTML("<strong>Alle Angaben ohne Gewähr.</strong> Bitte halten Sie sich an die Vorgaben des zuständigen Gesundheitsamts. Die hier veröffentliche 7-Tage-Inzidenz ist <strong>nicht</strong> relevant für lokale Corona-Beschränkungen. Geringe Zahlen in Vaterstetten sind nicht automatisch ein Beweis für eine geringe Infektionsgefahr in Vaterstetten."))
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
        title = "7-Tage-Inzidenz pro 100.000 Einwohner",
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
          p(HTML("Datengrundlage sind die SARS-CoV-2-Fallzahlen des <a href = \"https://lra-ebe.de/\">Landratsamts Ebersberg</a> (<a href=\"https://lra-ebe.de/aktuelles/aktuelle-meldungen/\">Aktuelle Pressemeldungen</a>, <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/\">Corona-Pressearchiv</a>). Das Gesundheitsamt veröffentlicht an jedem Werktag die kumulativen Fallzahlen und aktuellen Fälle, aufgeschlüsselt nach Kommunen, jeweils zum Stand des vorherigen Tages um 16 Uhr. Da die Zahlen nur in Form einer Grafik und nicht in einem maschinenlesbaren Format vorliegen, müssen diese händisch für dieses Projekt eingetragen werden. Auch wenn auf eine größtmögliche Sorgfalt geachtet wird, besteht daher beim Übertragen natürlich die Gefahr von Tippfehlern.")),
          p("Für die Berechnung der 7-Tage-Inzidenz für einen Tag X werden die Neuinfektionen der 7 vorangegangenen Tage, nicht aber des Tages X summiert. Das entspricht der Berechnungsweise des RKI. So ist es möglich, für den heutigen Tag eine 7-Tage-Inzidenz anzugeben, obwohl der Datenstand des Gesundheitsamtes bei gestern liegt.")
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

      fallzahlenInTimeRange <- reactive({
        fallzahlen %>%
          # we increase the range by 2 on both sides to have an ongoing curve
          # we could also just plot the whole data but this reduces the computational effort
          filter(input$dateRange[1] - 2 <= datum) %>%  # the logical and (&&) doesn't allow element-wise operations, so we split them
          filter(datum <= input$dateRange[2] + 2)
      })

      output$valueBoxAktuell <- renderValueBox({
        lastRowWithAktuell <- fallzahlen %>% filter(!is.na(aktuell)) %>% slice_tail()
        valueBox(
          lastRowWithAktuell$aktuell,
          "Aktuelle Fälle",
          color = "purple",
          icon = icon("user-check")
        )
      })

      output$valueBoxInzidenz <- renderValueBox({
        lastRow <- fallzahlen %>% slice_tail()
        valueBox(
          format(round(lastRow$inzidenz7, 1), nsmall = 1),
          "7-Tage-Inzidenz",
          color = "purple",
          icon = icon("chart-line")
        )
      })

      output$valueBoxStand <- renderValueBox({
        lastRowWithAktuell <- fallzahlen %>% filter(!is.na(aktuell)) %>% slice_tail()
        valueBox(
          format(lastRowWithAktuell$datum, "%-d. %b %Y"),
          "Datenstand des Gesundheitsamtes",
          color = "purple",
          icon = icon("calendar-day")
        )
      })

      output$neuinfektionen <- renderPlot({
        ggplot(fallzahlenInTimeRange(), mapping = aes(x = datum, y = neuinfektionen)) + list(
          geom_col(na.rm = TRUE, alpha = 0.5),
          if (input$showNumbers)
            geom_text(aes(label = neuinfektionen), vjust = "bottom", hjust = "middle", nudge_y = 0.5, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          getDateScale(),
          getYScale()
        )
      }, res = 96)

      output$inzidenz7 <- renderPlot({
        ggplot(fallzahlenInTimeRange(), mapping = aes(x = datum, y = inzidenz7)) + list(
          geom_line(na.rm = TRUE, alpha = 0.5),
          geom_point(na.rm = TRUE, alpha = 0.5, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = round(inzidenz7)), vjust = "bottom", hjust = "middle", nudge_y = 8, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)

      output$aktuell <- renderPlot({
        ggplot(fallzahlenInTimeRange(), mapping = aes(x = datum, y = aktuell)) + list(
          geom_line(data = filter(fallzahlenInTimeRange(), !is.na(aktuell)), alpha = 0.5),
          geom_point(na.rm = TRUE, alpha = 0.5, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = aktuell), vjust = "bottom", hjust = "middle", nudge_y = 2.5, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          expand_limits(y = 0),
          getDateScale(),
          getYScale()
        )
      }, res = 96)
    }
  )
}
