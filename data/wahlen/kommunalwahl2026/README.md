# Kommunalwahl 2026 in der Gemeinde Vaterstetten

## [`gemeinderatErgebnisAllgemein.csv`](./gemeinderatErgebnisAllgemein.csv)

Der Datensatz [gemeinderatErgebnisAllgemein.csv](./gemeinderatErgebnisAllgemein.csv) umfasst allgemeine Ergebnisse der Gemeinderatswahl (nicht partei-spezifisch), nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildGemeinderatErgebnisse.R](./buildGemeinderatErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 01` bis `Stimmbezirk 50`) oder `Gesamt` für alle Stimmbezirke
|`stimmbezirkNr`|integer|Nummer des Stimmbezirks (`1` bis `50`) oder `NA` für Gesamt
|`stimmbezirkArt`|text|`Wahllokal` oder `Briefwahl` oder `NA` für Gesamt
|`wahlberechtigte`|integer|Anzahl der Wahlberechtigten (für Briefwahlstimmbezirke immer `0`)
|`waehler`|integer|Anzahl der Wähler<sup>[1]</sup>
|`ungueltigeStimmzettel`|integer|Anzahl ungültiger Stimmzettel
|`gueltigeStimmzettel`|integer|Anzahl gültiger Stimmzettel
|`gueltigeStimmen`|integer|Anzahl gültiger Stimmen (jeder Stimmzettel kann bis zu 30 Stimmen vergeben)
|`stimmzettelNurListenkreuz`|integer|Anzahl Stimmzettel, auf denen nur eine einzelne Liste angekreuzt wurde (ohne Häufeln)
|`stimmzettelNurEineListe`|integer|Anzahl Stimmzettel, auf denen die Stimmen nur innerhalb einer Partei verteilt wurden (inkl. reinem Listenkreuz)

* `waehler` = `ungueltigeStimmzettel` + `gueltigeStimmzettel`
* `gueltigeStimmzettel` ≤ `gueltigeStimmen` ≤ `gueltigeStimmzettel` * 30
* `stimmzettelNurListenkreuz` ≤ `stimmzettelNurEineListe` ≤ `gueltigeStimmzettel`

<sup>[1]</sup> Briefwähler werden nicht in ihrem eigentlichen (Wahllokal-)Stimmbezirk als Wähler gezählt, sondern in einem Briefwahlstimmbezirk. Daher ist es nicht möglich, die Wahlbeteiligung nach Stimmbezirk aufgeschlüsselt anzugeben, da nicht bekannt ist, wie viele Briefwähler es in den einzelnen Wahllokal-Stimmbezirken gibt.

### Quellen

* [AKDB/OSRZ-Wahlportal zur Gemeinderatswahl 2026 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/presse.html):
  * [`gesamtergebnis.csv`](https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/gesamtergebnis.csv) (Direktdownload)


## [`gemeinderatErgebnisNachPartei.csv`](./gemeinderatErgebnisNachPartei.csv)

Der Datensatz [gemeinderatErgebnisNachPartei.csv](./gemeinderatErgebnisNachPartei.csv) umfasst die Gemeinderatswahlsergebnisse der einzelnen Partei-Listen, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildGemeinderatErgebnisse.R](./buildGemeinderatErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 01` bis `Stimmbezirk 50`) oder `Gesamt` für alle Stimmbezirke
|`stimmbezirkNr`|integer|Nummer des Stimmbezirks (`1` bis `50`) oder `NA` für Gesamt
|`partei`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z. B. `CSU` oder `Grüne`)
|`stimmen`|integer|Anzahl gültiger Stimmen für diese Partei
|`stimmzettelNurListenkreuz`|integer|Anzahl Stimmzettel, auf denen nur diese Partei-Liste angekreuzt wurde (ohne Häufeln)
|`stimmzettelNurEineListe`|integer|Anzahl Stimmzettel, auf denen die Stimmen nur innerhalb dieser Partei verteilt wurden (inkl. reinem Listenkreuz)

* `stimmzettelNurListenkreuz` ≤ `stimmzettelNurEineListe`

### Quellen

* [AKDB/OSRZ-Wahlportal zur Gemeinderatswahl 2026 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/presse.html):
  * [`gesamtergebnis.csv`](https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/gesamtergebnis.csv) (Direktdownload)


## [`gemeinderatErgebnisNachPerson.csv`](./gemeinderatErgebnisNachPerson.csv)

Der Datensatz [gemeinderatErgebnisNachPerson.csv](./gemeinderatErgebnisNachPerson.csv) umfasst die Gemeinderatswahlsergebnisse der einzelnen Personen auf den Partei-Listen, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildGemeinderatErgebnisse.R](./buildGemeinderatErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 01` bis `Stimmbezirk 50`) oder `Gesamt` für alle Stimmbezirke
|`stimmbezirkNr`|integer|Nummer des Stimmbezirks (`1` bis `50`) oder `NA` für Gesamt
|`partei`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z. B. `CSU` oder `Grüne`)
|`listenNr`|integer|Listen-Nummer der Person, auf die sich die Zeile bezieht (z. B. `1` für den 1. Listenplatz)
|`stimmen`|integer|Anzahl gültiger Stimmen für diese Person
|`erreichterPlatz`|integer|Erreichter Platz der Person auf der Liste, basierend auf der Stimmenanzahl (1 = die Person mit den meisten Stimmen auf der Liste)

### Quellen

* [AKDB/OSRZ-Wahlportal zur Gemeinderatswahl 2026 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/presse.html):
  * [`gesamtergebnis.csv`](https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/gesamtergebnis.csv) (Direktdownload)


## [`gemeinderatPersonen.csv`](./gemeinderatPersonen.csv)

Der Datensatz [gemeinderatPersonen.csv](./gemeinderatPersonen.csv) umfasst die Stammdaten der einzelnen Personen auf den Partei-Listen. (Der Datensatz kann z. B. als Lookup für `gemeinderatErgebnisNachPerson.csv` verwendet werden, da dort auf redundante Merkmale verzichtet wird.)

|Spalte|Format|Beschreibung
|-|-|-
|`Partei`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z. B. `CSU` oder `Grüne`)
|`ListenNr`|integer|Listen-Nummer der Person, auf die sich die Zeile bezieht (z. B. `1` für den 1. Listenplatz)
|`Name`|text|Name der Person
|`Wohnort`|text|Wohnort der Person, oder `NA` falls nicht bekannt
|`Geschlecht`|text|Geschlechtsangabe (`weiblich`, `maennlich`, `nicht-binär`)
|`Geburtsjahr`|integer|Geburtsjahr

### Quellen

* Offizielle Bekanntmachung zur Kommunalwahl auf der Website der Gemeinde Vaterstetten (nicht mehr online verfügbar)
* Die Geschlechtsangaben wurden manuell anhand der Vornamen und ggf. weiterer Informationen recherchiert.


## [`parteien.csv`](./parteien.csv)

Der Datensatz [parteien.csv](./parteien.csv) umfasst die Namen, Nummern und Farben der Parteien. Nicht alle dieser Parteien sind bei jeder Wahl angetreten (z. B. nur für den Kreistag, aber nicht für den Gemeinderat). (Der Datensatz kann z. B. als Lookup für die anderen Datensätze verwendet werden, da aus Redundanzgründen dort auf d Farben verzichtet wurde. Außerdem werden die Parteinummern benötigt, um aus den Rohdaten auf die Parteinamen zu schließen.)

Der Datensatz wurde händisch erstellt.

|Spalte|Format|Beschreibung
|-|-|-
|`parteiNr`|integer|Nummer der Partei (vorgegeben durch Rohformat)
|`partei`|text|Kurzname der Partei (z. B. `CSU` oder `Grüne`)
|`farbe`|[hexcolor](https://de.wikipedia.org/wiki/Hexadezimale_Farbdefinition)|(Inoffizielle) Farbe der Partei (z. B. `#ff0000`)

### Quellen

* [AKDB/OSRZ-Wahlportal zur Gemeinderatswahl 2026 in Vaterstetten](https://wahlen.osrz-akdb.de/ob-p/175132/2/20260308/gemeinderatswahl_gemeinde/presse.html) (`parteiNr`)
* Eigene Definition (`farbe`)


## [`stimmbezirke.geojson`](./stimmbezirke.geojson)

Der Geodatensatz [stimmbezirke.geojson](./stimmbezirke.geojson) stellt die Gebietszuteilung der Wahllokalstimmbezirke 1 bis 25 dar. Die Daten sind im [GeoJSON-Format](https://de.wikipedia.org/wiki/GeoJSON) gespeichert, jeder Stimmbezirk ist dabei ein Polygon oder MultiPolygon.

Der Geodatensatz wurde mit dem Tool [uMap](https://umap.openstreetmap.de/de/) händisch erstellt und als GeoJSON exportiert. Die uMap-Karte kann hier abgerufen werden: [https://umap.openstreetmap.de/de/map/kommunalwahl-2026-stimmbezirke_124973](https://umap.openstreetmap.de/de/map/kommunalwahl-2026-stimmbezirke_124973)

### Quellen

* Gemeinde Vaterstetten (Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf dessen Basis die [uMap-Karte](https://umap.openstreetmap.de/de/map/kommunalwahl-2026-stimmbezirke_124973) erstellt werden konnte)

