library(readr)
library(dplyr)
library(tidyr)
library(stringr)

raw <- read_delim(
  file = "data/wahlen/kommunalwahl2026/raw/gemeinderatGesamtergebnis.csv",
  delim = ";",
  col_names = TRUE,
  show_col_types = FALSE
)

parteien <- read_csv(
  file = "data/wahlen/kommunalwahl2026/parteien.csv",
  show_col_types = FALSE
)

rawCombined <- raw %>%
  mutate(
    stimmbezirk = case_when(
      Gebietsart == "GEMEINDE" ~ "Gesamt",
      !is.na(Bezirksnummer) & Bezirksnummer != "" ~ paste0("Stimmbezirk ", str_pad(as.integer(Bezirksnummer), 2, pad = "0")),
      TRUE ~ Gebietsname
    ),
    stimmbezirkNr = if_else(Bezirksnummer == "", NA, as.integer(Bezirksnummer)),
    stimmbezirkArt = case_match(
      Gebietsart,
      "STIMMBEZIRK" ~ "Wahllokal",
      "BRIEFWAHLBEZIRK" ~ "Briefwahl",
      .default = NA_character_
    )
  )

partyCols <- rawCombined %>%
  names() %>%
  str_subset("^D\\d+$")

parteiNrLevels <- partyCols %>%
  str_remove("^D") %>%
  as.integer() %>%
  sort()

ergebnisAllgemein <- rawCombined %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr,
    stimmbezirkArt,
    wahlberechtigte = `Wahlberechtigte gesamt (A)`,
    waehler = `Waehler gesamt (B)`,
    ungueltigeStimmzettel = `Stimmen ungueltige (C)`,
    gueltigeStimmzettel = `Waehler gesamt (B)` - `Stimmen ungueltige (C)`,
    gueltigeStimmen = `Stimmen gueltige (D)`,
    stimmzettelNurListenkreuz = rowSums(across(matches("^D\\d+_unveraendert$")), na.rm = TRUE),
    stimmzettelNurEineListe = rowSums(across(matches("^D\\d+_(unveraendert|veraendert)$")), na.rm = TRUE)
  )

write_csv(
  ergebnisAllgemein,
  file = "data/wahlen/kommunalwahl2026/gemeinderatErgebnisAllgemein.csv"
)

ergebnisNachPartei <- rawCombined %>%
  rename_with(~ paste0(.x, "_stimmen"), matches("^D\\d+$")) %>%
  pivot_longer(
    cols = matches("^D\\d+_(unveraendert|veraendert|stimmen)$"),
    names_prefix = "D",
    names_to = c("parteiNr", ".value"),
    names_sep = "_",
    names_transform = list(parteiNr = as.integer)
  ) %>%
  filter(parteiNr %in% parteiNrLevels) %>%
  left_join(parteien %>% select(parteiNr, partei), by = "parteiNr") %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr,
    partei,
    stimmen,
    stimmzettelNurListenkreuz = unveraendert,
    stimmzettelNurEineListe = unveraendert + veraendert
  )

write_csv(
  ergebnisNachPartei,
  file = "data/wahlen/kommunalwahl2026/gemeinderatErgebnisNachPartei.csv"
)

ergebnisNachPerson <- rawCombined %>%
  pivot_longer(
    cols = matches("^D\\d+_\\d+$"),
    names_prefix = "D",
    names_to = c("parteiNr", "listenNr"),
    names_sep = "_",
    names_transform = list(parteiNr = as.integer, listenNr = as.integer),
    values_to = "stimmen"
  ) %>%
  filter(parteiNr %in% parteiNrLevels) %>%
  left_join(parteien %>% select(parteiNr, partei), by = "parteiNr") %>%
  group_by(stimmbezirk, partei) %>%
  mutate(erreichterPlatz = row_number(desc(stimmen))) %>%
  ungroup() %>%
  transmute(
    stimmbezirk,
    stimmbezirkNr,
    partei,
    listenNr,
    stimmen,
    erreichterPlatz
  )

write_csv(
  ergebnisNachPerson,
  file = "data/wahlen/kommunalwahl2026/gemeinderatErgebnisNachPerson.csv"
)
