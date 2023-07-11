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
    status = readr::col_factor(),
    inbetriebnahme = col_date(format = "%Y-%m-%d"),
    inbetriebnahmeGeplant = col_date(format = "%Y-%m-%d"),
    stilllegung = col_date(format = "%Y-%m-%d"),
    name = col_character(),
    betreiber = col_character(),
    gebaeudeNutzung = readr::col_factor(c("haushalt", "GHD", "industrie", "landwirtschaft", "oeffentlich", "sonstige")),
    plz = readr::col_factor(),
    ort = readr::col_factor(),
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
    einspeisung = readr::col_factor(),
    mieterstrom = col_logical()
  )
) %>%
  mutate(
    gebaeudeNutzung = recode_factor(gebaeudeNutzung,
      haushalt = "Private Haushalte",
      GHD = "Gewerbe, Handel, Dienstleistungen",
      industrie = "Industrie",
      landwirtschaft = "Landwirtschaft",
      oeffentlich = "Öffentliche Gebäude",
      sonstige = "Sonstige",
    ),
    # just to ensure order of factors; this can't be done above, since col_factor() has a problem with umlauts as in "Weißenfeld"
    status = recode_factor(status, 
      "In Planung" = "In Planung",
      "In Betrieb" = "In Betrieb",
      "Vorübergehend stillgelegt" = "Vorübergehend stillgelegt",
      "Endgültig stillgelegt" = "Endgültig stillgelegt",
      .ordered = TRUE
    ),
    ort = recode_factor(ort,
      "Baldham" = "Baldham",
      "Vaterstetten" = "Vaterstetten",
      "Weißenfeld" = "Weißenfeld",
      "Hergolding" = "Hergolding",
      "Parsdorf" = "Parsdorf",
      "Purfing" = "Purfing",
      "Neufarn" = "Neufarn",
    ),
    anlagenGroesse = cut(
      bruttoleistung_kW,
      breaks = c(0, 10, 100, Inf),
      labels = c("Kleine Anlagen (<10kW)", "Mittlere Anlagen (10-100kW)", "Große Anlagen (≥100kW)"), 
      include.lowest = TRUE
    )
  ) %>%
  identity()

installationenNachJahrGrouped <- memoise(function(groupVar) {
  mastr %>%
    filter(!is.na(inbetriebnahme)) %>%
    group_by(year = year(inbetriebnahme), across(all_of(groupVar))) %>%
    summarise(bruttoleistung_kW = sum(bruttoleistung_kW), anlagen = n(), .groups = "drop") %>%
    identity()
})


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


plotly_default_config <- function(p, hovermode = "x") {
  p %>%
    config(displayModeBar = FALSE) %>%
    config(locale = "de") %>%
    layout(xaxis = list(fixedrange = TRUE, rangemode = "tozero")) %>%
    layout(yaxis = list(fixedrange = TRUE)) %>%
    layout(hovermode = hovermode) %>%
    layout(dragmode = FALSE) %>%
    layout(legend = list(bgcolor = "#ffffffaa", orientation = "h")) %>% # legend below plot
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
  add_trace(y = ~leistungStillgelegt / 1000, type = "scatter", mode = "lines", fill = "tozeroy", color = I("#ff0000"), name = "Stillgelegt") %>%
  add_trace(y = ~leistungInBetrieb / 1000, type = "scatter", mode = "lines", fill = "tonexty", color = I("#0570b0"), name = "In Betrieb") %>%
  layout(yaxis = list(exponentformat = "none", ticksuffix = " MWp")) %>%
  plotly_axis_spacing(anlagenKumulativ$datum, left = 0, right = 0.02) %>%
  plotly_default_config() %>%
  plotly_hide_axis_titles() %>%
  plotly_build() %>%
  identity()

plotlyAnlagen <- plot_ly(anlagenKumulativ, x = ~datum, line = list(shape = "hv"), yhoverformat = ",d", height = 350) %>%
  add_trace(y = ~anlagenStillgelegt, type = "scatter", mode = "lines", fill = "tozeroy", color = I("#ff0000"), name = "Stillgelegt") %>%
  add_trace(y = ~anlagenInBetrieb, type = "scatter", mode = "lines", fill = "tonexty", color = I("#0570b0"), name = "In Betrieb") %>%
  plotly_axis_spacing(anlagenKumulativ$datum, left = 0, right = 0.02) %>%
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
        title = "Disclaimer",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML('Diese Zahlen basieren auf Eintragungen im <a href="https://www.marktstammdatenregister.de">Marktstammdatenregister</a>. Obwohl die Eintragung innerhalb eines Monats nach Inbetriebnahme verpflichtend und Voraussetzung für EEG-Förderung ist, werden viele Anlagen mit sehr großem Zeitverzug (bis zu zwei Jahre) eingetragen (siehe Grafik „Meldeverzug“ weiter unten). Somit sind die Zahlen für die letzten ein bis zwei Jahren wahrscheinlich zu niedrig. Außerdem werden immer wieder inkorrekte Angaben, z.&nbsp;B. zur Leistung, getätigt. Offensichtlich falsche Werte wurden bereits herausgefiltert.'))
        )
      )
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
        title = "Neu installierte Leistung pro Jahr",
        selectInput(
          ns("neuLeistungGroupVar"),
          label = NULL,
          choices = list(
            "Gruppiert nach Anlagengröße" = "anlagenGroesse",
            "Gruppiert nach Standort" = "ort",
            "Gruppiert nach Gebäudenutzung" = "gebaeudeNutzung"
          )
        ),
        plotlyOutput(ns("neuLeistungPlotly"), height = 350)
      ),
      box(
        title = "Neu installierte Anlagen pro Jahr",
        selectInput(
          ns("neuAnlagenGroupVar"),
          label = NULL,
          choices = list(
            "Gruppiert nach Anlagengröße" = "anlagenGroesse",
            "Gruppiert nach Standort" = "ort",
            "Gruppiert nach Gebäudenutzung" = "gebaeudeNutzung"
          )
        ),
        plotlyOutput(ns("neuAnlagenPlotly"), height = 350)
      ),
    ),

    fluidRow(
      box(
        title = "Mittlere Modulleistung in Watt-Peak pro Modul",
        {
          data <- mastr %>%
            filter(status == "In Betrieb") %>%
            group_by(year = year(inbetriebnahme)) %>%
            mutate(
              modulleistung = bruttoleistung_kW / module
            ) %>%
            filter(!is.na(modulleistung)) %>%
            filter(modulleistung < 1) %>% # more than 1 kWp per module is very unlikely 
            summarise(
              modulleistungP25 = quantile(modulleistung, .20),
              modulleistungMed = median(modulleistung),
              modulleistungP75 = quantile(modulleistung, .80),
            )

          plot_ly(data, x = ~year, yhoverformat = ",.1f", height = 350) %>%
            add_trace(y = ~modulleistungP75 * 1000, type = "scatter", mode = "lines", color = I("transparent"), name = "75%-Perzentil") %>%
            add_trace(y = ~modulleistungP25 * 1000, type = "scatter", mode = "lines", color = I("transparent"), name = "25%-Perzentil", fill = "tonexty", fillcolor = "rgba(5, 112, 176, 0.3)") %>%
            add_trace(y = ~modulleistungMed * 1000, type = "scatter", mode = "lines", color = I("#0570b0"), name = "Median") %>%
            layout(yaxis = list(exponentformat = "none", ticksuffix = " Wp", rangemode = "tozero")) %>%
            layout(showlegend = FALSE) %>%
            plotly_axis_spacing(data$year, left = 0, right = 0.02) %>%
            plotly_default_config() %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
          },
        p(HTML("Die Linie entspricht dem Median („mittlere“ Modulleistung), der farbige Bereich dem 25%- bis 75%-Perzentil, also der mittleren Hälfte aller Anlagen.")),
      ),
      box(
        title = "Stecker-Solarmodule („Balkonkraftwerke“)",
        {
          data <-  mastr %>% 
            filter(typ == "stecker") %>%
            filter(status == "In Betrieb") %>%
            group_by(inbetriebnahme) %>%
            summarise(module = sum(module)) %>%
            mutate(module = cumsum(module)) %>%
            add_row(
              inbetriebnahme = parse_date("2020-01-01"),
              module = 0,
              .before = 0
            )

          plot_ly(data, x = ~inbetriebnahme, line = list(shape = "hv"), yhoverformat = ",d", height = 350) %>%
            add_trace(y = ~module, type = "scatter", mode = "lines", color = I("#0570b0"), fill = "tozeroy", name = "Module") %>%
            layout(yaxis = list(rangemode = "tozero")) %>%
            plotly_axis_spacing(data$inbetriebnahme, left = 0, right = 0.02) %>%
            plotly_default_config() %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
        p(HTML("Mehr Infos zu Balkonkraftwerken gibt es im <a href=\"https://muenchen.solar2030.de/balkonkraftwerk/\">Guide von München Solar2030</a>.<br>Von Januar bis Ende September 2022, sowie von Januar 2023 bis Juni 2023 gab es eine Förderung von 25&nbsp;% und maximal 250&nbsp;€ von der <a href=\"https://www.vaterstetten.de/bauen-umwelt/energie-und-klimaschutz/energieeinspar-foerderprogramm/\">Gemeinde Vaterstetten</a>.")),
      ),
    ),

    fluidRow(
      box(
        title = "Meldeverzug zwischen Inbetriebnahme und MaStR-Registrierung",
        {
          data <- mastr %>%
            filter(status == "In Betrieb") %>%
            filter(inbetriebnahme >= "2019-02-01") %>% 
            filter(inbetriebnahme <= registrierungMaStR) %>%
            mutate(
              registrierungsDelay = as.integer(registrierungMaStR - inbetriebnahme),
              limit = as.integer(Sys.Date() - inbetriebnahme)
            ) %>%
            mutate(
              limit = ifelse(limit > max(registrierungsDelay), NA, limit)
            ) %>%
            identity()

          plot_ly(data, x = ~inbetriebnahme, yhoverformat = ",d", height = 350) %>%
            add_trace(y = ~registrierungsDelay, type = "scatter", mode = "markers", marker = list(opacity = 0.3, size = 8), name = "Meldeverzug") %>%
            add_trace(y = ~limit, type = "scatter", mode = "lines", color = I("#ff0000"), name = "Limit", line = list(dash = "dot")) %>%
            layout(xaxis = list(title = "Inbetriebnahme")) %>%
            layout(yaxis = list(title = "Meldeverzug", exponentformat = "none", ticksuffix = " Tage", rangemode = "tozero")) %>%
            layout(showlegend = FALSE) %>%
            plotly_axis_spacing(data$inbetriebnahme, left = 0.02, right = 0.02) %>%
            plotly_default_config(hovermode = "closest") %>%
            plotly_build() %>%
            identity()
        },
        p(HTML("Jeder Punkt stellt eine Anlage dar, wobei die Höhe des Punkts (also die Lage auf der Y-Achse) den Meldeverzug, also den Abstand zwischen Inbetriebnahme und Registrierung im Marktstammdatenregister darstellt. Es werden nur Inbetriebnahmen seit dem 1. Februar 2019 berücksichtigt, da erst seit diesem Zeitpunkt die Registrierung im MaStR möglich und innerhalb eines Monats nach Inbetriebnahme auch verpflichtend ist. Die rote Linie stellt den maximal möglichen Meldeverzug dar, der durch das heutige Datum gegeben ist.")),
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p(HTML('Datengrundlage ist das <a href="https://www.marktstammdatenregister.de">Marktstammdatenregister</a> (MaStR) der Bundesnetzagentur, in dem alle Anlagen und Einheiten des deutschen Energiesystems registriert sind bzw. sein sollten. Die öffentlich zugänglichen Daten stehen unter der <a href="https://www.govdata.de/dl-de/by-2-0">Datenlizenz Deutschland – Namensnennung – Version 2.0</a>.')),
        p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/energie", "Zum Daten-Download mit Dokumentation")),
      ),
    ),
  ) %>% renderTags()
})


server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      output$neuLeistungPlotly <- renderPlotly({
        data <- installationenNachJahrGrouped(input$neuLeistungGroupVar)
        plot_ly(data, x = ~year, yhoverformat = ",.0f") %>%
          add_trace(y = ~bruttoleistung_kW, type = "bar", color = ~get(input$neuLeistungGroupVar)) %>%
          layout(yaxis = list(exponentformat = "none", ticksuffix = " kWp")) %>%
          layout(barmode = "stack") %>%
          plotly_axis_spacing(data$year, left = 0, right = 0.02) %>%
          plotly_default_config() %>%
          plotly_hide_axis_titles() %>%
          plotly_build() %>%
          identity()
      })

      output$neuAnlagenPlotly <- renderPlotly({
        data <- installationenNachJahrGrouped(input$neuAnlagenGroupVar)
        plot_ly(data, x = ~year, yhoverformat = ",d") %>%
          add_trace(y = ~anlagen, type = "bar", color = ~get(input$neuAnlagenGroupVar)) %>%
          layout(barmode = "stack") %>%
          plotly_axis_spacing(data$year, left = 0, right = 0.02) %>%
          plotly_default_config() %>%
          plotly_hide_axis_titles() %>%
          plotly_build() %>%
          identity()
      })
    }
  )
}

