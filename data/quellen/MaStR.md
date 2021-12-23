# Marktstammdatenregister

Das [Marktstammdatenregister](https://www.marktstammdatenregister.de) (MaStR) ist ein Register der Bundesnetzagentur aller Anlagen und Einheiten in deutschen Energiesystem.

Die öffentlich zugänglichen Daten stehen unter der [Datenlizenz Deutschland – Namensnennung – Version 2.0](https://www.govdata.de/dl-de/by-2-0), die insbesondere Nutzung, Veränderung und Vervielfältigung erlaubt, solange ein Quellenvermerk erfolgt.

Der Abruf der Daten erfolgt auf der Webseite des Marktstammdatenregisters per JavaScript über eine JSON-API. Der CSV-Export erfolgt client-seitig auf Basis dieser Daten, ebenfalls per JavaScript.

## JSON-API

Die Basis-URL der API lautet: https://www.marktstammdatenregister.de/MaStR

Sämtliche Endpunkte können einfach per GET-Request des entsprechenden Pfads abgerufen werden, ggf. mit zusätzlichen Query-Parametern.

### Endpunkte

* `Einheit`
  * `EinheitJson`
    * [`GetVerkleinerteOeffentlicheEinheitStromerzeugung`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetVerkleinerteOeffentlicheEinheitStromerzeugung?filter=): Einheiten zur Stromerzeugung (nur Auswahl an Attributen)
    * [`GetErweiterteOeffentlicheEinheitStromerzeugung`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetErweiterteOeffentlicheEinheitStromerzeugung?filter=): Einheiten zur Stromerzeugung (alle Attribute)
    * [`GetVerkleinerteOeffentlicheEinheitStromverbrauch`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetVerkleinerteOeffentlicheEinheitStromverbrauch?filter=): Einheiten zum Stromverbrauch (nur Auswahl an Attributen)
    * [`GetErweiterteOeffentlicheEinheitStromverbrauch`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetErweiterteOeffentlicheEinheitStromverbrauch?filter=): Einheiten zum Stromverbrauch (alle Attribute)
    * [`GetVerkleinerteOeffentlicheEinheitGaserzeugung`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetVerkleinerteOeffentlicheEinheitGaserzeugung?filter=): Einheiten zur Gaserzeugung (nur Auswahl an Attributen)
    * [`GetErweiterteOeffentlicheEinheitGaserzeugung`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetErweiterteOeffentlicheEinheitGaserzeugung?filter=): Einheiten zur Gaserzeugung (alle Attribute)
    * [`GetVerkleinerteOeffentlicheEinheitGasverbrauch`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetVerkleinerteOeffentlicheEinheitGasverbrauch?filter=): Einheiten zum Gasverbrauch (nur Auswahl an Attributen)
    * [`GetErweiterteOeffentlicheEinheitGasverbrauch`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetErweiterteOeffentlicheEinheitGasverbrauch?filter=): Einheiten zum Gasverbrauch (alle Attribute)
    * [`GetGeloeschteUndDeaktivierteEinheiten`](https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetGeloeschteUndDeaktivierteEinheiten?filter=): Gelöschte und deaktivierte Einheiten
  * `NetzanschlusspunkteUndLokationenJson`
    * [`GetOeffentlicheNetzanschlusspunkteUndLokationenStromerzeugung`](https://www.marktstammdatenregister.de/MaStR/Einheit/NetzanschlusspunkteUndLokationenJson/GetOeffentlicheNetzanschlusspunkteUndLokationenStromerzeugung?filter=)
    * [`GetOeffentlicheNetzanschlusspunkteUndLokationenStromverbrauch`](https://www.marktstammdatenregister.de/MaStR/Einheit/NetzanschlusspunkteUndLokationenJson/GetOeffentlicheNetzanschlusspunkteUndLokationenStromverbrauch?filter=)
    * [`GetOeffentlicheNetzanschlusspunkteUndLokationenGaserzeugung`](https://www.marktstammdatenregister.de/MaStR/Einheit/NetzanschlusspunkteUndLokationenJson/GetOeffentlicheNetzanschlusspunkteUndLokationenGaserzeugung?filter=)
    * [`GetOeffentlicheNetzanschlusspunkteUndLokationenGasverbrauch`](https://www.marktstammdatenregister.de/MaStR/Einheit/NetzanschlusspunkteUndLokationenJson/GetOeffentlicheNetzanschlusspunkteUndLokationenGasverbrauch?filter=)
* `Akteur`
  * `MarktakteurJson`
    * [`GetMarktakteure`](https://www.marktstammdatenregister.de/MaStR/Akteur/MarktakteurJson/GetMarktakteure?filter=): Marktakteure des aktuell eingeloggten Benutzers (über Cookie)
    * [`GetOeffentlicheMarktakteure`](https://www.marktstammdatenregister.de/MaStR/Akteur/MarktakteurJson/GetOeffentlicheMarktakteure?filter=): Alle öffentlichen Marktakteure

### Query-Parameter

|Parameter|Pflicht|Beschreibung
|-|-|-
|`filter`|notwendig|Filter-Kriterium, z.&nbsp;B. `filter=Gemeinde~eq~'Vaterstetten'~and~Energieträger~eq~'2495'`. Kann auch leer gelassen werden (`filter=`). Die Filter-Bedingungen entsprechen denen der jQuery-Library [evoluteur/structured-filter](https://github.com/evoluteur/structured-filter#conditions).
|`pageSize`|optional|Anzahl der zurückzugebenden Elemente pro Seite. Standardmäßig 10, maximal 5000.
|`page`|optional|Wenn die Anzahl der Elemente größer als `pageSize`, kann mit `page=2`, … auf die folgenden Elemente zugegriffen werden. Die Zählung beginnt bei 1, Standardwert ist 1.
|`sort`|optional|Sortierung der Elemente nach einem Attribut, z.&nbsp;B. `sort=Bruttoleistung-desc`.
|`group`|optional|Unbekannte Funktion, wird in der Web-Oberfläche meist leer gelassen (`group=`).
