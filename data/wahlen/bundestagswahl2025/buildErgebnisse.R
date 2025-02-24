# This script needs to be executed from the project's root directy:
# $ Rscript data/wahlen/bundestagswahl2025/buildErgebnisse.R
# since it requires renv to be loaded

library(readr)
library(dplyr)
library(tidyr)

raw <- read_delim(
  file = "data/wahlen/bundestagswahl2025/raw/wahlbezirksergebnisse.csv",
  delim = ";",
  col_names = TRUE
) %>%
  filter(Gemeindename == "Vaterstetten") %>%
  mutate(
    Stimmbezirk = case_match(Gebietsname,
      "Vaterstetten" ~ "Gesamt",
      .default = Gebietsname
    ),
    Wahlberechtigte = `Wahlberechtigte gesamt (A)`,
    Waehler = `Waehler gesamt (B)`
  )

parteien <- read_csv("data/wahlen/bundestagswahl2025/parteien.csv")


## Erststimmen

ergebnisAllgemein <- raw %>%
  transmute(
    Stimmbezirk,
    Wahlberechtigte,
    Waehler,
    UngueltigeStimmen = `Direktstimmen ungueltige (C)`,
    GueltigeStimmen = `Direktstimmen gueltige (D)`
  )
write_csv(
  ergebnisAllgemein,
  file = "data/wahlen/bundestagswahl2025/erststimmenAllgemein.csv"
)

ergebnisNachPartei <- raw %>%
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
    ParteiKuerzel,
    Stimmen
  )
write_csv(
  ergebnisNachPartei,
  file = "data/wahlen/bundestagswahl2025/erststimmenNachPartei.csv"
)


## Zweitstimmen

ergebnisAllgemein <- raw %>%
  transmute(
    Stimmbezirk,
    Wahlberechtigte,
    Waehler,
    UngueltigeStimmen = `Listenstimmen ungueltige (E)`,
    GueltigeStimmen = `Listenstimmen gueltige (F)`
  )
write_csv(
  ergebnisAllgemein,
  file = "data/wahlen/bundestagswahl2025/zweitstimmenAllgemein.csv"
)

ergebnisNachPartei <- raw %>%
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
    ParteiKuerzel,
    Stimmen
  )
write_csv(
  ergebnisNachPartei,
  file = "data/wahlen/bundestagswahl2025/zweitstimmenNachPartei.csv"
)
