corona <- new.env()
sys.source("corona.R", envir = corona, chdir = TRUE)

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
          actionButton(ns("buttonCorona"), "Zu den Corona-Daten", icon = icon("virus"), width = "100%")
        )
      ),

      box(
        width = 6,
        tagList(
          "coming soon …"
        )
      )
    ),

    fluidRow(
      box(
        title = "Über das Projekt",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("<strong>vaterstetten-in-zahlen.de</strong> ist ein Open-Source-Projekt, um öffentliche verfügbare Daten und Zahlen über die Gemeinde Vaterstetten zu visualisieren (und dafür gegebenenfalls zu sammeln). Der Quellcode ist <a href=\"https://github.com/fxedel/vaterstetten-in-zahlen\">frei verfügbar auf GitHub</a>."))
        ),
      ),
    ),
  )
}

server <- function(id, parentSession) {
  moduleServer(
    id,
    function(input, output, session) {
      setBookmarkExclude(c("buttonCorona"))

      output$valueBoxInzidenz <- renderValueBox({
        lastRow <- corona$fallzahlen %>% slice_tail()
        valueBox(
          format(round(lastRow$inzidenz7, 1), nsmall = 1),
          paste("7-Tages-Inzidenz (", format(lastRow$datum, "%d.%m.%Y"), ")", sep = ""),
          color = "purple",
          icon = icon("virus")
        )
      })

      observeEvent(input$buttonCorona, {
        updateTabsetPanel(parentSession, "tab", selected = "corona")
      })
    }
  )
}
