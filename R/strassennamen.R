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
  Typ = factor(Typ, levels = c(
    "Personen mit Lokalbezug",
    "Komponisten",
    "Andere Personen",
    "Vögel",
    "Andere Tiere",
    "Obst",
    "Bäume",
    "Pflanzen",
    "Berge",
    "Ortsnamen",
    "Jahreszeiten",
    "Himmelskörper",
    "Bauwerke",
    "Sonstige"
  ))
)

strassenNamensherkuenfte <- left_join(
  osmStrassen %>% separate_longer_delim(NamensherkunftWikidata, "/"),
  wikidataNamensherkuenfte,
  by = join_by(NamensherkunftWikidata == WikidataObjekt)
# ) %>% mutate(
#   Typ = coalesce(Typ, "Unbekannt")
)

pal <- c("red", "green", "blue", "goldenrod", "magenta")
pal <- setNames(pal, c("Personen mit Lokalbezug", "Pflanzen", "Americas", "Oceania", "Africa"))

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
            # color = ~Typ,
            # colors = pal,
            height = 350,
            type = "bar",
            orientation = "h",
            text = ~n,
            hoverinfo = "none",
            textangle = 0,
            textposition = "inside"
          ) %>%
            plotly_default_config() %>%
            layout(yaxis = list(autorange = "reversed")) %>%
            layout(uniformtext = list(minsize = 14, mode = "show")) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
          },
        p(HTML("Die Linie entspricht dem Median („mittlere“ Modulleistung), der farbige Bereich dem 25%- bis 75%-Perzentil, also der mittleren Hälfte aller Anlagen.")),
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
        p(HTML("Die Linie entspricht dem Median („mittlere“ Modulleistung), der farbige Bereich dem 25%- bis 75%-Perzentil, also der mittleren Hälfte aller Anlagen.")),
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
    # layout(yaxis = list(fixedrange = TRUE, rangemode = "tozero")) %>%
    layout(dragmode = FALSE) %>%
    # layout(legend = list(bgcolor = "#ffffffaa", orientation = "h")) %>% # legend below plot
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
