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

fallzahlenArcGISGemeinden <- read_delim(
  file = "data/corona-fallzahlen/arcgisInzidenzGemeinden.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    ort = readr::col_factor(),
    neuPositiv = col_integer(),
    inzidenz7tage = col_double()
  )
)

fallzahlenArcGISLandkreis <- read_delim(
  file = "data/corona-fallzahlen/arcgisInzidenzLandkreis.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    datum = col_date(format = "%Y-%m-%d"),
    neuPositiv = col_integer(),
    inzidenz7tage = col_double()
  )
)

ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

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
          p(HTML("Die hier veröffentliche 7-Tage-Inzidenz ist <strong>nicht</strong> relevant für lokale Corona-Beschränkungen. Geringe Zahlen in Vaterstetten sind nicht automatisch ein Beweis für eine geringe Infektionsgefahr in Vaterstetten."))
        )
      )
    ),

    fluidRow(
      {
        last7rows <- fallzahlenArcGISGemeinden %>% filter(ort == "Vaterstetten") %>% slice_tail(n = 7)
        valueBox(
          sum(last7rows$neuPositiv),
          "Neue Fälle in den letzten 7 Tagen",
          color = "red",
          icon = icon("user-check")
        )
      },
      {
        lastRow <- fallzahlenArcGISGemeinden %>% filter(ort == "Vaterstetten") %>% slice_tail()
        valueBox(
          format(round(lastRow$inzidenz7tage, 1), nsmall = 1),
          "7-Tage-Inzidenz",
          color = "red",
          icon = icon("chart-line")
        )
      },
      {
        lastRow <- fallzahlenArcGISGemeinden %>% filter(ort == "Vaterstetten") %>% slice_tail()
        valueBox(
          format(lastRow$datum, "%-d. %b %Y"),
          "Datenstand des Gesundheitsamtes",
          color = "red",
          icon = icon("calendar-day")
        )
      }
    ),

    fluidRow(
      box(
        title = "Neuinfektionen (Gemeinde Vaterstetten)",
        {
          data <- fallzahlenArcGISGemeinden %>% filter(ort == "Vaterstetten")
          plot_ly(data, x = ~datum, yhoverformat = ",.0d", height = 400) %>%
            add_trace(y = ~neuPositiv, type = "bar") %>%
            plotly_default_config() %>%
            plotly_time_range(data$datum, defaultOffset = 42) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
        p("Mit „Neuinfektionen“ ist an dieser Stelle die Anzahl positiver Testungen gemeint.")
      ),
      box(
        title = "7-Tage-Inzidenz pro 100.000 Einwohner",
        {
          dataVat <- fallzahlenArcGISGemeinden %>% filter(ort == "Vaterstetten")
          plot_ly(yhoverformat = ",.1f", height = 400) %>%
            add_trace(data = dataVat, x = ~datum, y = ~inzidenz7tage, type = "scatter", mode = "lines", name = "Vaterstetten") %>%
            add_trace(data = fallzahlenArcGISLandkreis, x = ~datum, y = ~inzidenz7tage, type = "scatter", mode = "lines", name = "Landkreis Ebersberg") %>%
            plotly_default_config() %>%
            plotly_time_range(fallzahlenArcGISGemeinden$datum, defaultOffset = 42) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        }
      )
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
  ) %>% renderTags()
})


# Define the server logic for a module
server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
    }
  )
}


plotly_default_config <- function(p) {
  p %>%
    config(displayModeBar = FALSE) %>%
    config(locale = "de") %>%
    layout(xaxis = list(fixedrange = TRUE, rangemode = 'tozero')) %>%
    layout(yaxis = list(fixedrange = TRUE)) %>%
    layout(hovermode = "x") %>%
    layout(dragmode = FALSE) %>%
    identity()
}

plotly_axis_spacing <- function(p, col, left = 0, right = 0) {
  width <- max(col) - min(col)
  p %>%
    layout(xaxis = list(range = c(min(col)-left*width, max(col)+right*width)))
}

plotly_time_range <- function(p, timeCol, defaultOffset = 91) {
  maxDatum <- max(timeCol)
  p %>%
    # legend above plot
    layout(legend = list(bgcolor = "#ffffffaa", orientation = 'h', y = 1.2, yanchor = "bottom")) %>%
    # default time selection
    layout(xaxis = list(range = list(maxDatum-defaultOffset, maxDatum+1))) %>%
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
    config(doubleClick = FALSE) %>%
    identity()
}

plotly_hide_axis_titles <- function(p) {
  p %>%
    layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(margin = list(l = 0, pad = 0, b = 30)) %>%
    identity()
}
