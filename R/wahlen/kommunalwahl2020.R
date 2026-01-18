stimmbezirke <- st_read("data/wahlen/kommunalwahl2020/stimmbezirke.geojson", quiet = TRUE) %>%
  transmute(
    stimmbezirk = name,
    geometry
  )

parteien <- read_csv(
  file = "data/wahlen/kommunalwahl2020/parteien.csv",
  col_types = cols(
    parteiNr = readr::col_factor(),
    partei = readr::col_factor(),
    farbe = col_character()
  )
)

gemeinderatPersonen <- read_csv(
  file = "data/wahlen/kommunalwahl2020/gemeinderatPersonen.csv",
  col_types = cols(
    partei = readr::col_factor(levels = levels(parteien$partei)),
    listenNr = col_integer(),
    name = col_character(),
    alter = col_integer()
  ),
  na = c("", "NA")
)

gemeinderatErgebnisAllgemein <- read_csv(
  file = "data/wahlen/kommunalwahl2020/gemeinderatErgebnisAllgemein.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    stimmbezirkArt = readr::col_factor(),
    wahlberechtigte = col_integer(),
    waehler = col_integer(),
    ungueltigeStimmzettel = col_integer(),
    gueltigeStimmzettel = col_integer(),
    gueltigeStimmen = col_integer(),
    stimmzettelNurListenkreuz = col_integer(),
    stimmzettelNurEineListe = col_integer()
  )
) %>%
  left_join(stimmbezirke, by = join_by(stimmbezirk))

gemeinderatErgebnisNachStimmbezirkArt <- gemeinderatErgebnisAllgemein %>%
  filter(!is.na(stimmbezirkArt)) %>%
  group_by(stimmbezirkArt) %>%
  summarise(
    waehler = sum(waehler),
    ungueltigeStimmzettel = sum(ungueltigeStimmzettel),
    gueltigeStimmzettel = sum(gueltigeStimmzettel),
    gueltigeStimmen = sum(gueltigeStimmen)
  )

gemeinderatErgebnisNachPartei <- read_csv(
  file = "data/wahlen/kommunalwahl2020/gemeinderatErgebnisNachPartei.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    partei = readr::col_factor(levels = levels(parteien$partei)),
    stimmen = col_integer(),
    stimmzettelNurListenkreuz = col_integer(),
    stimmzettelNurEineListe = col_integer()
  )
) %>%
  # add farbe, parteiNr
  inner_join(parteien, by = "partei") %>%

  # add stimmenAnteil
  inner_join(gemeinderatErgebnisAllgemein %>% select(stimmbezirk, gueltigeStimmen), by = "stimmbezirk") %>%
  mutate(stimmenAnteil = stimmen/gueltigeStimmen) %>%

  # add geodata
  left_join(stimmbezirke, by = join_by(stimmbezirk))

gemeinderatErgebnisNachPerson <- read_csv(
  file = "data/wahlen/kommunalwahl2020/gemeinderatErgebnisNachPerson.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    partei = readr::col_factor(),
    listenNr = col_integer(),
    stimmen = col_integer(),
    erreichterPlatz = col_integer()
  )
) %>%
  # add name
  left_join(gemeinderatPersonen, by = c("partei", "listenNr")) %>%

  # add stimmenAnteilPartei, farbe, parteiNr
  left_join(gemeinderatErgebnisNachPartei %>% select(stimmbezirk, partei, parteiStimmen = stimmen, farbe, parteiNr), by = c("partei", "stimmbezirk")) %>%
  mutate(stimmenAnteilPartei = stimmen/parteiStimmen, parteiStimmen = NULL) %>%

  # add geodata
  left_join(stimmbezirke, by = join_by(stimmbezirk))

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
          p(HTML("Eingezeichnet sind die 24 Wahllokal-Stimmbezirke, die auch in <a href=\"https://umap.openstreetmap.fr/de/map/kommunalwahl-2020-stimmbezirke_598747#14/48.1192/11.7997\">dieser (inoffiziellen) Karte</a> im Detail angesehen werden können. Nicht eingezeichnet sind der Sonderstimmbezirk 25 in den Altenheimen sowie die Briefwahlbezirke (31-43). Da das Wahlverhalten der Briefwähler (mehr als 50% aller Wähler!) nicht dargestellt werden kann, führt dies möglicherweise zu Verzerrungen in der Darstellung. Jeder dargestellte Wahllokal-Stimmbezirk umfasst etwa 150 bis 350 Wähler:innen. Weiter ist zu beachten, dass manche Stimmbezirke teils sehr kleine isolierte Gebiete aufweisen (wie der Spechtweg oder das Gut Ammerthal) – das dortige Ergebnis entspricht dennoch dem Durchschnitt im ganzen Stimmbezirk, es ist also keine punktuelle Interpretation möglich.")),
        ),
      ),
    ),

    fluidRow(
      box(
        title = "Gemeinderatsstimmen nach Stimmbezirk-Art",
        {
          plot_ly(
            gemeinderatErgebnisNachStimmbezirkArt,
            height = 150,
            orientation = "h",
            yhoverformat = ",d",
            showlegend = TRUE
          ) %>%
            add_bars(y = ~stimmbezirkArt, x = ~ungueltigeStimmzettel, name = "ungültig", marker = list(color = "#B71C1C")) %>%
            add_bars(y = ~stimmbezirkArt, x = ~gueltigeStimmzettel, name = "gültig", marker = list(color = "#81C784")) %>%
            plotly_default_config() %>%
            layout(yaxis = list(autorange = "reversed")) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            layout(barmode = 'stack') %>%
            layout(hovermode = "y unified") %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
        p(),
        p("Anzahl ungültiger bzw. gültiger Stimmzettel in Wahllokal-Stimmbezirken und Briefwahlbezirken.")
      ),
    ),

    fluidRow(
      box(
        title = "Gemeinderat: Parteistimmen nach Stimmbezirk",
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
        title = "Gemeinderat: Personenstimmen nach Stimmbezirk, relativ zu Parteistimmen",
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
        title = "Gemeinderat: Häufelungen auf einzelne Kandidat:innen",
        width = 12,
        {
          data <- gemeinderatErgebnisNachPerson %>%
            filter(stimmbezirk == "Gesamt") %>%
            left_join(gemeinderatGiniKoeffizienten, by = "parteiNr") %>%
            group_by(partei)

          data %>%
            plot_ly(type = "bar") %>%
            config(displayModeBar = FALSE) %>%
            add_trace(
              x = ~listenNr,
              y = ~stimmen,
              text = ~paste0(name, ", ", partei, ": ", stimmen, " Stimmen"),
              color = ~I(farbe),
              name = ~paste0(parteiNr, ": ", as.character(partei), " (Gini: ", round(gini, 3), ")"),
              legendgroup = ~partei,
              yaxis = ~paste0("y", parteiNr),
              width = 1,
              hoverinfo = "text"
            ) %>%
            layout(dragmode = FALSE, showlegend = TRUE) %>%
            layout(
              yaxis = list(title = list(standoff = 0, font = list(size = 1))),
              margin = list(r = 0, l = 0, t = 0, b = 0, pad = 0)
            ) %>%
            subplot(shareY = TRUE, margin = 0.01) %>%
            plotly_build()
        },
        p(),
        p("Der Gini-Koeffizient gibt an, wie stark die Stimmen auf einzelne Kandidat:innen konzentriert sind (1 = alle Stimmen für eine Person, 0 = alle Personen erhalten gleich viele Stimmen).")
      )
    ),

    fluidRow(
      box(
        title = "Liste aller Kandidat:innen mit Listenplatz-Veränderung",
        width = 8,
        DT::dataTableOutput(ns("haeufelTabelle")),
        p(),
        p("Bei der Kommunalwahl ist es möglich, Stimmen auf einzelne Kandidat:innen zu verteilen. Somit kann die von der Partei festgelegte Listenreihenfolge durch die Wähler:innen verändert werden. In der Tabelle sind alle Kandidat:innen mit ihrem Listenplatz, dem erreichten Platz (nach Stimmenanzahl) und der Differenz (Delta) aufgeführt. Ein positives Delta bedeutet, dass die Person durch die Wähler:innen nach vorne gewählt wurde, ein negatives Delta bedeutet eine Verschlechterung gegenüber dem Listenplatz.")
      ),
      box(
        title = "Alter vs. Listenplatz-Veränderung",
        width = 4,
        {
          scatterData <- gemeinderatErgebnisNachPerson %>%
            filter(stimmbezirk == "Gesamt") %>%
            mutate(delta = listenNr - erreichterPlatz) %>%
            filter(!is.na(alter)) %>%
            mutate(
              alter_jitter = alter + runif(n(), -0.5, 0.5)
            )
          
          maxAbsDelta <- max(abs(scatterData$delta), na.rm = TRUE)
          
          p <- plot_ly() %>%
            add_trace(
              data = scatterData,
              x = ~alter_jitter,
              y = ~delta,
              type = "scatter",
              mode = "markers",
              marker = list(size = 8, opacity = 0.7),
              color = ~I(farbe),
              text = ~paste0(name, ", ", partei, "<br>Alter: ", alter, "<br>Listenplatz: ", listenNr, "<br>Erreichter Platz: ", erreichterPlatz, "<br>Delta: ", delta),
              hoverinfo = "text",
              showlegend = FALSE
            )
          
          p %>%
            add_segments(
              x = min(scatterData$alter, na.rm = TRUE),
              xend = max(scatterData$alter, na.rm = TRUE),
              y = 0,
              yend = 0,
              line = list(color = "gray", width = 1, dash = "dash"),
              showlegend = FALSE,
              hoverinfo = "none"
            ) %>%
            layout(
              xaxis = list(title = "Alter"),
              yaxis = list(title = "Listenplatz-Veränderung (nach vorne = positiv)", range = c(-maxAbsDelta, maxAbsDelta)),
              dragmode = FALSE
            ) %>%
            plotly_default_config()
        },
        p(),
        p("In diesem Diagramm sind alle Kandidat:innen, für die das Alter bekannt ist, nach Alter (X-Achse) und der Veränderung ihres Listenplatzes (Y-Achse) dargestellt, sowie nach Partei eingefärbt. Es ist zu erkennen, ob es einen Zusammenhang zwischen Alter und Listenplatz-Veränderung gibt und ob dieser je nach Partei unterschiedlich ist.")
      )
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage sind die Ergebnisse auf dem offziellen <a href=\"https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/index.html\">OK.VOTE-Portal</a>, dort werden die Daten als <a href=\"https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/OpenDataInfo.html\">Open-Data-CSV</a> angeboten. Außerdem vielen Dank an die Gemeinde Vaterstetten für die Weitergabe der Gebietszuteilung der Stimmbezirke. Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf Basis dessen <a href=\"https://umap.openstreetmap.fr/de/map/kommunalwahl-2020-stimmbezirke_598747#14/48.1192/11.7997\">diese (inoffizielle) Karte</a> erstellt werden konnte.")),
          p(HTML("Das Alter der Kandidat:innen der CSU wurde aus <a href=\"https://www.csu-vaterstetten.de/assets/pdf/aktuelle-meldungen/die-csu-gemeinderatsliste-2020-steht.pdf\">dieser Quelle</a> entnommen, für die Grünen aus <a href=\"https://gruene-ebersberg.de/vor-ort/k-z/vaterstetten/kommunalwahl-2020-vaterstetten/wahlvorschlag-der-gruenen-fuer-den-vaterstettener-gemeinderat\">dieser Quelle</a>. Für die anderen Parteien war das Alter nicht verfügbar.")),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/wahlen/kommunalwahl2020", "Zum Daten-Download mit Dokumentation")),
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

      output$parteistimmenMap <- renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printParteistimmenMap() %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
      })

      observe({
        printParteistimmenMap(leafletProxy("parteistimmenMap"))
      })

      printParteistimmenMap <- function(leafletObject) {
        partei <- gemeinderatParteien %>% filter(partei == input$parteistimmenMapPartei) %>% first()
        ergebnisPartei <- gemeinderatErgebnisNachPartei %>% filter(partei == input$parteistimmenMapPartei)
        pal <- colorNumeric(c("#ffffff", partei$farbe), c(0, max(ergebnisPartei$stimmenAnteil)))
        palForLegend <- colorNumeric(c("#ffffff", partei$farbe), c(0, max(ergebnisPartei$stimmenAnteil)) * -1, reverse = TRUE)

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnisPartei),
            stroke = TRUE,
            weight = 0.0001, # stroke width
            color = "#000000", # stroke color
            opacity = 0.0001, # stroke opacity
            fillColor = ~pal(stimmenAnteil),
            fillOpacity = 0.6,
            label = ~paste0(stimmbezirk, ": ", scales::percent(stimmenAnteil, accuracy = 0.1)),
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
            values = ~stimmenAnteil * -1,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }

      output$personenstimmenMap <- renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printPersonenstimmenMap() %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
      })

      dt_common_opts <- list(
        paging = TRUE,
        searching = TRUE,          # Columnfilter braucht Suche aktiv
        ordering = TRUE,
        dom = 'ltip',              # kein globales Suchfeld, aber Filterzeile bleibt
        order = list(list(5, 'desc')), # Veränderung/Delta-Spalte
        language = list(url = "https://cdn.datatables.net/plug-ins/1.13.1/i18n/de-DE.json"),
        columnDefs = list(
          list(
            targets = 2, # Alter Spalte
            render = DT::JS(
              "function(data, type, row, meta){",
              "  if(type === 'display' && data !== null && data !== ''){",
              "    return data + ' Jahre';",
              "  }",
              "  return data;",
              "}"
            )
          ),
          list(
            targets = 5, # Delta Spalte
            render = DT::JS( # Vorzeichen anzeigen
              "function(data, type, row, meta){",
              "  if(type === 'display'){",
              "    var n = parseFloat(data);",
              "    if(isNaN(n)) return data;",
              "    var sign = n > 0 ? '+' : '';",
              "    return sign + n;",
              "  }",
              "  return data;",
              "}"
            )
          ),
          list(
            targets = 5, # Delta Spalte
            createdCell = DT::JS( # Farbe je nach Vorzeichen
              "function(td, cellData){",
              "  var n = parseFloat(cellData);",
              "  var color = n > 0 ? '#2E7D32' : (n < 0 ? '#C62828' : '#555555');",
              "  $(td).css('color', color);",
              "}"
            )
          )
        )
      )

      haeufelData <- gemeinderatErgebnisNachPerson %>%
        filter(stimmbezirk == "Gesamt") %>%
        mutate(delta = listenNr - erreichterPlatz) %>%
        select(name, partei, alter, listenNr, erreichterPlatz, stimmen, delta)

      output$haeufelTabelle <- DT::renderDataTable({
        DT::datatable(
          haeufelData %>%
            transmute(
              Name = name,
              Partei = partei,
              Alter = alter,
              `Listen-Nr.` = listenNr,
              `Erreichter Platz` = erreichterPlatz,
              `Veränderung` = delta,
              `Stimmenanzahl` = stimmen
            ),
          filter = 'top',
          options = dt_common_opts,
          selection = 'none',
          rownames = FALSE
        )
      })
      observe({
        printPersonenstimmenMap(leafletProxy("personenstimmenMap"))
      })

      printPersonenstimmenMap <- function(leafletObject) {
        parts <- str_split(input$personenstimmenMapPerson, "-", 2, simplify = TRUE)
        personPartei <- parts[1,1]
        personListenNr <- parts[1,2]

        partei <- gemeinderatParteien %>% filter(partei == personPartei) %>% first()
        ergebnisPartei <- gemeinderatErgebnisNachPartei %>% filter(partei == personPartei)
        ergebnisPerson <- gemeinderatErgebnisNachPerson %>% filter(partei == personPartei) %>% filter(listenNr == personListenNr)

        pal <- colorNumeric(c("#ffffff", partei$farbe), c(0, max(ergebnisPerson$stimmenAnteilPartei)))
        palForLegend <- colorNumeric(c("#ffffff", partei$farbe), c(0, max(ergebnisPerson$stimmenAnteilPartei)) * -1, reverse = TRUE)

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnisPerson),
            stroke = TRUE,
            weight = 0.0001, # stroke width
            color = "#000000", # stroke color
            opacity = 0.0001, # stroke opacity
            fillColor = ~pal(stimmenAnteilPartei),
            fillOpacity = 0.6,
            label = ~paste0(stimmbezirk, ": ", scales::percent(stimmenAnteilPartei, accuracy = 0.1)),
            highlight = highlightOptions(
              bringToFront = TRUE,
              sendToBack = TRUE,
              weight = 3, # stroke width
              opacity = 1.0, # stroke opacity
            )
          ) %>%
          addLegend("topright",
            data = ergebnisPerson,
            pal = palForLegend,
            values = ~stimmenAnteilPartei * -1,,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }
    }
  )
}

gemeinderatHaeufelkoenige <- gemeinderatErgebnisNachPerson %>%
  filter(stimmbezirk == "Gesamt") %>%
  mutate(delta = listenNr - erreichterPlatz) %>%
  arrange(desc(delta)) %>%
  head(10) %>%
  select(name, partei, listenNr, erreichterPlatz, delta)

gemeinderatFlopHaeufler <- gemeinderatErgebnisNachPerson %>%
  filter(stimmbezirk == "Gesamt") %>%
  mutate(delta = listenNr - erreichterPlatz) %>%
  arrange(delta) %>%
  head(10) %>%
  select(name, partei, listenNr, erreichterPlatz, delta)

# Berechne Gini-Koeffizient für jede Partei
gemeinderatGiniKoeffizienten <- gemeinderatErgebnisNachPerson %>%
  filter(stimmbezirk == "Gesamt") %>%
  filter(stimmen > 0) %>% # schließe Personen aus, die nicht wählbar waren
  group_by(parteiNr) %>%
  summarise(
    gini = {
      x <- sort(stimmen)
      n <- length(x)
      2 * sum((1:n) * x) / (n * sum(x)) - (n + 1) / n
    }
  )

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
