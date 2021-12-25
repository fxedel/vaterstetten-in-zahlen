from datetime import datetime
import json
import os
import time
import re
import requests

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('energie', 'mastrPhotovoltaik.csv');
    current_rows = self.read_csv_rows(csv_filename)

    req = requests.get('https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetErweiterteOeffentlicheEinheitStromerzeugung?pageSize=1000&group=&filter=Gemeinde~eq~\'Vaterstetten\'~and~Energieträger~eq~\'2495\'')

    if req.status_code != 200:
      raise Exception('Can\'t access webpage: Status code ' + str(req.status_code))

    payload = json.loads(req.text)

    if payload['Errors'] != None:
      raise Exception('Data error: %s' % payload['Errors'])

    if payload['Total'] == 0:
      raise Exception('Queried data is empty')

    if payload['Total'] != len(payload['Data']):
      raise Exception('Total count (%d) does not match list length (%d)' % (payload['Total'], len(payload['Data'])))

    if payload['Total'] < len(current_rows):
      raise Exception('Queried data has less items (%d) than current data (%d)' % (payload['Total'], len(current_rows)))

    data_filtered = list(filter(filter_vaterstetten, payload['Data']))
    rows = list(map(map_row, data_filtered))
    rows = sorted(rows, key=lambda d: d['registrierungMaStr'])
    rows = sorted(rows, key=lambda d: d['inbetriebnahmeGeplant'] or '')
    rows = sorted(rows, key=lambda d: d['inbetriebnahme'] or 'Z')

    csv_diff = self.get_csv_diff(csv_filename, rows)

    if len(csv_diff) == 0:
      return

    if self.telegram_bot != None and self.telegram_chat_id != None:
      self.telegram_bot.send_message(
        self.telegram_chat_id,
        '```\n' + ''.join(csv_diff) + '\n```',
        parse_mode = "Markdown"
      )

    self.write_csv_rows(csv_filename, rows)

def map_row(x: dict) -> dict:
  return {
    'MaStRId': x['Id'],
    'MaStRNummer': x['MaStRNummer'],
    'EEGAnlagenschluessel': x['EegAnlagenschluessel'],
    'status': x['BetriebsStatusName'],
    'registrierungMaStr': parse_date(x['EinheitRegistrierungsdatum']),
    'inbetriebnahme': parse_date(x['InbetriebnahmeDatum']),
    'inbetriebnahmeGeplant': parse_date(x['GeplantesInbetriebsnahmeDatum']),
    'stilllegung': parse_date(x['EndgueltigeStilllegungDatum']),
    'name': x['EinheitName'] if is_public(x) else None,
    'betreiber': x['AnlagenbetreiberName'] if is_public(x) else None,
    'plz': x['Plz'],
    'ort': x['Ort'],
    'strasse': x['Strasse'],
    'hausnummer': parse_hausnummer(x['Hausnummer']),
    'lat': x['Breitengrad'],
    'long': x['Laengengrad'],
    'netzbetreiberPruefung': str(x['IsNBPruefungAbgeschlossen'] == 2954).lower(),
    'typ': parse_typ(x['LageEinheit'], x['LageEinheitBezeichnung']),
    'module': x['AnzahlSolarModule'],
    'ausrichtung': x['HauptausrichtungSolarModuleBezeichnung'],
    'bruttoleistung_kW': x['Bruttoleistung'],
    'nettonennleistung_kw': x['Nettonennleistung'],
    'EEGAusschreibung': str(x['EegZuschlag'] is not None).lower(),
    'einspeisung': x['VollTeilEinspeisungBezeichnung'],
    'mieterstrom': str(x['MieterstromAngemeldet'] == True).lower(),
  }

def is_public(x: dict) -> bool:
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
  ]

  if x['AnlagenbetreiberMaStRNummer'] in whitelist:
    return True

  blacklist = [
    "ABR934178889290",
  ]

  if x['AnlagenbetreiberMaStRNummer'] in blacklist:
    return False

  if x['AnlagenbetreiberName'].startswith('natürliche Person'):
    return False

  if not x['IsAnonymisiert']: # IsAnonymisiert refers to whether Strasse and Ort are visible; this is true if Bruttoleistung >= 30 kWp
    return True

  if 'GbR' in x['AnlagenbetreiberName']: # GbR firms are mostly used personally, since German law sometimes requires house owners to found a business for their photovoltaic system
    return False

  if 'e.V.' in x['AnlagenbetreiberName'] or 'e. V.' in x['AnlagenbetreiberName'] or 'eG' in x['AnlagenbetreiberName']: # Vereine and Genossenschaften are public in general
    return True

  return False


regex_date = r'^\/Date\(([0-9]+)\)\/$'

def parse_date(x: str) -> str:
  if x == None:
    return None

  unix_timestamp = re.search(regex_date, x).group(1)
  return datetime.utcfromtimestamp(int(unix_timestamp) / 1000).strftime('%Y-%m-%d')


regex_hausnummern_range = r'^([0-9]+[a-z]*)\s*[\-–]\s*([0-9]+[a-z]*)$'

def parse_hausnummer(x: str) -> str:
  if x == None:
    return None

  x = x.strip()

  matches_range = re.search(regex_hausnummern_range, x)
  if matches_range != None:
    x = '%s-%s' % (matches_range.group(1), matches_range.group(2))

  return x

def parse_typ(id: int, description: str) -> str:
  if id == 852:
    # Freifläche
    return "freiflaeche"
  if id == 853:
    # Bauliche Anlagen (Hausdach, Gebäude und Fassade)
    return "gebaeude"
  if id == 2484:
    # Bauliche Anlagen (Sonstige)
    return "gebaeude-other"
  if id == 2961:
    # Steckerfertige Erzeugungsanlage (sog. Plug-In- oder Balkon-PV-Anlage)
    return "stecker"

  # fallback
  return description

def filter_vaterstetten(einheit: dict) -> bool:
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
