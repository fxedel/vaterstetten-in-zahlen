# Landtagswahl 8. Oktober 2023 in der Gemeinde Vaterstetten

## [`landtagswahlErststimmenAllgemein.csv`](./landtagswahlErststimmenAllgemein.csv) / [`landtagswahlZweitstimmenAllgemein.csv`](./landtagswahlZweitstimmenAllgemein.csv)

Die Datensätze [landtagswahlErststimmenAllgemein.csv](./landtagswahlErststimmenAllgemein.csv) und [landtagswahlZweitstimmenAllgemein.csv](./landtagswahlZweitstimmenAllgemein.csv) umfassen allgemeine Ergebnisse der Erststimmen bzw. Zweitstimmen der Landtagswahl, nach Stimmbezirk aufgeschlüsselt.

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

* [Wahlportal zur Landtagswahl 2023 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20231008/landtagswahl_stkl_1_stk/index.html) ([`stimmen.csv`](https://wahlen.osrz-akdb.de/ob-p/175000/0/20231008/landtagswahl_stkl_1_stk/stimmen.csv), nur einzelne Spalten und Zeilen)


## [`landtagswahlErststimmenNachPartei.csv`](./landtagswahlErststimmenNachPartei.csv) / [`landtagswahlZweitstimmenNachPartei.csv`](./landtagswahlZweitstimmenNachPartei.csv)

Die Datensätze [landtagswahlErststimmenNachPartei.csv](./landtagswahlErststimmenNachPartei.csv) und [landtagswahlZweitstimmenNachPartei.csv](./landtagswahlZweitstimmenNachPartei.csv) umfassen die Erst- bzw. Zweitstimmen-Ergebnisse der einzelnen Parteien, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildErgebnisse.R](./buildErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`Stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 1` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`ParteiKuerzel`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `GRÜNE`)
|`Stimmen`|integer|Anzahl gültiger Stimmen für diese Partei

### Quellen

* [Wahlportal zur Landtagswahl 2023 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20231008/landtagswahl_stkl_1_stk/index.html) ([`stimmen.csv`](https://wahlen.osrz-akdb.de/ob-p/175000/0/20231008/landtagswahl_stkl_1_stk/stimmen.csv), nur einzelne Spalten und Zeilen)


## [`landtagswahlDirektkandidaten.csv`](./landtagswahlDirektkandidaten.csv)

Der Datensatz [landtagswahlDirektkandidaten.csv](./landtagswahlDirektkandidaten.csv) umfasst die Namen und Parteien der Direktkandidat:innen für die Erststimmen. (Der Datensatz kann z.&nbsp;B. als Lookup für `landtagswahlErststimmenNachPartei.csv` verwendet werden, da aus Redundanzgründen dort auf die Namen verzichtet wurde.)

|Spalte|Format|Beschreibung
|-|-|-
|`ParteiKuerzel`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `GRÜNE`)
|`Direktkandidat`|text|Name der Person

### Quellen

* [Wahlportal zur Landtagswahl 2023 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20231008/landtagswahl_stkl_1_stk/index.html) (händisch übertragen)


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

* [Wahlportal zur Landtagswahl 2023 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20231008/landtagswahl_stkl_1_stk/index.html) (händisch übertragen)
* Eigene Definition (`ParteiFarbe`)


## [`stimmbezirke.csv`](./stimmbezirke.csv)

Der Datensatz [`stimmbezirke.csv`](./stimmbezirke.csv) umfasst alle 30 Stimmbezirke. Die Briefwahlstimmbezirke (31 bis 45) lassen sich jeweils genau einem Wahllokalstimmbezirk (1 bis 15) zuordnen. Diese Zuordnung wird über die Spalte `StimmbezirkAggregiert` realisiert. Die aggregierten Stimmbezirke lassen sich somit also ebenfalls auf ein geographisches Gebiet zurückführen und umfassen alle Stimmen (sowohl Urnen-, als auch Briefwahl).

Der Datensatz wurde händisch erstellt.

|Spalte|Format|Beschreibung
|-|-|-
|`Stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 1` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`StimmbezirkArt`|text|`Wahllokal` oder `Briefwahl` oder `NA` für Gesamt
|`StimmbezirkAggregiert`|text|Name des aggregierten Stimmbezirks (z.&nbsp;B. `Stimmbezirke 1/2/31` für die Stimmbezirke 1, 2 und 31) oder `Gesamt` für alle Stimmbezirke

### Quellen

* Gemeinde Vaterstetten (persönliche Nachfrage)
* [Wahlportal zur Landtagswahl 2023 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20231008/landtagswahl_stkl_1_stk/index.html) (`opendata-wahllokale.csv`, nur einzelne Spalten)


## [`stimmbezirke.geojson`](./stimmbezirke.geojson)

Der Geodatensatz [`stimmbezirke.geojson`](./stimmbezirke.geojson) stellt die Gebietszuteilung der Wahllokalstimmbezirke 1 bis 15 dar. Die Daten sind im [GeoJSON-Format](https://de.wikipedia.org/wiki/GeoJSON) gespeichert, jeder Stimmbezirk ist dabei ein Polygon oder MultiPolygon.

Der Geodatensatz wurde mit dem Tool [uMap](https://umap.openstreetmap.fr/de/) händisch erstellt und als GeoJSON exportiert. Die uMap-Karte kann hier abgerufen werden: [https://umap.openstreetmap.fr/de/map/landtagswahl-2023-stimmbezirke-vaterstetten_966387](https://umap.openstreetmap.fr/de/map/landtagswahl-2023-stimmbezirke-vaterstetten_966387)

### Quellen

* Gemeinde Vaterstetten (Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf dessen Basis die [uMap-Karte](https://umap.openstreetmap.fr/de/map/landtagswahl-2023-stimmbezirke-vaterstetten_966387) erstellt werden konnte)
