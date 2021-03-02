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

addResourcePath(prefix = '/assets', directoryPath = 'assets')

ui <- function(request) {
  dashboardPage(skin = "purple",
    dashboardHeader(
      title = "Vaterstetten in Zahlen",
      titleWidth = 250,
      tags$li(class = "dropdown", 
        dropdownButton(label = "Download", circle = FALSE, right = TRUE, status = "header-dropdown", 
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
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "assets/style.css"),

        # colored status bar in mobile Chrome browser
        tags$meta(name = "theme-color", content = "#555299"),

        # used by Google Search
        tags$meta(property = "description", content = "vaterstetten-in-zahlen.de ist ein Open-Source-Projekt, um öffentlich verfügbare Daten und Zahlen über die Gemeinde Vaterstetten zu visualisieren."),

        # og:xyz meta tags are Facebook's Open Graph Markup
        tags$meta(property = "og:title", content = "Vaterstetten in Zahlen"),
        tags$meta(property = "og:description", content = "vaterstetten-in-zahlen.de ist ein Open-Source-Projekt, um öffentlich verfügbare Daten und Zahlen über die Gemeinde Vaterstetten zu visualisieren."),
        tags$meta(property = "og:url", content = "https://vaterstetten-in-zahlen.de"),

        # activate Twitter previews
        tags$meta(name = "twitter:card", content = "summary"),
      ),
      tabItems(
        tabItem(tabName = "main", mainPage$ui(request, "mainPage")),
        tabItem(tabName = "corona", corona$ui(request, "corona")),
        tabItem(tabName = "coronaImpfungen", coronaImpfungen$ui(request, "coronaImpfungen")),
        tabItem(tabName = "impressum", impressum$ui(request, "impressum"))
      ),
      fluidRow(
        box(
          title = "Über das Projekt",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tagList(
            p(HTML("<strong>vaterstetten-in-zahlen.de</strong> ist ein Open-Source-Projekt, um öffentlich verfügbare Daten und Zahlen über die Gemeinde Vaterstetten zu visualisieren (und dafür gegebenenfalls zu sammeln). Der Quellcode ist <a href=\"https://github.com/fxedel/vaterstetten-in-zahlen\">frei verfügbar auf GitHub</a>."))
          ),
        ),
      ),
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
