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
            a("0152 56302925", href = "tel:+4915256302925"), br(),
            a("felix@vaterstetten-in-zahlen.de", href = "mailto:felix@vaterstetten-in-zahlen.de"),
          )
        )
      )
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
