
kommunalwahl2020 <- loadModule("R/wahlen/kommunalwahl2020.R")
btw2021 <- loadModule("R/wahlen/btw2021.R")
landtagswahl2023 <- loadModule("R/wahlen/landtagswahl2023.R")
europawahl2024 <- loadModule("R/wahlen/europawahl2024.R")

lfstatWahlergebnisseAllgemein <- read_csv(
  file = "data/wahlen/lfstatWahlergebnisseAllgemein.csv",
  col_types = cols(
    Wahl = readr::col_factor(),
    Wahltag = col_date(format = "%Y-%m-%d"),
    Stimmbezirk = readr::col_factor(),
    Wahlberechtigte = col_integer(),
    Waehler = col_integer(),
    Stimmentyp = readr::col_factor(),
    GueltigeStimmen = col_integer(),
    UngueltigeStimmen = col_integer()
  )
)

ergebnisseAllgemeinNachStimmbezirk <- bind_rows(
  lfstatWahlergebnisseAllgemein %>% transmute(
      Wahl = Wahl,
      Wahltag = Wahltag,
      Stimmbezirk = Stimmbezirk,
      Wahlberechtigte = Wahlberechtigte,
      Waehler = Waehler,
      WaehlerWahllokal = NA,
      WaehlerBriefwahl = NA,
      Stimmentyp = Stimmentyp,
      GueltigeStimmen = GueltigeStimmen,
      UngueltigeStimmen = UngueltigeStimmen,
      geometry = st_sfc(st_multipolygon(), crs = "WGS84")
  ),
  kommunalwahl2020$gemeinderatErgebnisAllgemein %>%
    mutate(
      WaehlerWahllokal = ifelse(stimmbezirkArt == "Wahllokal", waehler, 0),
      WaehlerBriefwahl = ifelse(stimmbezirkArt == "Briefwahl", waehler, 0)
    ) %>%
    transmute(
      Wahl = "Gemeinderatswahl",
      Wahltag = as.Date("2020-03-15"),
      Stimmbezirk = stimmbezirk,
      Wahlberechtigte = ifelse(Stimmbezirk == "Gesamt", wahlberechtigte, NA),
      Waehler = ifelse(Stimmbezirk == "Gesamt", waehler, NA),
      WaehlerWahllokal = ifelse(Stimmbezirk == "Gesamt", sum(WaehlerWahllokal, na.rm = TRUE), NA),
      WaehlerBriefwahl = ifelse(Stimmbezirk == "Gesamt", sum(WaehlerBriefwahl, na.rm = TRUE), NA),
      Stimmentyp = NA,
      GueltigeStimmen = gueltigeStimmzettel,
      UngueltigeStimmen = ungueltigeStimmzettel,
      geometry = geometry
    ),
  btw2021$zweitstimmenAllgemeinNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Bundestagswahl",
      Wahltag = as.Date("2021-09-26"),
      Stimmbezirk = StimmbezirkAggregiert,
      Wahlberechtigte = Wahlberechtigte,
      Waehler = Waehler,
      WaehlerWahllokal = WaehlerWahllokal,
      WaehlerBriefwahl = WaehlerBriefwahl,
      Stimmentyp = "Zweitstimme",
      GueltigeStimmen = GueltigeStimmen,
      UngueltigeStimmen = UngueltigeStimmen,
      geometry = geometry
    ),
  landtagswahl2023$zweitstimmenAllgemeinNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Landtagswahl",
      Wahltag = as.Date("2023-10-08"),
      Stimmbezirk = StimmbezirkAggregiert,
      Wahlberechtigte = Wahlberechtigte,
      Waehler = Waehler,
      WaehlerWahllokal = WaehlerWahllokal,
      WaehlerBriefwahl = WaehlerBriefwahl,
      Stimmentyp = "Zweitstimme",
      GueltigeStimmen = GueltigeStimmen,
      UngueltigeStimmen = UngueltigeStimmen,
      geometry = geometry
    ),
  europawahl2024$ergebnisAllgemeinNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Europawahl",
      Wahltag = as.Date("2024-06-09"),
      Stimmbezirk = StimmbezirkAggregiert,
      Wahlberechtigte = Wahlberechtigte,
      Waehler = Waehler,
      WaehlerWahllokal = WaehlerWahllokal,
      WaehlerBriefwahl = WaehlerBriefwahl,
      Stimmentyp = NA,
      GueltigeStimmen = GueltigeStimmen,
      UngueltigeStimmen = UngueltigeStimmen,
      geometry = geometry
    ),
) %>%
  mutate(
    Wahl = as.factor(Wahl),
    Wahlbeteiligung = Waehler/Wahlberechtigte,
    Briefwahlquote = WaehlerBriefwahl/Waehler,
    Stimmentyp = as.factor(Stimmentyp),
    UngueltigQuote = UngueltigeStimmen/Waehler,
  ) %>%
  arrange(Wahltag, is.na(WaehlerWahllokal)) %>% # values with WaehlerWahllokal = NA should be last, so they get eliminated by distinct
  distinct(Wahl, Wahltag, Stimmbezirk, Stimmentyp, .keep_all = TRUE) %>%
  identity()

lfstatWahlergebnisseNachPartei <- read_csv(
  file = "data/wahlen/lfstatWahlergebnisseNachPartei.csv",
  col_types = cols(
    Wahl = readr::col_factor(),
    Wahltag = col_date(format = "%Y-%m-%d"),
    Stimmbezirk = readr::col_factor(),
    ParteiCode = readr::col_character(),
    ParteiLabel = readr::col_factor(),
    Stimmentyp = readr::col_factor(),
    Stimmen = col_integer()
  )
) %>%
  left_join(
    tribble(
      ~ParteiCode, ~ParteiKuerzel, ~ParteiFarbe,
      "GRUENE", "Grüne", NA,
      "AFD", "AfD", NA,
      "FREIEWAEHLER", "FW", NA,
      "DIELINKE", "Die Linke", NA,
      "OEDP", "ÖDP", NA,
      "TIERSCHUTZ", "Tierschutzpartei", NA,
      "DIEPARTEI", "Die PARTEI", NA,
      "PIRATEN", "Piraten", NA,
      "V-PARTEI", "V-Partei³", NA,
      "GESUNDHEIT", "Gesundheitsforschung", NA,
      "DIEBASIS", "dieBasis", NA,
      "BUENDNISC", "Bündnis C", NA,
      "WEGIII", "III. Weg", NA,
      "DIEURBANE", "du.", NA,
      "DIEHUMANISTEN", "PdH", NA,
      "TEAMTODENHOEFER", "Team Todenhöfer", NA,
      "UNABHAENGIG", "UNABHÄNGIGE", NA,
      "VOLT", "Volt", NA,
      "FAMILIE", "Familie", NA,
      "TIERSCHUTZ1", "TIERSCHUTZ hier!", NA,
      "MENSCHLICHEWELT", "Menschliche Welt", NA,
      "BUENDNISD", "Bündnis Deutschland", NA,
      "KLIMALISTE", "Klimaliste", NA,
      "LETZTGENERATION", "Letzte Generation", NA,
      "PDF", "PdF", NA,
      "WAEHLERGRUPPEN", "Wählergruppen", NA,
      "GEMWAHLVOR", "Gemeinsame Wahlvorschläge", NA,
      "BHE-DG", "BHE-DG", "#C3C318",
      "GB-BHE", "GB-BHE", "#C3C318",
      "GDP", "GDP", "#C3C318",
      "KPD-ALT", "KPD", "#8B0000",
      "KPD-NEU", "KPD-AO", "#8B0000",
      "REP", "REP", "#0075BE",
      "WAV", "WAV", "#FFEC8B",
      "DFU", "DFU", "#8b1c62",
      "FBU", "FBU", "#8b4726",
      "AUD", "AUD", "#F5DC64",
      "BFB", "BFB", "#0000ff",
    ),
    by = join_by(ParteiCode)
  ) %>%
  mutate(
    ParteiKuerzel = coalesce(ParteiKuerzel, ParteiCode)
  ) %>%
  mutate(
    ParteiKuerzel = ifelse(ParteiCode == "GESUNDHEIT" & Wahltag > "2022-01-01", "Verjüngungsforschung", ParteiKuerzel)
  ) %>%
  mutate(
    ParteiKuerzel = ifelse(ParteiCode == "NPD" & Wahltag > "2023-06-01", "Heimat", ParteiKuerzel)
  ) %>%
  mutate(
    # TODO: Probably Wählergruppen before 2014 were also named "Freie Wähler", verify this!
    ParteiKuerzel = ifelse(ParteiCode == "WAEHLERGRUPPEN" & Wahl == "Gemeinderatswahl" & Wahltag >= "2014-01-01", "FW", ParteiKuerzel)
  ) %>%
  mutate(
    # 2014: FBU/AfD, changed their name before 2020 to just AfD
    ParteiKuerzel = ifelse(ParteiCode == "GEMWAHLVOR" & Wahl == "Gemeinderatswahl" & Wahltag == "2014-03-16", "AfD", ParteiKuerzel)
  ) %>%
  mutate(
    ParteiKuerzel = as.factor(ParteiKuerzel)
  )

ergebnisseNachParteiNachStimmbezirk <- bind_rows(
  lfstatWahlergebnisseNachPartei %>%
    left_join(lfstatWahlergebnisseAllgemein, by = join_by(Wahl, Wahltag, Stimmbezirk, Stimmentyp)) %>%
    transmute(
      Wahl,
      Wahltag,
      Stimmbezirk,
      ParteiKuerzel,
      ParteiName = NA,
      ParteiFarbe,
      Stimmentyp,
      GueltigeStimmen,
      Wahlberechtigte,
      Stimmen,
      StimmenAnteil = Stimmen/GueltigeStimmen,
      StimmenProWahlberechtigte = Stimmen/Wahlberechtigte,
      geometry = st_sfc(st_multipolygon(), crs = "WGS84")
    ),
  kommunalwahl2020$gemeinderatErgebnisNachPartei %>%
    transmute(
      Wahl = "Gemeinderatswahl",
      Wahltag = as.Date("2020-03-15"),
      Stimmbezirk = stimmbezirk,
      ParteiKuerzel = partei,
      ParteiName = NA,
      ParteiFarbe = farbe,
      Stimmentyp = NA,
      StimmenAnteil = stimmen/gueltigeStimmen,
      StimmenProWahlberechtigte = NA,
      geometry = geometry
    ),
  btw2021$zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Bundestagswahl",
      Wahltag = as.Date("2021-09-26"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      ParteiName = ParteiName,
      ParteiFarbe = ParteiFarbe,
      Stimmentyp = "Zweitstimme",
      StimmenAnteil = Stimmen/GueltigeStimmen,
      StimmenProWahlberechtigte = NA,
      geometry = geometry
    ),
  landtagswahl2023$zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Landtagswahl",
      Wahltag = as.Date("2023-10-08"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      ParteiName = ParteiName,
      ParteiFarbe = ParteiFarbe,
      Stimmentyp = "Zweitstimme",
      StimmenAnteil = Stimmen/GueltigeStimmen,
      StimmenProWahlberechtigte = NA,
      geometry = geometry
    ),
  europawahl2024$ergebnisNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Europawahl",
      Wahltag = as.Date("2024-06-09"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      ParteiName = ParteiName,
      ParteiFarbe = ParteiFarbe,
      Stimmentyp = NA,
      StimmenAnteil = Stimmen/GueltigeStimmen,
      StimmenProWahlberechtigte = NA,
      geometry = geometry
    ),
) %>%

  # merge some renamed parties
  left_join(
    tribble(
      ~ParteiKuerzelMerged, ~ParteiNameMerged, ~ParteiKuerzel, 

      "Heimat/NPD", "Die Heimat, ehemals Nationaldemokratische Partei Deutschlands", "Heimat",
      "Heimat/NPD", "Die Heimat, ehemals Nationaldemokratische Partei Deutschlands", "NPD",

      "Verjüngungsforschung/Gesundheitsforschung", "Partei für schulmedizinische Verjüngungsforschung, ehemals Partei für Gesundheitsforschung", "Verjüngungsforschung",
      "Verjüngungsforschung/Gesundheitsforschung", "Partei für schulmedizinische Verjüngungsforschung, ehemals Partei für Gesundheitsforschung", "Gesundheitsforschung",
    ),
    by = join_by(ParteiKuerzel)
  ) %>%
  mutate(
    ParteiKuerzel = coalesce(ParteiKuerzelMerged, ParteiKuerzel),
    ParteiName = coalesce(ParteiNameMerged, ParteiName),
  ) %>%

  # unify ParteiFarbe
  group_by(ParteiKuerzel) %>%
  fill(ParteiFarbe, .direction = "down") %>%
  mutate(
    ParteiFarbe = coalesce(last(ParteiFarbe), "#666666")
  ) %>%
  ungroup(ParteiKuerzel) %>%

  mutate(
    Wahl = as.factor(Wahl),
    Stimmentyp = as.factor(Stimmentyp)
  ) %>%
  arrange(Wahltag) %>%
  distinct(Wahl, Wahltag, Stimmbezirk, ParteiKuerzel, Stimmentyp, .keep_all = TRUE) %>%
  identity()


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
        width = 12,
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
            meta = ~paste0(ParteiKuerzel, " (", Wahl, " ", year(Wahltag), ")"),
            hovertemplate = "%{y}<extra><b style='color: rgb(68, 68, 68); font-weight: normal !important'>%{meta}</b></extra>"
          ) %>%
            add_trace(type = "scatter", mode = "lines+markers") %>%
            plotly_default_config() %>%
            layout(yaxis = list(tickformat = ".0%", rangemode = "tozero")) %>%
            layout(hovermode = "x", hoverdistance = 5) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        }
      ),
      box(
        title = "Wahlbeteiligung im zeitlichen Verlauf",
        width = 4,
        {
          data <- ergebnisseAllgemeinNachStimmbezirk %>%
            filter(Stimmbezirk == "Gesamt")

          plot_ly(
            data,
            height = 300,
            x = ~Wahltag,
            yhoverformat = ",.2%",
            meta = ~paste0(Wahl, " ", year(Wahltag)),
            hovertemplate = "%{y}<extra><b style='color: rgb(68, 68, 68); font-weight: normal !important'>%{meta}</b></extra>"
          ) %>%
            add_trace(y = ~Wahlbeteiligung, color = ~Wahl, type = "scatter", mode = "lines+markers") %>%
            plotly_default_config() %>%
            layout(yaxis = list(tickformat = ".0%", rangemode = "tozero")) %>%
            layout(legend = list(x = 1.0, y = 0.0, xanchor = "right")) %>% # legend inside plot
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        }
      ),
      box(
        title = "Briefwahlquote im zeitlichen Verlauf",
        width = 4,
        {
          data <- ergebnisseAllgemeinNachStimmbezirk %>%
            filter(Stimmbezirk == "Gesamt")

          plot_ly(
            data,
            height = 300,
            x = ~Wahltag,
            yhoverformat = ",.2%",
            meta = ~paste0(Wahl, " ", year(Wahltag)),
            hovertemplate = "%{y}<extra><b style='color: rgb(68, 68, 68); font-weight: normal !important'>%{meta}</b></extra>"
          ) %>%
            add_trace(y = ~Briefwahlquote, type = "scatter", mode = "lines+markers") %>%
            plotly_default_config() %>%
            layout(yaxis = list(tickformat = ".0%", rangemode = "tozero")) %>%
            plotly_hide_axis_titles() %>%
            plotly_build() %>%
            identity()
        }
      ),
      box(
        title = "Ungültige Stimmen im zeitlichen Verlauf",
        width = 4,
        {
          data <- ergebnisseAllgemeinNachStimmbezirk %>%
            filter(Stimmbezirk == "Gesamt")

          plot_ly(
            data,
            height = 300,
            x = ~Wahltag,
            yhoverformat = ",.2%",
            meta = ~paste0(Wahl, " ", year(Wahltag)),
            hovertemplate = "%{y}<extra><b style='color: rgb(68, 68, 68); font-weight: normal !important'>%{meta}</b></extra>"
          ) %>%
            add_trace(y = ~UngueltigQuote, color = ~Wahl, type = "scatter", mode = "lines+markers") %>%
            plotly_default_config() %>%
            layout(yaxis = list(tickformat = ".0%", rangemode = "tozero")) %>%
            layout(legend = list(x = 1.0, y = 1.0, xanchor = "right")) %>% # legend inside plot
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
                  filter(!st_is_empty(geometry)) %>%
                  group_by(ParteiKuerzel) %>%
                  fill(ParteiName, .direction = "downup") %>%
                  summarise(
                    MaxStimmenAnteil = max(StimmenAnteil),
                    ParteiName = last(ParteiName),
                    .groups = "drop",
                  ) %>%
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
            h4("Gemeinderatswahl 2020"),
            leafletOutput(ns("mapParteistimmenGemeinderatswahl2020"), height = 550),
            p("Hinweis: Bei den Kommunalwahlen können die Briefwahlstimmen keinen (geografischen) Stimmbezirken zugeordnet werden, daher stellt diese Karte nur etwa die Hälfte der Stimmen dar."),
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

    fluidRow(
      box(
        title = "Datengrundlage",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        tagList(
          p(HTML("Datengrundlage für alle Wahlen seit 2020 ist die Gemeinde Vaterstetten selbst; für Details siehe die jeweiligen Unterseiten.")),
          p(HTML('Datenquelle für alle Wahlen vor 2020: Bayerisches Landesamt für Statistik – <a href="https://www.statistik.bayern.de">www.statistik.bayern.de</a>.')),
          p(tags$a(class = "btn btn-default", href = "https://github.com/fxedel/vaterstetten-in-zahlen/tree/master/data/wahlen", "Zum Daten-Download mit Dokumentation")),
        ),
      ),
    ),

  ) %>% renderTags()
})


server <- function(id, parentSession) {
  moduleServer(
    id,
    function(input, output, session) {

      ## Parteistimmen

      renderParteistimmenMap <- function(wahl, wahljahr) {
        renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12),
          scrollWheelZoom = FALSE
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printParteistimmenMap(wahl, wahljahr) %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
        })
      }

      output$mapParteistimmenGemeinderatswahl2020 <- renderParteistimmenMap("Gemeinderatswahl", 2020)
      output$mapParteistimmenBundestagswahl2021 <- renderParteistimmenMap("Bundestagswahl", 2021)
      output$mapParteistimmenLandtagswahl2023 <- renderParteistimmenMap("Landtagswahl", 2023)
      output$mapParteistimmenEuropawahl2024 <- renderParteistimmenMap("Europawahl", 2024)

      observe({
        printParteistimmenMap(leafletProxy("mapParteistimmenGemeinderatswahl2020"), "Gemeinderatswahl", 2020)
        printParteistimmenMap(leafletProxy("mapParteistimmenBundestagswahl2021"), "Bundestagswahl", 2021)
        printParteistimmenMap(leafletProxy("mapParteistimmenLandtagswahl2023"), "Landtagswahl", 2023)
        printParteistimmenMap(leafletProxy("mapParteistimmenEuropawahl2024"), "Europawahl", 2024)
      })

      printParteistimmenMap <- function(leafletObject, wahl, wahljahr) {
        ergebnisAllElections <- ergebnisseNachParteiNachStimmbezirk %>%
          filter(!st_is_empty(geometry)) %>%
          filter(ParteiKuerzel == input$partei)
        ergebnis <- ergebnisAllElections %>%
          filter(Wahl == wahl) %>%
          filter(year(Wahltag) == wahljahr)

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
        palForLegend <- colorNumeric(c("#ffffff", parteiFarbe), c(0, max(dataForScale$StimmenAnteil)) * -1, reverse = TRUE)

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
            pal = palForLegend,
            values = ~StimmenAnteil * -1,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }


      ## Wahlbeteiligung

      renderWahlbeteiligungMap <- function(wahl, wahljahr) {
        renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12),
          scrollWheelZoom = FALSE
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printWahlbeteiligungMap(wahl, wahljahr) %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
        })
      }

      output$mapWahlbeteiligungBundestagswahl2021 <- renderWahlbeteiligungMap("Bundestagswahl", 2021)
      output$mapWahlbeteiligungLandtagswahl2023 <- renderWahlbeteiligungMap("Landtagswahl", 2023)
      output$mapWahlbeteiligungEuropawahl2024 <- renderWahlbeteiligungMap("Europawahl", 2024)

      observe({
        printWahlbeteiligungMap(leafletProxy("mapWahlbeteiligungBundestagswahl2021"), "Bundestagswahl", 2021)
        printWahlbeteiligungMap(leafletProxy("mapWahlbeteiligungLandtagswahl2023"), "Landtagswahl", 2023)
        printWahlbeteiligungMap(leafletProxy("mapWahlbeteiligungEuropawahl2024"), "Europawahl", 2024)
      })

      printWahlbeteiligungMap <- function(leafletObject, wahl, wahljahr) {
        ergebnisAllElections <- ergebnisseAllgemeinNachStimmbezirk %>%
          filter(!st_is_empty(geometry)) %>%
          filter(!is.na(Wahlbeteiligung))
        ergebnis <- ergebnisAllElections %>%
          filter(Wahl == wahl) %>%
          filter(year(Wahltag) == wahljahr)

        dataForScale <- if (input$switchWahlbeteiligungIndividualScale) ergebnis else ergebnisAllElections
        pal <- colorNumeric(c("#bbbbbb", "#000000"), c(min(dataForScale$Wahlbeteiligung), max(dataForScale$Wahlbeteiligung)))
        palForLegend <- colorNumeric(c("#bbbbbb", "#000000"), c(min(dataForScale$Wahlbeteiligung), max(dataForScale$Wahlbeteiligung)) * -1, reverse = TRUE)

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
            pal = palForLegend,
            values = ~Wahlbeteiligung * -1,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }


      ## Briefwahlquote

      renderBriefwahlquoteMap <- function(wahl, wahljahr) {
        renderLeaflet({
        leaflet(options = leafletOptions(
          zoom = 13,
          center = list(lng = 11.798, lat = 48.12),
          scrollWheelZoom = FALSE
        )) %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          printBriefwahlquoteMap(wahl, wahljahr) %>%
          isolate() # updates will be done by leafletProxy, no need to re-render whole map
        })
      }

      output$mapBriefwahlquoteBundestagswahl2021 <- renderBriefwahlquoteMap("Bundestagswahl", 2021)
      output$mapBriefwahlquoteLandtagswahl2023 <- renderBriefwahlquoteMap("Landtagswahl", 2023)
      output$mapBriefwahlquoteEuropawahl2024 <- renderBriefwahlquoteMap("Europawahl", 2024)

      observe({
        printBriefwahlquoteMap(leafletProxy("mapBriefwahlquoteBundestagswahl2021"), "Bundestagswahl", 2021)
        printBriefwahlquoteMap(leafletProxy("mapBriefwahlquoteLandtagswahl2023"), "Landtagswahl", 2023)
        printBriefwahlquoteMap(leafletProxy("mapBriefwahlquoteEuropawahl2024"), "Europawahl", 2024)
      })

      printBriefwahlquoteMap <- function(leafletObject, wahl, wahljahr) {
        ergebnisAllElections <- ergebnisseAllgemeinNachStimmbezirk %>%
          filter(!st_is_empty(geometry)) %>%
          filter(!is.na(Briefwahlquote))
        ergebnis <- ergebnisAllElections %>%
          filter(Wahl == wahl) %>%
          filter(year(Wahltag) == wahljahr)

        dataForScale <- if (input$switchBriefwahlquoteIndividualScale) ergebnis else ergebnisAllElections
        pal <- colorNumeric(c("#bbbbbb", "#000000"), c(min(dataForScale$Briefwahlquote), max(dataForScale$Briefwahlquote)))
        palForLegend <- colorNumeric(c("#bbbbbb", "#000000"), c(min(dataForScale$Briefwahlquote), max(dataForScale$Briefwahlquote)) * -1, reverse = TRUE)

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
            pal = palForLegend,
            values = ~Briefwahlquote * -1,
            title = NULL,
            labFormat = labelFormat(suffix = " %", transform = function(x) 100 * x * -1),
            opacity = 0.8,
            bins = 5
          )
      }
    }
  )
}
