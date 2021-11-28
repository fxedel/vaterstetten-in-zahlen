corona <- new.env()
sys.source("R/corona.R", envir = corona, chdir = FALSE)
coronaImpfungen <- new.env()
sys.source("R/coronaImpfungen.R", envir = coronaImpfungen, chdir = FALSE)
einwohner <- new.env()
sys.source("R/einwohner.R", envir = einwohner, chdir = FALSE)

ui <- function(request, id) {
  ns <- NS(id)
  tagList(
    h2("Vaterstetten in Zahlen"),

    fluidRow(
      box(
        title = "Corona in Vaterstetten",
        width = 6,
        tagList(
          valueBoxOutput(ns("valueBoxInzidenz"), width = 12),
          actionButton(ns("buttonCorona"), "Zu den Corona-Fallzahlen", icon = icon("virus"), width = "100%")
        )
      ),
      box(
        title = "Impfungen im Landkreis",
        width = 6,
        tagList(
          valueBoxOutput(ns("valueBoxImpfungen"), width = 12),
          actionButton(ns("buttonCoronaImpfungen"), "Zu den Corona-Impfungen", icon = icon("syringe"), width = "100%")
        )
      )
    ),

    fluidRow(
      box(
        title = "Einwohner in Vaterstetten",
        width = 6,
        tagList(
          valueBoxOutput(ns("valueBoxEinwohner"), width = 12),
          actionButton(ns("buttonEinwohner"), "Zu den Einwohnerstatistiken", icon = icon("users"), width = "100%")
        )
      ),
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
      output$valueBoxInzidenz <- renderValueBox({
        lastRow <- corona$fallzahlenArcGIS %>% slice_tail()
        valueBox(
          format(round(lastRow$inzidenz7tage, 1), nsmall = 1, decimal.mark = ",", big.mark = "."),
          paste0("7-Tage-Inzidenz (", format(lastRow$datum, "%d.%m.%Y"), ")"),
          color = "purple",
          icon = icon("virus"),
          href = "/?tab=corona"
        )
      })

      output$valueBoxImpfungen <- renderValueBox({
        lastRow <- coronaImpfungen$impfungenMerged %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        valueBox(
          paste0(format(round(lastRow$erstimpfungen / coronaImpfungen$einwohnerZahlLkEbe * 100, 1), nsmall = 1, decimal.mark = ",", big.mark = "."), "%"),
          paste0("Erstimpfquote (", format(lastRow$datum, "%d.%m.%Y"), ")"),
          color = "purple",
          icon = icon("syringe"),
          href = "/?tab=coronaImpfungen"
        )
      })

      output$valueBoxEinwohner <- renderValueBox({
        lastRow <- einwohner$lfstatBevoelkerungCombined %>% filter(!is.na(bevoelkerung)) %>% slice_tail()
        valueBox(
          format(lastRow$bevoelkerung, decimal.mark = ",", big.mark = "."),
          paste0("Einwohner (", format(lastRow$stichtag, "%d.%m.%Y"), ")"),
          color = "purple",
          icon = icon("users"),
          href = "/?tab=einwohner"
        )
      })

      observeEvent(input$buttonCorona, {
        updateTabsetPanel(parentSession, "tab", selected = "corona")
      })
      observeEvent(input$buttonCoronaImpfungen, {
        updateTabsetPanel(parentSession, "tab", selected = "coronaImpfungen")
      })
      observeEvent(input$buttonEinwohner, {
        updateTabsetPanel(parentSession, "tab", selected = "einwohner")
      })
    }
  )
}
