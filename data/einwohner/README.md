# Bevölkerung der Gemeinde Vaterstetten

## [`lfstatFortschreibungJahre.csv`](./lfstatFortschreibungJahre.csv)

Der Datensatz [lfstatFortschreibungJahre.csv](./lfstatFortschreibungJahre.csv) umfasst die jährliche Bevölkerungsfortschreibung seit 1956. „Fortschreibung“ bedeutet, dass die Bevölkerungszahlen auf Basis eines Anfangswerts (z.&nbsp;B. Volkszählungsergebnis) und anhand der Zu- und Wegzüge sowie der Geburten und Sterbefälle fortgeführt werden.

|Spalte|Format|Beschreibung
|-|-|-
|`stichtag`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Stichtag (31.12. des Jahres)
|`erhebungsart`|text|`fortschreibung`
|`bevoelkerung`|integer|Bevölkerungszahl, d.&nbsp;h. Anzahl der Personen mit Hauptwohnsitz im Gemeindegebiet
|`maennlich`|integer|Männliche Bevölkerung
|`weiblich`|integer|Weibliche Bevölkerung

* `maennlich` + `weiblich` = `bevoelkerung`

### Quellen

- [Bayerisches Landesamt für Statistik](../quellen/LfStat.md): Tabelle 12411-003z



## [`lfstatFortschreibungQuartale.csv`](./lfstatFortschreibungQuartale.csv)

Der Datensatz [lfstatFortschreibungQuartale.csv](./lfstatFortschreibungQuartale.csv) umfasst die quartalsweise Bevölkerungsfortschreibung seit 1971.

|Spalte|Format|Beschreibung
|-|-|-
|`stichtag`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Stichtag (31.3., 30.6., 30.9., bzw. 31.12. des Jahres)
|`erhebungsart`|text|`fortschreibung`
|`bevoelkerung`|integer|Bevölkerungszahl, d.&nbsp;h. Anzahl der Personen mit Hauptwohnsitz im Gemeindegebiet
|`maennlich`|integer|Männliche Bevölkerung
|`weiblich`|integer|Weibliche Bevölkerung

* `maennlich` + `weiblich` = `bevoelkerung`

### Quellen

- [Bayerisches Landesamt für Statistik](../quellen/LfStat.md): Tabelle 12411-009z



## [`lfstatVolkszaehlungen.csv`](./lfstatVolkszaehlungen.csv)

Der Datensatz [lfstatVolkszaehlungen.csv](./lfstatVolkszaehlungen.csv) umfasst die Volkszählungen seit 1840.

|Spalte|Format|Beschreibung
|-|-|-
|`stichtag`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Stichtag
|`erhebungsart`|text|`volkszaehlung`
|`bevoelkerung`|integer|Bevölkerungszahl, d.&nbsp;h. Anzahl der Personen mit Hauptwohnsitz im Gemeindegebiet
|`maennlich`|integer|Männliche Bevölkerung (teilweise `NA`)
|`weiblich`|integer|Weibliche Bevölkerung (teilweise `NA`)

* `maennlich` + `weiblich` = `bevoelkerung`

### Quellen

- [Bayerisches Landesamt für Statistik](../quellen/LfStat.md) (und dessen Vorgängerbehörden):
  - Tabelle 12111-101z (Volkszählungen 1840-1987 außer 1867 und 1910, nur Bevölkerung)
  - Tabelle 12111-103r (Volkszählungen 1970 und 1978, Geschlechter)
  - [Verzeichniß der Gemeinden des Königreichs Bayern nach dem Stande der Bevölkerung im Dezember 1867](https://www.bavarikon.de/object/bav:BSB-MDZ-00000BSB10316430), S. 26, unter „Parsdorf“ (Volkszählung 1867)
  - [Gemeinde-Verzeichnis für das Königreich Bayern nach der Volkszählung vom 1. Dezember 1910 und dem Gebietsstand vom 1. Juli 1911](http://www.literature.at/viewer.alo?objid=10516&viewmode=fullscreen), S. 10, unter „Parsdorf“ (Volkszählung 1910)
  - [Statistik kommunal 2022](https://www.statistik.bayern.de/mam/produkte/statistik_kommunal/2022/09175132.pdf) (Volkszählung 2011)
  - [Zensus 2022](https://www.zensus2022.de) (Volkszählung 2022)



## [`lfstatVorausberechnung2019.csv`](./lfstatVorausberechnung2019.csv)

Der Datensatz [lfstatVorausberechnung2019.csv](./lfstatVorausberechnung2019.csv) umfasst vorausberechnete Bevölkerungszahlen bis 2033 auf Basis des Jahres 2019.

Siehe [../quellen/LfStat.md#Vorausberechnung](../quellen/LfStat.md#Vorausberechnung) für Details.

|Spalte|Format|Beschreibung
|-|-|-
|`stichtag`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Stichtag
|`erhebungsart`|text|`volkszaehlung`
|`bevoelkerung`|integer|Bevölkerungszahl, d.&nbsp;h. Anzahl der Personen mit Hauptwohnsitz im Gemeindegebiet
|`maennlich`|integer|Männliche Bevölkerung (teilweise `NA`)
|`weiblich`|integer|Weibliche Bevölkerung (teilweise `NA`)

* `maennlich` + `weiblich` = `bevoelkerung`

### Quellen

- [Bayerisches Landesamt für Statistik](../quellen/LfStat.md): Tabelle 12421-102z
