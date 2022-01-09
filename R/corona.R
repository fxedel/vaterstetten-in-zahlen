einwohnerZahl <- 24404

fallzahlen <- read_delim(
  file = "data/corona-fallzahlen/fallzahlenVat.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    kumulativ = col_integer(),
    aktuell = col_integer()
  )
)

fallzahlenArcGIS <- read_csv("data/corona-fallzahlen/arcgisInzidenzGemeinden.csv") %>% filter(ort == "Vaterstetten")

ui <- function(request, id) {
  ns <- NS(id)
  tagList(
    h2("Corona-Fallzahlen in der Gemeinde Vaterstetten"),

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
      valueBoxOutput(ns("valueBoxNeuinfektionen")),
      valueBoxOutput(ns("valueBoxInzidenz")),
      valueBoxOutput(ns("valueBoxStand"))
    ),

    flowLayout(
      dateRangeInput(ns("dateRange"),
        label = NULL,
        start = max(fallzahlenArcGIS$datum) - 42,
        end = max(fallzahlenArcGIS$datum),
        min = min(fallzahlenArcGIS$datum),
        max = max(fallzahlenArcGIS$datum),
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
        plotOutput(ns("neuinfektionen"), height = 300),
        p("Mit „Neuinfektionen“ ist an dieser Stelle die Anzahl positiver Testungen gemeint.")
      ),
      box(
        title = "7-Tage-Inzidenz pro 100.000 Einwohner",
        plotOutput(ns("inzidenz7"), height = 300)
      )
    ),

    fluidRow(
      box(
        title = "Aktuelle Fälle (absolut)",
        plotOutput(ns("aktuell"), height = 300),
        p("Seit dem 18. Juni 2021 veröffentlicht das Landratsamt Ebersberg nicht mehr die Anzahl aktuell aktiver Fälle.")
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage und Methodik",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage ist die <a href=\"https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services\">ArcGIS-API</a>, die für das <a href=\"https://experience.arcgis.com/experience/dc7f97a7874b47aebf1a75e74749c047\">COVID-19 Dashboard Ebersberg</a> verwendet wird. Diese Daten stammen direkt vom Gesundheitsamt Ebersberg. Darin enthalten ist die Anzahl SARS-CoV-2-Neuinfektionen bzw. neu positiv getesteter Personen (landkreisweit und nach Gemeinden aufgeschlüsselt) sowie die daraus berechnete 7-Tage-Inzidenz. Diese API liefert bislang keine Daten zur Anzahl aktuell aktiver Fälle.")),
          p(HTML("Zuvor wurden die SARS-CoV-2-Fallzahlen der Homepage des <a href = \"https://lra-ebe.de/\">Landratsamts Ebersberg</a> (<a href=\"https://lra-ebe.de/aktuelles/aktuelle-meldungen/\">Aktuelle Pressemeldungen</a>, <a href=\"https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/\">Corona-Pressearchiv</a>) entnommen. Das Gesundheitsamt veröffentlichte an jedem Werktag die kumulativen Fallzahlen und aktuellen Fälle, aufgeschlüsselt nach Kommunen, jeweils zum Stand des vorherigen Tages um 16 Uhr. Da die Zahlen nur in Form einer Grafik und nicht in einem maschinenlesbaren Format vorlagen, mussten diese händisch für dieses Projekt eingetragen werden. Die Grafiken werden seit dem 18. Juni 2021 nicht mehr veröffentlicht.")),
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

      fallzahlenInTimeRange <- reactive({
        fallzahlen %>%
          # we increase the range by 2 on both sides to have an ongoing curve
          # we could also just plot the whole data but this reduces the computational effort
          filter(input$dateRange[1] - 2 <= datum) %>%  # the logical and (&&) doesn't allow element-wise operations, so we split them
          filter(datum <= input$dateRange[2] + 2)
      })

      fallzahlenArcGISInTimeRange <- reactive({
        fallzahlenArcGIS %>%
          # we increase the range by 2 on both sides to have an ongoing curve
          # we could also just plot the whole data but this reduces the computational effort
          filter(input$dateRange[1] - 2 <= datum) %>%  # the logical and (&&) doesn't allow element-wise operations, so we split them
          filter(datum <= input$dateRange[2] + 2)
      })

      output$valueBoxNeuinfektionen <- renderValueBox({
        last7rows <- fallzahlenArcGIS %>% slice_tail(n = 7)
        valueBox(
          sum(last7rows$neuPositiv),
          "Neue Fälle in den letzten 7 Tagen",
          color = "red",
          icon = icon("user-check")
        )
      })

      output$valueBoxInzidenz <- renderValueBox({
        lastRow <- fallzahlenArcGIS %>% slice_tail()
        valueBox(
          format(round(lastRow$inzidenz7tage, 1), nsmall = 1),
          "7-Tage-Inzidenz",
          color = "red",
          icon = icon("chart-line")
        )
      })

      output$valueBoxStand <- renderValueBox({
        lastRow <- fallzahlenArcGIS %>% slice_tail()
        valueBox(
          format(lastRow$datum, "%-d. %b %Y"),
          "Datenstand des Gesundheitsamtes",
          color = "red",
          icon = icon("calendar-day")
        )
      })

      output$neuinfektionen <- renderPlot({
        ggplot(fallzahlenArcGISInTimeRange(), mapping = aes(x = datum, y = neuPositiv)) + list(
          geom_col(na.rm = TRUE, alpha = 0.5, width = 1),
          if (input$showNumbers)
            geom_text(aes(label = neuPositiv), vjust = "bottom", hjust = "middle", nudge_y = 0.5, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
          else list(),
          getDateScale(),
          getYScale()
        )
      }, res = 96)

      output$inzidenz7 <- renderPlot({
        ggplot(fallzahlenArcGISInTimeRange(), mapping = aes(x = datum, y = inzidenz7tage)) + list(
          geom_line(na.rm = TRUE, alpha = 0.5),
          geom_point(na.rm = TRUE, alpha = 0.5, size = 1),
          if (input$showNumbers)
            geom_text(aes(label = round(inzidenz7tage)), vjust = "bottom", hjust = "middle", nudge_y = 8, check_overlap = TRUE, size = 3.4, na.rm = TRUE)
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
