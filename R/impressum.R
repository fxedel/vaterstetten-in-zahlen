ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

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
  ) %>% renderTags()
})

server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
    }
  )
}
