# Schulen in der Gemeinde Vaterstetten

## [`hgv.csv`](./hgv.csv)

Der Datensatz [hgv.csv](./hgv.csv) umfasst Daten zum [Humboldt-Gymnasium Vaterstetten](https://de.wikipedia.org/wiki/Humboldt-Gymnasium_Vaterstetten) nach Schuljahr.

|Spalte|Format|Beschreibung
|-|-|-
|`Schuljahresbeginn`|integer|Jahr, in dem das Schuljahr begann, z.&nbsp;B. `1999` für das Schuljahr `1999/2000`.
|`Schulleiter`|string|Name des/der Schulleiter:in
|`SchuelerSchuljahresbeginn`|integer|Anzahl Schüler:innen zum Schuljahresbeginn
|`Zugaenge`|integer|Unterjährige Zugänge an Schüler:innen
|`Abgaenge`|integer|Unterjährige Abgänge an Schüler:innen
|`SchuelerSchuljahresende`|integer|Anzahl Schüler:innen zum Schuljahresende
|`SchuelerMaennlich`|integer|Anzahl männlicher Schüler. Stichtag ist möglichst das Schuljahresende, kann aber variieren.
|`SchuelerWeiblich`|integer|Anzahl weiblicher Schülerinnen. Stichtag ist möglichst das Schuljahresende, kann aber variieren.
|`Kommentar`|string|Zusatzinfo zum Schuljahr, die eventuell auch einen Erklärungsansatz für die Schülerzahl bietet.

* `SchuelerSchuljahresbeginn` + `Zugaenge` – `Abgaenge` = `SchuelerSchuljahresende`


### Quellen

* Jahresberichte des Humboldt-Gymnasiums Vaterstetten, zur Verfügung gestellt durch Lehrkräfte und Privatleute.

### Fehlerkorrekturen

#### Schuljahr 1991/1992

Im Jahresbericht ist als Schülerzahl zum Schuljahresbeginn `960` angegeben, die Summe aus den einzelnen Klassenstärken ergibt jedoch `958`. Mit `958` ist die Tabelle aus diesem Jahresbericht wieder in sich stimmig (also `SchuelerSchuljahresbeginn` + `Zugaenge` – `Abgaenge` = `SchuelerSchuljahresende`, sowie `SchuelerMaennlich` + `SchuelerWeiblich` = `SchuelerSchuljahresende` und die Summen aus den Klassenwerten stimmen auch), deshalb wurde der Wert korrigiert.

#### Schuljahr 2005/2006

Im Jahresbericht ist als Schülerzahl zum Schuljahresbeginn `1305` angegeben, die Summe aus den einzelnen Klassenstärken ergibt jedoch `1295`. Mit `1305` ist die Tabelle aus diesem Jahresbericht wieder in sich stimmig (also `SchuelerMaennlich` + `SchuelerWeiblich` = `SchuelerSchuljahresende` und die Summen aus den Klassenwerten stimmen auch), deshalb wurde der Wert korrigiert.
