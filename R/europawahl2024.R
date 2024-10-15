utils <- new.env()
sys.source("R/utils.R", envir = utils, chdir = FALSE)


stimmbezirke <- read_csv(
  file = "data/wahlen/europawahl2024/stimmbezirke.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    StimmbezirkArt = readr::col_factor(),
    StimmbezirkAggregiert = readr::col_factor()
  )
)

stimmbezirkeGeodata <- st_read("data/wahlen/europawahl2024/stimmbezirke.geojson") %>%
  transmute(
    Stimmbezirk = name,
    geometry
  ) %>%
  left_join(stimmbezirke) %>%
  group_by(StimmbezirkAggregiert) %>%
  summarise(
    geometry = st_combine(geometry),
    .groups = "drop"
  )

parteien <- read_csv(
  file = "data/wahlen/europawahl2024/parteien.csv",
  col_types = cols(
    ParteiNr = readr::col_factor(),
    ParteiKuerzel = readr::col_factor(),
    ParteiName = readr::col_factor(),
    ParteiFarbe = col_character()
  )
)

ergebnisAllgemein <- read_csv(
  file = "data/wahlen/europawahl2024/ergebnisAllgemein.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    Wahlberechtigte = col_integer(),
    Waehler = col_integer(),
    UngueltigeStimmen = col_integer(),
    GueltigeStimmen = col_integer()
  )
) %>% 
  inner_join(stimmbezirke, by = join_by(Stimmbezirk))

ergebnisAllgemeinNachStimmbezirkAggregiert <- ergebnisAllgemein %>%
  group_by(StimmbezirkAggregiert, StimmbezirkArt) %>%
  summarise(
    Wahlberechtigte = sum(Wahlberechtigte),
    Waehler = sum(Waehler),
    UngueltigeStimmen = sum(UngueltigeStimmen),
    GueltigeStimmen = sum(GueltigeStimmen),
    .groups = "drop"
  ) %>%
  pivot_wider(
    id_cols = StimmbezirkAggregiert,
    names_from = StimmbezirkArt,
    values_from = Waehler,
    names_prefix = "Waehler",
    unused_fn = sum
  ) %>%
  mutate(
    Waehler = WaehlerWahllokal + WaehlerBriefwahl
  ) %>% mutate(
    WaehlerNA = NULL,
    Waehler = coalesce(Waehler, sum(Waehler, na.rm=TRUE)),
    WaehlerWahllokal = coalesce(WaehlerWahllokal, sum(WaehlerWahllokal, na.rm=TRUE)),
    WaehlerBriefwahl = coalesce(WaehlerBriefwahl, sum(WaehlerBriefwahl, na.rm=TRUE)),
    Wahlbeteiligung = Waehler/Wahlberechtigte,
    Briefwahlquote = WaehlerBriefwahl/Waehler
  )

ergebnisAllgemeinNachStimmbezirkArt <- ergebnisAllgemein %>%
  filter(!is.na(StimmbezirkArt)) %>%
  group_by(StimmbezirkArt) %>%
  summarise(
    Waehler = sum(Waehler),
    UngueltigeStimmen = sum(UngueltigeStimmen),
    GueltigeStimmen = sum(GueltigeStimmen)
  )

ergebnisNachPartei <- read_csv(
  file = "data/wahlen/europawahl2024/ergebnisNachPartei.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    ParteiKuerzel = readr::col_factor(levels = levels(parteien$ParteiKuerzel)),
    Stimmen = col_integer()
  )
) %>%
  inner_join(stimmbezirke, by = join_by(Stimmbezirk))

ergebnisNachParteiNachStimmbezirkAggregiert <- ergebnisNachPartei %>%
  group_by(StimmbezirkAggregiert, ParteiKuerzel) %>%
  summarise(
    Stimmen = sum(Stimmen),
    .groups = "drop"
  ) %>%
  inner_join(parteien, by = "ParteiKuerzel") %>%
  inner_join(ergebnisAllgemeinNachStimmbezirkAggregiert %>% select(StimmbezirkAggregiert, GueltigeStimmen), by = c("StimmbezirkAggregiert")) %>%
  mutate(StimmenAnteil = Stimmen/GueltigeStimmen)

ergebnisNachParteiNachStimmbezirkArt <- ergebnisNachPartei %>%
  group_by(StimmbezirkArt, ParteiKuerzel) %>%
  summarise(
    Stimmen = sum(Stimmen),
    .groups = "drop"
  ) %>%
  inner_join(parteien, by = "ParteiKuerzel") %>%
  inner_join(ergebnisAllgemeinNachStimmbezirkArt %>% select(StimmbezirkArt, GueltigeStimmen), by = c("StimmbezirkArt")) %>%
  mutate(StimmenAnteil = Stimmen/GueltigeStimmen)

ergebnisNachParteiNachCombined <- bind_rows(
  ergebnisNachParteiNachStimmbezirkAggregiert %>%
    mutate(Filter = StimmbezirkAggregiert, StimmbezirkAggregiert = NULL) %>%
    filter(Filter == "Gesamt"),
  ergebnisNachParteiNachStimmbezirkArt %>%
    mutate(Filter = paste0("Alle ", StimmbezirkArt, "bezirke"), StimmbezirkArt = NULL),
  ergebnisNachParteiNachStimmbezirkAggregiert %>%
    mutate(Filter = StimmbezirkAggregiert, StimmbezirkAggregiert = NULL) %>%
    filter(Filter != "Gesamt")
)


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Europawahl 9. Juni 2024 in der Gemeinde Vaterstetten"),

    fluidRow(
      box(
        title = "Hinweise zu den Stimmbezirken",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Insgesamt gibt es 30 Stimmbezirke. Eingezeichnet sind die 15 Wahllokal-Stimmbezirke (1 bis 15), die auch in <a href=\"https://umap.openstreetmap.fr/de/map/landtagswahl-2023-stimmbezirke-vaterstetten_966387\">dieser (inoffiziellen) Karte (identisch zur Landtagswahl 2023)</a> im Detail angesehen werden können. Die 15 Briefwahlbezirke (31 bis 45) lassen sich den Wahllokal-Stimmbezirken zuordnen, sodass jedes Gebiet die Stimmen eines Wahllokal-Stimmbezirks sowie eines Briefwahlbezirks umfasst.")),
        ),
      ),
    ),

    br(),

    fluidRow(
      box(
        title = "Ergebnis nach Stimmbezirk",
        selectInput(
          ns("mapPartei"),
          label = "Partei",
          choices = {
            data <- parteien %>% mutate(
              Label = paste0(ParteiKuerzel, " (", ParteiName, ")")
            )
            
            choices = setNames(data$ParteiKuerzel, data$Label)
            choices
          },
        ),
        leafletOutput(ns("map"), height = 550),
        p(),
        p("Die Gebiete sind jeweils nach den Stimmen der ausgewählten Partei eingefärbt. Jedes Gebiet umfasst einen Wahllokalstimmbezirk und einen Briefwahlbezirk."),
        p("Klicke auf einen Stimmbezirk, um ihn im Balkendiagramm anzuzeigen.")
      ),
      column(
        width = 6,
        box(
          width = NULL,
          title = "Stimmen nach Stimmbezirk",
          selectInput(
            ns("barChoices"),
            label = "Stimmbezirk",
            choices = {
              (ergebnisNachParteiNachCombined %>% filter(ParteiNr == 1))$Filter
            },
            selected = "Gesamt"
          ),
          plotlyOutput(ns("barPlotly"), height = 600)
        ),
        box(
          width = NULL,
          title = "Stimmen nach Stimmbezirk-Art",
          {
            plot_ly(
              ergebnisAllgemeinNachStimmbezirkArt,
              height = 100,
              orientation = "h",
              showlegend = TRUE
            ) %>%
              add_bars(y = ~StimmbezirkArt, x = ~UngueltigeStimmen, name = "ungültig", marker = list(color = "#B71C1C")) %>%
              add_bars(y = ~StimmbezirkArt, x = ~GueltigeStimmen, name = "gültig", marker = list(color = "#81C784")) %>%
              plotly_default_config() %>%
              layout(yaxis = list(autorange = "reversed")) %>%
              layout(xaxis = list(tickformat = ",d", hoverformat = ",d")) %>%
              layout(uniformtext = list(minsize = 14, mode = "show")) %>%
              layout(barmode = 'stack') %>%
              layout(hovermode = "y unified") %>%
              plotly_hide_axis_titles() %>%
              plotly_build() %>%
              identity()
          },
        ),
      ),
    ),

    fluidRow(
      box(
        title = "Wahlbeteiligung nach Stimmbezirk",
        {
          data <- ergebnisAllgemeinNachStimmbezirkAggregiert
          mapData <- stimmbezirkeGeodata %>% left_join(data, by = "StimmbezirkAggregiert")
          pal <- colorNumeric(c("#bbbbbb", "#000000"), c(0.65, 0.95))

          leaflet(stimmbezirkeGeodata, height = 550, options = leafletOptions(
            zoom = 13,
            center = list(lng = 11.798, lat = 48.12)
          )) %>%
            addProviderTiles(providers$CartoDB.Positron) %>%
            addPolygons(
              data = mapData,
              stroke = TRUE,
              weight = 0.0001, # stroke width
              color = "#000000", # stroke color
              opacity = 0.0001, # stroke opacity
              fillColor = ~pal(Wahlbeteiligung),
              fillOpacity = 0.6,
              layerId = ~StimmbezirkAggregiert,
              label = ~paste0(
                StimmbezirkAggregiert, ": ", scales::percent(Wahlbeteiligung, accuracy = 0.1), "<br />",
                "(", utils$germanNumberFormat(Waehler), " Wähler:innen bei ", utils$germanNumberFormat(Wahlberechtigte), " Wahlberechtigten)"
              ) %>% lapply(HTML),
              highlight = highlightOptions(
                bringToFront = TRUE,
                sendToBack = TRUE,
                weight = 3, # stroke width
                opacity = 1.0, # stroke opacity
              )
            ) %>%
            addLegend("topright",
              data = mapData,
              pal = pal,
              values = ~Wahlbeteiligung,
              title = NULL,
              labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
              opacity = 0.8,
              bins = 5
            )
        },
        p(),
        p("Die Gebiete sind jeweils nach dem Anteil der abgegebenen Stimmen (ungültige eingeschlossen) im Verhältnis zu allen Wahlberechtigten eingefärbt. Jedes Gebiet umfasst einen Wahllokalstimmbezirk und einen Briefwahlbezirk."),
        {
          rowGesamt <- ergebnisAllgemeinNachStimmbezirkAggregiert %>% filter(StimmbezirkAggregiert == "Gesamt")
          p(paste0("Die gesamte Wahlbeteiligung in der Gemeinde Vaterstetten beträgt ", scales::percent(rowGesamt$Wahlbeteiligung, accuracy = 0.1), " (", utils$germanNumberFormat(rowGesamt$Waehler), " Wähler:innen bei insgesamt ", utils$germanNumberFormat(rowGesamt$Wahlberechtigte), " Wahlberechtigten)."))
        },
      ),
      box(
        title = "Briefwahlquote nach Stimmbezirk",
        {
          data <- ergebnisAllgemeinNachStimmbezirkAggregiert
          mapData <- stimmbezirkeGeodata %>% left_join(data, by = "StimmbezirkAggregiert")
          pal <- colorNumeric(c("#888888", "#000000"), c(min(data$Briefwahlquote), max(data$Briefwahlquote)))

          leaflet(stimmbezirkeGeodata, height = 550, options = leafletOptions(
            zoom = 13,
            center = list(lng = 11.798, lat = 48.12)
          )) %>%
            addProviderTiles(providers$CartoDB.Positron) %>%
            addPolygons(
              data = mapData,
              stroke = TRUE,
              weight = 0.0001, # stroke width
              color = "#000000", # stroke color
              opacity = 0.0001, # stroke opacity
              fillColor = ~pal(Briefwahlquote),
              fillOpacity = 0.6,
              layerId = ~StimmbezirkAggregiert,
              label = ~paste0(
                StimmbezirkAggregiert, ": ", scales::percent(Briefwahlquote, accuracy = 0.1), "<br />",
                "(", utils$germanNumberFormat(WaehlerBriefwahl), " Briefwähler:innen bei insgesamt ", utils$germanNumberFormat(Waehler), " Wähler:innen)"
              ) %>% lapply(HTML),
              highlight = highlightOptions(
                bringToFront = TRUE,
                sendToBack = TRUE,
                weight = 3, # stroke width
                opacity = 1.0, # stroke opacity
              )
            ) %>%
            addLegend("topright",
              data = mapData,
              pal = pal,
              values = ~Briefwahlquote,
              title = NULL,
              labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
              opacity = 0.8,
              bins = 5
            )
        },
        p(),
        p("Die Gebiete sind jeweils nach dem Anteil der Briefwahlstimmen im Verhältnis zu allen abgegebenen Stimmen (ungültige eingeschlossen) eingefärbt. Jedes Gebiet umfasst einen Wahllokalstimmbezirk und einen Briefwahlbezirk."),
        {
          rowGesamt <- ergebnisAllgemeinNachStimmbezirkAggregiert %>% filter(StimmbezirkAggregiert == "Gesamt")
          p(paste0("Die gesamte Briefwahlquote in der Gemeinde Vaterstetten beträgt ", scales::percent(rowGesamt$Briefwahlquote, accuracy = 0.1), " (", utils$germanNumberFormat(rowGesamt$WaehlerBriefwahl), " Briefwähler:innen bei insgesamt ", utils$germanNumberFormat(rowGesamt$Waehler), " Wähler:innen)."))
        },
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage sind die Ergebnisse auf dem offziellen <a href=\"https://wahlen.osrz-akdb.de/ob-p/175000/0/20240609/europawahl_kreis/ergebnisse_gemeinde_09175132.html\">Wahlportal des Landkreises Ebersberg</a>, dort werden die Daten als <a href=\"https://wahlen.osrz-akdb.de/ob-p/175000/0/20240609/europawahl_kreis/presse.html\">CSV-Datei</a> angeboten. Außerdem vielen Dank an die Gemeinde Vaterstetten für die Weitergabe der Gebietszuteilung der Stimmbezirke. Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf Basis dessen <a href=\"https://umap.openstreetmap.fr/de/map/landtagswahl-2023-stimmbezirke-vaterstetten_966387\">diese (inoffizielle) Karte (identisch zur Landtagswahl 2023)</a> erstellt werden konnte.")),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/wahlen/europawahl2024", "Zum Daten-Download mit Dokumentation")),
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

      output$map <- renderLeaflet({
        leaflet(stimmbezirkeGeodata, options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printMap() %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
      })

      observe({
        printMap(leafletProxy("map"))
      })

      printMap <- function(leafletObject) {
        partei <- parteien %>% filter(ParteiKuerzel == input$mapPartei) %>% head()
        ergebnisPartei <- ergebnisNachParteiNachStimmbezirkAggregiert %>% filter(ParteiKuerzel == input$mapPartei)
        mapData <- stimmbezirkeGeodata %>% left_join(ergebnisPartei, by = "StimmbezirkAggregiert")
        pal <- colorNumeric(c("#ffffff", partei$ParteiFarbe), c(0, max(ergebnisPartei$StimmenAnteil)))

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = mapData,
            stroke = TRUE,
            weight = 0.0001, # stroke width
            color = "#000000", # stroke color
            opacity = 0.0001, # stroke opacity
            fillColor = ~pal(StimmenAnteil),
            fillOpacity = 0.6,
            layerId = ~StimmbezirkAggregiert,
            label = ~paste0(
              StimmbezirkAggregiert, ": ", scales::percent(StimmenAnteil, accuracy = 0.1), "<br />",
              "(", utils$germanNumberFormat(Stimmen), " von ", utils$germanNumberFormat(GueltigeStimmen), " Stimmen)"
            ) %>% lapply(HTML),
            highlight = highlightOptions(
              bringToFront = TRUE,
              sendToBack = TRUE,
              weight = 3, # stroke width
              opacity = 1.0, # stroke opacity
            )
          ) %>%
          addLegend("topright",
            data = mapData,
            pal = pal,
            values = ~StimmenAnteil,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
      }

      observe({
        event <- input$map_shape_click

        if (!is.null(event)) {
          updateSelectInput(session, "barChoices", selected = event$id)
        }
      })

      observe({
        printStimmenBarPlotly(input$barChoices, ergebnisNachParteiNachCombined, "barPlotly")
      })

      printStimmenBarPlotly <- function(chosenFilter, stimmenNachPartei, outputName) {
        data <- stimmenNachPartei %>%
          filter(Filter == chosenFilter) %>%
          mutate(ParteiKuerzel = droplevels(ParteiKuerzel))

        output[[outputName]] <- renderPlotly({
          plot_ly(
            data,
            showlegend = FALSE
          ) %>%
            add_bars(y = ~ParteiKuerzel, x = ~StimmenAnteil, name = "Stimmenanteil", marker = ~list(color = ParteiFarbe),
              text = ~scales::percent(StimmenAnteil, accuracy = 0.1),
              hovertext = ~paste0("(", utils$germanNumberFormat(Stimmen), " von ", utils$germanNumberFormat(GueltigeStimmen), " Stimmen)")
            ) %>%
            plotly_default_config() %>%
            layout(yaxis = list(autorange = "reversed")) %>%
            layout(xaxis = list(tickformat = ".0%", hoverformat = ".1%", range = c(0, 0.55))) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            layout(hovermode = "y unified") %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        })
      }

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
    layout(dragmode = FALSE) %>%
    identity()
}

plotly_hide_axis_titles <- function(p) {
  p %>%
    layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(margin = list(l = 0, pad = 0, b = 30)) %>%
    identity()
}
