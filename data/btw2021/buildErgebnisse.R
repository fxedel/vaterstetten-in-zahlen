# This script needs to be executed from the project's root directy:
# $ Rscript data/btw2021/buildErgebnisse.R
# since it requires renv to be loaded

library(readr)
library(dplyr)
library(tidyr)

stimmbezirke <- read_delim(
  file = "data/btw2021/raw/opendata-wahllokale.csv",
  delim = ";",
  col_names = TRUE,
  col_types = cols(
    `Bezirk-Nr` = col_integer()
  )
) %>% mutate(
  stimmbezirkArt = case_match(`Bezirk-Art`,
    "W" ~ "Wahllokal",
    "B" ~ "Briefwahl"
  )
)

rawGesamt <- read_delim(
  file = "data/btw2021/raw/Open-Data-Bundestagswahl1573.csv",
  delim = ";",
  col_names = TRUE,
  col_types = cols(
    `gebiet-nr` = col_integer()
  )
) %>% mutate(stimmbezirk = "Gesamt")
rawNachStimmbezirk <- read_delim(
  file = "data/btw2021/raw/Open-Data-Bundestagswahl1576.csv",
  delim = ";",
  col_names = TRUE,
  col_types = cols(
    `gebiet-nr` = col_integer()
  )
) %>% mutate(stimmbezirk = `gebiet-name`)
  
rawCombined = bind_rows(rawGesamt, rawNachStimmbezirk) %>%
  left_join(
    stimmbezirke %>% select(`Bezirk-Nr`, stimmbezirkArt),
    by = join_by(`gebiet-nr` == `Bezirk-Nr`)
  )

parteien <- read_csv("data/btw2021/parteien.csv")


## Erststimmen

ergebnisAllgemein <- rawCombined %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr = `gebiet-nr`,
    stimmbezirkArt,
    wahlberechtigte = A,
    waehler = B,
    ungueltigeStimmen = C,
    gueltigeStimmen = D
  )
write_csv(
  ergebnisAllgemein,
  file = "data/btw2021/erststimmenAllgemein.csv"
)

ergebnisNachPartei <- rawCombined %>%
  rename_with(~ paste(.x, "stimmen", sep = "_"), matches("^D\\d+$")) %>%
  pivot_longer(
    matches("^D\\d+_[a-z]+$"),
    names_prefix = "D",
    names_to = c("parteiNr", ".value"),
    names_sep = "_",
    names_transform = c(parteiNr = as.numeric)
  ) %>%
  left_join(parteien %>% select(Nr, Kuerzel), by = join_by(parteiNr == Nr)) %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr = `gebiet-nr`,
    partei = Kuerzel,
    stimmen
  )
write_csv(
  ergebnisNachPartei,
  file = "data/btw2021/erststimmenNachPartei.csv"
)


## Zweitstimmen

ergebnisAllgemein <- rawCombined %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr = `gebiet-nr`,
    stimmbezirkArt,
    wahlberechtigte = A,
    waehler = B,
    ungueltigeStimmen = E,
    gueltigeStimmen = F
  )
write_csv(
  ergebnisAllgemein,
  file = "data/btw2021/zweitstimmenAllgemein.csv"
)

ergebnisNachPartei <- rawCombined %>%
  rename_with(~ paste(.x, "stimmen", sep = "_"), matches("^F\\d+$")) %>%
  pivot_longer(
    matches("^F\\d+_[a-z]+$"),
    names_prefix = "F",
    names_to = c("parteiNr", ".value"),
    names_sep = "_",
    names_transform = c(parteiNr = as.numeric)
  ) %>%
  left_join(parteien %>% select(Nr, Kuerzel), by = join_by(parteiNr == Nr)) %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr = `gebiet-nr`,
    partei = Kuerzel,
    stimmen
  )
write_csv(
  ergebnisNachPartei,
  file = "data/btw2021/zweitstimmenNachPartei.csv"
)
