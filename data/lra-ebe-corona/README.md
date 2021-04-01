# Zahlen zur Corona-Pandemie im Landkreis Ebersberg

## Datensätze

### [`fallzahlenVat.csv`](./fallzahlenVat.csv)

Der Datensatz [fallzahlenVat.csv](./fallzahlenVat.csv) umfasst die händisch übertragenen kumulierten und aktuellen Infektionen in Vaterstetten.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`kumulativ`|integer|Gesamtzahl aller SARS-CoV-2-Infektionen seit Pandemiebeginn
|`aktuell`|integer|Aktuell aktive Fälle

* `kumulativ` = `aktuell` + Genesene + Verstorbene


### [`impfungenLkEbe.csv`](./impfungenLkEbe.csv)
 
Der Datensatz [impfungenLkEbe.csv](./impfungenLkEbe.csv) umfasst die Zahl an verabreichten Impfdosen im gesamten Landkreis Ebersberg.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tag, auf den sich die Fallzahlen beziehen
|`erstimpfungen`|integer|Kumulative Zahl verabreichter Erstimpfungen
|`zweitimpfungen`|integer|Kumulative Zahl verabreichter Zweitimpfungen
|`erstimpfungenAb80`|integer|Kumulative Zahl verabreichter Erstimpfungen an Über-80-Jährige
|`zweitimpfungenAb80`|integer|Kumulative Zahl verabreichter Zweitimpfungen an Über-80-Jährige
|`onlineanmeldungen`|integer|Aktuelle Zahl an Online-Registrierungen über das [Bayerische Impfportal](https://impfzentren.bayern/) (im Landkreis Ebersberg)

* `erstimpfungen` + `zweitimpfungen` = Kumulative Zahl verabreichter Impfdosen
* `erstimpfungenAb80` ≤ `erstimpfungen`
* `zweitimpfungenAb80` ≤ `zweitimpfungen`


## Originalquelle

Das Gesundheitsamt veröffentlicht an (fast) jedem Werktag aktuelle Zahlen zur Corona-Pandemie im Landkreis Ebersberg:

* *April 2021*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0421/)
* *März 2021*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0321/)
* *Februar 2021*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0221/)
* *Januar 2021*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0121/)
* *Dezember 2020*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-1220/)
* *November 2020*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-1120/)
* *Oktober 2020*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-1020/)
* *September 2020*: [Corona-Virus: Aktuelle Informationen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0920/)
* *Alle Pressemeldungen seit dem 2. März 2020*: [Corona-Pressearchiv](https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/)

Diese Daten umfassen:

* SARS-CoV-2-Infektionen (jeweils zum Stand des vorherigen Tages um 16 Uhr):
  * Für den gesamten Landkreis:
    * Infektionen insgesamt (kumuliert), davon:
      * Aktuell Infizierte
      * Geheilte
      * Todesfälle
    * 7-Tage-Inzidenz
    * In Quarantäne befindliche Kontaktpersonen der Kategorie 1
  * Aufgeschlüsselt nach Kommune (nur als Grafik):
    * Infektionen insgesamt (kumuliert), davon:
      * Aktuell Infizierte
      * Geheilte und Todesfälle
* Impfungen *(teils unregelmäßig)*:
  * Kumulative Zahl verabreichter Impfdosen, in der Regel aufgeschlüsselt nach Erst- oder Zweitimpfung, Alter, Indikation (z.B. Pflegeheim)
  * Aktuelle Zahl an Online-Registrierungen über das [Bayerische Impfportal](https://impfzentren.bayern/)
  * Impfstoff-Lieferungen
  * Anrufe bei der Hotline des Impfzentrums

Außerdem werden auf der Seite des Impfzentrums Ebersberg tagesaktuelle Zahlen zu SARS-CoV-2-Impfungen veröffentlicht, jedoch im Gegensatz zu den Pressemitteilungen ohne Archiv:

* [Impfzentrum Ebersberg](https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/)

Diese Daten umfassen:

* Kumulative Zahl verabreichter Impfdosen, aufgeschlüsselt nach Erst- oder Zweitimpfung und Anteil Über-80-Jähriger
* Verfügbarkeit an Impfdosen (nur für die Erstimpfung; Dosen für die Zweitimpfung werden vom Freistaat Bayern vorgehalten):
  * Voraussichtliche nächste Lieferungen
  * Bisher gelieferte Impfdosen, nach Monat aufgeschlüsselt

## Fehlerkorrekturen

### 3./6. April 2020

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

### 7. September 2020

Die kumulative Fallzahl sowie die Zahl aktueller Fälle sinkt zum 7.&nbsp;September jeweils um 1, um dann am folgenden Tag wieder um 1 zu steigen. Vermutlich handelt es sich hier um ein Versehen, deswegen wurde für dieses Projekt die entsprechende Zeile gelöscht.

```diff
 2020-09-03,85,6
 2020-09-06,88,6
-2020-09-07,87,5
 2020-09-08,88,6
```

Denkbar wäre auch, dass am 6.&nbsp;September eine Person fälschlicherweise zu Vaterstetten gezählt und dann am Folgetag Poing, Aßling oder einem anderen Landkreis zugeordnet wurde; zudem wäre dann am 8.&nbsp;September wieder ein neuer Fall in Vaterstetten gemeldet worden. In diesem Fall bewirkt die vorgenommene Fehlerkorrektur lediglich eine Verschiebung der Neuinfektion vom 8. auf den 6.&nbsp; September.
