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
hgv <- new.env()
sys.source("R/hgv.R", envir = hgv, chdir = FALSE)


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Vaterstetten in Zahlen"),

    fluidRow(
      box(
        title = "Corona in Vaterstetten",
        width = 6,
        tagList(
          {
            lastRowCorona <- corona$fallzahlenArcGISGemeinden %>% filter(ort == "Vaterstetten") %>% slice_tail()
            actionLink(ns("linkCorona"), valueBox(
              utils$germanNumberFormat(lastRowCorona$inzidenz7tage, accuracy = .1),
              paste0("7-Tage-Inzidenz (", format(lastRowCorona$datum, "%d.%m.%Y"), ")"),
              color = "red",
              icon = icon("virus"),
              width = 12
            ))
          },
          actionButton(ns("buttonCorona"), "Zu den Corona-Fallzahlen", icon = icon("virus"), width = "100%")
        )
      ),
      box(
        title = "Impfungen im Landkreis",
        width = 6,
        tagList(
          {
            lastRowCoronaImpfungen <- coronaImpfungen$impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
            actionLink(ns("linkCoronaImpfungen"), valueBox(
              utils$germanNumberFormat(lastRowCoronaImpfungen$erstimpfungen / coronaImpfungen$einwohnerZahlLkEbe * 100, accuracy = .1, suffix = "%"),
              paste0("Erstimpfquote (", format(lastRowCoronaImpfungen$datum, "%d.%m.%Y"), ")"),
              color = "blue",
              icon = icon("syringe"),
              width = 12
            ))
          },
          actionButton(ns("buttonCoronaImpfungen"), "Zu den Corona-Impfungen", icon = icon("syringe"), width = "100%")
        )
      )
    ),

    fluidRow(
      box(
        title = "Photovoltaik in Vaterstetten",
        width = 6,
        tagList(
          {
            actionLink(ns("linkPhotovoltaik"), valueBox(
              utils$germanNumberFormat(photovoltaik$inBetriebStats$bruttoleistung_kW, suffix = " MWp", scale = 1/1000, accuracy = 0.2),
              "Installierte Photovoltaik-Leistung in Vaterstetten",
              color = "yellow",
              icon = icon("solar-panel"),
              width = 12
            ))
          },
          actionButton(ns("buttonPhotovoltaik"), "Zu den Photovoltaik-Anlagen", icon = icon("solar-panel"), width = "100%")
        )
      ),
      box(
        title = "Einwohner in Vaterstetten",
        width = 6,
        tagList(
          {
            lastRowEinwohner <- einwohner$lfstatBevoelkerungCombined %>% filter(!is.na(bevoelkerung)) %>% slice_tail()
            actionLink(ns("linkEinwohner"), valueBox(
              utils$germanNumberFormat(lastRowEinwohner$bevoelkerung),
              paste0("Einwohner (", format(lastRowEinwohner$stichtag, "%d.%m.%Y"), ")"),
              color = "olive",
              icon = icon("users"),
              width = 12
            ))
          },
          actionButton(ns("buttonEinwohner"), "Zu den Einwohnerstatistiken", icon = icon("users"), width = "100%")
        )
      ),
      box(
        title = "Humboldt-Gymnasium Vaterstetten",
        width = 6,
        tagList(
          {
            row <- hgv$arcgisSchuelerPrognose[which.max(hgv$arcgisSchuelerPrognose$schueler),]
            actionLink(ns("linkHGV"), valueBox(
              utils$germanNumberFormat(row$schueler),
              paste0("Schüler:innen werden am HGV für das Schuljahr ", row$schuljahresbeginn, "/", row$schuljahresbeginn+1, " prognostiziert"),
              color = "aqua",
              icon = icon("school"),
              width = 12
            ))
          },
          actionButton(ns("buttonHGV"), "Zu den HGV-Statistiken", icon = icon("school"), width = "100%")
        )
      ),
    ),

    fluidRow(
      box(
        width = 6,
        tagList(
          "Weitere Visualisierungen sind in Arbeit …"
        )
      )
    ),
  ) %>% renderTags()
})

server <- function(id, parentSession) {
  moduleServer(
    id,
    function(input, output, session) {
      observe({
        req(input$linkCorona | input$buttonCorona)
        updateTabsetPanel(parentSession, "tab", selected = "corona")
      })
      observe({
        req(input$linkCoronaImpfungen | input$buttonCoronaImpfungen)
        updateTabsetPanel(parentSession, "tab", selected = "coronaImpfungen")
      })
      observe({
        req(input$linkPhotovoltaik | input$buttonPhotovoltaik)
        updateTabsetPanel(parentSession, "tab", selected = "photovoltaik")
      })
      observe({
        req(input$linkEinwohner | input$buttonEinwohner)
        updateTabsetPanel(parentSession, "tab", selected = "einwohner")
      })
      observe({
        req(input$linkHGV | input$buttonHGV)
        updateTabsetPanel(parentSession, "tab", selected = "hgv")
      })
    }
  )
}
