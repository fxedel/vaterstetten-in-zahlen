# Schulen in der Gemeinde Vaterstetten

## [`arcgisSchueler.csv`](./arcgisSchueler.csv)

Der Datensatz [arcgisSchueler.csv](./arcgisSchueler.csv) umfasst Daten zu den Schulen des Landkreises Ebersberg (Gymnasien, Realschulen, Förderschulen), nach Schuljahr.

|Spalte|Format|Beschreibung
|-|-|-
|`schule`|text|Name der Schule. 
|`schuljahresbeginn`|integer|Jahr, in dem das Schuljahr begann, z.&nbsp;B. `1999` für das Schuljahr `1999/2000`.
|`schueler`|integer|Anzahl Schüler:innen
|`klassen`|integer|Anzahl Klassen (ohne Oberstufe am Gymnasium)


### Quellen

* [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-arcgis.md) (service_a22606ef95d34115b9b209cc73bd6c55)


## [`arcgisSchuelerPrognose2022.csv`](./arcgisSchuelerPrognose2022.csv)

Der Datensatz [arcgisSchuelerPrognose2022.csv](./arcgisSchuelerPrognose2022.csv) umfasst eine Prognose aus dem Frühjahr 2022 zu den Schülerzahlen der Schulen des Landkreises Ebersberg (Gymnasien, Realschulen, Förderschulen), nach Schuljahr, bis zum Jahr 2035.

Grundlage der Prognose ist die Einwohnerentwicklung im Landkreis Ebersberg, die anhand von Altersstruktur, Fertilität, Mortalität, Wanderungen und Siedlungsentwicklung bestimmt wird.

Weitere Informationen zur Prognose:
* [Sitzung des Ausschusses für Soziales, Familie, Bildung, Sport und Kultur des Kreistages Ebersberg, TOP 6](https://buergerinfo.lra-ebe.de/si0057.asp?__ksinr=1399)
  * [Sitzungsvorlage](https://buergerinfo.lra-ebe.de/getfile.asp?id=67288&type=view)
  * [Präsentation](https://buergerinfo.lra-ebe.de/getfile.asp?id=67923&type=do)

|Spalte|Format|Beschreibung
|-|-|-
|`schule`|text|Name der Schule. 
|`schuljahresbeginn`|integer|Jahr, in dem das Schuljahr begann, z.&nbsp;B. `1999` für das Schuljahr `1999/2000`.
|`schueler`|integer|Anzahl Schüler:innen


### Quellen

* [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-arcgis.md) (service_a22606ef95d34115b9b209cc73bd6c55)


## [`arcgisSchuelerNachWohnort.csv`](./arcgisSchuelerNachWohnort.csv)

Der Datensatz [arcgisSchuelerNachWohnort.csv](./arcgisSchuelerNachWohnort.csv) umfasst Daten zum Wohnort der Schüler:innen der Schulen des Landkreises Ebersberg, nach Schuljahr.

|Spalte|Format|Beschreibung
|-|-|-
|`schule`|text|Name der Schule.
|`wohnort`|text|Wohnort der Schüler:innen. Kann eine einzelne Gemeinde oder ein ganzer Landkreis sein (Gemeindeebene für Kommunen im Landkreis Ebersberg oder für kreisfreie Städte, sonst meist Kreisebene).
|`schuljahresbeginn`|integer|Jahr, in dem das Schuljahr begann, z.&nbsp;B. `1999` für das Schuljahr `1999/2000`.
|`schueler`|integer|Anzahl Schüler:innen aus diesem Wohnort, die in diesem Jahr diese Schule besuchten.


### Quellen

* [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-arcgis.md) (Herkunft)


## [`hgvJahresberichte.csv`](./hgvJahresberichte.csv)

Der Datensatz [hgvJahresberichte.csv](./hgvJahresberichte.csv) umfasst Daten zum [Humboldt-Gymnasium Vaterstetten](https://de.wikipedia.org/wiki/Humboldt-Gymnasium_Vaterstetten) aus den Jahresberichten, nach Schuljahr.

|Spalte|Format|Beschreibung
|-|-|-
|`schuljahresbeginn`|integer|Jahr, in dem das Schuljahr begann, z.&nbsp;B. `1999` für das Schuljahr `1999/2000`.
|`schulleiter`|text|Name des/der Schulleiter:in
|`schuelerSchuljahresbeginn`|integer|Anzahl Schüler:innen zum Schuljahresbeginn
|`zugaenge`|integer|Unterjährige Zugänge an Schüler:innen
|`abgaenge`|integer|Unterjährige Abgänge an Schüler:innen
|`schuelerSchuljahresende`|integer|Anzahl Schüler:innen zum Schuljahresende
|`schuelerMaennlich`|integer|Anzahl männlicher Schüler. Stichtag ist möglichst das Schuljahresende, kann aber variieren.
|`schuelerWeiblich`|integer|Anzahl weiblicher Schülerinnen. Stichtag ist möglichst das Schuljahresende, kann aber variieren.
|`klassen`|integer|Anzahl Klassen (ohne Oberstufe)
|`kommentar`|text|Zusatzinfo zum Schuljahr, die eventuell auch einen Erklärungsansatz für die Schülerzahl bietet.

* `schuelerSchuljahresbeginn` + `zugaenge` – `abgaenge` = `schuelerSchuljahresende`


### Quellen

* Jahresberichte des Humboldt-Gymnasiums Vaterstetten, zur Verfügung gestellt durch Lehrkräfte und Privatleute.

### Fehlerkorrekturen

#### Schuljahr 1991/1992

Im Jahresbericht ist als Schülerzahl zum Schuljahresbeginn `960` angegeben, die Summe aus den einzelnen Klassenstärken ergibt jedoch `958`. Mit `958` ist die Tabelle aus diesem Jahresbericht wieder in sich stimmig (also `schuelerSchuljahresbeginn` + `zugaenge` – `abgaenge` = `schuelerSchuljahresende`, sowie `schuelerMaennlich` + `schuelerWeiblich` = `schuelerSchuljahresende` und die Summen aus den Klassenwerten stimmen auch), deshalb wurde der Wert korrigiert.

#### Schuljahr 2005/2006

Im Jahresbericht ist als Schülerzahl zum Schuljahresbeginn `1305` angegeben, die Summe aus den einzelnen Klassenstärken ergibt jedoch `1295`. Mit `1295` ist die Tabelle aus diesem Jahresbericht wieder in sich stimmig (also `schuelerMaennlich` + `schuelerWeiblich` = `schuelerSchuljahresbeginn` und die Summen aus den Klassenwerten stimmen auch), deshalb wurde der Wert korrigiert.
