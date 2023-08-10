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
  StimmbezirkArt = case_match(`Bezirk-Art`,
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
) %>% mutate(Stimmbezirk = "Gesamt")
rawNachStimmbezirk <- read_delim(
  file = "data/btw2021/raw/Open-Data-Bundestagswahl1576.csv",
  delim = ";",
  col_names = TRUE,
  col_types = cols(
    `gebiet-nr` = col_integer()
  )
) %>% mutate(Stimmbezirk = `gebiet-name`)
  
rawCombined = bind_rows(rawGesamt, rawNachStimmbezirk) %>%
  left_join(
    stimmbezirke %>% select(`Bezirk-Nr`, StimmbezirkArt),
    by = join_by(`gebiet-nr` == `Bezirk-Nr`)
  )

parteien <- read_csv("data/btw2021/parteien.csv")


## Erststimmen

ergebnisAllgemein <- rawCombined %>%
  transmute(
    Stimmbezirk,
    StimmbezirkNr = `gebiet-nr`,
    StimmbezirkArt,
    Wahlberechtigte = A,
    Waehler = B,
    UngueltigeStimmen = C,
    GueltigeStimmen = D
  )
write_csv(
  ergebnisAllgemein,
  file = "data/btw2021/erststimmenAllgemein.csv"
)

ergebnisNachPartei <- rawCombined %>%
  rename_with(~ paste(.x, "Stimmen", sep = "_"), matches("^D\\d+$")) %>%
  pivot_longer(
    matches("^D\\d+_[a-z]+$"),
    names_prefix = "D",
    names_to = c("ParteiNr", ".value"),
    names_sep = "_",
    names_transform = c(ParteiNr = as.numeric)
  ) %>%
  left_join(parteien, by = "ParteiNr") %>%
  transmute(
    Stimmbezirk,
    StimmbezirkNr = `gebiet-nr`,
    ParteiKuerzel,
    Stimmen
  )
write_csv(
  ergebnisNachPartei,
  file = "data/btw2021/erststimmenNachPartei.csv"
)


## Zweitstimmen

ergebnisAllgemein <- rawCombined %>%
  transmute(
    Stimmbezirk,
    StimmbezirkNr = `gebiet-nr`,
    StimmbezirkArt,
    Wahlberechtigte = A,
    Waehler = B,
    UngueltigeStimmen = E,
    GueltigeStimmen = F
  )
write_csv(
  ergebnisAllgemein,
  file = "data/btw2021/zweitstimmenAllgemein.csv"
)

ergebnisNachPartei <- rawCombined %>%
  rename_with(~ paste(.x, "Stimmen", sep = "_"), matches("^F\\d+$")) %>%
  pivot_longer(
    matches("^F\\d+_[a-z]+$"),
    names_prefix = "F",
    names_to = c("ParteiNr", ".value"),
    names_sep = "_",
    names_transform = c(ParteiNr = as.numeric)
  ) %>%
  left_join(parteien, by = "ParteiNr") %>%
  transmute(
    Stimmbezirk,
    StimmbezirkNr = `gebiet-nr`,
    ParteiKuerzel,
    Stimmen
  )
write_csv(
  ergebnisNachPartei,
  file = "data/btw2021/zweitstimmenNachPartei.csv"
)