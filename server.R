library(dplyr, warn.conflicts = FALSE)
library(leaflet, warn.conflicts = FALSE)
library(lubridate, warn.conflicts = FALSE)
library(memoise, warn.conflicts = FALSE)
library(plotly, warn.conflicts = FALSE)
library(purrr, warn.conflicts = FALSE)
library(readr, warn.conflicts = FALSE)
library(scales, warn.conflicts = FALSE)
library(sf, warn.conflicts = FALSE)
library(shiny, warn.conflicts = FALSE)
library(shinydashboard, warn.conflicts = FALSE)
library(shinyWidgets, warn.conflicts = FALSE)
library(bslib, warn.conflicts = FALSE)
library(stringr, warn.conflicts = FALSE)
library(tidyr, warn.conflicts = FALSE)
library(htmltools, warn.conflicts = FALSE)
library(DT, warn.conflicts = FALSE)

# print(.packages())

Sys.setlocale("LC_TIME", "de_DE.utf8")

moduleCache <- new.env()
loadModule <- function(filename) {
  if (!(filename %in% names(moduleCache))) {
    print(paste0("load ", filename))
    moduleEnv <- new.env()
    sys.source(filename, envir = moduleEnv, chdir = FALSE)
    moduleCache[[filename]] <- moduleEnv
  }

  return(moduleCache[[filename]])
}


mainPage <- loadModule("R/mainPage.R")
corona <- loadModule("R/corona.R")
coronaImpfungen <- loadModule("R/coronaImpfungen.R")
photovoltaik <- loadModule("R/photovoltaik.R")
einwohner <- loadModule("R/einwohner.R")
hgv <- loadModule("R/hgv.R")
rsv <- loadModule("R/rsv.R")
strassennamen <- loadModule("R/strassennamen.R")

wahlenOverview <- loadModule("R/wahlen/overview.R")
kommunalwahl2020 <- loadModule("R/wahlen/kommunalwahl2020.R")
bundestagswahl2021 <- loadModule("R/wahlen/bundestagswahl2021.R")
landtagswahl2023 <- loadModule("R/wahlen/landtagswahl2023.R")
europawahl2024 <- loadModule("R/wahlen/europawahl2024.R")
bundestagswahl2025 <- loadModule("R/wahlen/bundestagswahl2025.R")

impressum <- loadModule("R/impressum.R")

theme_set(theme_light())

addResourcePath(prefix = '/assets', directoryPath = 'assets')

ui <- function(request) {
  query = parseQueryString(request$QUERY_STRING)

  dashboardPage(skin = "purple",
    dashboardHeader(
      title = "Vaterstetten in Zahlen",
      titleWidth = 280,
      tags$li(class = "dropdown",
        a(tagList(icon("github"), "Daten-Download"), href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data")
      )
    ),
    dashboardSidebar(
      width = 280,
      sidebarMenu(id = "tab", selected = query$tab,
        menuItem("Start", tabName = "main", icon = icon("home"), selected = query$tab == "main" || is.null(query$tab)),
        menuItem("Einwohner", tabName = "einwohner", icon = icon("users"), selected = query$tab == "einwohner"),
        menuItem("Photovoltaik", tabName = "photovoltaik", icon = icon("solar-panel"), selected = query$tab == "photovoltaik"),
        menuItem("Schulen", icon = icon("school"), startExpanded = TRUE,
          menuSubItem("Humboldt-Gymnasium", tabName = "hgv", selected = query$tab == "hgv"),
          menuSubItem("Realschule Vaterstetten", tabName = "rsv", selected = query$tab == "rsv")
        ),
        menuItem("Straßennamen", tabName = "strassennamen", icon = icon("road"), selected = query$tab == "strassennamen"),
        menuItem("Wahlen", icon = icon("vote-yea"), startExpanded = TRUE,
          menuSubItem("Übersicht", tabName = "wahlenOverview", selected = query$tab == "wahlenOverview"),
          menuSubItem("Kommunalwahl 2020", tabName = "kommunalwahl2020", selected = query$tab == "kommunalwahl2020"),
          menuSubItem("Bundestagswahl 2021", tabName = "bundestagswahl2021", selected = query$tab == "bundestagswahl2021"),
          menuSubItem("Landtagswahl 2023", tabName = "landtagswahl2023", selected = query$tab == "landtagswahl2023"),
          menuSubItem("Europawahl 2024", tabName = "europawahl2024", selected = query$tab == "europawahl2024"),
          menuSubItem("Bundestagswahl 2025", tabName = "bundestagswahl2025", selected = query$tab == "bundestagswahl2025")
        ),
        menuItem("Archiv", icon = icon("box-archive"), startExpanded = TRUE,
          menuItem("Corona-Fallzahlen", tabName = "corona", icon = icon("virus"), selected = query$tab == "corona"),
          menuItem("Corona-Impfungen", tabName = "coronaImpfungen", icon = icon("syringe"), selected = query$tab == "coronaImpfungen")
        ),
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
        tabItem(tabName = "hgv", hgv$ui(request, "hgv")),
        tabItem(tabName = "rsv", rsv$ui(request, "rsv")),
        tabItem(tabName = "strassennamen", strassennamen$ui(request, "strassennamen")),

        tabItem(tabName = "wahlenOverview", wahlenOverview$ui(request, "wahlenOverview")),
        tabItem(tabName = "kommunalwahl2020", kommunalwahl2020$ui(request, "kommunalwahl2020")),
        tabItem(tabName = "bundestagswahl2021", bundestagswahl2021$ui(request, "bundestagswahl2021")),
        tabItem(tabName = "landtagswahl2023", landtagswahl2023$ui(request, "landtagswahl2023")),
        tabItem(tabName = "europawahl2024", europawahl2024$ui(request, "europawahl2024")),
        tabItem(tabName = "bundestagswahl2025", bundestagswahl2025$ui(request, "bundestagswahl2025")),

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
    query = parseQueryString(session$clientData$url_search)
    if (is.null(query$tab) || query$tab != session$input$tab) {
      updateQueryString(paste0("?tab=", session$input$tab), mode = "push")
    }
  })

  observe({
    updateTabsetPanel(session, "tab", input$tab)
  })

  observe({
    req(input$logo)
    updateTabsetPanel(session, "tab", selected = "main")
  })

  mainPage$server("mainPage", session)
  corona$server("corona")
  coronaImpfungen$server("coronaImpfungen")
  photovoltaik$server("photovoltaik")
  einwohner$server("einwohner")
  hgv$server("hgv")
  rsv$server("rsv")
  strassennamen$server("strassennamen")

  wahlenOverview$server("wahlenOverview")
  kommunalwahl2020$server("kommunalwahl2020")
  bundestagswahl2021$server("bundestagswahl2021")
  landtagswahl2023$server("landtagswahl2023")
  europawahl2024$server("europawahl2024")
  bundestagswahl2025$server("bundestagswahl2025")

  impressum$server("impressum")
}

shinyApp(ui, server, options = list(host = "0.0.0.0", port = 4373))
