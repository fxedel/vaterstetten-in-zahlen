# Verkehr in der Gemeinde Vaterstetten

## [`osmStrassen.csv`](./osmStrassen.csv)

Der Datensatz [osmStrassen.csv](./osmStrassen.csv) umfasst sämtliche benannten Straßen und Wege in der Gemeinde Vaterstetten, die in [OpenStreetMap](https://www.openstreetmap.org/relation/929822) (OSM) erfasst sind. Straßen, die zwar gleich benannt sind, aber offensichtlich nicht zusammengehören (z.&nbsp;B. durch unterschiedliche Postleitzahlen, Ortsteile), werden getrennt aufgeführt.

|Spalte|Format|Beschreibung
|-|-|-
|`Name`|text|Offizieller Straßenname. Entspricht dem OSM-Tag `name`.
|`NamensherkunftWikidata`|`Q[0-9]+`, mehrere Werte mit `/` getrennt|Namensherkunft als Wikidata-ObjektID, z.&nbsp;B. [`Q115460896`](https://www.wikidata.org/wiki/Q115460896). Entspricht dem OSM-Tag [`name:etymology:wikidata`](https://wiki.openstreetmap.org/wiki/Key:name:etymology:wikidata).
|`Postleitzahl`|`[0-9]{5}`, mehrere Werte mit `/` getrennt|Postleitzahlgebiete, in denen die Straße liegt. Nur die Vaterstettener Postleitzahlen werden berücksichtigt: 85591 (Vaterstetten), 85598 (Baldham), 85599 (Parsdorf, Hergolding), 85622 (Weißenfeld), 85646 (Neufarn, Purfing)
|`OSMWayIDs`|integer, mehrere Werte mit `/` getrennt|IDs der Wege (_ways_) in OSM, die zu dieser Straße gehören, z.&nbsp;B. [`25028199`](https://www.openstreetmap.org/way/25028199)/[`51818365`](https://www.openstreetmap.org/way/51818365). Diese sind meist, aber nicht immer miteinander verbunden.
|`Geometry`|[Simple Feature MultiLineString](https://de.wikipedia.org/wiki/Simple_Feature_Access)|Geometrie der Straße als Liste von Pfaden; entspricht den OSM-Wegen.

### Quellen und Lizenz

- Datenquelle: [OpenStreetMap](https://www.openstreetmap.org) (OSM)
  - Copyright: [openstreetmap.org/copyright](https://openstreetmap.org/copyright), [Open Data Commons Open Database License](https://opendatacommons.org/licenses/odbl/) (ODbL)
  - Datenabruf über die [Overpass API](https://overpass-api.de/)
- Dieser Datensatz unterliegt somit ebenfalls der [Open Data Commons Open Database License](https://opendatacommons.org/licenses/odbl/) (ODbL)


## [`wikidataNamensherkuenfte.csv`](./wikidataNamensherkuenfte.csv)

Der Datensatz [osmStrassen.csv](./osmStrassen.csv) umfasst diejenigen [Wikidata](https://www.wikidata.org)-Datenobjekte, die in [OpenStreetMap](https://www.openstreetmap.org/relation/929822) als Namensherkunft ([`name:etymology:wikidata`](https://wiki.openstreetmap.org/wiki/Key:name:etymology:wikidata)) einer Straße in der Gemeinde Vaterstetten referenziert sind (siehe [`osmStrassen.csv`](./osmStrassen.csv)).

|Spalte|Format|Beschreibung
|-|-|-
|`WikidataObjekt`|`Q[0-9]+`|Wikidata-ObjektID, z.&nbsp;B. [`Q115460896`](https://www.wikidata.org/wiki/Q115460896).
|`Bezeichnung`|text|Deutschsprachige Bezeichnung aus Wikidata
|`Beschreibung`|text|Deutschsprachige Beschreibung aus Wikidata
|`Typ`|text|Kategorisierung der Straßenbenennung. Dieser erfolgt durch Vaterstetten in Zahlen und ist Vaterstetten-spezifisch (z.&nbsp;B. Typ `Komponisten`)
|`Geschlecht`|text, meist `maennlich` oder `weiblich`|Geschlecht, falls Objekt eine Person ist.

### Quellen und Lizenz

- Liste der Wikidata-ObjektIDs: [OpenStreetMap](https://www.openstreetmap.org) (OSM)
  - Copyright: [openstreetmap.org/copyright](https://openstreetmap.org/copyright), [Open Data Commons Open Database License](https://opendatacommons.org/licenses/odbl/) (ODbL)
  - Datenabruf über die [Overpass API](https://overpass-api.de/)
  - siehe [`osmStrassen.csv`](./osmStrassen.csv)
- [Wikidata](https://www.wikidata.org)
  - Copyright: [Creative Commons Zero (CC0)](https://creativecommons.org/about/cc0)
  - Datenabruf über die [SPARQL API](https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service)
