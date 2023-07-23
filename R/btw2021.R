stimmbezirke <- st_read("data/btw2021/stimmbezirke.geojson") %>%
  transmute(
    stimmbezirk = name,
    geometry
  )

parteien <- read_csv(
  file = "data/btw2021/parteien.csv",
  col_types = cols(
    Nr = readr::col_factor(),
    Kuerzel = readr::col_factor(),
    Name = readr::col_factor(),
    Farbe = col_character()
  )
)

direktkandidaten <- read_csv(
  file = "data/btw2021/direktkandidaten.csv",
  col_types = cols(
    Partei = readr::col_factor(),
    Name = readr::col_factor()
  )
)

erststimmenAllgemein <- read_csv(
  file = "data/btw2021/erststimmenAllgemein.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    stimmbezirkArt = readr::col_factor(),
    wahlberechtigte = col_integer(),
    waehler = col_integer(),
    ungueltigeStimmen = col_integer(),
    gueltigeStimmen = col_integer()
  )
)

erststimmenNachStimmbezirkArt <- erststimmenAllgemein %>%
  filter(!is.na(stimmbezirkArt)) %>%
  group_by(stimmbezirkArt) %>%
  summarise(
    waehler = sum(waehler),
    ungueltigeStimmen = sum(ungueltigeStimmen),
    gueltigeStimmen = sum(gueltigeStimmen)
  )

erststimmenNachPartei <- read_csv(
  file = "data/btw2021/erststimmenNachPartei.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    partei = readr::col_factor(levels = levels(parteien$Kuerzel)),
    stimmen = col_integer()
  )
) %>%
  inner_join(parteien, by = join_by(partei == Kuerzel)) %>%
  inner_join(direktkandidaten %>% transmute(
    Partei,
    Direktkandidat = Name
  ), by = join_by(partei == Partei)) %>%
  inner_join(erststimmenAllgemein %>% select(stimmbezirk, gueltigeStimmen), by = "stimmbezirk") %>%
  mutate(stimmenAnteil = stimmen/gueltigeStimmen)


zweitstimmenAllgemein <- read_csv(
  file = "data/btw2021/zweitstimmenAllgemein.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    stimmbezirkArt = readr::col_factor(),
    wahlberechtigte = col_integer(),
    waehler = col_integer(),
    ungueltigeStimmen = col_integer(),
    gueltigeStimmen = col_integer()
  )
)

zweitstimmenNachStimmbezirkArt <- zweitstimmenAllgemein %>%
  filter(!is.na(stimmbezirkArt)) %>%
  group_by(stimmbezirkArt) %>%
  summarise(
    waehler = sum(waehler),
    ungueltigeStimmen = sum(ungueltigeStimmen),
    gueltigeStimmen = sum(gueltigeStimmen)
  )

zweitstimmenNachPartei <- read_csv(
  file = "data/btw2021/zweitstimmenNachPartei.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    partei = readr::col_factor(levels = levels(parteien$Kuerzel)),
    stimmen = col_integer()
  )
) %>%
  inner_join(parteien, by = join_by(partei == Kuerzel)) %>%
  inner_join(zweitstimmenAllgemein %>% select(stimmbezirk, gueltigeStimmen), by = "stimmbezirk") %>%
  mutate(stimmenAnteil = stimmen/gueltigeStimmen)



ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Bundestagswahl 26. September 2021 in der Gemeinde Vaterstetten"),

    fluidRow(
      box(
        title = "Hinweise zu den Stimmbezirken",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Eingezeichnet sind die 14 Wahllokal-Stimmbezirke, die auch in <a href=\"https://umap.openstreetmap.fr/de/map/bundestagswahl-2021-stimmbezirke_659020#14/48.1192/11.7997\">dieser (inoffiziellen) Karte</a> im Detail angesehen werden können. Nicht eingezeichnet sind die Briefwahlbezirke (31-43). Da das Wahlverhalten der Briefwähler (ca 2/3 der Wähler!) nicht dargestellt werden kann, führt dies möglicherweise zu Verzerrungen in der Darstellung. Weiter ist zu beachten, dass manche Stimmbezirke teils sehr kleine isolierte Gebiete aufweisen (wie der Hofkellermeisterweg oder das Gut Ammerthal) – das dortige Ergebnis entspricht dennoch dem Durchschnitt im ganzen Stimmbezirk, es ist also keine punktuelle Interpretation möglich.")),
        ),
      ),
    ),


    fluidRow(
      box(
        title = "Erststimmen nach Stimmbezirk-Art",
        {
          plot_ly(
            erststimmenNachStimmbezirkArt,
            height = 150,
            type = "bar",
            orientation = "h",
            yhoverformat = ",d",
            showlegend = TRUE
          ) %>%
            add_trace(y = ~stimmbezirkArt, x = ~ungueltigeStimmen, name = "ungültig", marker = list(color = "#B71C1C")) %>%
            add_trace(y = ~stimmbezirkArt, x = ~gueltigeStimmen, name = "gültig", marker = list(color = "#81C784")) %>%
            plotly_default_config() %>%
            layout(yaxis = list(autorange = "reversed")) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            layout(barmode = 'stack') %>%
            layout(hovermode = "y unified") %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
      ),
      box(
        title = "Zweitstimmen nach Stimmbezirk-Art",
        {
          plot_ly(
            zweitstimmenNachStimmbezirkArt,
            height = 150,
            type = "bar",
            orientation = "h",
            yhoverformat = ",d",
            showlegend = TRUE
          ) %>%
            add_trace(y = ~stimmbezirkArt, x = ~ungueltigeStimmen, name = "ungültig", marker = list(color = "#B71C1C")) %>%
            add_trace(y = ~stimmbezirkArt, x = ~gueltigeStimmen, name = "gültig", marker = list(color = "#81C784")) %>%
            plotly_default_config() %>%
            layout(yaxis = list(autorange = "reversed")) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            layout(barmode = 'stack') %>%
            layout(hovermode = "y unified") %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
      ),
    ),

    fluidRow(
      box(
        title = "Erststimmen nach Stimmbezirk (ohne Briefwahl)",
        selectInput(
          ns("erststimmenMapPartei"),
          label = "Partei",
          choices = {
            data <- direktkandidaten %>% mutate(
              label = paste0(Partei, " (", Name, ")")
            )
            
            choices = setNames(data$Partei, data$label)
            choices
          }
        ),
        leafletOutput(ns("erststimmenMap"), height = 550),
        p(),
        p("Die 24 Wahllokal-Stimmbezirke sind jeweils nach den Gemeinderatsstimmen der ausgewählten Partei-Liste eingefärbt. Nicht berücksichtigt sind Briefwahlstimmen.")
      ),
      box(
        title = "Zweitstimmen nach Stimmbezirk (ohne Briefwahl)",
        selectInput(
          ns("zweitstimmenMapPartei"),
          label = "Partei",
          choices = parteien$Kuerzel
        ),
        leafletOutput(ns("zweitstimmenMap"), height = 550),
        p(),
        p("Die 24 Wahllokal-Stimmbezirke sind jeweils nach den Gemeinderatsstimmen der ausgewählten Partei-Liste eingefärbt. Nicht berücksichtigt sind Briefwahlstimmen.")
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage sind die Ergebnisse auf dem offziellen <a href=\"https://okvote.osrz-akdb.de/OK.VOTE_OB/BTW21/09175132/praesentation/index.html\">OK.VOTE-Portal</a>, dort werden die Daten als <a href=\"https://okvote.osrz-akdb.de/OK.VOTE_OB/BTW21/09175132/praesentation/opendata.html\">Open-Data-CSV</a> angeboten. Außerdem vielen Dank an die Gemeinde Vaterstetten für die Weitergabe der Gebietszuteilung der Stimmbezirke. Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf Basis dessen <a href=\"https://umap.openstreetmap.fr/de/map/bundestagswahl-2021-stimmbezirke_659020\">diese (inoffizielle) Karte</a> erstellt werden konnte.")),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/btw2021", "Zum Daten-Download mit Dokumentation")),
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
        leaflet(stimmbezirke, options = leafletOptions(
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
        partei <- parteien %>% filter(Kuerzel == input$erststimmenMapPartei) %>% head()
        ergebnisPartei <- erststimmenNachPartei %>% filter(partei == input$erststimmenMapPartei)
        mapData <- stimmbezirke %>% left_join(ergebnisPartei, by = "stimmbezirk")
        pal <- colorNumeric(c("#ffffff", partei$Farbe), c(0, max(ergebnisPartei$stimmenAnteil)))

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = mapData,
            stroke = FALSE,
            fillOpacity = 0.6,
            label = ~paste0(
              stimmbezirk, ": ", scales::percent(stimmenAnteil, accuracy = 0.1), "<br />",
              "(", stimmen, " von ", gueltigeStimmen, " Stimmen)"
            ) %>% lapply(HTML),
            fillColor = ~pal(stimmenAnteil)
          ) %>%
          addLegend("topright",
            data = mapData,
            pal = pal,
            values = ~stimmenAnteil,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
      }

      output$zweitstimmenMap <- renderLeaflet({
        leaflet(stimmbezirke, options = leafletOptions(
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
        partei <- parteien %>% filter(Kuerzel == input$zweitstimmenMapPartei) %>% head()
        ergebnisPartei <- zweitstimmenNachPartei %>% filter(partei == input$zweitstimmenMapPartei)
        mapData <- stimmbezirke %>% left_join(ergebnisPartei, by = "stimmbezirk")
        pal <- colorNumeric(c("#ffffff", partei$Farbe), c(0, max(ergebnisPartei$stimmenAnteil)))

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = mapData,
            stroke = FALSE,
            fillOpacity = 0.6,
            label = ~paste0(
              stimmbezirk, ": ", scales::percent(stimmenAnteil, accuracy = 0.1), "<br />",
              "(", stimmen, " von ", gueltigeStimmen, " Stimmen)"
            ) %>% lapply(HTML),
            fillColor = ~pal(stimmenAnteil)
          ) %>%
          addLegend("topright",
            data = mapData,
            pal = pal,
            values = ~stimmenAnteil,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
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
