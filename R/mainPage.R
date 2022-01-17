utils <- new.env()
sys.source("R/utils.R", envir = utils, chdir = FALSE)
corona <- new.env()
sys.source("R/corona.R", envir = corona, chdir = FALSE)
coronaImpfungen <- new.env()
sys.source("R/coronaImpfungen.R", envir = coronaImpfungen, chdir = FALSE)
photovoltaik <- new.env()
sys.source("R/photovoltaik.R", envir = photovoltaik, chdir = FALSE)
einwohner <- new.env()
sys.source("R/einwohner.R", envir = einwohner, chdir = FALSE)

lastRowCorona <- corona$fallzahlenArcGISGemeinden %>% filter(ort == "Vaterstetten") %>% slice_tail()
valueBoxCorona <- valueBox(
  utils$germanNumberFormat(lastRowCorona$inzidenz7tage, accuracy = .1),
  paste0("7-Tage-Inzidenz (", format(lastRowCorona$datum, "%d.%m.%Y"), ")"),
  color = "red",
  icon = icon("virus"),
  href = "/?tab=corona",
  width = 12
)

lastRowCoronaImpfungen <- coronaImpfungen$impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
valueBoxCoronaImpfungen <- valueBox(
  utils$germanNumberFormat(lastRowCoronaImpfungen$erstimpfungen / coronaImpfungen$einwohnerZahlLkEbe * 100, accuracy = .1, suffix = "%"),
  paste0("Erstimpfquote (", format(lastRowCoronaImpfungen$datum, "%d.%m.%Y"), ")"),
  color = "blue",
  icon = icon("syringe"),
  href = "/?tab=coronaImpfungen",
  width = 12
)

valueBoxPhotovoltaik <- valueBox(
  utils$germanNumberFormat(photovoltaik$inBetriebStats$bruttoleistung_kW, suffix = " MWp", scale = 1/1000, accuracy = 0.2),
  "Installierte Photovoltaik-Leistung in Vaterstetten",
  color = "yellow",
  icon = icon("solar-panel"),
  width = 12
)

lastRowEinwohner <- einwohner$lfstatBevoelkerungCombined %>% filter(!is.na(bevoelkerung)) %>% slice_tail()
valueBoxEinwohner <- valueBox(
  utils$germanNumberFormat(lastRowEinwohner$bevoelkerung),
  paste0("Einwohner (", format(lastRowEinwohner$stichtag, "%d.%m.%Y"), ")"),
  color = "olive",
  icon = icon("users"),
  href = "/?tab=einwohner",
  width = 12
)


ui <- function(request, id) {
  ns <- NS(id)
  tagList(
    h2("Vaterstetten in Zahlen"),

    fluidRow(
      box(
        title = "Corona in Vaterstetten",
        width = 6,
        tagList(
          valueBoxCorona,
          actionButton(ns("buttonCorona"), "Zu den Corona-Fallzahlen", icon = icon("virus"), width = "100%")
        )
      ),
      box(
        title = "Impfungen im Landkreis",
        width = 6,
        tagList(
          valueBoxCoronaImpfungen,
          actionButton(ns("buttonCoronaImpfungen"), "Zu den Corona-Impfungen", icon = icon("syringe"), width = "100%")
        )
      )
    ),

    fluidRow(
      box(
        title = "Photovoltaik in Vaterstetten",
        width = 6,
        tagList(
          valueBoxPhotovoltaik,
          actionButton(ns("buttonPhotovoltaik"), "Zu den Photovoltaik-Anlagen", icon = icon("solar-panel"), width = "100%")
        )
      ),
      box(
        title = "Einwohner in Vaterstetten",
        width = 6,
        tagList(
          valueBoxEinwohner,
          actionButton(ns("buttonEinwohner"), "Zu den Einwohnerstatistiken", icon = icon("users"), width = "100%")
        )
      )
    ),

    fluidRow(
      box(
        width = 6,
        tagList(
          "Weitere Visualisierungen sind in Arbeit …"
        )
      )
    ),
  )
}

server <- function(id, parentSession) {
  moduleServer(
    id,
    function(input, output, session) {
      observeEvent(input$buttonCorona, {
        updateTabsetPanel(parentSession, "tab", selected = "corona")
      })
      observeEvent(input$buttonCoronaImpfungen, {
        updateTabsetPanel(parentSession, "tab", selected = "coronaImpfungen")
      })
      observeEvent(input$buttonPhotovoltaik, {
        updateTabsetPanel(parentSession, "tab", selected = "photovoltaik")
      })
      observeEvent(input$buttonEinwohner, {
        updateTabsetPanel(parentSession, "tab", selected = "einwohner")
      })
    }
  )
}
