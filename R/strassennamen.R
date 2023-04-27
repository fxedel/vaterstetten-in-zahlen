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
  )
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
  "Personen mit Lokalbezug" = "#880000",
  "Komponisten" = "#ee7700",
  "andere Personen" = "#ee0000",
  "Vögel" = "#33ddff",
  "andere Tiere" = "#00ffdd",
  "Früchte" = "#66ff00",
  "Bäume" = "#006600",
  "andere Pflanzen" = "#66cc00",
  "Berge" = "#bb4400",
  "Ortsnamen" = "#e8bf28",
  "Jahreszeiten" = "#aa00aa",
  "Himmelskörper" = "#000066",
  "Bauwerke" = "#ccccff",
  "Sonstige" = "#cccccc",
  "Unbekannt" = "#999999"
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
    )

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
