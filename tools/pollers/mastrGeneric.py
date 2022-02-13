from datetime import datetime
import re

from pollers.poller import *

class MastrGenericPoller(Poller):
  # see https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetFilterColumnsErweiterteOeffentlicheEinheitStromerzeugung

  ENERGIETRAEGER_ANDERE_GASE_ID = 2411
  ENERGIETRAEGER_BIOMASSE_ID = 2493
  ENERGIETRAEGER_BRAUNKOHLE_ID = 2408
  ENERGIETRAEGER_DRUCK_AUS_GASLEITUNGEN_ID = 2957
  ENERGIETRAEGER_DRUCK_AUS_WASSERLEITUNGEN_ID = 2958
  ENERGIETRAEGER_ERDGAS_ID = 2410
  ENERGIETRAEGER_GEOTHERMIE_ID = 2403
  ENERGIETRAEGER_GRUBENGAS_ID = 2406
  ENERGIETRAEGER_KERNENERGIE_ID = 2494
  ENERGIETRAEGER_KLAERSCHLAMM_ID = 2405
  ENERGIETRAEGER_MINEARALOELPRODUKTE_ID = 2409
  ENERGIETRAEGER_NICHT_BIOGENER_ABFALL_ID = 2412
  ENERGIETRAEGER_SOLARE_STRAHLUNGSENERGIE_ID = 2495
  ENERGIETRAEGER_SOLARTHERMIE_ID = 2404
  ENERGIETRAEGER_SPEICHER_ID = 2496
  ENERGIETRAEGER_STEINKOHLE_ID = 2407
  ENERGIETRAEGER_WAERME_ID = 2413
  ENERGIETRAEGER_WASSER_ID = 2498
  ENERGIETRAEGER_WIND_ID = 2497

  BATTERIETECHNOLOGIE_BLEI = 'Blei'
  BATTERIETECHNOLOGIE_HOCHTEMPERATUR = 'Hochtemperatur'
  BATTERIETECHNOLOGIE_LITHIUM = 'Lithium'
  BATTERIETECHNOLOGIE_NICKEL = 'Nickel-Cadmium / Nickel-Metallhydrid'
  BATTERIETECHNOLOGIE_REDOX_FLOW = 'Redox-Flow'
  BATTERIETECHNOLOGIE_SONSTIGE = 'Sonstige'

  BATTERIETECHNOLOGIE_BY_ID = {
    728: BATTERIETECHNOLOGIE_BLEI,
    730: BATTERIETECHNOLOGIE_HOCHTEMPERATUR,
    727: BATTERIETECHNOLOGIE_LITHIUM,
    731: BATTERIETECHNOLOGIE_NICKEL,
    729: BATTERIETECHNOLOGIE_REDOX_FLOW,
    732: BATTERIETECHNOLOGIE_SONSTIGE,
  }

  HAUPTNEIGUNGSWINKEL_BIS_20 = "<20°"
  HAUPTNEIGUNGSWINKEL_20_BIS_40 = "20-40°"
  HAUPTNEIGUNGSWINKEL_40_BIS_60 = "40-60°"
  HAUPTNEIGUNGSWINKEL_AB_60 = ">60°"
  HAUPTNEIGUNGSWINKEL_FASSADE = "fassadenintegriert"
  HAUPTNEIGUNGSWINKEL_NACHGEFUEHRT = "nachgefuehrt"

  HAUPTNEIGUNGSWINKEL_BY_ID = {
    810: HAUPTNEIGUNGSWINKEL_BIS_20,
    809: HAUPTNEIGUNGSWINKEL_20_BIS_40,
    808: HAUPTNEIGUNGSWINKEL_40_BIS_60,
    807: HAUPTNEIGUNGSWINKEL_AB_60,
    806: HAUPTNEIGUNGSWINKEL_FASSADE,
    811: HAUPTNEIGUNGSWINKEL_NACHGEFUEHRT,
  }
  
  LAGE_FREIFLAECHE = "freiflaeche" # Freifläche 
  LAGE_GEBAEUDE = "gebaeude" # Bauliche Anlagen (Hausdach, Gebäude und Fassade)
  LAGE_GEBAEUDE_OTHER = "gebaeude-other" # Bauliche Anlagen (Sonstige)
  LAGE_STECKER = "stecker" # Steckerfertige Erzeugungsanlage (sog. Plug-In- oder Balkon-PV-Anlage)
  LAGE_WINDKRAFT_LAND = "windkraft-land" # Windkraft an Land
  LAGE_WINDKRAFT_SEE = "windkraft-see" # Windkraft auf See

  LAGE_BY_ID = {
    852: LAGE_FREIFLAECHE,
    853: LAGE_GEBAEUDE,
    2484: LAGE_GEBAEUDE_OTHER,
    2961: LAGE_STECKER,
    888: LAGE_WINDKRAFT_LAND,
    889: LAGE_WINDKRAFT_SEE,
  }

  LEISTUNGSBEGRENZUNG_50 = "50%"
  LEISTUNGSBEGRENZUNG_60 = "60%"
  LEISTUNGSBEGRENZUNG_70 = "70%"
  LEISTUNGSBEGRENZUNG_SONSTIGE = "sonstige"
  LEISTUNGSBEGRENZUNG_OHNE = "ohne"

  LEISTUNGSBEGRENZUNG_BY_ID = {
    805: LEISTUNGSBEGRENZUNG_50,
    804: LEISTUNGSBEGRENZUNG_60,
    803: LEISTUNGSBEGRENZUNG_70,
    1535: LEISTUNGSBEGRENZUNG_SONSTIGE,
    802: LEISTUNGSBEGRENZUNG_OHNE
  }

  NETZBETREIBERPRUEFUNG_GEPRUEFT_ID = 2954
  NETZBETREIBERPRUEFUNG_IN_PRUEFUNG_ID = 2955

  NUTZUNGSBEREICH_GHD = "GHD" # Gewerbe, Handel, Dienstleistungen
  NUTZUNGSBEREICH_HAUSHALT = "haushalt"
  NUTZUNGSBEREICH_INDUSTRIE = "industrie"
  NUTZUNGSBEREICH_LANDWIRTSCHAFT = "landwirtschaft"
  NUTZUNGSBEREICH_OEFFENTLICH = "oeffentlich" # Öffentliches Gebäude
  NUTZUNGSBEREICH_SONSTIGE = "sonstige"

  NUTZUNGSBEREICH_BY_ID = {
    714: NUTZUNGSBEREICH_GHD,
    713: NUTZUNGSBEREICH_HAUSHALT,
    715: NUTZUNGSBEREICH_INDUSTRIE,
    716: NUTZUNGSBEREICH_LANDWIRTSCHAFT,
    717: NUTZUNGSBEREICH_OEFFENTLICH,
    718: NUTZUNGSBEREICH_SONSTIGE,
  }

  def is_public(self, x: dict) -> bool:
    whitelist = [
      "ABR985464955328", # Gemeinde Vaterstetten
      "ABR920681169288", # 3E-eG Eigene Erneuerbare Energie Genossenschaft
      "ABR982596453098", # 3E-eG Eigene Erneuerbare Energie Genossenschaft
      "ABR935107317006", # Kath. Kirchenstiftung Maria Königin Baldham
      "ABR923417495323", # Kath. Kirchenstiftung Vaterstetten
      "ABR925649324174", # Kath. Siedlungswerk München
      "ABR964895737925", # Großmann Erden GmbH
      "ABR930947414953", # Energiehof Stefan Großmann-Neuhäusler
      "ABR932247507397", # ENTEGA NATURpur AG / Gymnasium Vaterstetten
      "ABR998244537751", # Bernhard Eschbaumer Forst- & Gartentechnik
      "ABR978161481993", # Brenner Selbstklebetechnik
      "ABR936688381776", # Raiffeisenbank Zorneding eG
      "ABR981935485455", # Auer Baustoffe GmbH ＆ Co. KG
      "ABR991822525591", # Landkreis Ebersberg
      "ABR939016877651", # Eurytos Energie GmbH ＆ Co. KG
      "ABR951481578482", # ibeko-solar GmbH
      "ABR981309102131", # ibeko-system GmbH
    ]

    if x['AnlagenbetreiberMaStRNummer'] in whitelist:
      return True

    if x['NutzungsbereichGebSA'] is not None and self.NUTZUNGSBEREICH_BY_ID[x['NutzungsbereichGebSA']] == self.NUTZUNGSBEREICH_OEFFENTLICH:
      return True

    has_betreiber_name = x['AnlagenbetreiberName'] is not None

    if has_betreiber_name and x['AnlagenbetreiberName'].startswith('natürliche Person'):
      return False

    if not x['IsAnonymisiert']: # IsAnonymisiert refers to whether Strasse and Ort are visible; this is true if Bruttoleistung >= 30 kWp
      return True

    if has_betreiber_name and 'GbR' in x['AnlagenbetreiberName']: # GbR firms are mostly used personally, since German law sometimes requires house owners to found a business for their photovoltaic system
      return False

    if has_betreiber_name and ('e.V.' in x['AnlagenbetreiberName'] or 'e. V.' in x['AnlagenbetreiberName'] or 'eG' in x['AnlagenbetreiberName']): # Vereine and Genossenschaften are public in general
      return True

    return False


  def parse_date(self, dateStr: str) -> str:
    if dateStr == None:
      return None

    unix_timestamp = re.search(r'^\/Date\(([0-9]+)\)\/$', dateStr).group(1)
    return datetime.utcfromtimestamp(int(unix_timestamp) / 1000).strftime('%Y-%m-%d')

  def parse_hausnummer(self, hausnummerStr: str) -> str:
    if hausnummerStr == None:
      return None

    hausnummerStr = hausnummerStr.strip()

    # try normalizing ranges like "26 a– 2c h" to "26 a - 26 h"
    matches_range = re.search(r'^([0-9a-z ]+)\s*[\-–]\s*([0-9a-z ]+)$', hausnummerStr)
    if matches_range != None:
      hausnummerStr = '%s - %s' % (matches_range.group(1), matches_range.group(2))

    return hausnummerStr

  def filter_vaterstetten(self, einheit: dict) -> bool:
    orte = [
      'Vaterstetten',
      'Baldham',
      'Weißenfeld',
      'Hergolding',
      'Parsdorf',
      'Neufarn',
      'Purfing'
    ]

    if not einheit['Ort'] in orte:
      # Uncomment this to identify mis-classified Einheiten and report them at https://www.marktstammdatenregister.de/MaStR/Startseite/Kontakt
      # print('Einheit with wrong Ort: %s %s, %s %s, %s (%s) https://www.marktstammdatenregister.de/MaStR/Einheit/Detail/IndexOeffentlich/%s' % (
      #   einheit['Plz'],
      #   einheit['Ort'],
      #   einheit['Strasse'] or '',
      #   einheit['Hausnummer'] or '',
      #   einheit['EinheitName'],
      #   einheit['AnlagenbetreiberName'],
      #   einheit['Id'],
      # ))
      return False

    return True
