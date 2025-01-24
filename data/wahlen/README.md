# Wahlergebnisse der Gemeinde Vaterstetten

Für einzelne Wahlen siehe Unterordner.


## [`lfstatWahlergebnisseAllgemein.csv`](./lfstatWahlergebnisseAllgemein.csv)

Der Datensatz [lfstatWahlergebnisseAllgemein.csv](./lfstatWahlergebnisseAllgemein.csv) umfasst allgemeine Ergebnisse zu Wahlen in der Gemeinde Vaterstetten seit 1946. Die Stimmenanzahlen beziehen sich immer auf den angegebenen Stimmentyp (z.&nbsp;B. Zweitstimme). Bei Wahlen mit mehr als einer Stimme pro Stimmentyp (z.&nbsp;B. Gemeinderatswahl mit bis zu 30 Stimmen) beziehen sich die Stimmenanzahlen auf die Anzahl der Stimmzettel.

|Spalte|Format|Beschreibung
|-|-|-
|`Wahl`|text|Art der Wahl (`Bundestagswahl`, `Europawahl`, `Landtagswahl` oder `Gemeinderatswahl`)
|`Wahltag`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag der Wahl
|`Stimmbezirk`|text|Stimmbezirk, auf den sich das Ergebnis bezieht, oder `Gesamt`
|`Wahlberechtigte`|integer|Anzahl wahlberechtigter Personen
|`Waehler`|integer|Anzahl Wähler:innen, d.&nbsp;h. abgegebene Stimmzettel (inklusive ungültige Stimmen)
|`Stimmentyp`|text|Art der Stimme, bei Wahlen mit Erst- und Zweitstimme (`Erststimme`, `Zweitstimme` oder leer)
|`GueltigeStimmen`|integer|Gültige Stimmen bzw. Stimmzettel
|`UngueltigeStimmen`|integer|Ungültige Stimmen bzw. Stimmzettel

- `Waehler` ≤ `Wahlberechtigte`
- `Waehler` = `UngueltigeStimmen` + `GueltigeStimmen`


### Quellen

- [Bayerisches Landesamt für Statistik](../quellen/LfStat.md):
  - Bundestagswahlen: Tabellen 14111-001z, 14111-002z
  - Europawahlen: Tabellen 14211-001z, 14211-002z
  - Landtagswahlen: Tabellen 14311-001z, 14311-002z
  - Gemeinderatswahlen: Tabellen 14431-001z, 14431-002z



## [`lfstatWahlergebnisseNachPartei.csv`](./lfstatWahlergebnisseNachPartei.csv)

Der Datensatz [lfstatWahlergebnisseNachPartei.csv](./lfstatWahlergebnisseNachPartei.csv) umfasst die Ergebnisse der einzelnen Parteien zu Wahlen in der Gemeinde Vaterstetten seit 1946. Die Stimmenanzahlen beziehen sich immer auf den angegebenen Stimmentyp (z.&nbsp;B. Zweitstimme). Bei Wahlen mit mehr als einer Stimme pro Stimmentyp (z.&nbsp;B. Gemeinderatswahl mit bis zu 30 Stimmen) handelt es sich um so genannte „gewichtete Stimmen“, d.&nbsp;h., die Summe der gewichteten Stimmen über alle Parteien ergibt die Anzahl der gültigen Stimmzettel, die in [lfstatWahlergebnisseAllgemein.csv](./lfstatWahlergebnisseAllgemein.csv) als `GueltigeStimmen` erfasst wird.

|Spalte|Format|Beschreibung
|-|-|-
|`Wahl`|text|Art der Wahl (`Bundestagswahl`, `Europawahl`, `Landtagswahl` oder `Gemeinderatswahl`)
|`Wahltag`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag der Wahl
|`Stimmbezirk`|text|Stimmbezirk, auf den sich das Ergebnis bezieht, oder `Gesamt`
|`ParteiCode`|text|Eindeutiger Bezeichner für die Partei; nur Großbuchstaben und Bindestrich, maximal 15 Zeichen.
|`ParteiLabel`|text|Vollständiger Name der Partei mit Parteikürzel als Klammerzusatz und optional weiteren Erläuterungen als Klammerzusatz
|`Stimmentyp`|text|Art der Stimme, bei Wahlen mit Erst- und Zweitstimme (`Erststimme`, `Zweitstimme` oder leer)
|`Stimmen`|integer|Gültige (ggf. gewichtete) Stimmen für diese Partei


### Quellen

- [Bayerisches Landesamt für Statistik](../quellen/LfStat.md):
  - Bundestagswahlen: Tabelle 14111-003z
  - Europawahlen: Tabelle 14211-003z
  - Landtagswahlen: Tabelle 14311-003z
  - Gemeinderatswahlen: Tabelle 14431-003z
