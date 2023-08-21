# ArcGIS-API des Landratsamtes Ebersberg

Das [Covid-19 Dashboard Ebersberg](https://experience.arcgis.com/experience/dc7f97a7874b47aebf1a75e74749c047) des Landkreises Ebersberg benutzt als Backend eine ArcGIS REST API: https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services

Mittlerweile wird diese API auch für andere Zwecke benutzt.

Diese API beinhaltet folgende Tabellen (sog. *FeatureServer*):

- **Basisdaten**:
  - `EBE_Gemeindegrenzen_2018_mit_Einwohnerzahl`: Grenzen und Einwohner der Landkreisgemeinden, wird aktualisiert
  - `Ebersberg_Gemeindegrenzen`: Grenzen und Einwohner der Landkreisgemeinden, Stand 2021
- **SARS-CoV-2-Pandemie**:
  - Gemeldete Infektionen:
    - `EBE_Landkreis_Inzidenztabelle`: Neuinfektionen im Landkreis, 2020-03-02 bis 2023-06-10
    - ~~`EBE_Gemeinden_Inzidenztabelle_3`: Neuinfektionen im Landkreis, nach Gemeinde aufgeschlüsselt~~ (gelöscht)
    - ~~`EBE_grenzen_und_inzidentabelle3`: wie `EBE_Gemeinden_Inzidenztabelle_3`, aber mit Gebietsgröße~~ (gelöscht)
    - ~~`Sicht_EBE_Gemeinden_mit_Inzidenzen_aktuell_3`: wie `EBE_grenzen_und_inzidentabelle3`, aber mit Gebiet als Polygon und nur für den aktuellen Tag~~ (gelöscht)
    - ~~`EBE_Altersgruppen_Inzidenztabelle`: Neuinfektionen im Landkreis, nach Alter aufgeschlüsselt~~ (gelöscht)
    - ~~`Mutationen_Quarantaene`: einzelne Fälle mit Virusvariante und Isolationsende~~ (gelöscht)
    - `CoronaIndexListe_Gemeinde`: einzelne Fälle mit Meldedatum, Geburtsjahr und Ort, zwischen 2021-01-02 und 2021-04-21
    - `CoronaIndexListe_21_04_2021_Gemeinde_GebJahr`: einzelne Fälle mit Meldedatum, Geburtsjahr und Gemeinde, zwischen 2021-01-02 und 2021-04-21
  - Abwassermessung:
    - `Abwasser_Monitoring_VIEW`: Messungen nach Gemeinde, Entnahmen von 2021-06-30 bis 2023-03-23
    - `Offentlich_Auswertung_Abwasser_VIEW`: Wöchentliche Zusammenfassung der Messungen mit qualitativem Trend und Kommentar, seit 2022-04-17
    - `Abwassermonitoring_LK_EBE_Entnahmestellen_Dashboard`: Entnahmestellen
    - ~~`Kanalnetz_EGG`: Abwasserkanalnetz~~ (gelöscht)
    - ~~`Join_Survey_EBE_Landkreis_Inzidenztabelle`: Join aus `Abwasser_Monitoring_VIEW` und `EBE_Landkreis_Inzidenztabelle`~~ (gelöscht)
    - ~~`Join_Survey_EBE_Gemeinden_Inzidenztabelle_3`: Join aus `Abwasser_Monitoring_VIEW` und `EBE_Gemeinden_Inzidenztabelle_3`~~ (gelöscht)
  - Impfungen:
    - ~~`Covid19_Impfmeldungen_Öffentlich`: Impfungen nach Einrichtung, sowie für das Impfzentrum auch nach Geschlecht und Altersgruppen, 2021-04-21 bis 2023-02-09~~ (gelöscht)
    - `EBE_Gesamtsummen_Impfmeldungen_Öffentlich`: Impfungen gesamt, 2021-04-21 bis 2023-02-09
- **Ukraine-Krise**:
  - ~~`Unterkunft_Angebot_view_public`: Unterkunftsmeldungen für ukrainische Flüchtlinge~~ (gelöscht)
- **Schulen (des Landkreises)**:
  - `service_f197ad656f8e485c93b5191f14f9600d`: Basisinfos zu den Schulen
  - `Herkunft`: Schülerzahlen nach Schule und Wohnort, 2019–2021
  - `Gebiete_und_Herkunft_(View)`: wie `Herkunft`, aber mit Gebiet als Polygon
  - `service_a22606ef95d34115b9b209cc73bd6c55`: Schülerzahlen nach Schule und Jahr, 2003–2035, ab 2022 Prognose
  - `Ganztagesgruppen`: Anzahl Ganztagesklassen (aufgeschlüsselt nach gGTS, OGTS in der Primarstufe und OGTS in der Sekundarstufe) nach Schule und Jahr, seit 2009
  - `Bruckenklassen`: Anzahl Brückenklassen nach Schule und Jahr, seit 2022


Dokumentation zur Benutzung von ArcGIS REST API Feature Services: https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-.htm

Und Benutzung in Python: https://developers.arcgis.com/python/guide/working-with-feature-layers-and-features/
