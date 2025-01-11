
kommunalwahl2020 <- loadModule("R/wahlen/kommunalwahl2020.R")
btw2021 <- loadModule("R/wahlen/btw2021.R")
landtagswahl2023 <- loadModule("R/wahlen/landtagswahl2023.R")
europawahl2024 <- loadModule("R/wahlen/europawahl2024.R")

ergebnisseAllgemeinNachStimmbezirk <- bind_rows(
  kommunalwahl2020$gemeinderatErgebnisAllgemein %>%
    mutate(
      WaehlerWahllokal = ifelse(stimmbezirkArt == "Wahllokal", waehler, 0),
      WaehlerBriefwahl = ifelse(stimmbezirkArt == "Briefwahl", waehler, 0)
    ) %>%
    transmute(
      Wahl = "Kommunalwahl 2020",
      Wahltyp = "Gemeinderatswahl",
      Wahltag = as.Date("2020-03-15"),
      Stimmbezirk = stimmbezirk,
      Wahlberechtigte = ifelse(Stimmbezirk == "Gesamt", wahlberechtigte, NA),
      Waehler = ifelse(Stimmbezirk == "Gesamt", waehler, NA),
      WaehlerWahllokal = ifelse(Stimmbezirk == "Gesamt", sum(WaehlerWahllokal, na.rm = TRUE), NA),
      WaehlerBriefwahl = ifelse(Stimmbezirk == "Gesamt", sum(WaehlerBriefwahl, na.rm = TRUE), NA),
      GueltigeStimmen = gueltigeStimmzettel,
      UngueltigeStimmen = ungueltigeStimmzettel,
      geometry = geometry
    ),
  btw2021$zweitstimmenAllgemeinNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Bundestagswahl 2021",
      Wahltyp = "Bundestagswahl (Zweitstimmen)",
      Wahltag = as.Date("2021-09-26"),
      Stimmbezirk = StimmbezirkAggregiert,
      Wahlberechtigte = Wahlberechtigte,
      Waehler = Waehler,
      WaehlerWahllokal = WaehlerWahllokal,
      WaehlerBriefwahl = WaehlerBriefwahl,
      GueltigeStimmen = GueltigeStimmen,
      UngueltigeStimmen = UngueltigeStimmen,
      geometry = geometry
    ),
  landtagswahl2023$zweitstimmenAllgemeinNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Landtagswahl 2023",
      Wahltyp = "Landtagswahl (Zweitstimmen)",
      Wahltag = as.Date("2023-10-08"),
      Stimmbezirk = StimmbezirkAggregiert,
      Wahlberechtigte = Wahlberechtigte,
      Waehler = Waehler,
      WaehlerWahllokal = WaehlerWahllokal,
      WaehlerBriefwahl = WaehlerBriefwahl,
      GueltigeStimmen = GueltigeStimmen,
      UngueltigeStimmen = UngueltigeStimmen,
      geometry = geometry
    ),
  europawahl2024$ergebnisAllgemeinNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Europawahl 2024",
      Wahltyp = "Europawahl",
      Wahltag = as.Date("2024-06-09"),
      Stimmbezirk = StimmbezirkAggregiert,
      Wahlberechtigte = Wahlberechtigte,
      Waehler = Waehler,
      WaehlerWahllokal = WaehlerWahllokal,
      WaehlerBriefwahl = WaehlerBriefwahl,
      GueltigeStimmen = GueltigeStimmen,
      UngueltigeStimmen = UngueltigeStimmen,
      geometry = geometry
    ),
) %>%
  mutate(
    Wahl = as.factor(Wahl),
    Wahltyp = as.factor(Wahltyp),
    Wahlbeteiligung = Waehler/Wahlberechtigte,
    Briefwahlquote = WaehlerBriefwahl/Waehler,
    UngueltigQuote = UngueltigeStimmen/Waehler,
  )

unifyParteiFarben <- function(data) {
  lastFarben <- data %>%
    group_by(ParteiKuerzel) %>%
    summarise(ParteiFarbeUnified = last(ParteiFarbe))

  data %>%
    left_join(lastFarben, by = join_by(ParteiKuerzel)) %>%
    mutate(
      ParteiFarbe = ParteiFarbeUnified,
      ParteiFarbeUnified = NULL
    )
}

ergebnisseNachParteiNachStimmbezirk <- bind_rows(
  kommunalwahl2020$gemeinderatErgebnisNachPartei %>%
    transmute(
      Wahl = "Kommunalwahl 2020",
      Wahltyp = "Gemeinderatswahl",
      Wahltag = as.Date("2020-03-15"),
      Stimmbezirk = stimmbezirk,
      ParteiKuerzel = partei,
      ParteiName = NA,
      ParteiFarbe = farbe,
      StimmenAnteil = stimmen/gueltigeStimmen,
      geometry = geometry
    ),
  btw2021$zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Bundestagswahl 2021",
      Wahltyp = "Bundestagswahl (Zweitstimmen)",
      Wahltag = as.Date("2021-09-26"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      ParteiName = ParteiName,
      ParteiFarbe = ParteiFarbe,
      StimmenAnteil = Stimmen/GueltigeStimmen,
      geometry = geometry
    ),
  landtagswahl2023$zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Landtagswahl 2023",
      Wahltyp = "Landtagswahl (Zweitstimmen)",
      Wahltag = as.Date("2023-10-08"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      ParteiName = ParteiName,
      ParteiFarbe = ParteiFarbe,
      StimmenAnteil = Stimmen/GueltigeStimmen,
      geometry = geometry
    ),
  europawahl2024$ergebnisNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Europawahl 2024",
      Wahltyp = "Europawahl",
      Wahltag = as.Date("2024-06-09"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      ParteiName = ParteiName,
      ParteiFarbe = ParteiFarbe,
      StimmenAnteil = Stimmen/GueltigeStimmen,
      geometry = geometry
    ),
) %>%
  unifyParteiFarben() %>%
  mutate(
    Wahl = as.factor(Wahl),
    Wahltyp = as.factor(Wahltyp)
  )


plotly_default_config <- function(p) {
  p %>%
    config(locale = "de") %>%
    config(displaylogo = FALSE) %>%
    config(displayModeBar = TRUE) %>%
    config(modeBarButtons = list(list("toImage", "hoverClosestCartesian", "hoverCompareCartesian"))) %>%
    config(toImageButtonOptions = list(scale = 2)) %>%
    layout(dragmode = FALSE) %>%
    identity()
}

plotly_hide_axis_titles <- function(p) {
  p %>%
    layout(xaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(yaxis = list(title = list(standoff = 0, font = list(size = 1)))) %>%
    layout(margin = list(l = 0, pad = 0, b = 30)) %>%
    identity()
}


ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Wahlen in Vaterstetten"),

    fluidRow(
      box(
        title = "Wahlergebnisse im zeitlichen Verlauf",
        width = 7,
        {
          data <- ergebnisseNachParteiNachStimmbezirk %>%
            filter(Stimmbezirk == "Gesamt") %>%
            group_by(ParteiKuerzel) %>%
            mutate(MaxStimmenAnteil = max(StimmenAnteil)) %>%
            filter(MaxStimmenAnteil >= 0.02)

          plot_ly(
            data,
            x = ~Wahltag,
            y = ~StimmenAnteil,
            name = ~ParteiKuerzel,
            color = ~I(ParteiFarbe),
            yhoverformat = ",.2%",
            meta = ~paste0(ParteiKuerzel, " (", Wahl, ")"),
            hovertemplate = "%{y}<extra><b style='color: rgb(68, 68, 68); font-weight: normal !important'>%{meta}</b></extra>"
          ) %>%
            add_trace(type = "scatter", mode = "lines+markers") %>%
            plotly_default_config() %>%
            layout(yaxis = list(tickformat = ".0%", rangemode = "tozero")) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        }
      ),
      box(
        title = "Wahlbeteiligung, Briefwahlquote und ungültige Stimmen im zeitlichen Verlauf",
        width = 5,
        {
          data <- ergebnisseAllgemeinNachStimmbezirk %>%
            filter(Stimmbezirk == "Gesamt")

          plot_ly(
            data,
            x = ~Wahltag,
            yhoverformat = ",.2%",
            meta = ~paste0("(", Wahl, ")"),
            hovertemplate = "%{y}<extra><b style='color: rgb(68, 68, 68); font-weight: normal !important'>%{text} %{meta}</b></extra>"
          ) %>%
            add_trace(y = ~Wahlbeteiligung, name = "Wahlbeteiligung", text = "Wahlbeteiligung", type = "scatter", mode = "lines+markers") %>%
            add_trace(y = ~Briefwahlquote, name = "Briefwahlquote", text = "Briefwahlquote", type = "scatter", mode = "lines+markers") %>%
            add_trace(y = ~UngueltigQuote, name = "Ungültige Stimmen", text = "Ungültige Stimmen", type = "scatter", mode = "lines+markers") %>%
            plotly_default_config() %>%
            layout(yaxis = list(tickformat = ".0%", rangemode = "tozero")) %>%
            layout(legend = list(x = 0.7, y = 0.2)) %>% # legend inside plot
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        }
      ),
    ),

    fluidRow(
      box(
        title = "Ergebnisse nach Partei in den Stimmbezirken",
        width = 12,
        fluidRow(
          column(
            width = 10,
            selectInput(
              ns("partei"),
              label = "Partei",
              choices = {
                data <- ergebnisseNachParteiNachStimmbezirk %>%
                  filter(Stimmbezirk != "Gesamt") %>%
                  filter(!is.na(ParteiName)) %>%
                  group_by(ParteiKuerzel, ParteiName) %>%
                  summarise(MaxStimmenAnteil = max(StimmenAnteil), .groups = "drop") %>%
                  arrange(-MaxStimmenAnteil) %>% mutate(
                    Label = paste0(ParteiKuerzel, " (", ParteiName, ")")
                  )

                choices = setNames(data$ParteiKuerzel, data$Label)
                choices
              },
            ),
          ),
          column(
            width = 2,
            input_switch(ns("switchParteistimmenIndividualScale"), "Individuelle Farbskala pro Wahl"),
          ),
        ),
        fluidRow(
          column(
            width = 4,
            h4("Kommunalwahl 2020 (Gemeinderat)"),
            leafletOutput(ns("mapParteistimmenKommunalwahl2020"), height = 550),
            p("Hinweis: Bei der Kommunalwahl können die Briefwahlstimmen keinen (geografischen) Stimmbezirken zugeordnet werden, daher stellt diese Karte nur etwa die Hälfte der Stimmen dar."),
          ),
          column(
            width = 4,
            h4("Bundestagswahl 2021 (Zweitstimme)"),
            leafletOutput(ns("mapParteistimmenBundestagswahl2021"), height = 550),
          ),
          column(
            width = 4,
            h4("Landtagswahl 2023 (Zweitstimme)"),
            leafletOutput(ns("mapParteistimmenLandtagswahl2023"), height = 550),
          ),
        ),
        fluidRow(
          column(
            width = 4,
            h4("Europawahl 2024"),
            leafletOutput(ns("mapParteistimmenEuropawahl2024"), height = 550),
          ),
        ),
      )
    ),

    fluidRow(
      box(
        title = "Wahlbeteiligung in den Stimmbezirken",
        width = 12,
        fluidRow(
          column(
            width = 2,
            input_switch(ns("switchWahlbeteiligungIndividualScale"), "Individuelle Farbskala pro Wahl"),
          ),
        ),
        fluidRow(
          column(
            width = 4,
            h4("Bundestagswahl 2021 (Zweitstimme)"),
            leafletOutput(ns("mapWahlbeteiligungBundestagswahl2021"), height = 550),
          ),
          column(
            width = 4,
            h4("Landtagswahl 2023 (Zweitstimme)"),
            leafletOutput(ns("mapWahlbeteiligungLandtagswahl2023"), height = 550),
          ),
          column(
            width = 4,
            h4("Europawahl 2024"),
            leafletOutput(ns("mapWahlbeteiligungEuropawahl2024"), height = 550),
          ),
        ),
      )
    ),

    fluidRow(
      box(
        title = "Briefwahlquote in den Stimmbezirken",
        width = 12,
        fluidRow(
          column(
            width = 2,
            input_switch(ns("switchBriefwahlquoteIndividualScale"), "Individuelle Farbskala pro Wahl"),
          ),
        ),
        fluidRow(
          column(
            width = 4,
            h4("Bundestagswahl 2021 (Zweitstimme)"),
            leafletOutput(ns("mapBriefwahlquoteBundestagswahl2021"), height = 550),
          ),
          column(
            width = 4,
            h4("Landtagswahl 2023 (Zweitstimme)"),
            leafletOutput(ns("mapBriefwahlquoteLandtagswahl2023"), height = 550),
          ),
          column(
            width = 4,
            h4("Europawahl 2024"),
            leafletOutput(ns("mapBriefwahlquoteEuropawahl2024"), height = 550),
          ),
        ),
      )
    ),
  ) %>% renderTags()
})


server <- function(id, parentSession) {
  moduleServer(
    id,
    function(input, output, session) {

      ## Parteistimmen

      renderParteistimmenMap <- function(wahl) {
        renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12),
          scrollWheelZoom = FALSE
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printParteistimmenMap(wahl) %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
        })
      }

      output$mapParteistimmenKommunalwahl2020 <- renderParteistimmenMap("Kommunalwahl 2020")
      output$mapParteistimmenBundestagswahl2021 <- renderParteistimmenMap("Bundestagswahl 2021")
      output$mapParteistimmenLandtagswahl2023 <- renderParteistimmenMap("Landtagswahl 2023")
      output$mapParteistimmenEuropawahl2024 <- renderParteistimmenMap("Europawahl 2024")

      observe({
        printParteistimmenMap(leafletProxy("mapParteistimmenKommunalwahl2020"), "Kommunalwahl 2020")
        printParteistimmenMap(leafletProxy("mapParteistimmenBundestagswahl2021"), "Bundestagswahl 2021")
        printParteistimmenMap(leafletProxy("mapParteistimmenLandtagswahl2023"), "Landtagswahl 2023")
        printParteistimmenMap(leafletProxy("mapParteistimmenEuropawahl2024"), "Europawahl 2024")
      })

      printParteistimmenMap <- function(leafletObject, wahl) {
        ergebnisAllElections <- ergebnisseNachParteiNachStimmbezirk %>%
          filter(ParteiKuerzel == input$partei)
        ergebnis <- ergebnisAllElections %>%
          filter(Wahl == wahl)

        if (nrow(ergebnis) == 0) {
          return(
            leafletObject %>%
              clearShapes() %>%
              clearControls() %>%
              identity()
          )
        }

        parteiFarbe <- (ergebnisseNachParteiNachStimmbezirk %>%
          filter(ParteiKuerzel == input$partei) %>%
          last()
        )$ParteiFarbe

        dataForScale <- if (input$switchParteistimmenIndividualScale) ergebnis else ergebnisAllElections
        pal <- colorNumeric(c("#ffffff", parteiFarbe), c(0, max(dataForScale$StimmenAnteil)))

        leafletObject %>%
          clearShapes() %>%
          clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnis),
            stroke = TRUE,
            weight = 0.0001, # stroke width
            color = "#000000", # stroke color
            opacity = 0.0001, # stroke opacity
            fillColor = ~pal(StimmenAnteil),
            fillOpacity = 0.6,
            layerId = ~Stimmbezirk,
            label = ~paste0(
              Stimmbezirk, ": ", scales::percent(StimmenAnteil, accuracy = 0.1)
            ) %>% lapply(HTML),
            highlight = highlightOptions(
              bringToFront = TRUE,
              sendToBack = TRUE,
              weight = 3, # stroke width
              opacity = 1.0, # stroke opacity
            )
          ) %>%
          addLegend("topright",
            data = dataForScale,
            pal = pal,
            values = ~StimmenAnteil,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
      }


      ## Wahlbeteiligung

      renderWahlbeteiligungMap <- function(wahl) {
        renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12),
          scrollWheelZoom = FALSE
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printWahlbeteiligungMap(wahl) %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
        })
      }

      output$mapWahlbeteiligungBundestagswahl2021 <- renderWahlbeteiligungMap("Bundestagswahl 2021")
      output$mapWahlbeteiligungLandtagswahl2023 <- renderWahlbeteiligungMap("Landtagswahl 2023")
      output$mapWahlbeteiligungEuropawahl2024 <- renderWahlbeteiligungMap("Europawahl 2024")

      observe({
        printWahlbeteiligungMap(leafletProxy("mapWahlbeteiligungBundestagswahl2021"), "Bundestagswahl 2021")
        printWahlbeteiligungMap(leafletProxy("mapWahlbeteiligungLandtagswahl2023"), "Landtagswahl 2023")
        printWahlbeteiligungMap(leafletProxy("mapWahlbeteiligungEuropawahl2024"), "Europawahl 2024")
      })

      printWahlbeteiligungMap <- function(leafletObject, wahl) {
        ergebnisAllElections <- ergebnisseAllgemeinNachStimmbezirk %>%
          filter(!is.na(Wahlbeteiligung))
        ergebnis <- ergebnisAllElections %>%
          filter(Wahl == wahl)

        dataForScale <- if (input$switchWahlbeteiligungIndividualScale) ergebnis else ergebnisAllElections
        pal <- colorNumeric(c("#bbbbbb", "#000000"), c(min(dataForScale$Wahlbeteiligung), max(dataForScale$Wahlbeteiligung)))

        leafletObject %>%
          clearShapes() %>%
          clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnis),
            stroke = TRUE,
            weight = 0.0001, # stroke width
            color = "#000000", # stroke color
            opacity = 0.0001, # stroke opacity
            fillColor = ~pal(Wahlbeteiligung),
            fillOpacity = 0.6,
            layerId = ~Stimmbezirk,
            label = ~paste0(
              Stimmbezirk, ": ", scales::percent(Wahlbeteiligung, accuracy = 0.1)
            ) %>% lapply(HTML),
            highlight = highlightOptions(
              bringToFront = TRUE,
              sendToBack = TRUE,
              weight = 3, # stroke width
              opacity = 1.0, # stroke opacity
            )
          ) %>%
          addLegend("topright",
            data = dataForScale,
            pal = pal,
            values = ~Wahlbeteiligung,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
      }


      ## Briefwahlquote

      renderBriefwahlquoteMap <- function(wahl) {
        renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12),
          scrollWheelZoom = FALSE
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printBriefwahlquoteMap(wahl) %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
        })
      }

      output$mapBriefwahlquoteBundestagswahl2021 <- renderBriefwahlquoteMap("Bundestagswahl 2021")
      output$mapBriefwahlquoteLandtagswahl2023 <- renderBriefwahlquoteMap("Landtagswahl 2023")
      output$mapBriefwahlquoteEuropawahl2024 <- renderBriefwahlquoteMap("Europawahl 2024")

      observe({
        printBriefwahlquoteMap(leafletProxy("mapBriefwahlquoteBundestagswahl2021"), "Bundestagswahl 2021")
        printBriefwahlquoteMap(leafletProxy("mapBriefwahlquoteLandtagswahl2023"), "Landtagswahl 2023")
        printBriefwahlquoteMap(leafletProxy("mapBriefwahlquoteEuropawahl2024"), "Europawahl 2024")
      })

      printBriefwahlquoteMap <- function(leafletObject, wahl) {
        ergebnisAllElections <- ergebnisseAllgemeinNachStimmbezirk %>%
          filter(!is.na(Briefwahlquote))
        ergebnis <- ergebnisAllElections %>%
          filter(Wahl == wahl)

        dataForScale <- if (input$switchBriefwahlquoteIndividualScale) ergebnis else ergebnisAllElections
        pal <- colorNumeric(c("#bbbbbb", "#000000"), c(min(dataForScale$Briefwahlquote), max(dataForScale$Briefwahlquote)))

        leafletObject %>%
          clearShapes() %>%
          clearControls() %>%
          addPolygons(
            data = st_as_sf(ergebnis),
            stroke = TRUE,
            weight = 0.0001, # stroke width
            color = "#000000", # stroke color
            opacity = 0.0001, # stroke opacity
            fillColor = ~pal(Briefwahlquote),
            fillOpacity = 0.6,
            layerId = ~Stimmbezirk,
            label = ~paste0(
              Stimmbezirk, ": ", scales::percent(Briefwahlquote, accuracy = 0.1)
            ) %>% lapply(HTML),
            highlight = highlightOptions(
              bringToFront = TRUE,
              sendToBack = TRUE,
              weight = 3, # stroke width
              opacity = 1.0, # stroke opacity
            )
          ) %>%
          addLegend("topright",
            data = dataForScale,
            pal = pal,
            values = ~Briefwahlquote,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x),
            opacity = 0.8,
            bins = 5
          )
      }
    }
  )
}
