# Corona-Impfungen im Landkreis Ebersberg

## [`impfungenLkEbe.csv`](./impfungenLkEbe.csv)
 
Der Datensatz [impfungenLkEbe.csv](./impfungenLkEbe.csv) umfasst die Zahl an verabreichten Impfdosen im gesamten Landkreis Ebersberg.

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
