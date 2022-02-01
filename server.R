library(dplyr)
library(leaflet)
library(lubridate)
library(memoise)
library(plotly)
library(purrr)
library(readr)
library(scales)
library(sf)
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(stringr)
library(tidyr)
library(htmltools)

# print(.packages())

Sys.setlocale("LC_TIME", "de_DE.utf8")

mainPage <- new.env()
sys.source("R/mainPage.R", envir = mainPage, chdir = FALSE)
corona <- new.env()
sys.source("R/corona.R", envir = corona, chdir = FALSE)
coronaImpfungen <- new.env()
sys.source("R/coronaImpfungen.R", envir = coronaImpfungen, chdir = FALSE)
photovoltaik <- new.env()
sys.source("R/photovoltaik.R", envir = photovoltaik, chdir = FALSE)
einwohner <- new.env()
sys.source("R/einwohner.R", envir = einwohner, chdir = FALSE)
kommunalwahl2020 <- new.env()
sys.source("R/kommunalwahl2020.R", envir = kommunalwahl2020, chdir = FALSE)
impressum <- new.env()
sys.source("R/impressum.R", envir = impressum, chdir = FALSE)

theme_set(theme_light())

addResourcePath(prefix = '/assets', directoryPath = 'assets')

ui <- function(request) {
  query = parseQueryString(request$QUERY_STRING)

  dashboardPage(skin = "purple",
    dashboardHeader(
      title = "Vaterstetten in Zahlen",
      titleWidth = 280,
      tags$li(class = "dropdown",
        a(tagList(icon("github"), "Download"), href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data")
      )
    ),
    dashboardSidebar(
      width = 280,
      sidebarMenu(id = "tab", selected = query$tab,
        menuItem("Start", tabName = "main", icon = icon("home"), selected = query$tab == "main" || is.null(query$tab)),
        menuItem("Corona-Fallzahlen", tabName = "corona", icon = icon("virus"), selected = query$tab == "corona"),
        menuItem("Corona-Impfungen", tabName = "coronaImpfungen", icon = icon("syringe"), selected = query$tab == "coronaImpfungen"),
        menuItem("Photovoltaik", tabName = "photovoltaik", icon = icon("solar-panel"), selected = query$tab == "photovoltaik"),
        menuItem("Einwohner", tabName = "einwohner", icon = icon("users"), selected = query$tab == "einwohner"),
        menuItem("Kommunalwahl 2020", tabName = "kommunalwahl2020", icon = icon("vote-yea"), selected = query$tab == "kommunalwahl2020"),
        menuItem("Impressum", tabName = "impressum", icon = icon("id-card"), selected = query$tab == "impressum")
      )
    ),
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "assets/style.css"),

        tags$script(type = "text/javascript", src = "assets/script.js"),
        
        tags$link(rel = "icon", type = "image/png", href = "/assets/logo_32x32.png", sizes = "32x32"),
        tags$link(rel = "icon", type = "image/png", href = "/assets/logo_128x128.png", sizes = "128x128"),
        tags$link(rel = "icon", type = "image/png", href = "/assets/logo_152x152.png", sizes = "152x152"),
        tags$link(rel = "icon", type = "image/png", href = "/assets/logo_167x167.png", sizes = "167x167"),
        tags$link(rel = "icon", type = "image/png", href = "/assets/logo_180x180.png", sizes = "180x180"),
        tags$link(rel = "apple-touch-icon", type = "image/png", href = "/assets/logo_180x180.png", sizes = "180x180"),
        tags$link(rel = "icon", type = "image/png", href = "/assets/logo_196x196.png", sizes = "196x196"),

        # colored status bar in mobile Chrome browser
        tags$meta(name = "theme-color", content = "#555299"),

        # used by Google Search
        tags$meta(property = "description", content = "vaterstetten-in-zahlen.de ist ein Open-Source-Projekt, um öffentlich verfügbare Daten und Zahlen über die Gemeinde Vaterstetten zu visualisieren."),

        # og:xyz meta tags are Facebook's Open Graph Markup
        tags$meta(property = "og:title", content = "Vaterstetten in Zahlen"),
        tags$meta(property = "og:description", content = "vaterstetten-in-zahlen.de ist ein Open-Source-Projekt, um öffentlich verfügbare Daten und Zahlen über die Gemeinde Vaterstetten zu visualisieren."),
        tags$meta(property = "og:url", content = "https://vaterstetten-in-zahlen.de"),
        tags$meta(property = "og:image", content = "https://vaterstetten-in-zahlen.de/assets/logo_512x512.png"),
        tags$meta(property = "og:image:width", content = "512"),
        tags$meta(property = "og:image:height", content = "512"),

        # activate Twitter previews
        tags$meta(name = "twitter:card", content = "summary"),

        # Google Search Console
        tags$meta(name = "google-site-verification", content = "LV313urokNhRgEiwriQi33VkY1MboB9-til_qMZpGPI")
      ),
      tabItems(
        tabItem(tabName = "main", mainPage$ui(request, "mainPage")),
        tabItem(tabName = "corona", corona$ui(request, "corona")),
        tabItem(tabName = "coronaImpfungen", coronaImpfungen$ui(request, "coronaImpfungen")),
        tabItem(tabName = "photovoltaik", photovoltaik$ui(request, "photovoltaik")),
        tabItem(tabName = "einwohner", einwohner$ui(request, "einwohner")),
        tabItem(tabName = "kommunalwahl2020", kommunalwahl2020$ui(request, "kommunalwahl2020")),
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
    updateQueryString(paste0("?tab=", session$input$tab), mode = "push")
  })

  mainPage$server("mainPage", session)
  corona$server("corona")
  coronaImpfungen$server("coronaImpfungen")
  photovoltaik$server("photovoltaik")
  einwohner$server("einwohner")
  kommunalwahl2020$server("kommunalwahl2020")
  impressum$server("impressum")
}

shinyApp(ui, server, options = list(host = "0.0.0.0", port = 4373))
