# Europawahl 9. Juni 2024 in der Gemeinde Vaterstetten

## [`ergebnisAllgemein.csv`](./ergebnisAllgemein.csv)

Der Datensatz [ergebnisAllgemein.csv](./ergebnisAllgemein.csv) umfasst allgemeine Ergebnisse der Europawahl, nach Stimmbezirk aufgeschlüsselt.

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

* [Wahlportal zur Europawahl 2024 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20240609/europawahl_kreis/ergebnisse_gemeinde_09175132.html) ([`stimmen.csv`](https://wahlen.osrz-akdb.de/ob-p/175000/0/20240609/europawahl_kreis/stimmen.csv), nur einzelne Spalten und Zeilen)


## [`ergebnisNachPartei.csv`](./ergebnisNachPartei.csv)

Der Datensatz [ergebnisNachPartei.csv](./ergebnisNachPartei.csv) umfassen die Europawahl-Ergebnisse der einzelnen Parteien, nach Stimmbezirk aufgeschlüsselt.

Der Datensatz wurde semi-automatisch mit dem RScript [buildErgebnisse.R](./buildErgebnisse.R) aus den Rohdaten generiert.

|Spalte|Format|Beschreibung
|-|-|-
|`Stimmbezirk`|text|Name des Stimmbezirks, auf den sich die Zeile bezieht (`Stimmbezirk 1` bis `Stimmbezirk 43`) oder `Gesamt` für alle Stimmbezirke
|`ParteiKuerzel`|text|Kurzname der Partei, auf die sich die Zeile bezieht (z.&nbsp;B. `CSU` oder `GRÜNE`)
|`Stimmen`|integer|Anzahl gültiger Stimmen für diese Partei

### Quellen

* [Wahlportal zur Europawahl 2024 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20240609/europawahl_kreis/ergebnisse_gemeinde_09175132.html) ([`stimmen.csv`](https://wahlen.osrz-akdb.de/ob-p/175000/0/20240609/europawahl_kreis/stimmen.csv), nur einzelne Spalten und Zeilen)


## [`parteien.csv`](./parteien.csv)

Der Datensatz [parteien.csv](./parteien.csv) umfasst die Namen, Nummern und Farben der Parteien. (Der Datensatz kann z.&nbsp;B. als Lookup für die anderen Datensätze verwendet werden, da aus Redundanzgründen dort auf die Farben verzichtet wurde. Außerdem werden die Parteinummern benötigt, um aus den Rohdaten auf die Parteinamen zu schließen.)

Der Datensatz wurde händisch erstellt.

|Spalte|Format|Beschreibung
|-|-|-
|`ParteiNr`|integer|Nummer der Partei (vorgegeben durch Rohformat)
|`ParteiKuerzel`|text|Kurzname der Partei (z.&nbsp;B. `CSU` oder `GRÜNE`)
|`ParteiName`|text|Offizieller Name der Partei (z.&nbsp;B. `Christlich-Soziale Union in Bayern e.V.` oder `BÜNDNIS 90/DIE GRÜNEN`)
|`ParteiFarbe`|[hexcolor](https://de.wikipedia.org/wiki/Hexadezimale_Farbdefinition)|(Inoffizielle) Farbe der Partei (z.&nbsp;B. `#ff0000`)

### Quellen

* [Wahlportal zur Europawahl 2024 im Landkreis Ebersberg](https://wahlen.osrz-akdb.de/ob-p/175000/0/20240609/europawahl_kreis/ergebnisse_gemeinde_09175132.html) (händisch übertragen)
* Eigene Definition (`ParteiFarbe`)


## [`stimmbezirke.csv`](./stimmbezirke.csv)

Der Datensatz [`stimmbezirke.csv`](./stimmbezirke.csv) ist identisch zu [`../landtagswahl2023/stimmbezirke.csv`](../landtagswahl2023/stimmbezirke.csv).


## [`stimmbezirke.geojson`](./stimmbezirke.geojson)

Der Datensatz [`stimmbezirke.geojson`](./stimmbezirke.geojson) ist identisch zu [`../landtagswahl2023/stimmbezirke.geojson`](../landtagswahl2023/stimmbezirke.geojson).
