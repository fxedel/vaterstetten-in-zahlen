utils <- loadModule("R/utils.R")
strassennamen <- loadModule("R/strassennamen.R")
photovoltaik <- loadModule("R/photovoltaik.R")
einwohner <- loadModule("R/einwohner.R")
hgv <- loadModule("R/hgv.R")


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Vaterstetten in Zahlen"),

    fluidRow(
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
    ),

    fluidRow(
      box(
        title = "Humboldt-Gymnasium Vaterstetten",
        width = 6,
        tagList(
          {
            row <- hgv$arcgisSchuelerPrognose[which.max(hgv$arcgisSchuelerPrognose$schuljahresbeginn),]
            actionLink(ns("linkHGV"), valueBox(
              utils$germanNumberFormat(row$schueler),
              paste0("Schüler:innen werden am HGV für das Schuljahr ", row$schuljahresbeginn, "/", row$schuljahresbeginn+1, " prognostiziert"),
              color = "aqua",
              icon = icon("school"),
              width = 12
            ))
          },
          actionButton(ns("buttonHGV"), "Zum Humboldt-Gymnasium", icon = icon("school"), width = "100%")
        )
      ),
      box(
        title = "Staatliche Realschule Vaterstetten",
        width = 6,
        tagList(
          {
            row <- rsv$arcgisSchuelerPrognose[which.max(rsv$arcgisSchuelerPrognose$schuljahresbeginn),]
            actionLink(ns("linkRSV"), valueBox(
              utils$germanNumberFormat(row$schueler),
              paste0("Schüler:innen werden an der Realschule für das Schuljahr ", row$schuljahresbeginn, "/", row$schuljahresbeginn+1, " prognostiziert"),
              color = "aqua",
              icon = icon("school"),
              width = 12
            ))
          },
          actionButton(ns("buttonRSV"), "Zur Realschule Vaterstetten", icon = icon("school"), width = "100%")
        )
      ),
    ),

    fluidRow(
      box(
        title = "Straßen in Vaterstetten",
        width = 6,
        tagList(
          {
            actionLink(ns("linkStrassen"), valueBox(
              nrow(strassennamen$osmStrassen),
              paste0("Straßen gibt es in der Gemeinde"),
              color = "maroon",
              icon = icon("road"),
              width = 12
            ))
          },
          actionButton(ns("buttonStrassen"), "Zu den Straßennamen", icon = icon("road"), width = "100%")
        )
      ),
      box(
        width = 6,
        tagList(
          "Weitere Visualisierungen sind in Arbeit …"
        )
      ),
    ),
  ) %>% renderTags()
})

server <- function(id, parentSession) {
  moduleServer(
    id,
    function(input, output, session) {
      observe({
        req(input$linkStrassen | input$buttonStrassen)
        updateTabsetPanel(parentSession, "tab", selected = "strassennamen")
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
      observe({
        req(input$linkRSV | input$buttonRSV)
        updateTabsetPanel(parentSession, "tab", selected = "rsv")
      })
    }
  )
}
