# Datengrundlage
stimmbezirke <- st_read("data/wahlen/kommunalwahl2026/stimmbezirke.geojson", quiet = TRUE) %>%
  transmute(
    stimmbezirk = name,
    geometry
  )

parteien <- read_csv(
  file = "data/wahlen/kommunalwahl2026/parteien.csv",
  col_types = cols(
    parteiNr = readr::col_factor(),
    partei = readr::col_factor(),
    farbe = col_character()
  )
)

gemeinderatPersonen <- read_csv(
  file = "data/wahlen/kommunalwahl2026/gemeinderatPersonen.csv",
  col_types = cols(
    Partei = readr::col_factor(levels = levels(parteien$partei)),
    ListenNr = col_integer(),
    Name = col_character(),
    Wohnort = col_character(),
    Geschlecht = col_character(),
    Geburtsjahr = col_integer()
  ),
  na = c("", "NA")
) %>%
  transmute(
    partei = Partei,
    listenNr = ListenNr,
    name = Name,
    wohnort = coalesce(Wohnort, "n. a."),
    geschlecht = Geschlecht,
    geburtsjahr = Geburtsjahr
  )

# Hilfsvariablen für die Verteilungen
parteiGruppenLevels <- c(
  "Gesamt",
  "",
  gemeinderatPersonen %>% distinct(partei) %>% pull(partei) %>% as.character()
)

wohnortLevels <- gemeinderatPersonen %>%
  pull(wohnort) %>%
  as.character() %>%
  unique() %>%
  sort() %>%
  {
    c(setdiff(., "n. a."), if ("n. a." %in% .) "n. a.")
  }

wohnortVerteilung <- bind_rows(
  gemeinderatPersonen %>% transmute(parteiGruppe = as.character(partei), wohnort),
  gemeinderatPersonen %>% transmute(parteiGruppe = "Gesamt", wohnort)
) %>%
  count(parteiGruppe, wohnort, name = "anzahl") %>%
  complete(parteiGruppe = parteiGruppenLevels, wohnort = wohnortLevels, fill = list(anzahl = 0)) %>%
  group_by(parteiGruppe) %>%
  mutate(anteil = anzahl / sum(anzahl) * 100) %>%
  ungroup() %>%
  mutate(
    parteiGruppe = factor(parteiGruppe, levels = parteiGruppenLevels),
    wohnort = factor(wohnort, levels = wohnortLevels)
  )

dekadenLevels <- paste0(seq(1940, 2000, by = 10), "er")

geburtsjahrVerteilung <- bind_rows(
  gemeinderatPersonen %>%
    transmute(
      parteiGruppe = as.character(partei),
      dekade = paste0(floor(geburtsjahr / 10) * 10, "er")
    ),
  gemeinderatPersonen %>%
    transmute(
      parteiGruppe = "Gesamt",
      dekade = paste0(floor(geburtsjahr / 10) * 10, "er")
    )
) %>%
  filter(dekade %in% dekadenLevels) %>%
  count(parteiGruppe, dekade, name = "anzahl") %>%
  complete(parteiGruppe = parteiGruppenLevels, dekade = dekadenLevels, fill = list(anzahl = 0)) %>%
  group_by(parteiGruppe) %>%
  mutate(anteil = anzahl / sum(anzahl) * 100) %>%
  ungroup() %>%
  mutate(
    parteiGruppe = factor(parteiGruppe, levels = parteiGruppenLevels),
    dekade = factor(dekade, levels = dekadenLevels)
  )

geschlechtLevels <- c("weiblich", "nicht-binär", "maennlich")
geschlechtFarben <- c(
  "weiblich" = "#8624f5",
  "nicht-binär" = "#999999",
  "maennlich" = "#1fc3aa"
)

geschlechtVerteilung <- bind_rows(
  gemeinderatPersonen %>% transmute(parteiGruppe = as.character(partei), geschlecht),
  gemeinderatPersonen %>% transmute(parteiGruppe = "Gesamt", geschlecht)
) %>%
  count(parteiGruppe, geschlecht, name = "anzahl") %>%
  complete(parteiGruppe = parteiGruppenLevels, geschlecht = geschlechtLevels, fill = list(anzahl = 0)) %>%
  group_by(parteiGruppe) %>%
  mutate(anteil = anzahl / sum(anzahl) * 100) %>%
  ungroup() %>%
  mutate(
    parteiGruppe = factor(parteiGruppe, levels = parteiGruppenLevels),
    geschlecht = factor(geschlecht, levels = geschlechtLevels)
  )

# Wahlergebnisse
gemeinderatErgebnisAllgemein <- read_csv(
  file = "data/wahlen/kommunalwahl2026/gemeinderatErgebnisAllgemein.csv",
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
  file = "data/wahlen/kommunalwahl2026/gemeinderatErgebnisNachPartei.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    partei = readr::col_factor(levels = levels(parteien$partei)),
    stimmen = col_integer(),
    stimmzettelNurListenkreuz = col_integer(),
    stimmzettelNurEineListe = col_integer()
  )
) %>%
  inner_join(parteien, by = "partei") %>%
  inner_join(gemeinderatErgebnisAllgemein %>% select(stimmbezirk, gueltigeStimmen), by = "stimmbezirk") %>%
  mutate(stimmenAnteil = stimmen / gueltigeStimmen) %>%
  left_join(stimmbezirke, by = join_by(stimmbezirk))

gemeinderatErgebnisNachPerson <- read_csv(
  file = "data/wahlen/kommunalwahl2026/gemeinderatErgebnisNachPerson.csv",
  col_types = cols(
    stimmbezirk = readr::col_factor(),
    stimmbezirkNr = readr::col_factor(),
    partei = readr::col_factor(levels = levels(parteien$partei)),
    listenNr = col_integer(),
    stimmen = col_integer(),
    erreichterPlatz = col_integer()
  )
) %>%
  left_join(gemeinderatPersonen, by = c("partei", "listenNr")) %>%
  left_join(gemeinderatErgebnisNachPartei %>% select(stimmbezirk, partei, parteiStimmen = stimmen, farbe, parteiNr), by = c("partei", "stimmbezirk")) %>%
  mutate(stimmenAnteilPartei = stimmen / parteiStimmen, parteiStimmen = NULL) %>%
  left_join(stimmbezirke, by = join_by(stimmbezirk))

gemeinderatParteien <- parteien %>%
  inner_join(gemeinderatErgebnisNachPartei %>% select(partei) %>% distinct(), by = "partei")

stimmzettelVerteilung <- bind_rows(
  gemeinderatErgebnisAllgemein %>%
    filter(stimmbezirk == "Gesamt") %>%
    transmute(
      kategorie = "Gesamt",
      nurListenkreuz = stimmzettelNurListenkreuz,
      innerhalb = stimmzettelNurEineListe - stimmzettelNurListenkreuz,
      parteiuebergreifend = gueltigeStimmzettel - stimmzettelNurEineListe
    ),
  gemeinderatErgebnisAllgemein %>%
    filter(stimmbezirkArt == "Briefwahl") %>%
    summarise(
      kategorie = "Briefwahl",
      nurListenkreuz = sum(stimmzettelNurListenkreuz),
      innerhalb = sum(stimmzettelNurEineListe - stimmzettelNurListenkreuz),
      parteiuebergreifend = sum(gueltigeStimmzettel - stimmzettelNurEineListe)
    ),
  gemeinderatErgebnisAllgemein %>%
    filter(stimmbezirkArt == "Wahllokal") %>%
    summarise(
      kategorie = "Wahllokal",
      nurListenkreuz = sum(stimmzettelNurListenkreuz),
      innerhalb = sum(stimmzettelNurEineListe - stimmzettelNurListenkreuz),
      parteiuebergreifend = sum(gueltigeStimmzettel - stimmzettelNurEineListe)
    )
) %>%
  mutate(kategorie = factor(kategorie, levels = c("Gesamt", "Briefwahl", "Wahllokal"))) %>%
  rowwise() %>%
  mutate(
    summe = nurListenkreuz + innerhalb + parteiuebergreifend,
    nurListenkreuz_pct = nurListenkreuz / summe * 100,
    innerhalb_pct = innerhalb / summe * 100,
    parteiuebergreifend_pct = parteiuebergreifend / summe * 100
  ) %>%
  ungroup()

ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Kommunalwahl März 2026 in der Gemeinde Vaterstetten"),

    fluidRow(
      box(
        title = "Kandidat:innen nach Wohnort (pro Partei)",
        width = 4,
        {
          plot_ly(
            wohnortVerteilung,
            x = ~anteil,
            y = ~parteiGruppe,
            color = ~wohnort,
            type = "bar",
            orientation = "h",
            customdata = ~anzahl,
            hovertemplate = "<b>%{fullData.name}</b><br>%{y}: %{x:.1f}% (%{customdata} Kandidat:innen)<extra></extra>"
          ) %>%
            plotly_default_config() %>%
            layout(
              barmode = "stack",
              yaxis = list(autorange = "reversed"),
              xaxis = list(ticksuffix = "%", range = c(0, 100)),
              hovermode = "y unified",
              legend = list(orientation = "h")
            ) %>%
            plotly_hide_axis_titles()
        },
        p(),
        p("Die Balken zeigen den prozentualen Anteil der Wohnorte der Kandidat:innen; \"n. a.\" ist eine eigene Kategorie für alle Kandidat:innen ohne Angabe eines Wohnorts. Die oberste Zeile umfasst alle Kandidat:innen, die folgenden Zeilen jeweils die Kandidat:innen einer Partei.")
      ),
      box(
        title = "Kandidat:innen nach Geburtsjahrzehnt (pro Partei)",
        width = 4,
        {
          dekadenFarben <- colorRampPalette(c("#d94801", "#fd8d3c", "#feedde"))(length(dekadenLevels))
          names(dekadenFarben) <- dekadenLevels

          plot_ly(
            geburtsjahrVerteilung,
            x = ~anteil,
            y = ~parteiGruppe,
            color = ~dekade,
            colors = dekadenFarben,
            type = "bar",
            orientation = "h",
            customdata = ~anzahl,
            hovertemplate = "<b>%{fullData.name}</b><br>%{y}: %{x:.1f}% (%{customdata} Kandidat:innen)<extra></extra>"
          ) %>%
            plotly_default_config() %>%
            layout(
              barmode = "stack",
              yaxis = list(autorange = "reversed"),
              xaxis = list(ticksuffix = "%", range = c(0, 100)),
              hovermode = "y unified",
              legend = list(orientation = "h")
            ) %>%
            plotly_hide_axis_titles()
        },
        p(),
        p("Die Balken zeigen den prozentualen Anteil der Kandidat:innen nach Geburtsjahrzehnt. Die oberste Zeile umfasst alle Kandidat:innen, die folgenden Zeilen jeweils die Kandidat:innen einer Partei.")
      ),
      box(
        title = "Kandidat:innen nach Geschlecht (pro Partei)",
        width = 4,
        {
          plot_ly(
            geschlechtVerteilung,
            x = ~anteil,
            y = ~parteiGruppe,
            color = ~geschlecht,
            colors = geschlechtFarben,
            type = "bar",
            orientation = "h",
            customdata = ~anzahl,
            hovertemplate = "<b>%{fullData.name}</b><br>%{y}: %{x:.1f}% (%{customdata} Kandidat:innen)<extra></extra>"
          ) %>%
            plotly_default_config() %>%
            layout(
              barmode = "stack",
              yaxis = list(autorange = "reversed"),
              xaxis = list(ticksuffix = "%", range = c(0, 100)),
              hovermode = "y unified",
              legend = list(orientation = "h"),
              shapes = list(
                list(
                  type = "line",
                  x0 = 50,
                  x1 = 50,
                  y0 = -0.5,
                  y1 = length(parteiGruppenLevels) - 0.5,
                  line = list(color = "#666666", width = 1, dash = "dash")
                )
              )
            ) %>%
            plotly_hide_axis_titles()
        },
        p(),
        p("Die Balken zeigen den prozentualen Anteil der Kandidat:innen nach Geschlecht. Die oberste Zeile umfasst alle Kandidat:innen, die folgenden Zeilen jeweils die Kandidat:innen einer Partei.")
      )
    ),

    fluidRow(
      box(
        title = "Hinweise zu den Stimmbezirken",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Eingezeichnet sind die 25 Wahllokal-Stimmbezirke, die auch in <a href=\"https://umap.openstreetmap.de/de/map/kommunalwahl-2026-stimmbezirke_124973#14/48.1192/11.7997\">dieser (inoffiziellen) Karte</a> im Detail angesehen werden können. Nicht eingezeichnet sind die Briefwahlbezirke (31-50). Da das Wahlverhalten der Briefwähler:innen (mehr als 60% aller Wähler:innen!) nicht räumlich dargestellt werden kann, führt dies möglicherweise zu Verzerrungen in der Darstellung. Jeder dargestellte Wahllokal-Stimmbezirk umfasst etwa 150 bis 300 Wähler:innen. Weiter ist zu beachten, dass manche Stimmbezirke teils sehr kleine isolierte Gebiete aufweisen (wie der Spechtweg oder das Gut Ammerthal) – das dortige Ergebnis entspricht dennoch dem Durchschnitt im ganzen Stimmbezirk, es ist also keine punktuelle Interpretation möglich.")),
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
            layout(barmode = "stack") %>%
            layout(hovermode = "y unified") %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
        p(),
        p("Anzahl ungültiger bzw. gültiger Stimmzettel in Wahllokal-Stimmbezirken und Briefwahlbezirken.")
      ),
      box(
        title = "Verteilung der Stimmzettel",
        width = 6,
        {
          plot_ly(
            stimmzettelVerteilung,
            height = 150,
            orientation = "h",
            showlegend = TRUE
          ) %>%
            add_bars(y = ~kategorie, x = ~nurListenkreuz_pct, name = "Nur Listenkreuz", marker = list(color = "#FFA726"), hovertemplate = "<b>Nur Listenkreuz</b><br>%{x:.1f}%<extra></extra>") %>%
            add_bars(y = ~kategorie, x = ~innerhalb_pct, name = "Innerhalb Partei verteilt", marker = list(color = "#66BB6A"), hovertemplate = "<b>Innerhalb Partei verteilt</b><br>%{x:.1f}%<extra></extra>") %>%
            add_bars(y = ~kategorie, x = ~parteiuebergreifend_pct, name = "Parteiübergreifend verteilt", marker = list(color = "#42A5F5"), hovertemplate = "<b>Parteiübergreifend verteilt</b><br>%{x:.1f}%<extra></extra>") %>%
            plotly_default_config() %>%
            layout(yaxis = list(autorange = "reversed")) %>%
            layout(xaxis = list(ticksuffix = "%")) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            layout(barmode = "stack") %>%
            layout(hovermode = "y unified") %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
        p(),
        p("Prozentuale Verteilung der gültigen Stimmzettel: Stimmzettel mit nur einem Listenkreuz (unverändert), innerhalb einer Partei verteilte Stimmen (Kumulieren innerhalb einer Liste) und parteiübergreifend verteilte Stimmen (Kumulieren und Panaschieren über mehrere Listen).")
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
        p("Die 25 Wahllokal-Stimmbezirke sind jeweils nach den Gemeinderatsstimmen der ausgewählten Partei eingefärbt. Briefwahlstimmen können in der Karte nicht berücksichtigt werden.")
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
        p("Der eingezeichnete Stimmenanteil entspricht immer der Stimmenanzahl der einzelnen Person im Verhältnis zu ihrer Partei. Das Gesamtergebnis der Partei ist dabei nicht entscheidend.")
      )
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
        p("Der Gini-Koeffizient (oben rechts) gibt an, wie stark die Stimmen auf einzelne Kandidat:innen konzentriert sind (1 = alle Stimmen für eine Person, 0 = alle Personen erhalten gleich viele Stimmen).")
      )
    ),

    fluidRow(
      box(
        title = "Liste aller Kandidat:innen mit Listenplatz-Veränderung",
        width = 8,
        DT::dataTableOutput(ns("haeufelTabelle")),
        p(),
        p("Bei der Kommunalwahl ist es möglich, Stimmen auf einzelne Kandidat:innen zu verteilen. Somit kann die von der Partei festgelegte Listenreihenfolge durch die Wähler:innen verändert werden. In der Tabelle sind alle Kandidat:innen mit ihrem Listenplatz, dem erreichten Platz (nach Stimmenanzahl) und der Differenz (Listenplatz-Veränderung) aufgeführt. Eine positive Veränderung bedeutet, dass die Person durch die Wähler:innen nach vorne gewählt wurde, ein negativer Wert bedeutet eine Verschlechterung gegenüber dem Listenplatz.")
      ),
      box(
        title = "Geburtsjahr vs. Listenplatz-Veränderung",
        width = 4,
        {
          scatterData <- gemeinderatErgebnisNachPerson %>%
            filter(stimmbezirk == "Gesamt") %>%
            mutate(delta = listenNr - erreichterPlatz) %>%
            filter(!is.na(geburtsjahr)) %>%
            mutate(geburtsjahr_jitter = geburtsjahr + runif(n(), -0.5, 0.5))

          maxAbsDelta <- max(abs(scatterData$delta), na.rm = TRUE)

          p <- plot_ly() %>%
            add_trace(
              data = scatterData,
              x = ~geburtsjahr_jitter,
              y = ~delta,
              type = "scatter",
              mode = "markers",
              marker = list(size = 8, opacity = 0.7),
              color = ~I(farbe),
              text = ~paste0(name, ", ", partei, "<br>Geburtsjahr: ", geburtsjahr, "<br>Listenplatz: ", listenNr, "<br>Erreichter Platz: ", erreichterPlatz, "<br>Delta: ", delta),
              hoverinfo = "text",
              showlegend = FALSE
            )

          p %>%
            add_segments(
              x = min(scatterData$geburtsjahr, na.rm = TRUE),
              xend = max(scatterData$geburtsjahr, na.rm = TRUE),
              y = 0,
              yend = 0,
              line = list(color = "gray", width = 1, dash = "dash"),
              showlegend = FALSE,
              hoverinfo = "none"
            ) %>%
            layout(
              xaxis = list(title = "Geburtsjahr"),
              yaxis = list(title = "Listenplatz-Veränderung (nach vorne = positiv)", range = c(-maxAbsDelta, maxAbsDelta)),
              dragmode = FALSE
            ) %>%
            plotly_default_config()
        },
        p(),
        p("Dieses Diagramm zeigt alle Kandidat:innen als einzelne Punkte, angeordnet nach Geburtsjahr (X-Achse) und Listenplatz-Veränderung (Y-Achse) sowie eingefärbt nach Partei. Es ist zu erkennen, ob es einen Zusammenhang zwischen Alter und Listenplatz-Veränderung gibt und ob dieser je nach Partei unterschiedlich ist.")
      )
    ),

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage sind die Ergebnisse auf dem offziellen <a href=\"https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/presse.html\">AKDB/OSRZ-Portal</a>, dort werden die Daten als <a href=\"https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/gesamtergebnis.csv\">CSV</a> angeboten. Außerdem vielen Dank an die Gemeinde Vaterstetten für die Weitergabe der Gebietszuteilung der Stimmbezirke. Dies erfolgte in Form von Karten- bzw. Geodaten zur Einordnung der Stimmbezirke, auf Basis dessen <a href=\"https://umap.openstreetmap.de/de/map/kommunalwahl-2026-stimmbezirke_124973\">diese (inoffizielle) Karte</a> erstellt werden konnte.")),
          p("Das Geburtsjahr der Kandidat:innen wurde der offiziellen Bekanntmachung zur Kommunalwahl auf der Website der Gemeinde Vaterstetten entnommen (nicht mehr online verfügbar)."),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/wahlen/kommunalwahl2026", "Zum Daten-Download mit Dokumentation"))
        ),
      ),
    ),
  ) %>% renderTags()
})

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
        ergebnisParteiMap <- ergebnisPartei %>% filter(!is.na(geometry))
        maxAnteil <- max(ergebnisParteiMap$stimmenAnteil, na.rm = TRUE)
        if (!is.finite(maxAnteil) || maxAnteil <= 0) {
          maxAnteil <- 1
        }
        pal <- colorNumeric(c("#ffffff", partei$farbe), c(0, maxAnteil))
        palForLegend <- colorNumeric(c("#ffffff", partei$farbe), c(0, maxAnteil) * -1, reverse = TRUE)

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnisParteiMap),
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
            data = ergebnisParteiMap,
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
        order = list(list(5, "desc")),
        language = list(url = "https://cdn.datatables.net/plug-ins/1.13.1/i18n/de-DE.json"),
        columnDefs = list(
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
        select(name, partei, geburtsjahr, listenNr, erreichterPlatz, stimmen, delta)

      output$haeufelTabelle <- DT::renderDataTable({
        DT::datatable(
          haeufelData %>%
            transmute(
              Name = name,
              Partei = partei,
              Geburtsjahr = geburtsjahr,
              `Listen-Nr.` = listenNr,
              `Erreichter Platz` = erreichterPlatz,
              `Veränderung` = delta,
              Stimmenanzahl = stimmen
            ),
          filter = "top",
          options = dt_common_opts,
          selection = "none",
          rownames = FALSE
        )
      })

      observe({
        printPersonenstimmenMap(leafletProxy("personenstimmenMap"))
      })

      printPersonenstimmenMap <- function(leafletObject) {
        parts <- str_split(input$personenstimmenMapPerson, "-", 2, simplify = TRUE)
        personPartei <- parts[1, 1]
        personListenNr <- as.integer(parts[1, 2])

        partei <- gemeinderatParteien %>% filter(partei == personPartei) %>% first()
        ergebnisPerson <- gemeinderatErgebnisNachPerson %>% filter(partei == personPartei, listenNr == personListenNr)
        ergebnisPersonMap <- ergebnisPerson %>% filter(!is.na(geometry))

        maxAnteil <- max(ergebnisPersonMap$stimmenAnteilPartei, na.rm = TRUE)
        if (!is.finite(maxAnteil) || maxAnteil <= 0) {
          maxAnteil <- 1
        }

        pal <- colorNumeric(c("#ffffff", partei$farbe), c(0, maxAnteil))
        palForLegend <- colorNumeric(c("#ffffff", partei$farbe), c(0, maxAnteil) * -1, reverse = TRUE)

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnisPersonMap),
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
            data = ergebnisPersonMap,
            pal = palForLegend,
            values = ~stimmenAnteilPartei * -1,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }
    }
  )
}

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
