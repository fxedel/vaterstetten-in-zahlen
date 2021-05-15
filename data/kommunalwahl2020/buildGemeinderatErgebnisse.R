library(readr)
library(dplyr)
library(tidyr)

rawGesamt <- read_delim(
  file = "data/kommunalwahl2020/raw/Open-Data-Gemeinderatswahl-Bayern1163.csv",
  delim = ";",
  col_names = TRUE,
  col_types = cols(
    `gebiet-nr` = col_integer()
  )
) %>% mutate(stimmbezirk = "Gesamt")
rawNachStimmbezirk <- read_delim(
  file = "data/kommunalwahl2020/raw/Open-Data-Gemeinderatswahl-Bayern1166.csv",
  delim = ";",
  col_names = TRUE,
  col_types = cols(
    `gebiet-nr` = col_integer()
  )
) %>% mutate(stimmbezirk = `gebiet-name`)
rawCombined = bind_rows(rawGesamt, rawNachStimmbezirk)

parteien <- read_csv("data/kommunalwahl2020/parteien.csv")

ergebnisAllgemein <- rawCombined %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr = `gebiet-nr`,
    wahlberechtigte = A,
    waehler = B,
    ungueltigeStimmzettel = C,
    gueltigeStimmzettel = E - C,
    gueltigeStimmen = D,
    stimmzettelNurListenkreuz = Summe_unveraendert,
    stimmzettelNurEineListe = Summe_unveraendert + Summe_veraendert
  )
write_csv(
  ergebnisAllgemein,
  file = "data/kommunalwahl2020/gemeinderatErgebnisAllgemein.csv"
)

ergebnisNachPartei <- rawCombined %>%
  rename_with(~ paste(.x, "stimmen", sep = "_"), matches("^D\\d$")) %>%
  pivot_longer(
    matches("^D\\d_[a-z]+$"),
    names_prefix = "D",
    names_to = c("parteiNr", ".value"),
    names_sep = "_",
    names_transform = c(parteiNr = as.numeric)
  ) %>%
  left_join(parteien %>% select(parteiNr, partei), by = "parteiNr") %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr = `gebiet-nr`,
    partei,
    stimmen,
    stimmzettelNurListenkreuz = unveraendert,
    stimmzettelNurEineListe = unveraendert + veraendert
  )
write_csv(
  ergebnisNachPartei,
  file = "data/kommunalwahl2020/gemeinderatErgebnisNachPartei.csv"
)

ergebnisNachPerson <- rawCombined %>%
  pivot_longer(
    matches("^D\\d_\\d+$"),
    names_prefix = "D",
    names_to = c("parteiNr", "listenNr"),
    names_sep = "_",
    names_transform = c(parteiNr = as.numeric, listenNr = as.numeric),
    values_to = "stimmen"
  ) %>%
  left_join(parteien %>% select(parteiNr, partei), by = "parteiNr") %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr = `gebiet-nr`,
    partei,
    listenNr,
    stimmen
  )
write_csv(
  ergebnisNachPerson,
  file = "data/kommunalwahl2020/gemeinderatErgebnisNachPerson.csv"
)

