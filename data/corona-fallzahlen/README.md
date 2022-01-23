# Corona-Fallzahlen im Landkreis Ebersberg

## [`arcgisInzidenzLandkreis.csv`](./arcgisInzidenzLandkreis.csv)

Der Datensatz [arcgisInzidenzLandkreis.csv](./arcgisInzidenzLandkreis.csv) umfasst die automatisch aktualisierten Neuinfektionen und daraus berechneten Inzidenzen für den Landkreis Ebersberg.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`neuPositiv`|integer|Zahl neuer positiver Testungen; synonym als „Neuinfektionen“ bezeichnet
|`inzidenz7tage`|float|7-Tage-Inzidenz (Summe Neuinfektionen des aktuellen Tags und der vorherigen 6 Tage pro 100.000 Einwohner)

### Quellen

- [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-arcgis.md) (EBE_Landkreis_Inzidenztabelle)


## [`arcgisInzidenzAltersgruppen.csv`](./arcgisInzidenzAltersgruppen.csv)

Der Datensatz [arcgisInzidenzAltersgruppen.csv](./arcgisInzidenzAltersgruppen.csv) umfasst die automatisch aktualisierten Neuinfektionen und daraus berechneten Inzidenzen für den Landkreis Ebersberg, aufgeschlüsselt nach Altersgruppe.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`altersgruppe`|text|Altersgruppe, auf die sich die Zahlen an Neuinfektionen beziehen: `00-04`, `05-14`, `15-34`, `35-59`, `60-79`, `80+`
|`neuPositiv`|integer|Zahl neuer positiver Testungen; synonym als „Neuinfektionen“ bezeichnet
|`inzidenz7tage`|float|7-Tage-Inzidenz (Summe Neuinfektionen des aktuellen Tags und der vorherigen 6 Tage pro 100.000 Einwohner dieser Altersgruppe)

### Quellen

- [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-arcgis.md) (EBE_Altersgruppen_Inzidenztabelle)



## [`arcgisInzidenzGemeinden.csv`](./arcgisInzidenzGemeinden.csv)

Der Datensatz [arcgisInzidenzGemeinden.csv](./arcgisInzidenzGemeinden.csv) umfasst die automatisch aktualisierten Neuinfektionen und daraus berechneten Inzidenzen, aufgeschlüsselt nach Gemeinden.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`ort`|text|Kommune, auf die sich die Fallzahlen beziehen
|`neuPositiv`|integer|Zahl neuer positiver Testungen; synonym als „Neuinfektionen“ bezeichnet
|`inzidenz7tage`|float|7-Tage-Inzidenz (Summe Neuinfektionen des aktuellen Tags und der vorherigen 6 Tage pro 100.000 Einwohner)

### Quellen

- [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-arcgis.md) (EBE_Gemeinden_Inzidenztabelle)



## [`fallzahlenVat.csv`](./fallzahlenVat.csv)

Der Datensatz [fallzahlenVat.csv](./fallzahlenVat.csv) umfasst die händisch übertragenen kumulierten und aktuellen Infektionen in Vaterstetten.

Durch die Einstellung der Grafiken des Landratsamtes sind die Daten nur bis zum 17. Juni 2021 verfügbar.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`kumulativ`|integer|Gesamtzahl aller SARS-CoV-2-Infektionen seit Pandemiebeginn
|`aktuell`|integer|Aktuell aktive Fälle

* `kumulativ` = `aktuell` + Genesene + Verstorbene

### Quellen

- [Pressemitteilungen des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-pressemeldungen.md) (Landkreis-Grafik)


### Fehlerkorrekturen

#### 3./6. April 2020

Die kumulative Fallzahl für Vaterstetten lag laut Grafiken des Gesundheitsamtes am 6.&nbsp;April 2020 bei 42, am darauf folgenden Tag jedoch bei nur noch 39. Dies ist eigentlich nicht möglich, da eine kumulative Zahl per Definition nicht sinken kann. Zudem steht in der Grafik für den 6.&nbsp;Aprils eine Gesamtzahl aktueller Fälle von 152, während die Summe der aktuellen Fälle in allen Kommunen nur 150 ergibt. Am 8.&nbsp;April wurde gemeldet, dass in der Grafik des vorherigen Tages ein Fehler passiert sei; bspw. seien die Zahlen für Vaterstetten zu hoch. Die Grafik des 7.&nbsp;Aprils liegt wohl inzwischen nur noch in einer korrigierten Form vor.

Da es offensichtlich Probleme bei der Zählung und/oder Zuordnung der Infektionen in die Kommunen gegeben hat und diese spätestens am 8.&nbsp;April korrigiert wurden, sind die Zahlen für den 3. und 6.&nbsp;April als falsch anzusehen und wurden für dieses Projekt entfernt.

```diff
 2020-04-01,32,24
 2020-04-02,36,26
-2020-04-03,40,26
-2020-04-06,42,20
 2020-04-07,39,16
 2020-04-08,39,18
 2020-04-09,39,14
 2020-04-11,43,15
```

#### 7. September 2020

Die kumulative Fallzahl sowie die Zahl aktueller Fälle sinkt zum 7.&nbsp;September jeweils um 1, um dann am folgenden Tag wieder um 1 zu steigen. Vermutlich handelt es sich hier um ein Versehen, deswegen wurde für dieses Projekt die entsprechende Zeile gelöscht.

```diff
 2020-09-03,85,6
 2020-09-06,88,6
-2020-09-07,87,5
 2020-09-08,88,6
```

Denkbar wäre auch, dass am 6.&nbsp;September eine Person fälschlicherweise zu Vaterstetten gezählt und dann am Folgetag Poing, Aßling oder einem anderen Landkreis zugeordnet wurde; zudem wäre dann am 8.&nbsp;September wieder ein neuer Fall in Vaterstetten gemeldet worden. In diesem Fall bewirkt die vorgenommene Fehlerkorrektur lediglich eine Verschiebung der Neuinfektion vom 8. auf den 6.&nbsp; September.

#### 12. Mai 2021

Die [Grafik vom 12.&nbsp;Mai 2021](https://lra-ebe.de/media/5018/2021-05-12-corona-balkendiagramm.png) weißt gegenüber [der vom Vortag](https://lra-ebe.de/media/5015/2021-05-11-corona-balkendiagramm.png) und der darauffolgenden vom [16.&nbsp;Mai 2021](https://lra-ebe.de/media/5029/2021-05-16-corona-balkendiagramm.png) einige Unstimmigkeiten auf. So ist die kumulierte Zahl zum 12.&nbsp;Mai sprunghaft gestiegen und gleichzeitig die Zahl aktueller Fälle deutlich gesunken, außerdem ist in Ebersberg und Steinhöring die kumulierte Zahl gesunken, was per Definition nicht passieren darf. Zum 16.&nbsp;Mai ist die kumulierte Zahl für Vaterstetten wieder auf ein niedrigeres Niveau gesunken, es kann also angenommen werden, dass es sich bei den Zahlen vom 12.&nbsp;Mai um einen Fehler gehandelt hat.

```diff
 2021-05-11,961,43
-2021-05-12,980,34
 2021-05-16,969,30
```
