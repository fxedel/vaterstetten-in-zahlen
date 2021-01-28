ui <- function(request, id) {
  ns <- NS(id)
  tagList(
    h2("Impressum"),

    fluidRow(
      box(
        title = "Kontakt",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(
            strong("Felix Edelmann"), br(),
            "Dachsweg 13", br(),
            "85598 Baldham", br(),
            "0152 56302925", br(),
            a("felix@vaterstetten-in-zahlen.de", href = "mailto:felix@vaterstetten-in-zahlen.de"),
          )
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

server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
    }
  )
}
