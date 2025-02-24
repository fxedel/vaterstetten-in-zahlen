# Bundestagswahl 23. Februar 2025 in der Gemeinde Vaterstetten

## [`erststimmenAllgemein.csv`](./erststimmenAllgemein.csv) / [`zweitstimmenAllgemein.csv`](./zweitstimmenAllgemein.csv)

Die Datensätze [erststimmenAllgemein.csv](./erststimmenAllgemein.csv) und [zweitstimmenAllgemein.csv](./zweitstimmenAllgemein.csv) umfassen allgemeine Ergebnisse der Erststimmen bzw. Zweitstimmen der Bundestagswahl, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildErgebnisse.R](./buildErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`Stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 1` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`Wahlberechtigte`|integer|Anzahl der Wahlberechtigten (für Briefwahlstimmbezirke immer `0`)
|`Waehler`|integer|Anzahl der Wähler<sup>[1]<sup>
|`UngueltigeStimmen`|integer|Anzahl ungültiger Stimmen
|`GueltigeStimmen`|integer|Anzahl gültiger Stimmen

* `Waehler` ≤ `Wahlberechtigte`, falls es kein Briefwahlstimmbezirk ist
* `Waehler` = `UngueltigeStimmen` + `GueltigeStimmen`

<sup>[1]</sup> Briefwähler werden nicht in ihrem eigentlichen (Wahllokal-)Stimmbezirk als Wähler gezählt, sondern im zugehörigen Briefwahlstimmbezirk.

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2025 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/ergebnisse_gemeinde_09175132.html):
  * [`wahlbezirksergebnisse.csv`](raw/wahlbezirksergebnisse.csv) ([Weblink](https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/wahlbezirksergebnisse.csv))


## [`erststimmenNachPartei.csv`](./erststimmenNachPartei.csv) / [`zweitstimmenNachPartei.csv`](./zweitstimmenNachPartei.csv)

Die Datensätze [erststimmenNachPartei.csv](./erststimmenNachPartei.csv) und [zweitstimmenNachPartei.csv](./zweitstimmenNachPartei.csv) umfassen die Erst- bzw. Zweitstimmen-Ergebnisse der einzelnen Parteien, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildErgebnisse.R](./buildErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`Stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 1` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`ParteiKuerzel`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `Grüne`)
|`Stimmen`|integer|Anzahl gültiger Stimmen für diese Partei

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2025 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/ergebnisse_gemeinde_09175132.html):
  * [`wahlbezirksergebnisse.csv`](raw/wahlbezirksergebnisse.csv) ([Weblink](https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/wahlbezirksergebnisse.csv))


## [`direktkandidaten.csv`](./direktkandidaten.csv)

Der Datensatz [direktkandidaten.csv](./direktkandidaten.csv) umfasst die Namen und Parteien der Direktkandidat:innen für die Erststimmen. (Der Datensatz kann z.&nbsp;B. als Lookup für `erststimmenNachPartei.csv` verwendet werden, da aus Redundanzgründen dort auf die Namen verzichtet wurde.)

|Spalte|Format|Beschreibung
|-|-|-
|`ParteiKuerzel`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `Grüne`)
|`Direktkandidat`|text|Name der Person

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2025 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/ergebnisse_gemeinde_09175132.html) (händisch übertragen)


## [`parteien.csv`](./parteien.csv)

Der Datensatz [parteien.csv](./parteien.csv) umfasst die Namen, Nummern und Farben der Parteien. Nicht alle dieser Parteien sind bei der Erststimmen-Wahl mit eine:r Direktkandidat:in angetreten. (Der Datensatz kann z.&nbsp;B. als Lookup für die anderen Datensätze verwendet werden, da aus Redundanzgründen dort auf die Farben verzichtet wurde. Außerdem werden die Parteinummern benötigt, um aus den Rohdaten auf die Parteinamen zu schließen.)

Der Datensatz wurde händisch erstellt.

|Spalte|Format|Beschreibung
|-|-|-
|`ParteiNr`|integer|Nummer der Partei (vorgegeben durch Rohformat)
|`ParteiKuerzel`|text|Kurzname der Partei (z.&nbsp;B. `CSU` oder `Grüne`)
|`ParteiName`|text|Offizieller Name der Partei (z.&nbsp;B. `Christlich-Soziale Union in Bayern e.V.` oder `BÜNDNIS 90/DIE GRÜNEN`)
|`ParteiFarbe`|[hexcolor](https://de.wikipedia.org/wiki/Hexadezimale_Farbdefinition)|(Inoffizielle) Farbe der Partei (z.&nbsp;B. `#ff0000`)

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2025 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175000/212/20250223/bundestagswahl_kwl_1_wk/ergebnisse_gemeinde_09175132.html) (händisch übertragen)
* Eigene Definition (`ParteiFarbe`)


## [`stimmbezirke.csv`](./stimmbezirke.csv)

Der Datensatz [`stimmbezirke.csv`](./stimmbezirke.csv) ist identisch zu [`../landtagswahl2023/stimmbezirke.csv`](../landtagswahl2023/stimmbezirke.csv).


## [`stimmbezirke.geojson`](./stimmbezirke.geojson)

Der Datensatz [`stimmbezirke.geojson`](./stimmbezirke.geojson) ist identisch zu [`../landtagswahl2023/stimmbezirke.geojson`](../landtagswahl2023/stimmbezirke.geojson).
