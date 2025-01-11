utils <- loadModule("R/utils.R")


rsvJahresberichte <- read_delim(
  file = "data/schulen/rsvJahresberichte.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    schuljahresbeginn = col_integer(),
    schulleiter = col_character(),
    schuelerSchuljahresbeginn = col_integer(),
    zugaenge = col_integer(),
    abgaenge = col_integer(),
    schuelerSchuljahresende = col_integer(),
    schuelerMaennlich = col_integer(),
    schuelerWeiblich = col_integer(),
    klassen = col_integer(),
    kommentar = col_character(),
  )
) %>% mutate(
    schulleiter = parse_factor(schulleiter, include_na = FALSE),
    schueler = coalesce(schuelerSchuljahresbeginn, schuelerSchuljahresende)
  )

arcgisSchueler <- read_delim(
  file = "data/schulen/arcgisSchueler.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    schule = readr::col_factor(),
    schuljahresbeginn = col_integer(),
    schueler = col_integer(),
    klassen = col_integer(),
  )
) %>% filter(
    schule == "Staatliche Realschule Vaterstetten"
  )

rsv <- merge(rsvJahresberichte, arcgisSchueler, by = "schuljahresbeginn", all = TRUE) %>% mutate(
  schule = NULL,
  schuelerJahresbericht = schueler.x,
  schuelerArcgis = schueler.y,
  schueler = coalesce(schuelerJahresbericht, schuelerArcgis),
  schueler.x = NULL,
  schueler.y = NULL,
  klassenJahresbericht = klassen.x,
  klassenArcgis = klassen.y,
  klassen = coalesce(klassenJahresbericht, klassenArcgis),
  klassen.x = NULL,
  klassen.y = NULL,
)

arcgisSchuelerPrognose <- read_delim(
  file = "data/schulen/arcgisSchuelerPrognose2022.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    schule = readr::col_factor(),
    schuljahresbeginn = col_integer(),
    schueler = col_integer(),
  )
) %>% filter(
    schule == "Staatliche Realschule Vaterstetten"
  )

schulleiter <- rsv %>%
  filter(!is.na(schulleiter)) %>%
  group_by(schulleiter) %>%
  summarise(
    anfang = min(schuljahresbeginn),
    ende = max(schuljahresbeginn),
    .groups = "drop"
  ) %>% mutate(
    jahre = ende - anfang + 1,
  )


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Staatliche Realschule Vaterstetten"),

    fluidRow(
      box(
        title = "Mithilfe gesucht!",
        width = 12,
        status = "info",
        solidHeader = TRUE,
        tagList(
          p(HTML('Damit wir genauso umfassende Daten wie für das <a href="/?tab=hgv">Humboldt-Gymnasium</a> darstellen können, brauchen wir Ihre Mithilfe. Haben Sie alte Jahresberichte oder vergleichbare Quellen parat? Dann freuen wir uns über eine Datenspende an <a href="mailto:felix@vaterstetten-in-zahlen.de">felix@vaterstetten-in-zahlen.de</a> oder gleich via <a href="https://github.com/fxedel/vaterstetten-in-zahlen">GitHub</a>.')),
          p("Insbesondere wären folgende Informationen hilfreich:"),
          tags$ul(
            tags$li("Sämtliche Jahresberichte seit dem Schuljahr 1980/1981 – daraus dann jeweils die Seite mit den Schülerstatistiken"),
            tags$li("Namen und Amtszeiten der Schulleiter:innen"),
          ),
          p("Davon abgesehen sind natürlich sämtliche zusätzliche Daten ebenfalls möglicherweise von Interesse."),
          p("Vielen Dank an alle Mithelfenden!"),
        ),
      ),
    ),

    fluidRow(
      box(
        title = "Schülerzahlen",
        width = 6,
        radioGroupButtons(
          inputId = ns("plotTotalTextSwitch"),
          label = NULL,
          choices = c("Ohne Text" = "empty", "Mit Kommentaren" = "comments", "Mit Schulleitern" = "schulleiter")
        ),
        plotlyOutput(ns("plotTotal")),
        p({
          lastRow <- rsv %>% filter(!is.na(schueler)) %>% slice_tail()
          paste0("Im Schuljahr ", lastRow$schuljahresbeginn, "/", lastRow$schuljahresbeginn+1, " haben ", utils$germanNumberFormat(lastRow$schueler), " Schüler:innen die Realschule Vaterstetten besucht.")
        }),
        p("Die Prognose wurde im Frühjahr 2022 vom Landratsamt Ebersberg veröffentlicht. Grundlage ist die Einwohnerentwicklung im Landkreis Ebersberg, die anhand von Altersstruktur, Fertilität, Mortalität, Wanderungen und Siedlungsentwicklung bestimmt wird."),
        p("Hinweis: Im Schuljahr 2020/2021 ist Schulleiterin Anita Ruppelt plötzlich verstorben, daraufhin übernahm ihr Stellvertreter Stefan Gasior.")
      ),
      box(
        title = "Klassenanzahl",
        width = 6,
        {
          plot_ly(data = rsv, x = ~schuljahresbeginn) %>%
            add_trace(y = ~klassen, name = "Klassen", type = "scatter", mode = "lines+markers", text = ~paste0(schuljahresbeginn, "/", schuljahresbeginn+1), hovertemplate = "%{y} Klassen,\nSchuljahr %{text}<extra></extra>") %>%
            plotly_default_config() %>%
            plotly_time_range(min_year = min(rsv$schuljahresbeginn), max_year = max(rsv$schuljahresbeginn)) %>%
            layout(yaxis = list(title = "Klassen", tickformat = ",d")) %>%
            layout(xaxis = list(title = "")) %>%
            plotly_build()
        },
      ),
    ),

    fluidRow(
      box(
        title = "Durchschnittliche Klassengröße",
        width = 6,
        {
          plot_ly(data = rsv, x = ~schuljahresbeginn) %>%
            add_trace(y = ~schueler/klassen, name = "Klassen", type = "scatter", mode = "lines+markers", text = ~paste0(schuljahresbeginn, "/", schuljahresbeginn+1), hovertemplate = "⌀ %{y} Schüler:innen pro Klasse,\nSchuljahr %{text}<extra></extra>") %>%
            plotly_default_config() %>%
            plotly_time_range(min_year = min(rsv$schuljahresbeginn), max_year = max(rsv$schuljahresbeginn)) %>%
            layout(yaxis = list(title = "Klassen", tickformat = ",.1f")) %>%
            layout(xaxis = list(title = "")) %>%
            plotly_build()
        },
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        width = 12,
        status = "primary",
        solidHeader = TRUE,
        tagList(
          p(HTML('Datenquelle ist die <a href=\"https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services\">ArcGIS-API</a> des Landratsamts Ebersberg, die für das <a href=\"https://experience.arcgis.com/experience/da3e6d0ac8774a3a9e3ad227e7123c30\">Bildungsdashboard Ebersberg</a> verwendet wird. Dazu gehört u.&nbsp;A. die Schülerprognose.')),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/schulen", "Zum Daten-Download mit Dokumentation")),
        ),
      ),
    ),

  ) %>% renderTags()
})


plotly_default_config <- function(p) {
  p %>%
    config(locale = "de") %>%
    config(displaylogo = FALSE) %>%
    config(displayModeBar = TRUE) %>%
    config(modeBarButtons = list(list("toImage"))) %>%
    config(toImageButtonOptions = list(scale = 2)) %>%
    layout(yaxis = list(fixedrange = TRUE, rangemode = "tozero")) %>%
    layout(dragmode = FALSE) %>%
    layout(legend = list(bgcolor = "#ffffffaa", orientation = "h")) %>% # legend below plot
    identity()
}

plotly_time_range <- function(p, min_year, max_year) {
  p %>%
    layout(hovermode = "x") %>%
    layout(xaxis = list(fixedrange = TRUE, range = c(min_year-1, max_year+1))) %>%
    identity()
}

server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {

      output$plotTotal <- renderPlotly({
        p <- plot_ly(data = rsv, x = ~schuljahresbeginn) %>%
          add_trace(y = ~schueler, name = "Schüler:innen", type = "scatter", mode = "lines+markers", text = ~paste0(schuljahresbeginn, "/", schuljahresbeginn+1), hovertemplate = "%{y} Schüler:innen,\nSchuljahr %{text}<extra></extra>") %>%
          add_trace(data = arcgisSchuelerPrognose, y = ~schueler, name = "Prognose", type = "scatter", mode = "lines", line = list(dash = "5px,3px"), text = ~paste0(schuljahresbeginn, "/", schuljahresbeginn+1), hovertemplate = "Prognose:\n%{y} Schüler:innen,\nSchuljahr %{text}<extra></extra>") %>%
          identity()

        if (input$plotTotalTextSwitch == "comments") {
          p <- p %>%
            add_annotations(data = rsv %>% filter(!is.na(kommentar)), x = ~schuljahresbeginn, y = 30, text = ~paste0(schuljahresbeginn, ": ", kommentar), textangle = -90, xanchor = "center", yanchor = "bottom", showarrow = FALSE) %>%
            identity()
        } else if (input$plotTotalTextSwitch == "schulleiter") {
          p <- p %>%
            add_annotations(data = schulleiter, x = ~((anfang+ende)/2), y = 30, text = ~schulleiter, textangle = -90, xanchor = "center", yanchor = "bottom", showarrow = FALSE) %>%
            add_segments(data = schulleiter, x = ~anfang-1/2, xend = ~anfang-1/2, y = 0, yend = 1200, color = I("gray"), line = list(dash = "dot"), showlegend = FALSE, hoverinfo = "skip") %>%
            identity()
        }

        p %>%
          plotly_default_config() %>%
          plotly_time_range(min_year = min(rsv$schuljahresbeginn), max_year = max(arcgisSchuelerPrognose$schuljahresbeginn)) %>%
          layout(yaxis = list(title = "Schüler:innen", tickformat = ",d")) %>%
          layout(xaxis = list(title = "")) %>%
          plotly_build()
      })

    }
  )
}
