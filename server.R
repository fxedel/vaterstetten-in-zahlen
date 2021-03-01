library(shiny)
library(shinydashboard)
library(ggplot2)
library(shinyWidgets)

mainPage <- new.env()
sys.source("R/mainPage.R", envir = mainPage, chdir = FALSE)
corona <- new.env()
sys.source("R/corona.R", envir = corona, chdir = FALSE)
coronaImpfungen <- new.env()
sys.source("R/coronaImpfungen.R", envir = coronaImpfungen, chdir = FALSE)
impressum <- new.env()
sys.source("R/impressum.R", envir = impressum, chdir = FALSE)

theme_set(theme_light())

ui <- function(request) {
  dashboardPage(skin = "purple",
    dashboardHeader(
      title = "Vaterstetten in Zahlen",
      titleWidth = 250,
      tags$li(class="dropdown", 
        dropdownButton(label ="Download", circle = FALSE, right=TRUE, status = "header-dropdown", 
           downloadLink("downloadFallzahlen", "Corona-Fallzahlen in Vaterstetten"),
           downloadLink("downloadImpfungen", "Corona-Impfungen im Landkreis Ebersberg")
        )
      )
    ),
    dashboardSidebar(
      width = 250,
      sidebarMenu(id = "tab",
        menuItem("Start", tabName = "main", icon = icon("home")),
        menuItem("Corona-Fallzahlen in Vat", tabName = "corona", icon = icon("virus")),
        menuItem("Corona-Impfungen in EBE", tabName = "coronaImpfungen", icon = icon("syringe")),
        menuItem("Impressum", tabName = "impressum", icon = icon("id-card"))
      )
    ),
    dashboardBody(
      includeCSS("www/style.css"),
      tabItems(
        tabItem(tabName = "main", mainPage$ui(request, "mainPage")),
        tabItem(tabName = "corona", corona$ui(request, "corona")),
        tabItem(tabName = "coronaImpfungen", coronaImpfungen$ui(request, "coronaImpfungen")),
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

  mainPage$server("mainPage", session)
  corona$server("corona")
  coronaImpfungen$server("coronaImpfungen")
  impressum$server("impressum")
  
  output$downloadFallzahlen <- downloadHandler("fallzahlenVat.csv", content = function(dlFile) {
    file.copy("data/lra-ebe-corona/fallzahlenVat.csv", dlFile)
    }, contentType = "text/csv")
  
  output$downloadImpfungen <- downloadHandler("impfungenLkEbe.csv", content = function(dlFile) {
    file.copy("data/lra-ebe-corona/impfungenLkEbe.csv", dlFile)
  }, contentType = "text/csv")
}

shinyApp(ui, server, options = list(host = "0.0.0.0", port = 4373), enableBookmarking = "url")
