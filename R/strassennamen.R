utils <- new.env()
sys.source("R/utils.R", envir = utils, chdir = FALSE)

osmStrassen <- read_delim(
  file = "data/verkehr/osmStrassen.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    Name = col_character(),
    NamensherkunftWikidata = col_character(),
    Postleitzahl = col_character(),
    OSMWayIDs = col_character(),
    Geometry = col_character(),
  )
) %>% mutate(
  StreetID = row_number()
) %>% st_as_sf(wkt = "Geometry")

multiStreetnames <- osmStrassen %>% as.data.frame() %>% group_by(
  Name,
) %>% summarise(
  Anzahl = n(),
  Postleitzahlen = paste0(Postleitzahl, collapse = ", "),
) %>% filter(
  Anzahl > 1
) %>% select(
  Name,
  Anzahl,
  Postleitzahlen,
)

wikidataNamensherkuenfte <- read_delim(
  file = "data/verkehr/wikidataNamensherkuenfte.csv",
  delim = ",",
  col_names = TRUE,
  col_types = cols(
    WikidataObjekt = col_character(),
    Bezeichnung = col_character(),
    Beschreibung = col_character(),
    Typ = readr::col_factor(),
    Geschlecht = readr::col_factor(levels = c("maennlich", "weiblich")),
  )
) %>% mutate(
  Geschlecht = recode_factor(Geschlecht,
    "maennlich" = "männlich",
    "weiblich" = "weiblich"
  )
)

strassenNamensherkuenfte <- left_join(
  osmStrassen %>% separate_longer_delim(NamensherkunftWikidata, "/"),
  wikidataNamensherkuenfte,
  by = join_by(NamensherkunftWikidata == WikidataObjekt)
) %>% mutate(
  Typ = coalesce(Typ, "Unbekannt")
) %>% mutate(
  Typ = factor(Typ, levels = c(
    "Komponisten",
    "Personen mit Lokalbezug",
    "andere Personen",
    "Vögel",
    "andere Tiere",
    "Früchte",
    "Bäume",
    "Blumen",
    "andere Pflanzen",
    "Berge",
    "Ortsnamen",
    "Jahreszeiten",
    "Himmelskörper",
    "Bauwerke",
    "Sonstige",
    "Unbekannt"
  ))
) %>% mutate(
  Typ = recode_factor(Typ,
    "Komponisten" = "Komponist:innen"
  )
)

typColors <- c(
  "Komponist:innen" = "#ee7700",
  "Personen mit Lokalbezug" = "#aa0033",
  "andere Personen" = "#ee0000",
  "Vögel" = "#33ddff",
  "andere Tiere" = "#00ffdd",
  "Früchte" = "#66ff00",
  "Bäume" = "#006600",
  "Blumen" = "#dd66cc",
  "andere Pflanzen" = "#66cc00",
  "Berge" = "#995533",
  "Ortsnamen" = "#e8bf28",
  "Jahreszeiten" = "#aa00cc",
  "Himmelskörper" = "#000066",
  "Bauwerke" = "#aaaaff",
  "Sonstige" = "#aaaaaa",
  "Unbekannt" = "#333333"
)

typTextColors <- c(
  "Komponist:innen" = "#000000",
  "Personen mit Lokalbezug" = "#ffffff",
  "andere Personen" = "#ffffff",
  "Vögel" = "#000000",
  "andere Tiere" = "#000000",
  "Früchte" = "#000000",
  "Bäume" = "#ffffff",
  "Blumen" = "#000000",
  "andere Pflanzen" = "#000000",
  "Berge" = "#ffffff",
  "Ortsnamen" = "#000000",
  "Jahreszeiten" = "#ffffff",
  "Himmelskörper" = "#ffffff",
  "Bauwerke" = "#000000",
  "Sonstige" = "#000000",
  "Unbekannt" = "#ffffff"
)

genderColors <- c(
  "männlich" = "#1fc3aa",
  "weiblich" = "#8624f5"
)

ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Straßennamen in der Gemeinde Vaterstetten"),

    fluidRow(
      box(
        title = "Straßennamen nach Typ",
        {
          plot_ly(
            strassenNamensherkuenfte %>% count(Typ) %>% filter(!is.na(Typ)),
            x = ~n,
            y = ~Typ,
            color = ~Typ,
            colors = typColors,
            height = 350,
            type = "bar",
            orientation = "h",
            text = ~n,
            hoverinfo = "y",
            hovertemplate = "%{x} %{y}<extra></extra>",
            textangle = 0,
            insidetextfont = list(color = typTextColors),
            outsidetextfont = list(color = "#222222"),
            showlegend = FALSE
          ) %>%
            plotly_default_config() %>%
            layout(yaxis = list(autorange = "reversed")) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
      ),
      box(
        title = "Straßennamen für Personen, nach Geschlecht",
        {
          plot_ly(
            strassenNamensherkuenfte %>% count(Geschlecht),
            x = ~n,
            y = ~Geschlecht,
            color = ~Geschlecht,
            colors = genderColors,
            height = 350,
            type = "bar",
            orientation = "h",
            text = ~n,
            hoverinfo = "none",
            textangle = 0,
            textposition = "inside"
          ) %>%
            plotly_default_config() %>%
            layout(yaxis = list(categoryorder = "total ascending")) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        },
      ),
    ),

    fluidRow(
      box(
        width = 6,
        leafletOutput(ns("map"), height = 550),
      ),
      box(
        width = 6,
        title = "Mehrfache Straßennamen",
        {
          datatable(
            multiStreetnames,
            selection = "single",
            rownames = FALSE,
            elementId = ns("multiStreetTable"),
            options = list(
              paging = FALSE,
              searching = FALSE,
              ordering = FALSE,
              info = FALSE
            ),
          )
        },
        p(),
        p("Einige Straßennamen kommen in der Gemeinde Vaterstetten mehrfach vor, jedoch in der Regel unter unterschiedlichen Postleitzahlen. Mit einem Klick auf eine Tabellenzeile werden die entsprechenden Straßen in der Karte hervorgehoben."),
      ),
    ),

    fluidRow(
      box(
        title = "Datengrundlage und Methodik",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p(HTML('Die Kartendaten, also die Straßen mit u.&nbsp;a. Name, Namensherkunft und geometrischer Struktur stammen von <a href="https://openstreetmap.org/copyright">OpenStreetMap</a> (OSM) und stehen unter der <a href="https://opendatacommons.org/licenses/odbl/">Open Data Commons Open Database License</a>. Der Datenabruf erfolgt über die <a href="https://overpass-api.de/">Overpass API</a>.')),
        p(HTML('Die Namensherkünfte sind in OSM als Referenzen auf <a href="https://www.wikidata.org">Wikidata</a>-Objekte hinterlegt. Für die Beschreibung und Kategorisierung dieser Namensherkünfte werden daher diese Wikidata-Objekte über die <a href="https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service">SPARQL API</a> abgerufen.')),
        p(HTML('Straßen, die zwar gleich benannt sind, aber offensichtlich nicht zusammengehören (z.&nbsp;B. durch unterschiedliche Postleitzahlen, Ortsteile), werden getrennt aufgeführt und gezählt. Beispiele dafür sind die Schwalbenstraße in Baldham und Vaterstetten, sowie die vier Weißenfelder Straßen, die jeweils von Ottendichl, Feldkirchen, Ammerthal und Parsdorf nach Weißenfeld führen. Unbenannte Straßen und Straßen, die nur nummeriert sind (EBE 4 oder A 99), werden nicht berücksichtigt. Benannte Fuß-/Radwege werden wie Straßen behandelt.')),
        p(HTML('Manche Straßen sind mehreren Herkünften – meist Personen – zugeordnet; entweder, weil sie tatsächlich mehreren Personen gewidmet sind, oder weil die Widmung unbekannt ist und mehrere Personen in Frage kommen. Dies ist z.&nbsp;B. bei der Schumannstraße der Fall (Clara und/oder Robert Schumann).')),
        # https://www.vaterstetten.de/zahlen-fakten/publikationen/strassennamen-der-gemeinde-vaterstetten.pdf?cid=cdy
        p(HTML('OpenStreetMap und Wikidata werden von Freiwilligen gepflegt, jede:r kann sich daran beteiligen. Zum Eintragen der Namensherkünfte, die in OSM hinterlegt sind, gibt es ein praktisches Tool von <a href="https://mapcomplete.osm.be/etymology?z=14&lat=48.12072&lon=11.79725&language=de#">MapComplete</a>. Eine ähnliche Kartendarstellung der Namensherkünfte gibt es in der <a href="https://etymology.dsantini.it/#11.778,48.104,13.7,type">Open Etymology Map</a>. Das Projekt <a href="https://equalstreetnames.org/">EqualStreetNames</a> fokussiert sich auf die Geschlechterverteilung von öffentlichen Benennungen.')),
        p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/verkehr", "Zum Daten-Download mit Dokumentation")),
      ),
    ),

  ) %>% renderTags()
})

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

server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      mapData <- strassenNamensherkuenfte %>%
        mutate(
          label = ifelse(is.na(NamensherkunftWikidata), "", paste0(
            '<strong style="font-size: 1.2em; margin-top: .5em; display: block">',
              # TODO: to add links like these, the label should somehow be permanent (on click?)
              # '<a href="https://www.wikidata.org/wiki/', htmlEscape(NamensherkunftWikidata), '">',
              # htmlEscape(Bezeichnung),
              # '</a>',
              htmlEscape(Bezeichnung), ' (', htmlEscape(NamensherkunftWikidata), ')',
            '</strong>',
            htmlEscape(Beschreibung %>% replace_na(""))
          ))
        ) %>%
        group_by(StreetID, Name, Geometry) %>% summarize(
          Typ = paste(unique(Typ), collapse = "/"),
          label = paste(label, collapse = "<br />"),
          .groups = "drop"
        )

      output$map <- renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12)
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printMap() %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
      })

      currentStreetFilter <- reactiveVal('')

      observe({
        inputValue = input$multiStreetTable_rows_selected
        if (is.null(inputValue)) {
          inputValue = '' # string comparison is way easier than nulls
        }

        if (inputValue != currentStreetFilter()) {
          currentStreetFilter(inputValue)
          printMap(leafletProxy("map"), currentStreetFilter())
        }
      })

      printMap <- function(leafletObject, streetFilter = '') {
        data <- mapData
        colors <- unname(typColors[data$Typ])

        if (streetFilter != '') {
          street <- multiStreetnames[streetFilter, ]
          data <- data %>% filter(
            Name == street$Name
          )
          colors <- '#000000'
        }

        leafletObject %>%
          clearShapes() %>% clearControls() %>%
          addPolylines(
            data = data$Geometry,
            color = colors,
            label = lapply(paste0(
              '<strong style="font-size: 1.4em">', htmlEscape(data$Name), '</strong>',
              '<br />',
              htmlEscape(data$Typ),
              data$label
            ), HTML),
            labelOptions = labelOptions(
              style = list(
                'min-width' = '150px',
                'max-width' = '250px',
                'width' = 'max-content',
                'white-space' = 'normal'
              )
            )
          )
      }

    }
  )
}
