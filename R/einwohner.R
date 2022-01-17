lfstatFortschreibungJahre <- read_delim(
  file = "data/einwohner/lfstatFortschreibungJahre.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    stichtag = col_date(format = "%Y-%m-%d"),
    erhebungsart = readr::col_factor(),
    bevoelkerung = col_integer(),
    maennlich = col_integer(),
    weiblich = col_integer()
  )
)

lfstatFortschreibungQuartale <- read_delim(
  file = "data/einwohner/lfstatFortschreibungQuartale.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    stichtag = col_date(format = "%Y-%m-%d"),
    erhebungsart = readr::col_factor(),
    bevoelkerung = col_integer(),
    maennlich = col_integer(),
    weiblich = col_integer()
  )
)

lfstatVolkszaehlungen <- read_delim(
  file = "data/einwohner/lfstatVolkszaehlungen.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    stichtag = col_date(format = "%Y-%m-%d"),
    erhebungsart = readr::col_factor(),
    bevoelkerung = col_integer(),
    maennlich = col_integer(),
    weiblich = col_integer()
  )
)

lfstatBevoelkerungCombined <- bind_rows(
  lfstatFortschreibungJahre,
  lfstatFortschreibungQuartale,
  lfstatVolkszaehlungen
) %>%
  distinct() %>%
  arrange(stichtag) %>% # sort
  mutate(
    erhebungsart = factor(
      erhebungsart,
      levels = c("volkszaehlung", "fortschreibung"),
      labels = c("Volkszählung", "Fortschreibung")
    ),
    frauenanteil = weiblich/bevoelkerung
  ) %>%
  identity()



ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Bevölkerung in der Gemeinde Vaterstetten"),

    fluidRow(
      box(
        title = "Bevölkerungsstatistik",
        width = 12,
        {
          plot_ly(x = ~stichtag, yhoverformat = ",d", xhoverformat = "%-d. %b %Y", height = 350) %>%
            add_trace(data = lfstatBevoelkerungCombined %>% filter(!is.na(maennlich)), y = ~maennlich, name = "Männer", type = "scatter", mode = "none", fill = 'tozeroy', fillcolor = "#66c2a5", stackgroup = "geschlecht") %>%
            add_trace(data = lfstatBevoelkerungCombined %>% filter(!is.na(weiblich)), y = ~weiblich, name = "Frauen",type = "scatter", mode = "none", fill = 'tonexty', fillcolor = "#8da0cb",  stackgroup = "geschlecht") %>%
            add_trace(data = lfstatBevoelkerungCombined, y = ~bevoelkerung, name = "Bevölkerung", type = "scatter", mode = "lines", color = I("#000000")) %>%
            add_trace(data = lfstatBevoelkerungCombined %>% filter(erhebungsart == "Volkszählung"), y = ~bevoelkerung, name = "Volkszählungen", type = "scatter", mode = "markers", hovertemplate = "Volkszählung<extra></extra>", color = I("#000000")) %>%
            plotly_default_config() %>%
            plotly_time_range(lfstatBevoelkerungCombined$stichtag) %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
        p("Dargestellt sind sowohl Volkszählungsergebnisse, als auch die jährliche und seit 1971 sogar quartalsweise Bevölkerungsfortschreibung auf Basis der Melderegister. Bei den Volkszählungen 1987 und 2011 sind deutliche „Knicks“ zu erkennen: Hier wurde durch die Volkszählung die Ungenauigkeit der Melderegister korrigiert."),
        p("Mit „Bevölkerung“ sind hier lediglich Personen mit Hauptwohnsitz in der Gemeinde Vaterstetten gemeint, wie es in der Bevölkerungsstatistik üblich ist. Nebenwohnsitze werden zum Teil in anderen Statistiken erfasst. Die Staatsangehörigkeit spielt keine Rolle.")
      )
    ),

    fluidRow(
      box(
        title = "Frauenanteil",
        {
          data <- lfstatBevoelkerungCombined %>% filter(!is.na(frauenanteil))
          plot_ly(data, x = ~stichtag, yhoverformat = ",.2%", xhoverformat = "%-d. %b %Y", height = 350) %>%
            add_trace(y = ~frauenanteil, type = "scatter", mode = "lines", name = "Frauenanteil", color = I("#8da0cb")) %>%
            layout(shapes = list(type='line', x0 = min(data$stichtag), x1 = max(data$stichtag), y0 = 0.5, y1 = 0.5, line = list(dash = 'dot', width = 1))) %>%
            layout(yaxis = list(range = list(0.3, 0.7), tickformat = ',.0%')) %>%
            plotly_default_config() %>%
            plotly_time_range(data$stichtag) %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        }
      )
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        width = 12,
        status = "primary",
        solidHeader = TRUE,
        tagList(
          p(HTML('Datenquelle: Bayerisches Landesamt für Statistik – <a href="https://www.statistik.bayern.de">www.statistik.bayern.de</a>.'))
        ),
      ),
    ),
  ) %>% renderTags()
})

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
    layout(legend = list(bgcolor = "#ffffffaa", orientation = 'h')) %>% # legend below plot
    identity()
}

plotly_time_range <- function(p, xaxis) {
  axisWidth <- max(xaxis) - min(xaxis)
  scaleFactor <- 0.01
  p %>%
    layout(xaxis = list(
      rangeselector = list(
        buttons = list(
          list(count = 10, label = "10 Jahre", step = "year", stepmode = "backward"),
          list(count = 50, label = "50 Jahre", step = "year", stepmode = "backward"),
          list(step = "all", label = "Gesamt")
        )
      )
    )) %>%
    config(doubleClick = FALSE) %>%
    identity()
}

plotly_hide_axis_titles <- function(p) {
  return(
    p %>%
      layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
      layout(margin = list(l = 0, pad = 0, b = 30)) %>%
      identity()
  )
}
