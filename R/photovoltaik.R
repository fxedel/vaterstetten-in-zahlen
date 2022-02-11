utils <- new.env()
sys.source("R/utils.R", envir = utils, chdir = FALSE)

mastr <- read_delim(
  file = "data/energie/mastrPhotovoltaik.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    MaStRId = col_integer(),
    MaStRNummer = col_character(),
    EEGAnlagenschluessel = col_character(),
    status = readr::col_factor(c("In Planung", "In Betrieb", "Vorübergehend stillgelegt", "Endgültig stillgelegt"), ordered = TRUE),
    inbetriebnahme = col_date(format = "%Y-%m-%d"),
    inbetriebnahmeGeplant = col_date(format = "%Y-%m-%d"),
    stilllegung = col_date(format = "%Y-%m-%d"),
    name = col_character(),
    betreiber = col_character(),
    plz = readr::col_factor(),
    ort = readr::col_factor(c("Baldham", "Vaterstetten", "Weißenfeld", "Hergolding", "Parsdorf", "Purfing", "Neufarn")),
    strasse = col_character(),
    hausnummer = col_character(),
    lat = col_double(),
    long = col_double(),
    netzbetreiberPruefung = col_logical(),
    typ = readr::col_factor(c("freiflaeche", "gebaeude", "gebaeude-other", "stecker")),
    module = col_integer(),
    ausrichtung = col_character(),
    bruttoleistung_kW = col_double(),
    nettonennleistung_kW = col_double(),
    EEGAusschreibung = col_logical(),
    einspeisung = readr::col_factor(c("Teileinspeisung", "Volleinspeisung")),
    mieterstrom = col_logical()
  )
) %>%
  mutate(
    anlagenGroesse = cut(
      bruttoleistung_kW,
      breaks = c(0, 10, 100, Inf),
      labels = c("Kleine Anlagen (<10kW)", "Mittlere Anlagen (10-100kW)", "Große Anlagen (≥100kW)"), 
      include.lowest = TRUE
    )
  ) %>%
  identity()

installationenNachJahrGroesse <- mastr %>%
  filter(!is.na(inbetriebnahme)) %>%
  group_by(year = year(inbetriebnahme), anlagenGroesse) %>%
  summarise(bruttoleistung_kW = sum(bruttoleistung_kW), anlagen = n(), .groups = "drop") %>%
  identity()

anlagenKumulativ <- merge(
  mastr %>%
    filter(!is.na(inbetriebnahme)) %>%
    filter(status != "In Planung") %>%
    group_by(inbetriebnahme) %>%
    summarise(bruttoleistung_kW = sum(bruttoleistung_kW), anlagen = n()) %>% # summarize installations of same day
    transmute(
      datum = inbetriebnahme,
      leistungInbetriebgenommen = cumsum(bruttoleistung_kW),
      anlagenInbetriebgenommen = cumsum(anlagen)
    ),
  mastr %>%
    filter(!is.na(stilllegung)) %>%
    group_by(stilllegung) %>%
    summarise(bruttoleistung_kW = sum(bruttoleistung_kW), anlagen = n()) %>% # summarize suspensions of same day
    transmute(
      datum = stilllegung,
      leistungStillgelegt = cumsum(bruttoleistung_kW),
      anlagenStillgelegt = cumsum(anlagen)
    ),
  by = "datum", all = "true") %>% # outer join
  add_row(
    datum = parse_date("2000-01-01"),
    leistungInbetriebgenommen = 0,
    anlagenInbetriebgenommen = 0,
    leistungStillgelegt = 0,
    anlagenStillgelegt = 0,
    .before = 0
  ) %>%
  fill(
    leistungInbetriebgenommen,
    anlagenInbetriebgenommen,
    leistungStillgelegt,
    anlagenStillgelegt,
    .direction = "down"
  ) %>%
  transmute(
    datum,
    leistungInBetrieb = leistungInbetriebgenommen - leistungStillgelegt,
    anlagenInBetrieb = anlagenInbetriebgenommen - anlagenStillgelegt,
    leistungStillgelegt,
    anlagenStillgelegt,
  ) %>%
  identity()

inBetriebStats <- mastr %>%
  filter(status == "In Betrieb") %>%
  summarise(bruttoleistung_kW = sum(bruttoleistung_kW), anlagen = n()) %>%
  identity()
inPlanungStats <- mastr %>%
  filter(status == "In Planung") %>%
  summarise(bruttoleistung_kW = sum(bruttoleistung_kW), anlagen = n()) %>%
  identity()

valueBoxLeistungInBetrieb <- valueBox(
  utils$germanNumberFormat(inBetriebStats$bruttoleistung_kW, suffix = " MWp", scale = 1/1000, accuracy = 0.2),
  "Installierte Photovoltaik-Leistung in Vaterstetten",
  color = "yellow",
  icon = icon("bolt")
)
valueBoxAnlagenInBetrieb <- valueBox(
  utils$germanNumberFormat(inBetriebStats$anlagen),
  "Photovoltaik-Anlagen in Betrieb",
  color = "yellow",
  icon = icon("solar-panel")
)
valueBoxAnlagenInPlanung <- valueBox(
  utils$germanNumberFormat(inPlanungStats$anlagen),
  "Photovoltaik-Anlagen in Planung",
  color = "yellow",
  icon = icon("edit")
)


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

plotly_axis_spacing <- function(p, col, left = 0, right = 0) {
  width <- max(col) - min(col)
  p %>%
    layout(xaxis = list(range = c(min(col)-left*width, max(col)+right*width)))
}

plotly_hide_axis_titles <- function(p) {
  p %>%
    layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(margin = list(l = 0, pad = 0, b = 30)) %>%
    identity()
}

plotlyLeistung <- plot_ly(anlagenKumulativ, x = ~datum, line = list(shape = "hv"), yhoverformat = ",.2f", height = 350) %>%
  add_trace(y = ~leistungStillgelegt / 1000, type = "scatter", mode = "lines", fill = 'tozeroy', color = I("#ff0000"), name = "Stillgelegt") %>%
  add_trace(y = ~leistungInBetrieb / 1000, type = "scatter", mode = "lines", fill = 'tonexty', color = I("#0570b0"), name = "In Betrieb") %>%
  layout(yaxis = list(exponentformat = "none", ticksuffix = " MWp")) %>%
  plotly_axis_spacing(anlagenKumulativ$datum, left = 0, right = 0.02) %>%
  plotly_default_config() %>%
  plotly_hide_axis_titles() %>%
  plotly_build() %>%
  identity()

plotlyAnlagen <- plot_ly(anlagenKumulativ, x = ~datum, line = list(shape = "hv"), yhoverformat = ",d", height = 350) %>%
  add_trace(y = ~anlagenStillgelegt, type = "scatter", mode = "lines", fill = 'tozeroy', color = I("#ff0000"), name = "Stillgelegt") %>%
  add_trace(y = ~anlagenInBetrieb, type = "scatter", mode = "lines", fill = 'tonexty', color = I("#0570b0"), name = "In Betrieb") %>%
  plotly_axis_spacing(anlagenKumulativ$datum, left = 0, right = 0.02) %>%
  plotly_default_config() %>%
  plotly_hide_axis_titles() %>%
  plotly_build() %>%
  identity()

plotlyLeistungNachJahrGroesse <- plot_ly(installationenNachJahrGroesse, x = ~year, yhoverformat = ",.0f", height = 350) %>%
  add_trace(y = ~bruttoleistung_kW, type = "bar", color = ~anlagenGroesse) %>%
  layout(yaxis = list(exponentformat = "none", ticksuffix = " kWp")) %>%
  layout(barmode = 'stack') %>%
  plotly_axis_spacing(installationenNachJahrGroesse$year, left = 0, right = 0.02) %>%
  plotly_default_config() %>%
  plotly_hide_axis_titles() %>%
  plotly_build() %>%
  identity()

plotlyAnlagenNachJahrGroesse <- plot_ly(installationenNachJahrGroesse, x = ~year, yhoverformat = ",d", height = 350) %>%
  add_trace(y = ~anlagen, type = "bar", color = ~anlagenGroesse) %>%
  layout(barmode = 'stack') %>%
  plotly_axis_spacing(installationenNachJahrGroesse$year, left = 0, right = 0.02) %>%
  plotly_default_config() %>%
  plotly_hide_axis_titles() %>%
  plotly_build() %>%
  identity()

ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Photovoltaik-Anlagen in der Gemeinde Vaterstetten"),

    fluidRow(
      valueBoxLeistungInBetrieb,
      valueBoxAnlagenInBetrieb,
      valueBoxAnlagenInPlanung
    ),

    fluidRow(
      box(
        title = "Installierte Photovoltaik-Leistung",
        plotlyLeistung
      ),
      box(
        title = "Installierte Photovoltaik-Anlagen",
        plotlyAnlagen
      ),
    ),

    fluidRow(
      box(
        title = "Neu installierte Leistung nach Jahr",
        plotlyLeistungNachJahrGroesse
      ),
      box(
        title = "Neu installierte Anlagen nach Jahr",
        plotlyAnlagenNachJahrGroesse
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p(HTML('Datengrundlage ist das <a href="https://www.marktstammdatenregister.de">Marktstammdatenregister</a> (MaStR) der Bundesnetzagentur, in dem alle Anlagen und Einheiten des deutschen Energiesystems registriert sind bzw. sein sollten. Die öffentlich zugänglichen Daten stehen unter der <a href="https://www.govdata.de/dl-de/by-2-0">Datenlizenz Deutschland – Namensnennung – Version 2.0</a>.')),
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
