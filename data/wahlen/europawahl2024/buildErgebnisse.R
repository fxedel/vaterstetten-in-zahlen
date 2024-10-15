# This script needs to be executed from the project's root directy:
# $ Rscript data/wahlen/europawahl2024/buildErgebnisse.R
# since it requires renv to be loaded

library(readr)
library(dplyr)
library(tidyr)

raw <- read_delim(
  file = "data/wahlen/europawahl2024/raw/stimmen.csv",
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

parteien <- read_csv("data/wahlen/europawahl2024/parteien.csv")

ergebnisAllgemein <- raw %>%
  transmute(
    Stimmbezirk,
    Wahlberechtigte,
    Waehler,
    UngueltigeStimmen = `Stimmen ungueltige (C)`,
    GueltigeStimmen = `Stimmen gueltige (D)`
  )
write_csv(
  ergebnisAllgemein,
  file = "data/wahlen/europawahl2024/ergebnisAllgemein.csv"
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
  file = "data/wahlen/europawahl2024/ergebnisNachPartei.csv"
)
