# Kommunalwahl 2020 in der Gemeinde Vaterstetten

## [`gemeinderatErgebnisAllgemein.csv`](./gemeinderatErgebnisAllgemein.csv)

Der Datensatz [gemeinderatErgebnisAllgemein.csv](./gemeinderatErgebnisAllgemein.csv) umfasst allgemeine Ergebnisse der Gemeinderatswahl (nicht partei-spezifisch), nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildGemeinderatErgebnisse.R](./buildGemeinderatErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 01` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`stimmbezirkNr`|integer|Nummer des Stimmbezirks (`1` bis `43`) oder `NA` für Gesamt
|`stimmbezirkArt`|text|`Wahllokal` oder `Briefwahl` oder `NA` für Gesamt
|`wahlberechtigte`|integer|Anzahl der Wahlberechtigten (für Briefwahlstimmbezirke immer `0`)
|`waehler`|integer|Anzahl der Wähler<sup>[1]<sup>
|`ungueltigeStimmzettel`|integer|Anzahl ungültiger Stimmzettel
|`gueltigeStimmzettel`|integer|Anzahl gültiger Stimmzettel
|`gueltigeStimmen`|integer|Anzahl gültiger Stimmen (jeder Stimmzettel kann bis zu 30 Stimmen vergeben)
|`stimmzettelNurListenkreuz`|integer|Anzahl Stimmzettel, auf denen nur eine einzelne Liste angekreuzt wurde (ohne „Häufeln“)
|`stimmzettelNurEineListe`|integer|Anzahl Stimmzettel, auf denen die Stimmen nur innerhalb einer Partei verteilt wurden (inkl. reinem Listenkreuz)

* `waehler` ≤ `wahlberechtigte`, falls es kein Briefwahlstimmbezirk ist
* `waehler` = `ungueltigeStimmzettel` + `gueltigeStimmzettel`
* `gueltigeStimmzettel` ≤ `gueltigeStimmen` ≤ `gueltigeStimmzettel` * 30
* `stimmzettelNurListenkreuz` ≤ `stimmzettelNurEineListe` ≤ `gueltigeStimmzettel`

<sup>[1]</sup> Briefwähler werden nicht in ihrem eigentlichen (Wahllokal-)Stimmbezirk als Wähler gezählt, sondern in einem Briefwahlstimmbezirk. Daher ist es nicht möglich, die Wahlbeteiligung nach Stimmbezirk aufgeschlüsselt anzugeben, da nicht bekannt ist, wie viele Briefwähler es in den Stimmbezirken gibt.

### Quellen

* [OK.VOTE-Portal zur Kommunalwahl 2020 in Vaterstetten](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/OpenDataInfo.html):
  * [`Open-Data-Gemeinderatswahl-Bayern1163.csv`](raw/Open-Data-Gemeinderatswahl-Bayern1163.csv) ([Weblink](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/Open-Data-Gemeinderatswahl-Bayern1163.csv))
  * [`Open-Data-Gemeinderatswahl-Bayern1166.csv`](raw/Open-Data-Gemeinderatswahl-Bayern1163.csv) ([Weblink](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/Open-Data-Gemeinderatswahl-Bayern1166.csv))


## [`gemeinderatErgebnisNachPartei.csv`](./gemeinderatErgebnisNachPartei.csv)

Der Datensatz [gemeinderatErgebnisNachPartei.csv](./gemeinderatErgebnisNachPartei.csv) umfasst die Gemeinderatswahlsergebnisse der einzelnen Partei-Listen, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildGemeinderatErgebnisse.R](./buildGemeinderatErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 01` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`stimmbezirkNr`|integer|Nummer des Stimmbezirks (`1` bis `43`) oder `NA` für Gesamt
|`partei`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `Grüne`)
|`stimmen`|integer|Anzahl gültiger Stimmen für diese Partei
|`stimmzettelNurListenkreuz`|integer|Anzahl Stimmzettel, auf denen nur diese Partei-Liste angekreuzt wurde (ohne „Häufeln“)
|`stimmzettelNurEineListe`|integer|Anzahl Stimmzettel, auf denen die Stimmen nur innerhalb dieser Partei verteilt wurden (inkl. reinem Listenkreuz)

* `stimmzettelNurListenkreuz` ≤ `stimmzettelNurEineListe`

### Quellen

* [OK.VOTE-Portal zur Kommunalwahl 2020 in Vaterstetten](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/OpenDataInfo.html):
  * [`Open-Data-Gemeinderatswahl-Bayern1163.csv`](raw/Open-Data-Gemeinderatswahl-Bayern1163.csv) ([Weblink](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/Open-Data-Gemeinderatswahl-Bayern1163.csv))
  * [`Open-Data-Gemeinderatswahl-Bayern1166.csv`](raw/Open-Data-Gemeinderatswahl-Bayern1163.csv) ([Weblink](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/Open-Data-Gemeinderatswahl-Bayern1166.csv))


## [`gemeinderatErgebnisNachPerson.csv`](./gemeinderatErgebnisNachPerson.csv)

Der Datensatz [gemeinderatErgebnisNachPerson.csv](./gemeinderatErgebnisNachPerson.csv) umfasst die Gemeinderatswahlsergebnisse der einzelnen Personen auf den Partei-Listen, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildGemeinderatErgebnisse.R](./buildGemeinderatErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 01` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`stimmbezirkNr`|integer|Nummer des Stimmbezirks (`1` bis `43`) oder `NA` für Gesamt
|`partei`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `Grüne`)
|`listenNr`|integer|Listen-Nummer der Person, auf die sich die Zeile bezieht (z.&nbsp;B. `1` für den 1. Listenplatz)
|`stimmen`|integer|Anzahl gültiger Stimmen für diese Person
|`erreichterPlatz`|integer|Erreichter Platz der Person auf der Liste, basierend auf der Stimmenanzahl (1 = die Person mit den meisten Stimmen auf der Liste)

### Quellen

* [OK.VOTE-Portal zur Kommunalwahl 2020 in Vaterstetten](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/OpenDataInfo.html):
  * [`Open-Data-Gemeinderatswahl-Bayern1163.csv`](raw/Open-Data-Gemeinderatswahl-Bayern1163.csv) ([Weblink](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/Open-Data-Gemeinderatswahl-Bayern1163.csv))
  * [`Open-Data-Gemeinderatswahl-Bayern1166.csv`](raw/Open-Data-Gemeinderatswahl-Bayern1163.csv) ([Weblink](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/Open-Data-Gemeinderatswahl-Bayern1166.csv))


## [`gemeinderatPersonen.csv`](./gemeinderatPersonen.csv)

Der Datensatz [gemeinderatPersonen.csv](./gemeinderatPersonen.csv) umfasst die Namen der einzelnen Personen auf den Partei-Listen. (Der Datensatz kann z.&nbsp;B. als Lookup für `gemeinderatErgebnisNachPerson.csv` verwendet werden, da aus Redundanzgründen dort auf die Namen verzichtet wurde.)

|Spalte|Format|Beschreibung
|-|-|-
|`partei`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `Grüne`)
|`listenNr`|integer|Listen-Nummer der Person, auf die sich die Zeile bezieht (z.&nbsp;B. `1` für den 1. Listenplatz)
|`name`|text|Name der Person
|`alter`|integer|Alter (i.d.R. zum Zeitpunkt der Wahl), falls bekannt

### Quellen

* [OK.VOTE-Portal zur Kommunalwahl 2020 in Vaterstetten](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/index.html) (händisch übertragen)
* Alter:
  * CSU: https://www.csu-vaterstetten.de/assets/pdf/aktuelle-meldungen/die-csu-gemeinderatsliste-2020-steht.pdf
  * Grüne: https://gruene-ebersberg.de/vor-ort/k-z/vaterstetten/kommunalwahl-2020-vaterstetten/wahlvorschlag-der-gruenen-fuer-den-vaterstettener-gemeinderat


## [`parteien.csv`](./parteien.csv)

Der Datensatz [parteien.csv](./parteien.csv) umfasst die Namen, Nummern und Farben der Parteien. Nicht alle dieser Parteien sind bei jeder Wahl (z.&nbsp;B. Gemeinderat) angetreten. (Der Datensatz kann z.&nbsp;B. als Lookup für die anderen Datensätze verwendet werden, da aus Redundanzgründen dort auf die Farben verzichtet wurde. Außerdem werden die Parteinummern benötigt, um aus den Rohdaten auf die Parteinamen zu schließen.)

Der Datensatz wurde händisch erstellt.

|Spalte|Format|Beschreibung
|-|-|-
|`parteiNr`|integer|Nummer der Partei (vorgegeben durch Rohformat)
|`partei`|text|Kurzname der Partei (z.&nbsp;B. `CSU` oder `Grüne`)
|`farbe`|[hexcolor](https://de.wikipedia.org/wiki/Hexadezimale_Farbdefinition)|(Inoffizielle) Farbe der Partei (z.&nbsp;B. `#ff0000`)

### Quellen

* [OK.VOTE-Portal zur Kommunalwahl 2020 in Vaterstetten](https://okvote.osrz-akdb.de/OK.VOTE_OB/Wahl-2020-03-15/09175132/html5/index.html) (`parteiNr`)
* Eigene Definition (`farbe`)


## [`stimmbezirke.geojson`](./stimmbezirke.geojson)

Der Geodatensatz [`stimmbezirke.geojson`](./stimmbezirke.geojson) stellt die Gebietszuteilung der Wahllokalstimmbezirke 1 bis 24 dar. Die Daten sind im [GeoJSON-Format](https://de.wikipedia.org/wiki/GeoJSON) gespeichert, jeder Stimmbezirk ist dabei ein Polygon oder MultiPolygon.

Der Geodatensatz wurde mit dem Tool [uMap](https://umap.openstreetmap.fr/de/) händisch erstellt und als GeoJSON exportiert. Die uMap-Karte kann hier abgerufen werden: [https://umap.openstreetmap.fr/de/map/kommunalwahl-2020-stimmbezirke_598747#14/48.1098/11.8031](https://umap.openstreetmap.fr/de/map/kommunalwahl-2020-stimmbezirke_598747#14/48.1098/11.8031)

### Quellen

* Gemeinde Vaterstetten (Dies erfolgte in Form von Listen von Straßennamen für jeden Stimmbezirk, auf dessen Basis die [uMap-Karte](https://umap.openstreetmap.fr/de/map/kommunalwahl-2020-stimmbezirke_598747#14/48.1098/11.8031) erstellt werden konnte)
