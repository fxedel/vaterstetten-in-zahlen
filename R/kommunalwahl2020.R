stimmbezirke <- st_read("data/kommunalwahl2020/stimmbezirke.geojson") %>%
  transmute(
    stimmbezirk = name,
    geometry
  )

parteien <- read_csv("data/kommunalwahl2020/parteien.csv")

gemeinderatPersonen <- read_csv("data/kommunalwahl2020/gemeinderatPersonen.csv")

gemeinderatErgebnisAllgemein <- read_csv("data/kommunalwahl2020/gemeinderatErgebnisAllgemein.csv")

gemeinderatErgebnisNachPartei <- read_csv("data/kommunalwahl2020/gemeinderatErgebnisNachPartei.csv") %>%
  # add farbe, parteiNr
  inner_join(parteien, by = "partei") %>%

  # add stimmenAnteil
  inner_join(gemeinderatErgebnisAllgemein %>% select(stimmbezirk, gueltigeStimmen), by = "stimmbezirk") %>%
  mutate(stimmenAnteil = stimmen/gueltigeStimmen, gueltigeStimmen = NULL)

gemeinderatErgebnisNachPerson <- read_csv("data/kommunalwahl2020/gemeinderatErgebnisNachPerson.csv") %>%
  # add name
  left_join(gemeinderatPersonen, by = c("partei", "listenNr")) %>%

  # add stimmenAnteilPartei, farbe, parteiNr
  left_join(gemeinderatErgebnisNachPartei %>% select(stimmbezirk, partei, parteiStimmen = stimmen, farbe, parteiNr), by = c("partei", "stimmbezirk")) %>%
  mutate(stimmenAnteilPartei = stimmen/parteiStimmen, parteiStimmen = NULL)

gemeinderatParteien <- parteien %>%
  inner_join(gemeinderatErgebnisNachPartei %>% select(partei) %>% distinct(), by = "partei")



ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Kommunalwahl März 2020 in der Gemeinde Vaterstetten"),

    fluidRow(
      box(
        title = "Hinweise zu den Stimmbezirken",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Eingezeichnet sind die 24 Wahllokal-Stimmbezirke, die auch in <a href=\"http://umap.openstreetmap.fr/de/map/kommunalwahl-2020-stimmbezirke_598747#14/48.1192/11.7997\">dieser (inoffiziellen) Karte</a> im Detail angesehen werden können. Nicht eingezeichnet sind der Sonderstimmbezirk 25 in den Altenheimen sowie die Briefwahlbezirke (31-43). Da das Wahlverhalten der Briefwähler nicht dargestellt werden kann, führt dies möglicherweise zu Verzerrungen in der Darstellung. Weiter ist zu beachten, dass manche Stimmbezirke teils sehr kleine isolierte Gebiete aufweisen (wie der Spechtweg oder das Gut Ammerthal) – das dortige Ergebnis entspricht dennoch dem Durchschnitt im ganzen Stimmbezirk, es ist also keine punktuelle Interpretation möglich.")),
        ),
      ),
    ),

    fluidRow(
      box(
        title = "Parteistimmen nach Stimmbezirk",
        selectInput(
          ns("parteistimmenMapPartei"),
          label = "Partei",
          choices = gemeinderatParteien$partei
        ),
        leafletOutput(ns("parteistimmenMap"), height = 550),
        p(),
        p("Die 24 Wahllokal-Stimmbezirke sind jeweils nach den Gemeinderatsstimmen der ausgewählten Partei-Liste eingefärbt. Nicht berücksichtigt sind Briefwahlstimmen.")
      ),
      box(
        title = "Personenstimmen nach Stimmbezirk, relativ zu Parteistimmen",
        selectInput(
          ns("personenstimmenMapPerson"),
          label = "Person",
          choices = gemeinderatParteien$partei %>%
            map(~ filter(gemeinderatPersonen, partei == .) %>% transmute(
              key = paste0(.$partei, "-", .$listenNr),
              label = paste0(.$partei, ", Platz ", .$listenNr, ": ", .$name)
            )) %>%
            map(~ setNames(as.list(.$key), .$label)) %>%
            setNames(gemeinderatParteien$partei)
        ),
        leafletOutput(ns("personenstimmenMap"), height = 550),
        p(),
        p("Der eingezeichnete Stimmenanteil entspricht immer der Stimmenanzahl der einzelnen Person im Verhältnis zu ihrer Partei-Liste. Das insgesamte Abschneiden der Partei im Vergleich zu den anderen Parteien ist irrelevant. Vielmehr wird dargestellt, wo eine Person unter den Anhängern ihrer Partei besonders beliebt ist.")
      ),
    ),

    fluidRow(
      box(
        title = "Häufelungen auf einzelne Kandidat*innen",
        width = 12,
        {
          gemeinderatErgebnisNachPerson %>%
            filter(stimmbezirk == "Gesamt") %>%
            group_by(partei) %>%
            plot_ly(type = "bar") %>%
            config(displayModeBar = FALSE) %>%
            add_trace(x = ~listenNr, y = ~stimmen, text = ~paste0(name, ", ", partei, ": ", stimmen, " Stimmen"), color = ~ I(farbe), name = ~parteiNr, yaxis = ~paste0("y", parteiNr), width = 1, hoverinfo = "text") %>%
            layout(dragmode = FALSE, showlegend = FALSE) %>%
            layout(yaxis = list(title = list(standoff = 0, font = list(size = 1))),
                margin = list(r = 0, l = 0, t = 0, b = 0, pad = 0)) %>%
            subplot(shareY = TRUE, margin = 0.01) %>%
            plotly_build()
        }
      )
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage sind die Ergebnisse auf dem offziellen <a href=\"https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/index.html/\">OK.VOTE-Portal</a>, dort werden die Daten als <a href=\"https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/OpenDataInfo.html\">Open-Data-CSV</a> angeboten. Außerdem vielen Dank an die Gemeinde Vaterstetten für die Weitergabe der Gebietszuteilung der Stimmbezirke. Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf Basis dessen <a href=\"http://umap.openstreetmap.fr/de/map/kommunalwahl-2020-stimmbezirke_598747#14/48.1192/11.7997\">diese (inoffizielle) Karte</a> erstellt werden konnte."))
        ),
      ),
    ),
  )
})

# Define the server logic for a module
server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {

      output$parteistimmenMap <- renderLeaflet({
        map <- leaflet(stimmbezirke, options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron)
        isolate(printMapPartei())
        map
      })

      printMapPartei <- function() {
        partei <- gemeinderatParteien %>% filter(partei == input$parteistimmenMapPartei) %>% head()
        ergebnisPartei <- gemeinderatErgebnisNachPartei %>% filter(partei == input$parteistimmenMapPartei)
        mapData <- stimmbezirke %>% left_join(ergebnisPartei, by = "stimmbezirk")
        pal <- colorNumeric(c("#ffffff", partei$farbe), c(0, max(ergebnisPartei$stimmenAnteil)))

        leafletProxy("parteistimmenMap", data = mapData) %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            stroke = FALSE,
            fillOpacity = 0.6,
            label = ~paste0(stimmbezirk, ": ", scales::percent(stimmenAnteil, accuracy = 0.1)),
            fillColor = ~pal(stimmenAnteil)
          ) %>%
          addLegend("topright", pal = pal, values = ~stimmenAnteil,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
      }

      observe({
        printMapPartei()
      })

      output$personenstimmenMap <- renderLeaflet({
        map <- leaflet(stimmbezirke, options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron)
        isolate(printPersonenstimmenMap())
        map
      })

      printPersonenstimmenMap <- function() {
        parts <- str_split(input$personenstimmenMapPerson, "-", 2, simplify = TRUE)
        personPartei <- parts[1,1]
        personListenNr <- parts[1,2]

        partei <- gemeinderatParteien %>% filter(partei == personPartei) %>% head()
        ergebnisPartei <- gemeinderatErgebnisNachPartei %>% filter(partei == personPartei)
        ergebnisPerson <- gemeinderatErgebnisNachPerson %>% filter(partei == personPartei) %>% filter(listenNr == personListenNr)

        mapData <- stimmbezirke %>% left_join(ergebnisPerson, by = "stimmbezirk")
        pal <- colorNumeric(c("#ffffff", partei$farbe), c(0, max(mapData$stimmenAnteilPartei)))

        leafletProxy("personenstimmenMap", data = mapData) %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            stroke = FALSE,
            fillOpacity = 0.6,
            label = ~paste0(stimmbezirk, ": ", scales::percent(stimmenAnteilPartei, accuracy = 0.1)),
            fillColor = ~pal(stimmenAnteilPartei)
          ) %>%
          addLegend("topright", pal = pal, values = ~stimmenAnteilPartei,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
      }

      observe({
        printPersonenstimmenMap()
      })
    }
  )
}
