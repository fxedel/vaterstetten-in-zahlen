# Energiedaten der Gemeinde Vaterstetten

## [`mastrPhotovoltaik.csv`](./mastrPhotovoltaik.csv)

Der Datensatz [mastrPhotovoltaik.csv](./mastrPhotovoltaik.csv) umfasst sämtliche Photovoltaik-Anlagen in der Gemeinde Vaterstetten, die im [Marktstammdatenregister](https://www.marktstammdatenregister.de) erfasst sind.

|Spalte|Format|Beschreibung
|-|-|-
|`MaStRId`|integer|ID der Anlage im Marktstammdatenregister. Wird u.&nbsp;a. in der URL der Detailansicht verwendet, z.&nbsp;B. mit ID [1954768](https://www.marktstammdatenregister.de/MaStR/Einheit/Detail/IndexOeffentlich/1954768).
|`MaStRNummer`|`SEE[0-9]{12}`|Öffentliche Kennnummer der Anlage im Markstammdatenregister: `SEE` gefolgt von einer zwölf-stelligen Ziffer, z.&nbsp;B. `SEE943971188158`.
|`EEGAnlagenschluessel`|`E[0-9A-Z]{32}`|EEG-Anlagenschlüssel, falls es sich um eine EEG-Anlage handelt: `E` gefolgt von einer 32-stelligen Kombination aus Zahlen und Buchstaben (siehe unten für Details).
|`status`|text|`In Planung`, `In Betrieb`, `Vorübergehend stillgelegt` oder `Endgültig stillgelegt`.
|`registrierungMaStR`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Registrierung der Anlage im Marktstammdatenregister. Dies kann weit vor oder weit nach Inbetriebnahme der Anlage sein. Die früheste Registrierung erfolgte 2019, während die älteste Anlage 2000 in Betrieb genommen wurde.
|`inbetriebnahme`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tatsächliche Inbetriebnahme der Anlage. Ist bei `status`=`In Planung` meist leer, da ist allerdings `inbetriebnahmeGeplant` gesetzt.
|`inbetriebnahmeGeplant`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Geplante Inbetriebnahme der Anlage falls `status`=`In Planung`.
|`stilllegung`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Endgültige Stilllegung der Anlage falls `status`=`Endgültig stillgelegt`.
|`name`|text|Angegebener Name der PV-Anlage (nur bei Organisationen oder größeren Anlagen)
|`betreiber`|text|Betreiber der PV-Anlage (nur bei Organisationen oder größeren Anlagen)
|`plz`|`[0-9]{5}`|Standort: Postleitzahl
|`ort`|text|Standort: Ortsname (`Baldham`, `Vaterstetten`, `Weißenfeld`, `Hergolding`, `Parsdorf`, `Purfing` oder `Neufarn`)
|`strasse`|text|Standort: Straßenname (nur bei größeren Anlagen)
|`hausnummer`|text|Standort: Hausnummer (nur bei größeren Anlagen)
|`lat`|float|Standort: Breitengrad, z.&nbsp;B. `48.11154` (nur bei größeren Anlagen)
|`long`|float|Standort: Längengrad, z.&nbsp;B. `11.778989` (nur bei größeren Anlagen)
|`netzbetreiberPruefung`|`true`/`false`|Ob die Netzbetreiberprüfung bereits erfolgt ist.
|`typ`|text|Art der Installation: `freiflaeche`, `gebaeude`, `gebaeude-other` oder `stecker` (für Steckersolaranlage/„Balkonkraftwerke“)
|`module`|integer|Anzahl der Photovoltaikmodule
|`ausrichtung`|text|Hauptausrichtung der Photovoltaikmodule, z.&nbsp;B. `Nord`, `Nord-Ost`, `Ost`, `Ost-West`, `Süd-Ost`, `Süd`, `Süd-West`, `West`, `Nord-West`, `nachgeführt`
|`bruttoleistung_kW`|float|Bruttoleistung in Kilowatt-Peak. Dies entspricht der Summe der Modulleistungen.
|`nettonennleistung_kW`|float|Nettonennleistung in Kilowatt-Peak. Dies entspricht dem kleineren Wert aus Wechselrichterleistung und Summe der Modulleistungen.
|`EEGAusschreibung`|`true`/`false`|Ob an einer EEG-Ausschreibung teilgenommen wurde (nur bei sehr großen Anlagen).
|`einspeisung`|text|Umfang der Einspeisung: `Teileinspeisung` oder `Volleinspeisung`
|`mieterstrom`|`true`/`false`|Ob es sich um einer Mieterstrom-Anlage handelt.

* `nettonennleistung_kW` ≤ `bruttoleistung_kW`


### EEG-Anlagenschlüssel

Der 33-stellige EEG-Anlagenschlüssel setzt sich wie folgt zusammen:

- 1\. Zeichen: `E` für „Erzeugungsanlage aus Erneuerbaren Energien“
- 2\. Zeichen: Regelzone, in Vaterstetten ist dies `2` für TenneT.
- 3.-6. Zeichen: Die vier letzten Ziffern der Betriebsnummer des Netzbetreibers. Für Vaterstetten ist das:
  - `1875` (bis 2008, für E.ON Bayern Netz GmbH mit Betriebsnummer 10001875)
  - `1041` (seit 2009, für E.ON Bayern AG mit Betriebsnummer 10001041, mittlerweile Bayernwerk Netz GmbH)
- 7.-8. Zeichen: Netznummer, dies ist in Vaterstetten stets `01`.
- 9.-33. Zeichen: Steht dem Netzbetreiber frei zur Verfügung. Üblich sind Zahlen und Großbuchstaben, es sind aber wohl auch Kleinbuchstaben und einige Zeichen aus dem ASCII-Standard zulässig, wobei der EEG-Anlagenschlüssel unabhängig von Groß-/Kleinschreibung eindeutig sein muss (_case-insensitive uniqueness_).

Für Netzbetreiber mit einer Betriebsnummer >10009999 unterscheidet sich das Format dadurch, dass an 3. Stelle ein `X` eingefügt und die letzten fünf Ziffern der Betriebsnummer verwendet werden, wodurch zwei Zeichen weniger zur freien Verfügung stehen.

Siehe auch:
- „Regeln für die Generierung von eindeutigen EEG-Anlagenschlüsseln durch die Anschlussnetzbetreiber“, Bundesverband für Energie- und Wasserwirtschaft e.&nbsp;V. (BDEW), 24. September 2020, https://www.bdew.de/media/documents/2020-09-24_Erg%C3%A4nzung-zu-Umsetzungshilfe-EEG-2017_Generierung-EEG-Anlagenschl%C3%BCssel.pdf
- „Die Zusammensetzung des EEG-Anlagenschlüssel“, kinewables GmbH, 27. November 2018, https://www.kinewables.de/news-termine/aktuelles-detail/die-zusammensetzung-des-eeg-anlagenschluessel.html

### Quellen und Lizenz

- [Marktstammdatenregister der Bundesnetzagentur](../quellen/MaStR.md), JSON-Endpunkt `GetErweiterteOeffentlicheEinheitStromerzeugung`



## [`mastrSpeicher.csv`](./mastrSpeicher.csv)

Der Datensatz [mastrSpeicher.csv](./mastrSpeicher.csv) umfasst sämtliche Stromspeicher in der Gemeinde Vaterstetten, die im [Marktstammdatenregister](https://www.marktstammdatenregister.de) erfasst sind.

|Spalte|Format|Beschreibung
|-|-|-
|`MaStRId`|integer|ID der Anlage im Marktstammdatenregister. Wird u.&nbsp;a. in der URL der Detailansicht verwendet, z.&nbsp;B. mit ID [1956745](https://www.marktstammdatenregister.de/MaStR/Einheit/Detail/IndexOeffentlich/1956745).
|`MaStRNummer`|`SEE[0-9]{12}`|Öffentliche Kennnummer der Anlage im Markstammdatenregister: `SEE` gefolgt von einer zwölf-stelligen Ziffer, z.&nbsp;B. `SEE943971188158`.
|`status`|text|`In Planung`, `In Betrieb`, `Vorübergehend stillgelegt` oder `Endgültig stillgelegt`.
|`registrierungMaStR`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Registrierung der Anlage im Marktstammdatenregister. Dies kann weit vor oder weit nach Inbetriebnahme der Anlage sein. Die früheste Registrierung erfolgte 2019, während die älteste Anlage 2014 in Betrieb genommen wurde.
|`inbetriebnahme`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Tatsächliche Inbetriebnahme der Anlage. Ist bei `status`=`In Planung` meist leer, da ist allerdings `inbetriebnahmeGeplant` gesetzt.
|`inbetriebnahmeGeplant`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Geplante Inbetriebnahme der Anlage falls `status`=`In Planung`.
|`stilllegung`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Endgültige Stilllegung der Anlage falls `status`=`Endgültig stillgelegt`.
|`name`|text|Angegebener Name der Anlage (nur bei Organisationen oder größeren Anlagen)
|`betreiber`|text|Betreiber der Anlage (nur bei Organisationen oder größeren Anlagen)
|`plz`|`[0-9]{5}`|Standort: Postleitzahl
|`ort`|text|Standort: Ortsname (`Baldham`, `Vaterstetten`, `Weißenfeld`, `Hergolding`, `Parsdorf`, `Purfing` oder `Neufarn`)
|`strasse`|text|Standort: Straßenname (nur bei größeren Anlagen)
|`hausnummer`|text|Standort: Hausnummer (nur bei größeren Anlagen)
|`lat`|float|Standort: Breitengrad, z.&nbsp;B. `48.11154` (nur bei größeren Anlagen)
|`long`|float|Standort: Längengrad, z.&nbsp;B. `11.778989` (nur bei größeren Anlagen)
|`netzbetreiberPruefung`|`true`/`false`|Ob die Netzbetreiberprüfung bereits erfolgt ist.
|`batterietechnologie`|text|Batterietechnologie: `Blei`, `Hochtemperatur`, `Lithium`, `Nickel-Cadmium / Nickel-Metallhydrid`, `Redox-Flow` oder `Sonstige`
|`bruttoleistung_kW`|float|Maximale Entladeleistung im Dauerbetrieb.
|`nettonennleistung_kW`|float|Nettonennleistung in Kilowatt. Dies entspricht dem kleineren Wert aus Wechselrichterleistung und Entladeleistung.
|`kapazitaet_kWh`|float|Speicherkapazität in Kilowattstunden.
|`einspeisung`|text|Umfang der Einspeisung: `Teileinspeisung` oder `Volleinspeisung`
|`istNotstromaggregat`|`true`/`false`|Ob die Anlage als Notstromaggregat verwendet wird, d.&nbsp;h. zur Versorgung bei Stromnetzstörungen dient.

* `nettonennleistung_kW` ≤ `bruttoleistung_kW`


### Quellen und Lizenz

- [Marktstammdatenregister der Bundesnetzagentur](../quellen/MaStR.md), JSON-Endpunkt `GetErweiterteOeffentlicheEinheitStromerzeugung`



## [`bayernwerkEnergiemonitorLandkreis.csv`](./bayernwerkEnergiemonitorLandkreis.csv)

Der Datensatz [bayernwerkEnergiemonitorLandkreis.csv](./bayernwerkEnergiemonitorLandkreis.csv) umfasst Tagesdaten zu Stromverbrauch und -erzeugung im Landkreis Ebersberg.

|Spalte|Format|Beschreibung
|-|-|-
|`datum`|[ISO 8601](https://de.wikipedia.org/wiki/ISO_8601), `YYYY-MM-DD`|Datum
|`verbrauch_kWh`|float|Gesamter Stromverbrauch
|`verbrauchPrivat_kWh`|float|Stromverbrauch Private Haushalte
|`verbrauchGewerbe_kWh`|float|Stromverbrauch Industrie und Gewerbe
|`verbrauchOeffentlich_kWh`|float|Stromverbrauch öffentliche / kommunale Anlagen
|`erzeugung_kWh`|float|Gesamte Stromerzeugung
|`erzeugungErneuerbar_kWh`|float|Gesamte erneuerbare Stromerzeugung
|`erzeugungBiomasse_kWh`|float|Stromerzeugung Biomasse / Biogas
|`erzeugungSolar_kWh`|float|Stromerzeugung Solar (Photovoltaik). Daten erst seit 2022-11-16 vorhanden.
|`erzeugungWasserkraft_kWh`|float|Stromerzeugung Wasserkraft
|`erzeugungWind_kWh`|float|Stromerzeugung Windkraft. Daten erst seit 2022-11-16 vorhanden.
|`erzeugungAndere_kWh`|float|Stromerzeugung weiterer Erzeuger (i.&nbsp;A. nicht erneuerbar)
|`netzeinspeisung_kWh`|float|Netzeinspeisung (d.&nbsp;h. wenn im Landkreis mehr Strom erzeugt wird, als verbraucht werden kann) 
|`netzbezug_kWh`|float|Netzbezug (d.&nbsp;h. wenn im Landkreis mehr Strom verbraucht wird, als erzeugt werden kann) 
|`ueberschuss`|float|Genaue Funktion unbekannt, Rohname `energyExcessCounter` lässt auf Anzahl Stromüberschüsse vermuten. Bislang immer 0.

* `verbrauch_kWh` = `verbrauchPrivat_kWh` + `verbrauchGewerbe_kWh` + `verbrauchOeffentlich_kWh`
* `erzeugung_kWh` = `erzeugungErneuerbar_kWh` + `erzeugungAndere_kWh`
* `erzeugungErneuerbar_kWh` = `erzeugungBiomasse_kWh` + `erzeugungSolar_kWh` + `erzeugungWasserkraft_kWh` + `erzeugungWind_kWh`


### Quellen und Lizenz

- BayernWerk Netz GmbH: [Energiemonitor Landkreis Ebersberg](https://energiemonitor.bayernwerk.de/ebersberg-landkreis)
  - API-Endpunkt [https://api-energiemonitor.eon.com/historic-data?regionCode=09175]
