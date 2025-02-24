utils <- loadModule("R/utils.R")


stimmbezirke <- read_csv(
  file = "data/wahlen/bundestagswahl2025/stimmbezirke.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    StimmbezirkArt = readr::col_factor(),
    StimmbezirkAggregiert = readr::col_factor()
  )
)

stimmbezirkeGeodata <- st_read("data/wahlen/bundestagswahl2025/stimmbezirke.geojson", quiet = TRUE) %>%
  transmute(
    Stimmbezirk = name,
    geometry
  ) %>%
  left_join(stimmbezirke, by = join_by(Stimmbezirk)) %>%
  group_by(StimmbezirkAggregiert) %>%
  summarise(
    geometry = st_combine(geometry),
    .groups = "drop"
  )

parteien <- read_csv(
  file = "data/wahlen/bundestagswahl2025/parteien.csv",
  col_types = cols(
    ParteiNr = readr::col_factor(),
    ParteiKuerzel = readr::col_factor(),
    ParteiName = readr::col_factor(),
    ParteiFarbe = col_character()
  )
)

direktkandidaten <- read_csv(
  file = "data/wahlen/bundestagswahl2025/direktkandidaten.csv",
  col_types = cols(
    ParteiKuerzel = readr::col_factor(),
    Direktkandidat = readr::col_factor()
  )
)

erststimmenAllgemein <- read_csv(
  file = "data/wahlen/bundestagswahl2025/erststimmenAllgemein.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    Wahlberechtigte = col_integer(),
    Waehler = col_integer(),
    UngueltigeStimmen = col_integer(),
    GueltigeStimmen = col_integer()
  )
) %>% 
  inner_join(stimmbezirke, by = join_by(Stimmbezirk))

erststimmenAllgemeinNachStimmbezirkAggregiert <- erststimmenAllgemein %>%
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
  ) %>%
  mutate(
    WaehlerNA = NULL,
    Waehler = coalesce(Waehler, sum(Waehler, na.rm=TRUE)),
    WaehlerWahllokal = coalesce(WaehlerWahllokal, sum(WaehlerWahllokal, na.rm=TRUE)),
    WaehlerBriefwahl = coalesce(WaehlerBriefwahl, sum(WaehlerBriefwahl, na.rm=TRUE)),
    Wahlbeteiligung = Waehler/Wahlberechtigte,
    Briefwahlquote = WaehlerBriefwahl/Waehler
  ) %>%
  left_join(stimmbezirkeGeodata, by = join_by(StimmbezirkAggregiert))

erststimmenAllgemeinNachStimmbezirkArt <- erststimmenAllgemein %>%
  filter(!is.na(StimmbezirkArt)) %>%
  group_by(StimmbezirkArt) %>%
  summarise(
    Waehler = sum(Waehler),
    UngueltigeStimmen = sum(UngueltigeStimmen),
    GueltigeStimmen = sum(GueltigeStimmen)
  )

erststimmenNachPartei <- read_csv(
  file = "data/wahlen/bundestagswahl2025/erststimmenNachPartei.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    ParteiKuerzel = readr::col_factor(levels = levels(parteien$ParteiKuerzel)),
    Stimmen = col_integer()
  )
) %>%
  inner_join(stimmbezirke, by = join_by(Stimmbezirk))

erststimmenNachParteiNachStimmbezirkAggregiert <- erststimmenNachPartei %>%
  group_by(StimmbezirkAggregiert, ParteiKuerzel) %>%
  summarise(
    Stimmen = sum(Stimmen),
    .groups = "drop"
  ) %>%
  inner_join(parteien, by = "ParteiKuerzel") %>%
  inner_join(direktkandidaten, by = "ParteiKuerzel") %>%
  inner_join(erststimmenAllgemeinNachStimmbezirkAggregiert %>% select(StimmbezirkAggregiert, GueltigeStimmen), by = c("StimmbezirkAggregiert")) %>%
  left_join(stimmbezirkeGeodata, by = join_by(StimmbezirkAggregiert)) %>%
  mutate(StimmenAnteil = Stimmen/GueltigeStimmen)

erststimmenNachParteiNachStimmbezirkArt <- erststimmenNachPartei %>%
  group_by(StimmbezirkArt, ParteiKuerzel) %>%
  summarise(
    Stimmen = sum(Stimmen),
    .groups = "drop"
  ) %>%
  inner_join(parteien, by = "ParteiKuerzel") %>%
  inner_join(direktkandidaten, by = "ParteiKuerzel") %>%
  inner_join(erststimmenAllgemeinNachStimmbezirkArt %>% select(StimmbezirkArt, GueltigeStimmen), by = c("StimmbezirkArt")) %>%
  mutate(StimmenAnteil = Stimmen/GueltigeStimmen)

erststimmenNachParteiNachCombined <- bind_rows(
  erststimmenNachParteiNachStimmbezirkAggregiert %>%
    mutate(Filter = StimmbezirkAggregiert, StimmbezirkAggregiert = NULL) %>%
    filter(Filter == "Gesamt"),
  erststimmenNachParteiNachStimmbezirkArt %>%
    mutate(Filter = paste0("Alle ", StimmbezirkArt, "bezirke"), StimmbezirkArt = NULL),
  erststimmenNachParteiNachStimmbezirkAggregiert %>%
    mutate(Filter = StimmbezirkAggregiert, StimmbezirkAggregiert = NULL) %>%
    filter(Filter != "Gesamt")
)


zweitstimmenAllgemein <- read_csv(
  file = "data/wahlen/bundestagswahl2025/zweitstimmenAllgemein.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    Wahlberechtigte = col_integer(),
    Waehler = col_integer(),
    UngueltigeStimmen = col_integer(),
    GueltigeStimmen = col_integer()
  )
) %>% 
  inner_join(stimmbezirke, by = join_by(Stimmbezirk))

zweitstimmenAllgemeinNachStimmbezirkAggregiert <- zweitstimmenAllgemein %>%
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
  ) %>%
  mutate(
    WaehlerNA = NULL,
    Waehler = coalesce(Waehler, sum(Waehler, na.rm=TRUE)),
    WaehlerWahllokal = coalesce(WaehlerWahllokal, sum(WaehlerWahllokal, na.rm=TRUE)),
    WaehlerBriefwahl = coalesce(WaehlerBriefwahl, sum(WaehlerBriefwahl, na.rm=TRUE)),
    Wahlbeteiligung = Waehler/Wahlberechtigte,
    Briefwahlquote = WaehlerBriefwahl/Waehler
  ) %>%
  left_join(stimmbezirkeGeodata, by = join_by(StimmbezirkAggregiert))

zweitstimmenAllgemeinNachStimmbezirkArt <- zweitstimmenAllgemein %>%
  filter(!is.na(StimmbezirkArt)) %>%
  group_by(StimmbezirkArt) %>%
  summarise(
    Waehler = sum(Waehler),
    UngueltigeStimmen = sum(UngueltigeStimmen),
    GueltigeStimmen = sum(GueltigeStimmen)
  )

zweitstimmenNachPartei <- read_csv(
  file = "data/wahlen/bundestagswahl2025/zweitstimmenNachPartei.csv",
  col_types = cols(
    Stimmbezirk = readr::col_factor(),
    ParteiKuerzel = readr::col_factor(levels = levels(parteien$ParteiKuerzel)),
    Stimmen = col_integer()
  )
) %>%
  inner_join(stimmbezirke, by = join_by(Stimmbezirk))

zweitstimmenNachParteiNachStimmbezirkAggregiert <- zweitstimmenNachPartei %>%
  group_by(StimmbezirkAggregiert, ParteiKuerzel) %>%
  summarise(
    Stimmen = sum(Stimmen),
    .groups = "drop"
  ) %>%
  inner_join(parteien, by = "ParteiKuerzel") %>%
  inner_join(zweitstimmenAllgemeinNachStimmbezirkAggregiert %>% select(StimmbezirkAggregiert, GueltigeStimmen), by = c("StimmbezirkAggregiert")) %>%
  left_join(stimmbezirkeGeodata, by = join_by(StimmbezirkAggregiert)) %>%
  mutate(StimmenAnteil = Stimmen/GueltigeStimmen)

zweitstimmenNachParteiNachStimmbezirkArt <- zweitstimmenNachPartei %>%
  group_by(StimmbezirkArt, ParteiKuerzel) %>%
  summarise(
    Stimmen = sum(Stimmen),
    .groups = "drop"
  ) %>%
  inner_join(parteien, by = "ParteiKuerzel") %>%
  inner_join(zweitstimmenAllgemeinNachStimmbezirkArt %>% select(StimmbezirkArt, GueltigeStimmen), by = c("StimmbezirkArt")) %>%
  mutate(StimmenAnteil = Stimmen/GueltigeStimmen)

zweitstimmenNachParteiNachCombined <- bind_rows(
  zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    mutate(Filter = StimmbezirkAggregiert, StimmbezirkAggregiert = NULL) %>%
    filter(Filter == "Gesamt"),
  zweitstimmenNachParteiNachStimmbezirkArt %>%
    mutate(Filter = paste0("Alle ", StimmbezirkArt, "bezirke"), StimmbezirkArt = NULL),
  zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    mutate(Filter = StimmbezirkAggregiert, StimmbezirkAggregiert = NULL) %>%
    filter(Filter != "Gesamt")
)


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Bundestagswahl 23. Februar 2025 in der Gemeinde Vaterstetten"),

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


    fluidRow(
      box(
        title = "Erststimmen nach Stimmbezirk",
        selectInput(
          ns("erststimmenMapPartei"),
          label = "Partei",
          choices = {
            data <- direktkandidaten %>% mutate(
              Label = paste0(ParteiKuerzel, " (", Direktkandidat, ")")
            )
            
            choices = setNames(data$ParteiKuerzel, data$Label)
            choices
          }
        ),
        leafletOutput(ns("erststimmenMap"), height = 550),
        p(),
        p("Die Gebiete sind jeweils nach den Erststimmen der ausgewählten Partei-Direktkandidat:innen eingefärbt. Jedes Gebiet umfasst einen Wahllokalstimmbezirk und einen Briefwahlbezirk; das Gebiet \"Stimmbezirke 1/2/31\" in den Ortschaften umfasst sogar zwei Wahllokalstimmbezirke."),
        p("Klicke auf einen Stimmbezirk, um ihn im Balkendiagramm anzuzeigen.")
      ),
      column(
        width = 6,
        box(
          width = NULL,
          title = "Erststimmen nach Stimmbezirk",
          selectInput(
            ns("erststimmenBarChoices"),
            label = "Stimmbezirk",
            choices = {
              (erststimmenNachParteiNachCombined %>% filter(ParteiNr == 1))$Filter
            },
            selected = "Gesamt"
          ),
          plotlyOutput(ns("erststimmenBarPlotly"))
        ),
        box(
          width = NULL,
          title = "Erststimmen nach Stimmbezirk-Art",
          {
            plot_ly(
              erststimmenAllgemeinNachStimmbezirkArt,
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

    br(),

    fluidRow(
      box(
        title = "Zweitstimmen nach Stimmbezirk",
        selectInput(
          ns("zweitstimmenMapPartei"),
          label = "Partei",
          choices = {
            data <- parteien %>% mutate(
              Label = paste0(ParteiKuerzel, " (", ParteiName, ")")
            )
            
            choices = setNames(data$ParteiKuerzel, data$Label)
            choices
          },
        ),
        leafletOutput(ns("zweitstimmenMap"), height = 550),
        p(),
        p("Die Gebiete sind jeweils nach den Zweitstimmen der ausgewählten Partei eingefärbt. Jedes Gebiet umfasst einen Wahllokalstimmbezirk und einen Briefwahlbezirk; das Gebiet \"Stimmbezirke 1/2/31\" in den Ortschaften umfasst sogar zwei Wahllokalstimmbezirke."),
        p("Klicke auf einen Stimmbezirk, um ihn im Balkendiagramm anzuzeigen.")
      ),
      column(
        width = 6,
        box(
          width = NULL,
          title = "Zweitstimmen nach Stimmbezirk",
          selectInput(
            ns("zweitstimmenBarChoices"),
            label = "Stimmbezirk",
            choices = {
              (zweitstimmenNachParteiNachCombined %>% filter(ParteiNr == 1))$Filter
            },
            selected = "Gesamt"
          ),
          plotlyOutput(ns("zweitstimmenBarPlotly"), height = 500)
        ),
        box(
          width = NULL,
          title = "Zweitstimmen nach Stimmbezirk-Art",
          {
            plot_ly(
              zweitstimmenAllgemeinNachStimmbezirkArt,
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
          data <- erststimmenAllgemeinNachStimmbezirkAggregiert
          pal <- colorNumeric(c("#bbbbbb", "#000000"), c(0.65, 0.95))
          palForLegend <- colorNumeric(c("#bbbbbb", "#000000"), c(0.65, 0.95) * -1, reverse = TRUE)

          leaflet(height = 550, options = leafletOptions(
            zoom = 13,
            center = list(lng = 11.798, lat = 48.12)
          )) %>%
            addProviderTiles(providers$CartoDB.Positron) %>%
            addPolygons(
              data = st_as_sf(data),
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
              data = data,
              pal = palForLegend,
              values = ~Wahlbeteiligung * -1,
              title = NULL,
              labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
              opacity = 0.8,
              bins = 5
            )
        },
        p(),
        p("Die Gebiete sind jeweils nach dem Anteil der abgegebenen Stimmen (ungültige eingeschlossen) im Verhältnis zu allen Wahlberechtigten eingefärbt. Jedes Gebiet umfasst einen Wahllokalstimmbezirk und einen Briefwahlbezirk; das Gebiet \"Stimmbezirke 1/2/31\" in den Ortschaften umfasst sogar zwei Wahllokalstimmbezirke."),
        {
          rowGesamt <- erststimmenAllgemeinNachStimmbezirkAggregiert %>% filter(StimmbezirkAggregiert == "Gesamt")
          p(paste0("Die gesamte Wahlbeteiligung in der Gemeinde Vaterstetten beträgt ", scales::percent(rowGesamt$Wahlbeteiligung, accuracy = 0.1), " (", utils$germanNumberFormat(rowGesamt$Waehler), " Wähler:innen bei insgesamt ", utils$germanNumberFormat(rowGesamt$Wahlberechtigte), " Wahlberechtigten)."))
        },
      ),
      box(
        title = "Briefwahlquote nach Stimmbezirk",
        {
          data <- erststimmenAllgemeinNachStimmbezirkAggregiert
          pal <- colorNumeric(c("#888888", "#000000"), c(min(data$Briefwahlquote), max(data$Briefwahlquote)))
          palForLegend <- colorNumeric(c("#888888", "#000000"), c(min(data$Briefwahlquote), max(data$Briefwahlquote)) * -1, reverse = TRUE)

          leaflet(height = 550, options = leafletOptions(
            zoom = 13,
            center = list(lng = 11.798, lat = 48.12)
          )) %>%
            addProviderTiles(providers$CartoDB.Positron) %>%
            addPolygons(
              data = st_as_sf(data),
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
              data = data,
              pal = palForLegend,
              values = ~Briefwahlquote * -1,
              title = NULL,
              labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
              opacity = 0.8,
              bins = 5
            )
        },
        p(),
        p("Die Gebiete sind jeweils nach dem Anteil der Briefwahlstimmen im Verhältnis zu allen abgegebenen Stimmen (ungültige eingeschlossen) eingefärbt. Jedes Gebiet umfasst einen Wahllokalstimmbezirk und einen Briefwahlbezirk; das Gebiet \"Stimmbezirke 1/2/31\" in den Ortschaften umfasst sogar zwei Wahllokalstimmbezirke."),
        {
          rowGesamt <- erststimmenAllgemeinNachStimmbezirkAggregiert %>% filter(StimmbezirkAggregiert == "Gesamt")
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
          p(HTML("Datengrundlage sind die Ergebnisse auf dem offziellen <a href=\"https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/ergebnisse_gemeinde_09175132.html\">Wahlportal des Landkreises Ebersberg</a>, dort werden die Daten als <a href=\"https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/presse.html\">CSV-Datei</a> angeboten. Außerdem vielen Dank an die Gemeinde Vaterstetten für die Weitergabe der Gebietszuteilung der Stimmbezirke. Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf Basis dessen <a href=\"https://umap.openstreetmap.fr/de/map/landtagswahl-2023-stimmbezirke-vaterstetten_966387\">diese (inoffizielle) Karte (identisch zur Landtagswahl 2023)</a> erstellt werden konnte.")),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/wahlen/bundestagswahl2025", "Zum Daten-Download mit Dokumentation")),
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

      output$erststimmenMap <- renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printErststimmenMap() %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
      })

      observe({
        printErststimmenMap(leafletProxy("erststimmenMap"))
      })

      printErststimmenMap <- function(leafletObject) {
        partei <- parteien %>% filter(ParteiKuerzel == input$erststimmenMapPartei) %>% first()
        ergebnisPartei <- erststimmenNachParteiNachStimmbezirkAggregiert %>% filter(ParteiKuerzel == input$erststimmenMapPartei)
        pal <- colorNumeric(c("#ffffff", partei$ParteiFarbe), c(0, max(ergebnisPartei$StimmenAnteil)))
        palForLegend <- colorNumeric(c("#ffffff", partei$ParteiFarbe), c(0, max(ergebnisPartei$StimmenAnteil)) * -1, reverse = TRUE)

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnisPartei),
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
            data = ergebnisPartei,
            pal = palForLegend,
            values = ~StimmenAnteil * -1,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }

      output$zweitstimmenMap <- renderLeaflet({
        leaflet(stimmbezirkeGeodata, options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printZweitstimmenMap() %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
      })

      observe({
        printZweitstimmenMap(leafletProxy("zweitstimmenMap"))
      })

      printZweitstimmenMap <- function(leafletObject) {
        partei <- parteien %>% filter(ParteiKuerzel == input$zweitstimmenMapPartei) %>% first()
        ergebnisPartei <- zweitstimmenNachParteiNachStimmbezirkAggregiert %>% filter(ParteiKuerzel == input$zweitstimmenMapPartei)
        pal <- colorNumeric(c("#ffffff", partei$ParteiFarbe), c(0, max(ergebnisPartei$StimmenAnteil)))
        palForLegend <- colorNumeric(c("#ffffff", partei$ParteiFarbe), c(0, max(ergebnisPartei$StimmenAnteil)) * -1, reverse = TRUE)

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnisPartei),
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
            data = ergebnisPartei,
            pal = palForLegend,
            values = ~StimmenAnteil * -1,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }

      observe({
        event <- input$erststimmenMap_shape_click

        if (!is.null(event)) {
          updateSelectInput(session, "erststimmenBarChoices", selected = event$id)
        }
      })

      observe({
        printStimmenBarPlotly(input$erststimmenBarChoices, erststimmenNachParteiNachCombined, "erststimmenBarPlotly")
      })

      observe({
        event <- input$zweitstimmenMap_shape_click

        if (!is.null(event)) {
          updateSelectInput(session, "zweitstimmenBarChoices", selected = event$id)
        }
      })

      observe({
        printStimmenBarPlotly(input$zweitstimmenBarChoices, zweitstimmenNachParteiNachCombined, "zweitstimmenBarPlotly")
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
