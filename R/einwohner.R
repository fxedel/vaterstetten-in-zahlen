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

saldoProJahr <- lfstatBevoelkerungCombined %>%
  # only keep latest entry for each year
  mutate(
    year = year(stichtag)
  ) %>%
  group_by(year) %>%
  filter(stichtag == max(stichtag)) %>%
  ungroup() %>%

  # remove last year if it is incomplete
  filter(
    row_number() < n() | (month(stichtag) == 12 & day(stichtag) == 31)
  ) %>%

  mutate(
    saldo = bevoelkerung - lag(bevoelkerung),
    interval = interval(lag(stichtag), stichtag),
    saldoProJahr = saldo / time_length(interval, unit = "years")
  ) %>%

  complete(year = seq(min(year), max(year)), fill = list()) %>%
  tail(-1) %>%
  fill(saldoProJahr, .direction = "up") %>%

  identity()


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Bevölkerung in der Gemeinde Vaterstetten"),

    fluidRow(
      box(
        title = "Bevölkerungsstatistik",
        width = 6,
        {
          plot_ly(x = ~stichtag, yhoverformat = ",d", xhoverformat = "%-d. %b %Y", height = 350) %>%
            add_trace(data = lfstatBevoelkerungCombined, y = ~bevoelkerung, name = "Bevölkerung", text = ~erhebungsart, type = "scatter", mode = "lines", color = I("#000000")) %>%
            add_trace(data = lfstatBevoelkerungCombined, y = ~maennlich, name = "Männer", type = "scatter", mode = "lines+markers", color = I("#1fc3aa"), marker = list(size = 3)) %>%
            add_trace(data = lfstatBevoelkerungCombined, y = ~weiblich, name = "Frauen", type = "scatter", mode = "lines+markers", color = I("#8624f5"), marker = list(size = 3)) %>%
            add_trace(data = lfstatBevoelkerungCombined %>% filter(erhebungsart == "Volkszählung"), y = ~bevoelkerung, name = "Volkszählungen", type = "scatter", mode = "markers", hoverinfo = "none", color = I("#000000")) %>%
            plotly_default_config() %>%
            plotly_time_range(
              range_start = min(lfstatBevoelkerungCombined$stichtag) - dyears(1),
              range_end = max(lfstatBevoelkerungCombined$stichtag) + dyears(0.25)
            ) %>%
            plotly_hide_axis_titles() %>%
            plotly_build()
        },
        p("Dargestellt sind sowohl Volkszählungsergebnisse, als auch seit 1956 die jährliche und seit 1971 sogar quartalsweise Bevölkerungsfortschreibung auf Basis der Melderegister. Bei den Volkszählungen 1987, 2011 und 2022 sind deutliche „Knicks“ zu erkennen: Hier wurde durch die Volkszählung die Ungenauigkeit der Melderegister korrigiert."),
        p(strong("Achtung: Die quartalsweisen Zahlen seit Juni 2022 sind noch nicht an die Volkszählung vom Mai 2022 angepasst, d. h., die Fortschreibung auf Basis der Melderegister wurde noch nicht durch das Volkszählungsergebnis korrigiert. Da die Bevölkerungszahl aus dem Zensus 2022 um etwa 1150 Einwohner:innen unter der vorherigen Fortschreibungszahl liegt, ist davon auszugehen, dass auch die aktuelle Bevölkerungszahl tatsächlich um etwa diese Zahl niedriger liegt.")),
        p("Mit „Bevölkerung“ sind hier lediglich Personen mit Hauptwohnsitz in der Gemeinde Vaterstetten gemeint, wie es in der Bevölkerungsstatistik üblich ist. Nebenwohnsitze werden zum Teil in anderen Statistiken erfasst. Die Staatsangehörigkeit spielt keine Rolle.")
      ),
      box(
        title = "Jährliche Bevölkerungsveränderung",
        width = 6,
        {
          data <- saldoProJahr %>% mutate(
            yearAsDate = date_decimal(year)
          )
          plot_ly(data, x = ~yearAsDate, xhoverformat = "%Y", height = 350) %>%
            add_trace(y = ~saldoProJahr, type = "bar", name = "Saldo pro Jahr") %>%
            add_trace(y = ~saldoProJahr, color = I("transparent"), type = "scatter", mode = "markers", name = "Saldo", hoverinfo = "none",  showlegend = FALSE) %>%
            add_segments(data = lfstatVolkszaehlungen, x = ~stichtag, xend = ~stichtag, y = -1000, yend = 1500, color = I("gray"), line = list(dash = "dot"), name = "Volkszählungen", hoverinfo = "none") %>%
            layout(yaxis = list(tickformat = "+,d")) %>%
            plotly_default_config() %>%
            layout(hovermode = "x unified") %>%
            plotly_time_range(
              range_start = min(data$yearAsDate) - dyears(1),
              range_end = max(data$yearAsDate) + dyears(1)
            ) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
        p("Dargestellt ist das jährliche Bevölkerungssaldo, also der Zuwachs bzw. die Abnahme der Bevölkerung im Vergleich zum Vorjahr, die sich durch Zu- und Abwanderung, sowie Geburten und Sterbefälle ergibt. Für die Jahre bis 1956, für die keine jährlichen Daten vorliegen, wird das durchschnittliche Saldo über mehrere Jahre hinweg berechnet, zu erkennen an den genau gleich hohen Balken nebeneinander."),
        p("Das Jahr mit dem größten Bevölkerungszuwachs ist 1973: In diesem Jahr ist die Bevölkerung um 1.629 Einwohner:innen gestiegen. Die rechnerisch starken Rückgänge in den Jahren 1987 und 2011 sind auf Korrekturen im Rahmen der jeweiligen Volkszählungen zurückzuführen und spiegeln keinen tatsächlichen starken Bevölkerungsrückgang in diesen Jahren wider.")
      )
    ),

    fluidRow(
      box(
        title = "Frauenanteil",
        width = 6,
        {
          data <- lfstatBevoelkerungCombined %>% filter(!is.na(frauenanteil))
          plot_ly(data, x = ~stichtag, yhoverformat = ",.2%", xhoverformat = "%-d. %b %Y", height = 350) %>%
            add_trace(y = ~frauenanteil, type = "scatter", mode = "lines", name = "Frauenanteil", color = I("#8da0cb")) %>%
            layout(shapes = list(type='line', x0 = min(data$stichtag), x1 = max(data$stichtag), y0 = 0.5, y1 = 0.5, line = list(dash = 'dot', width = 1))) %>%
            layout(yaxis = list(range = list(0.3, 0.7), tickformat = ',.0%')) %>%
            plotly_default_config() %>%
            plotly_time_range(
              range_start = min(data$stichtag) - dyears(1),
              range_end = max(data$stichtag) + dyears(0.25)
            ) %>%
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
          p(HTML('Datenquelle: Bayerisches Landesamt für Statistik – <a href="https://www.statistik.bayern.de">www.statistik.bayern.de</a>.')),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/einwohner", "Zum Daten-Download mit Dokumentation")),
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
    config(locale = "de") %>%
    config(displaylogo = FALSE) %>%
    config(displayModeBar = TRUE) %>%
    config(modeBarButtons = list(list("toImage"))) %>%
    config(toImageButtonOptions = list(scale = 2)) %>%
    layout(xaxis = list(fixedrange = TRUE)) %>%
    layout(yaxis = list(fixedrange = TRUE)) %>%
    layout(hovermode = "x unified") %>%
    layout(dragmode = FALSE) %>%
    layout(legend = list(bgcolor = "#ffffffaa", orientation = 'h')) %>% # legend below plot
    identity()
}

plotly_time_range <- function(p, range_start, range_end) {
  p %>%
    # default time selection
    layout(xaxis = list(range = list(range_start, range_end))) %>%
    layout(xaxis = list(
      rangeselector = list(
        buttons = list(
          list(count = 20, label = "20 Jahre", step = "year", stepmode = "backward"),
          list(count = 70, label = "70 Jahre", step = "year", stepmode = "backward"),
          list(count = range_end - range_start, label = "Gesamt", step = "day", stepmode = "backward")
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
