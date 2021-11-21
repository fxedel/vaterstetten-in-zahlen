# Corona-Impfungen im Landkreis Ebersberg

## [`arcgisImpfungen.csv`](./arcgisImpfungen.csv)

Der Datensatz [arcgisImpfungen.csv](./arcgisImpfungen.csv) umfasst die Zahl an verabreichten Impfungen im gesamten Landkreis Ebersberg.

Die Daten werden automatisiert erstellt und umfassen den Zeitraum seit dem 21. April 2021.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`erstimpfungen`|integer|Kumulative Zahl verabreichter Erstimpfungen
|`zweitimpfungen`|integer|Kumulative Zahl verabreichter Zweitimpfungen
|`drittimpfungen`|integer|Kumulative Zahl verabreichter Drittimpfungen
|`impfdosen`|integer|Kumulative Zahl verabreichter Impfdosen
|`impfdosenNeu`|integer|Zahl neu verabreichter Impfdosen im Vergleich zum Vortag

* `erstimpfungen` + `zweitimpfungen` + `drittimpfungen` > `impfdosen`, vermutlich aufgrund von Johnson&Johnson-Impfungen, die gleichzeitig `erstimpfungen` und `zweitimpfungen` um je eins erhöhen
* `erstimpfungen` ≤ `zweitimpfungen` ≤ `drittimpfungen`

### Quellen

- [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-arcgis.md) (EBE_Gesamtsummen_Impfmeldungen_Öffentlich)



## [`arcgisImpfungenNachEinrichtung.csv`](./arcgisImpfungenNachAlter.csv)

Der Datensatz [arcgisImpfungenNachEinrichtung.csv](./arcgisImpfungenNachEinrichtung.csv) umfasst die Zahl an verabreichten Impfungen im gesamten Landkreis Ebersberg, aufgeschlüsselt nach Einrichtung, in der die Impfung verabreicht wurde.

Die Daten werden automatisiert erstellt und umfassen den Zeitraum seit dem 21. April 2021.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`einrichtung`|text|Einrichtung, auf die sich die Zahlen an Impfungen beziehen: `Impfzentrum`, `Kreisklinik`, `Praxis`
|`erstimpfungen`|integer|Kumulative Zahl verabreichter Erstimpfungen
|`zweitimpfungen`|integer|Kumulative Zahl verabreichter Zweitimpfungen
|`drittimpfungen`|integer|Kumulative Zahl verabreichter Drittimpfungen
|`impfdosen`|integer|Kumulative Zahl verabreichter Impfdosen

* `erstimpfungen` + `zweitimpfungen` + `drittimpfungen` = `impfdosen` (vermutlich werden Johnson&Johnson-Impfungen zweifach zu `impfdosen` gezählt)
* `erstimpfungen` ≤ `zweitimpfungen` ≤ `drittimpfungen`

### Quellen

- [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-arcgis.md) (Covid19_Impfmeldungen_Öffentlich)



## [`arcgisImpfungenNachAlter.csv`](./arcgisImpfungenNachAlter.csv)

Der Datensatz [arcgisImpfungenNachAlter.csv](./arcgisImpfungenNachAlter.csv) umfasst die Zahl an verabreichten Impfungen im gesamten Landkreis Ebersberg, aufgeschlüsselt nach Altersgruppe und Einrichtung, wobei nur für die Einrichtung `Impfzentrum` Daten vorhanden sind.

Die Daten werden automatisiert erstellt und umfassen den Zeitraum seit dem 21. April 2021.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`einrichtung`|text|Einrichtung, auf die sich die Zahlen an Impfungen beziehen: Aktuell nur `Impfzentrum`
|`altersgruppe`|text|Altersgruppe, auf die sich die Zahlen an Impfungen beziehen: `0-19`, `10-19`, `20-29`, `30-39`, `40-49`, `50-59`, `60-69`, `70-79`, `80+`
|`erstimpfungen`|integer|Kumulative Zahl verabreichter Erstimpfungen
|`zweitimpfungen`|integer|Kumulative Zahl verabreichter Zweitimpfungen
|`drittimpfungen`|integer|Kumulative Zahl verabreichter Drittimpfungen

* `erstimpfungen` ≤ `zweitimpfungen` ≤ `drittimpfungen`

### Quellen

- [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-arcgis.md) (Covid19_Impfmeldungen_Öffentlich)



## [`arcgisImpfungenNachGeschlecht.csv`](./arcgisImpfungenNachGeschlecht.csv)

Der Datensatz [arcgisImpfungenNachGeschlecht.csv](./arcgisImpfungenNachGeschlecht.csv) umfasst die Zahl an verabreichten Impfungen im gesamten Landkreis Ebersberg, aufgeschlüsselt nach Geschlecht und Einrichtung, wobei nur für die Einrichtung `Impfzentrum` Daten vorhanden sind.

Die Daten werden automatisiert erstellt und umfassen den Zeitraum seit dem 21. April 2021.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`einrichtung`|text|Einrichtung, auf die sich die Zahlen an Impfungen beziehen: Aktuell nur `Impfzentrum`
|`geschlecht`|text|Geschlecht, auf das sich die Zahlen an Impfungen beziehen: `Weiblich`, `Maennlich`, `Divers`
|`erstimpfungen`|integer|Kumulative Zahl verabreichter Erstimpfungen
|`zweitimpfungen`|integer|Kumulative Zahl verabreichter Zweitimpfungen
|`drittimpfungen`|integer|Kumulative Zahl verabreichter Drittimpfungen

* `erstimpfungen` ≤ `zweitimpfungen` ≤ `drittimpfungen`

### Quellen

- [ArcGIS-API des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-arcgis.md) (Covid19_Impfmeldungen_Öffentlich)



## [`impfungenLandkreis.csv`](./impfungenLandkreis.csv)
 
Der Datensatz [impfungenLandkreis.csv](./impfungenLandkreis.csv) umfasst die Zahl an verabreichten Impfungen im gesamten Landkreis Ebersberg.

Die Daten wurden teils händisch, teils automatisiert erstellt und umfassen den Zeitraum von 26. Dezember 2020 bis zum 13. Juli 2021.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`erstimpfungen`|integer|Kumulative Zahl verabreichter Erstimpfungen
|`zweitimpfungen`|integer|Kumulative Zahl verabreichter Zweitimpfungen
|`erstimpfungenAb80`|integer|Kumulative Zahl verabreichter Erstimpfungen an Über-80-Jährige
|`zweitimpfungenAb80`|integer|Kumulative Zahl verabreichter Zweitimpfungen an Über-80-Jährige
|`erstimpfungenHausaerzte`|integer|Kumulative Zahl verabreichter Erstimpfungen durch Hausärzt*innen
|`zweitimpfungenHausaerzte`|integer|Kumulative Zahl verabreichter Zweitimpfungen durch Hausärzt*innen
|`registriert`|integer|Aktuelle Zahl an Online-Registrierungen über das [Bayerische Impfportal](https://impfzentren.bayern/) (im Landkreis Ebersberg)

* `erstimpfungen` + `zweitimpfungen` = Kumulative Zahl verabreichter Impfdosen
* `erstimpfungenAb80` ≤ `erstimpfungen`
* `zweitimpfungenAb80` ≤ `zweitimpfungen`
* `erstimpfungenHausaerzte` ≤ `erstimpfungen`
* `zweitimpfungenHausaerzte` ≤ `zweitimpfungen`

### Quellen

- [Impfzentrum Ebersberg](../quellen/lra-ebe-impfzentrum.md)
- [Pressemitteilungen des Landratsamtes Ebersberg](../quellen/lra-ebe-corona-pressemeldungen.md) (insbesondere in der Anfangszeit, sowie später die Ü80-Daten, als das Impfzentrum diese nicht mehr darstellte)
