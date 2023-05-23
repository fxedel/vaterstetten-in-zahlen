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
) %>% st_as_sf(wkt = "Geometry")

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
    "Personen mit Lokalbezug",
    "Komponisten",
    "andere Personen",
    "Vögel",
    "andere Tiere",
    "Früchte",
    "Bäume",
    "andere Pflanzen",
    "Berge",
    "Ortsnamen",
    "Jahreszeiten",
    "Himmelskörper",
    "Bauwerke",
    "Sonstige",
    "Unbekannt"
  ))
)

typColors <- c(
  "Personen mit Lokalbezug" = "#bb0033",
  "Komponisten" = "#ee7700",
  "andere Personen" = "#ee0000",
  "Vögel" = "#33ddff",
  "andere Tiere" = "#00ffdd",
  "Früchte" = "#66ff00",
  "Bäume" = "#006600",
  "andere Pflanzen" = "#66cc00",
  "Berge" = "#995533",
  "Ortsnamen" = "#e8bf28",
  "Jahreszeiten" = "#cc00cc",
  "Himmelskörper" = "#000066",
  "Bauwerke" = "#aaaaff",
  "Sonstige" = "#aaaaaa",
  "Unbekannt" = "#333333"
)

typTextColors <- c(
  "Personen mit Lokalbezug" = "#ffffff",
  "Komponisten" = "#000000",
  "andere Personen" = "#ffffff",
  "Vögel" = "#000000",
  "andere Tiere" = "#000000",
  "Früchte" = "#000000",
  "Bäume" = "#ffffff",
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
        {
          leaflet(options = leafletOptions(
            zoom = 13,
            center = list(lng = 11.798, lat = 48.12)
          ), height = 550) %>%
            addProviderTiles(providers$CartoDB.Positron) %>%
            addPolylines(
              data = strassenNamensherkuenfte$Geometry,
              color = unname(typColors[strassenNamensherkuenfte$Typ]),
              label = paste0(strassenNamensherkuenfte$Name, ": ", strassenNamensherkuenfte$Typ)
            ) %>%
            identity()
        }
      )
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
        p(HTML('OpenStreetMap und Wikidata werden von Freiwilligen gepflegt, jede:r kann sich daran beteiligen. Zum Eintragen der Namensherkünfte, die in OSM hinterlegt sind, gibt es ein praktisches Tool von <a href="https://mapcomplete.osm.be/etymology">Mapcomplete</a>. Eine ähnliche Kartendarstellung der Namensherkünfte gibt es auf <a href="https://etymology.dsantini.it/#11.778,48.104,13.7,type">etymology.dsantini.it</a>. Das Projekt <a href="https://github.com/EqualStreetNames/equalstreetnames/">EqualStreetNames</a> fokussiert sich auf die Geschlechterverteilung von öffentlichen Benennungen.')),
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


    }
  )
}
