## SARS-CoV-2-Fallzahlen des Gesundheitsamtes Ebersberg

Das Gesundheitsamt veröffentlicht an jedem Werktag aktuelle Zahlen zu SARS-CoV-2-Infektionen, jeweils zum Stand des vorherigen Tages um 16 Uhr. Diese Daten umfassen:

* Für den gesamten Landkreis:
  * Infektionen insgesamt (kumuliert), davon:
    * Aktuell Infizierte
    * Geheilte
    * Todesfälle
  * 7-Tage-Inzidenz
  * In Quarantäne befindliche Kontaktpersonen der Kategorie 1
  * *(unregelmäßig)* Anzahl Erst- und Zeitimpfungen
* Aufgeschlüsselt nach Kommune (nur als Grafik):
  * Infektionen insgesamt (kumuliert), davon:
    * Aktuell Infizierte
    * Geheilte und Todesfälle

Der Datensatz [fallzahlenVat.csv](./fallzahlenVat.csv) umfasst die händisch übertragenen kumulierten und aktuellen Infektionen in Vaterstetten.

### Datenquellen

* *Ab 2021*: [Corona-Virus: Aktuelle Pressemeldungen](https://lra-ebe.de/aktuelles/aktuelle-meldungen/corona-virus-aktuelle-pressemeldungen-0121/)
* *2. März 2020 bis 31. Dezember 2020*: [Corona-Pressearchiv](https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/corona-pressearchiv/)

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
