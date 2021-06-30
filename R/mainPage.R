corona <- new.env()
sys.source("R/corona.R", envir = corona, chdir = FALSE)
coronaImpfungen <- new.env()
sys.source("R/coronaImpfungen.R", envir = coronaImpfungen, chdir = FALSE)

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
          format(round(lastRow$inzidenz7tage, 1), nsmall = 1),
          paste0("7-Tage-Inzidenz (", format(lastRow$datum, "%d.%m.%Y"), ")"),
          color = "purple",
          icon = icon("virus"),
          href = "/?tab=corona"
        )
      })

      output$valueBoxImpfungen <- renderValueBox({
        lastRow <- coronaImpfungen$impfungen %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        valueBox(
          paste0(format(round(lastRow$erstimpfungen / coronaImpfungen$einwohnerZahlLkEbe * 100, 1), nsmall = 1), "%"),
          paste0("Erstimpfquote (", format(lastRow$datum, "%d.%m.%Y"), ")"),
          color = "purple",
          icon = icon("syringe"),
          href = "/?tab=coronaImpfungen"
        )
      })

      observeEvent(input$buttonCorona, {
        updateTabsetPanel(parentSession, "tab", selected = "corona")
      })
      observeEvent(input$buttonCoronaImpfungen, {
        updateTabsetPanel(parentSession, "tab", selected = "coronaImpfungen")
      })
    }
  )
}
