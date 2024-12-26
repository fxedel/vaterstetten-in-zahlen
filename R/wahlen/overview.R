
kommunalwahl2020 <- loadModule("R/wahlen/kommunalwahl2020.R")
btw2021 <- loadModule("R/wahlen/btw2021.R")
landtagswahl2023 <- loadModule("R/wahlen/landtagswahl2023.R")
europawahl2024 <- loadModule("R/wahlen/europawahl2024.R")

ergebnisseAllgemeinNachStimmbezirk <- bind_rows(
  kommunalwahl2020$gemeinderatErgebnisAllgemein %>%
    transmute(
      Wahl = "Kommunalwahl 2020",
      Wahltyp = "Gemeinderatswahl",
      Wahltag = as.Date("2020-03-15"),
      Stimmbezirk = stimmbezirk,
      Wahlberechtigte = wahlberechtigte,
      Waehler = waehler,
      WaehlerWahllokal = NA, # TODO: Gesamtzahl
      WaehlerBriefwahl = NA, # TODO: Gesamtzahl
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
    Briefwahlquote = WaehlerBriefwahl/Waehler
  )

ergebnisseNachParteiNachStimmbezirk <- bind_rows(
  kommunalwahl2020$gemeinderatErgebnisNachPartei %>%
    transmute(
      Wahl = "Kommunalwahl 2020",
      Wahltyp = "Gemeinderatswahl",
      Wahltag = as.Date("2020-03-15"),
      Stimmbezirk = stimmbezirk,
      ParteiKuerzel = partei,
      GueltigeStimmen = gueltigeStimmen,
      Stimmen = stimmen,
      geometry = geometry
    ),
  btw2021$zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Bundestagswahl 2021",
      Wahltyp = "Bundestagswahl (Zweitstimmen)",
      Wahltag = as.Date("2021-09-26"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      GueltigeStimmen = GueltigeStimmen,
      Stimmen = Stimmen,
      geometry = geometry
    ),
  landtagswahl2023$zweitstimmenNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Landtagswahl 2023",
      Wahltyp = "Landtagswahl (Zweitstimmen)",
      Wahltag = as.Date("2023-10-08"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      GueltigeStimmen = GueltigeStimmen,
      Stimmen = Stimmen,
      geometry = geometry
    ),
  europawahl2024$ergebnisNachParteiNachStimmbezirkAggregiert %>%
    transmute(
      Wahl = "Europawahl 2024",
      Wahltyp = "Europawahl",
      Wahltag = as.Date("2024-06-09"),
      Stimmbezirk = StimmbezirkAggregiert,
      ParteiKuerzel = ParteiKuerzel,
      GueltigeStimmen = GueltigeStimmen,
      Stimmen = Stimmen,
      geometry = geometry
    ),
) %>%
  mutate(
    Wahl = as.factor(Wahl),
    Wahltyp = as.factor(Wahltyp),
    StimmenAnteil = Stimmen/GueltigeStimmen
  )

ui <- memoise(omit_args = "request", function(request, id) {
  request <- NULL # unused variable, so we set it to NULL to avoid unintended usage

  ns <- NS(id)
  tagList(
    h2("Wahlen in Vaterstetten"),

    fluidRow(
    ),
  ) %>% renderTags()
})
server <- function(id, parentSession) {
  moduleServer(
    id,
    function(input, output, session) {
    }
  )
}
