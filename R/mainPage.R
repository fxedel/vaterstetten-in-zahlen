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
        lastRow <- corona$fallzahlen %>% slice_tail()
        valueBox(
          format(round(lastRow$inzidenz7, 1), nsmall = 1),
          paste("7-Tage-Inzidenz (", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("virus")
        )
      })

      output$valueBoxImpfungen <- renderValueBox({
        lastRow <- coronaImpfungen$impfungenRaw %>% filter(!is.na(erstimpfungen)) %>% slice_tail()
        valueBox(
          lastRow$erstimpfungen,
          paste("Geimpfte (mind. Erstimpfung, Stand:\u00A0", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("syringe")
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
