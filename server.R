library(shiny)
library(shinydashboard)
library(ggplot2)

mainPage <- new.env()
sys.source("R/mainPage.R", envir = mainPage, chdir = TRUE)
corona <- new.env()
sys.source("R/corona.R", envir = corona, chdir = TRUE)
impressum <- new.env()
sys.source("R/impressum.R", envir = impressum, chdir = TRUE)

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
        menuItem("Start", tabName = "main", icon = icon("home")),
        menuItem("Corona", tabName = "corona", icon = icon("virus")),
        menuItem("Impressum", tabName = "impressum", icon = icon("id-card"))
      )
    ),
    dashboardBody(
      tabItems(
        tabItem(tabName = "main", mainPage$ui(request, "mainPage")),
        tabItem(tabName = "corona", corona$ui(request, "corona")),
        tabItem(tabName = "impressum", impressum$ui(request, "impressum"))
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

  mainPage$server("mainPage")
  corona$server("corona")
  impressum$server("impressum")
}

shinyApp(ui, server, options = list(host = "0.0.0.0", port = 4373), enableBookmarking = "url")
