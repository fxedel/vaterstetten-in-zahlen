library(shiny)
library(shinydashboard)
library(ggplot2)

theme_set(theme_light())

ui <- function(request) {
  dashboardPage(skin = "purple",
    dashboardHeader(
      title = "Vaterstetten in Zahlen",
      titleWidth = 250
    ),
    dashboardSidebar(
      width = 250,
      sidebarMenu(id = "sidebar",
        menuItem("Start", tabName = "start", icon = icon("home"))
      )
    ),
    dashboardBody(
      tabItems(
        tabItem(tabName = "start",
          h2("Start")
        )
      )
    )
  )
}

server <- function(input, output, session) {
  observe({
    # Trigger this observer every time an input changes
    reactiveValuesToList(input)
    session$doBookmark()
  })
  onBookmarked(function(url) {
    updateQueryString(url)
  })

}

shinyApp(ui, server, options = list(host = "127.0.0.1", port = 4373), enableBookmarking = "url")