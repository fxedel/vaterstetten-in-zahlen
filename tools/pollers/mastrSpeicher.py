from datetime import datetime
import json
import os
import time
import re
import requests

from pollers.mastrGeneric import MastrGenericPoller

class MastrSpeicherPoller(MastrGenericPoller):
  def run(self):
    csv_filename = os.path.join('energie', 'mastrSpeicher.csv');
    current_rows = self.read_csv_rows(csv_filename)

    start = time.time()
    req = requests.get("https://www.marktstammdatenregister.de/MaStR/Einheit/EinheitJson/GetErweiterteOeffentlicheEinheitStromerzeugung?pageSize=1000&group=&filter=Gemeinde~eq~'Vaterstetten'~and~Energieträger~eq~'%d'" % self.ENERGIETRAEGER_SPEICHER_ID)
    print('> Queried data in %.1fs' % (time.time() - start))

    if req.status_code != 200:
      raise Exception('Can\'t access webpage: Status code ' + str(req.status_code))

    payload = json.loads(req.text)

    if payload['Errors'] != None:
      raise Exception('Data error: %s' % payload['Errors'])

    if payload['Total'] == 0:
      raise Exception('Queried data is empty')

    if payload['Total'] != len(payload['Data']):
      raise Exception('Total count (%d) does not match list length (%d)' % (payload['Total'], len(payload['Data'])))

    if payload['Total'] < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (payload['Total'], len(current_rows)))

    if payload['Total'] > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (payload['Total'], len(current_rows)))

    data_filtered = list(filter(self.filter_vaterstetten, payload['Data']))
    data_filtered = list(filter(self.filter_plausability, data_filtered))
    rows = list(map(self.map_row, data_filtered))
    rows = sorted(rows, key=lambda d: d['registrierungMaStR'])
    rows = sorted(rows, key=lambda d: d['inbetriebnahmeGeplant'] or '')
    rows = sorted(rows, key=lambda d: d['inbetriebnahme'] or 'Z')

    csv_diff = self.get_csv_diff(csv_filename, rows, context = 0)

    if len(csv_diff) == 0:
      return

    if self.telegram_bot != None and self.telegram_chat_id != None:
      data = ''.join(csv_diff)
      self.telegram_bot.send_message(
        self.telegram_chat_id,
        '```\n' + (data[:4080] if len(data) > 4080 else data) + '```',
        parse_mode = "Markdown"
      )

    self.write_csv_rows(csv_filename, rows)

  def filter_plausability(self, x: dict) -> bool:
    if str(x['SpannungsebenenNamen']).startswith('Niederspannung') and str(x['AnlagenbetreiberName']).startswith('natürliche Person'):
    
      if x['NutzbareSpeicherkapazitaet'] >= 300:
        # 300 kWh is about 10% of a typical household's yearly power consumption (3000 kWh), but batteries normally only last a single day
        return False

    return True

  def map_row(self, x: dict) -> dict:
    return {
      'MaStRId': x['Id'],
      'MaStRNummer': x['MaStRNummer'],
      'status': x['BetriebsStatusName'],
      'registrierungMaStR': self.parse_date(x['EinheitRegistrierungsdatum']),
      'inbetriebnahme': self.parse_date(x['InbetriebnahmeDatum']),
      'inbetriebnahmeGeplant': self.parse_date(x['GeplantesInbetriebsnahmeDatum']),
      'stilllegung': self.parse_date(x['EndgueltigeStilllegungDatum']),
      'name': x['EinheitName'] if self.is_public(x) else None,
      'betreiber': x['AnlagenbetreiberName'] if self.is_public(x) else None,
      'plz': x['Plz'],
      'ort': x['Ort'],
      'strasse': x['Strasse'],
      'hausnummer': self.parse_hausnummer(x['Hausnummer']),
      'lat': x['Breitengrad'],
      'long': x['Laengengrad'],
      'netzbetreiberPruefung': str(x['IsNBPruefungAbgeschlossen'] == self.NETZBETREIBERPRUEFUNG_GEPRUEFT_ID).lower(),
      'batterietechnologie': self.BATTERIETECHNOLOGIE_BY_ID[x['Batterietechnologie']],
      'bruttoleistung_kW': x['Bruttoleistung'],
      'nettonennleistung_kW': x['Nettonennleistung'],
      'kapazitaet_kWh': x['NutzbareSpeicherkapazitaet'],
      'einspeisung': x['VollTeilEinspeisungBezeichnung'],
      'istNotstromaggregat': str(x['IsEinheitNotstromaggregat']).lower(),
    }
