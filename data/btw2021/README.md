# Bundestagswahl 26. September 2021 in der Gemeinde Vaterstetten

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

<sup>[1]</sup> Briefwähler werden nicht in ihrem eigentlichen (Wahllokal-)Stimmbezirk als Wähler gezählt, sondern in einem Briefwahlstimmbezirk. Daher ist es nicht möglich, die Wahlbeteiligung nach Stimmbezirk aufgeschlüsselt anzugeben, da nicht bekannt ist, wie viele Briefwähler es in den Stimmbezirken gibt.

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2021 in Vaterstetten](../quellen/okvote.md) (`Open-Data-Bundestagswahl1573.csv` und `Open-Data-Bundestagswahl1576.csv`, nur einzelne Spalten)


## [`erststimmenNachPartei.csv`](./erststimmenNachPartei.csv) / [`zweitstimmenNachPartei.csv`](./zweitstimmenNachPartei.csv)

Die Datensätze [erststimmenNachPartei.csv](./erststimmenNachPartei.csv) und [zweitstimmenNachPartei.csv](./zweitstimmenNachPartei.csv) umfassen die Erst- bzw. Zweitstimmen-Ergebnisse der einzelnen Parteien, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildErgebnisse.R](./buildErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`Stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 1` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`ParteiKuerzel`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `GRÜNE`)
|`Stimmen`|integer|Anzahl gültiger Stimmen für diese Partei

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2021 in Vaterstetten](../quellen/okvote.md) (`Open-Data-Bundestagswahl1573.csv` und `Open-Data-Bundestagswahl1576.csv`, nur einzelne Spalten)


## [`direktkandidaten.csv`](./direktkandidaten.csv)

Der Datensatz [direktkandidaten.csv](./direktkandidaten.csv) umfasst die Namen und Parteien der Direktkandidat:innen für die Erststimmen. (Der Datensatz kann z.&nbsp;B. als Lookup für `erststimmenNachPartei.csv` verwendet werden, da aus Redundanzgründen dort auf die Namen verzichtet wurde.)

|Spalte|Format|Beschreibung
|-|-|-
|`ParteiKuerzel`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `GRÜNE`)
|`Direktkandidat`|text|Name der Person

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2021 in Vaterstetten](../quellen/okvote.md) (händisch übertragen)


## [`parteien.csv`](./parteien.csv)

Der Datensatz [parteien.csv](./parteien.csv) umfasst die Namen, Nummern und Farben der Parteien. Nicht alle dieser Parteien sind bei der Erststimmen-Wahl mit eine:r Direktkandidat:in angetreten. (Der Datensatz kann z.&nbsp;B. als Lookup für die anderen Datensätze verwendet werden, da aus Redundanzgründen dort auf die Farben verzichtet wurde. Außerdem werden die Parteinummern benötigt, um aus den Rohdaten auf die Parteinamen zu schließen.)

Der Datensatz wurde händisch erstellt.

|Spalte|Format|Beschreibung
|-|-|-
|`ParteiNr`|integer|Nummer der Partei (vorgegeben durch Rohformat)
|`ParteiKuerzel`|text|Kurzname der Partei (z.&nbsp;B. `CSU` oder `GRÜNE`)
|`ParteiName`|text|Offizieller Name der Partei (z.&nbsp;B. `Christlich-Soziale Union in Bayern e.V.` oder `BÜNDNIS 90/DIE GRÜNEN`)
|`ParteiFarbe`|[hexcolor](https://de.wikipedia.org/wiki/Hexadezimale_Farbdefinition)|(Inoffizielle) Farbe der Partei (z.&nbsp;B. `#ff0000`)

### Quellen

* [OK.VOTE-Portal zur Bundestagswahl 2021 in Vaterstetten](../quellen/okvote.md) (händisch übertragen)
* Eigene Definition (`ParteiFarbe`)


## [`stimmbezirke.csv`](./stimmbezirke.csv)

Der Datensatz [`stimmbezirke.csv`](./stimmbezirke.csv) umfasst alle 27 Stimmbezirke. Die Briefwahlstimmbezirke (31 bis 43) lassen sich jeweils genau einem Wahllokalstimmbezirk (1 bis 14) zuordnen (mit Ausnahme des Briefwahlstimmbezirks 31, der sich den beiden Wahllokalstimmbezirken 1 und 2 zuordnen lässt). Diese Zuordnung wird über die Spalte `StimmbezirkAggregiert` realisiert. Die aggregierten Stimmbezirke lassen sich somit also ebenfalls auf ein geographisches Gebiet zurückführen und umfassen alle Stimmen (sowohl Urnen-, als auch Briefwahl).

Der Datensatz wurde händisch erstellt.

|Spalte|Format|Beschreibung
|-|-|-
|`Stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 1` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`StimmbezirkArt`|text|`Wahllokal` oder `Briefwahl` oder `NA` für Gesamt
|`StimmbezirkAggregiert`|text|Name des aggregierten Stimmbezirks (z.&nbsp;B. `Stimmbezirke 1/2/31` für die Stimmbezirke 1, 2 und 31) oder `Gesamt` für alle Stimmbezirke

### Quellen

* Gemeinde Vaterstetten (persönliche Nachfrage)
* [OK.VOTE-Portal zur Bundestagswahl 2021 in Vaterstetten](../quellen/okvote.md) (`opendata-wahllokale.csv`, nur einzelne Spalten)


## [`stimmbezirke.geojson`](./stimmbezirke.geojson)

Der Geodatensatz [`stimmbezirke.geojson`](./stimmbezirke.geojson) stellt die Gebietszuteilung der Wahllokalstimmbezirke 1 bis 14 dar. Die Daten sind im [GeoJSON-Format](https://de.wikipedia.org/wiki/GeoJSON) gespeichert, jeder Stimmbezirk ist dabei ein Polygon oder MultiPolygon.

Der Geodatensatz wurde mit dem Tool [uMap](https://umap.openstreetmap.fr/de/) händisch erstellt und als GeoJSON exportiert. Die uMap-Karte kann hier abgerufen werden: [https://umap.openstreetmap.fr/de/map/bundestagswahl-2021-stimmbezirke_659020#14/48.1098/11.8031](https://umap.openstreetmap.fr/de/map/bundestagswahl-2021-stimmbezirke_659020#14/48.1098/11.8031)

### Quellen

* Gemeinde Vaterstetten (Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf dessen Basis die [uMap-Karte](https://umap.openstreetmap.fr/de/map/bundestagswahl-2021-stimmbezirke_659020#14/48.1098/11.8031) erstellt werden konnte)
