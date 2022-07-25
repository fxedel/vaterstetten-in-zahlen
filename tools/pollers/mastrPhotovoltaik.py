import os
import time

from pollers.mastrGeneric import MastrGenericPoller

class MastrPhotovoltaikPoller(MastrGenericPoller):

  def run(self):
    csv_filename = os.path.join('energie', 'mastrPhotovoltaik.csv');
    current_rows = self.read_csv_rows(csv_filename)

    start = time.time()
    data = self.query_with_pagination(
      filter = "Gemeinde~eq~'Vaterstetten'~and~Energieträger~eq~'%d'" % self.ENERGIETRAEGER_SOLARE_STRAHLUNGSENERGIE_ID,
      page_size = 500,
    )
    print('> Queried data in %.1fs' % (time.time() - start))

    data_filtered = list(filter(self.filter_vaterstetten, data))
    data_filtered = list(filter(self.filter_plausability, data_filtered))

    if len(data_filtered) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(data_filtered), len(current_rows)))

    if len(data_filtered) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(data_filtered), len(current_rows)))

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
    if x['NutzungsbereichGebSA'] is not None and self.NUTZUNGSBEREICH_BY_ID[x['NutzungsbereichGebSA']] == self.NUTZUNGSBEREICH_HAUSHALT:
      if x['Bruttoleistung'] >= 200:
        # more than 200 kW is very unlikely for a simple household
        return False
      if x['Nettonennleistung'] >= 200:
        # more than 200 kW is very unlikely for a simple household
        return False

    return True
    
  def map_row(self, x: dict) -> dict:
    return {
      'MaStRId': x['Id'],
      'MaStRNummer': x['MaStRNummer'],
      'EEGAnlagenschluessel': x['EegAnlagenschluessel'],
      'status': x['BetriebsStatusName'],
      'registrierungMaStR': self.parse_date(x['EinheitRegistrierungsdatum']),
      'inbetriebnahme': self.parse_date(x['InbetriebnahmeDatum']),
      'inbetriebnahmeGeplant': self.parse_date(x['GeplantesInbetriebsnahmeDatum']),
      'stilllegung': self.parse_date(x['EndgueltigeStilllegungDatum']),
      'name': x['EinheitName'] if self.is_public(x) else None,
      'betreiber': x['AnlagenbetreiberName'] if self.is_public(x) else None,
      'gebaeudeNutzung':
        self.NUTZUNGSBEREICH_BY_ID[x['NutzungsbereichGebSA']] if x['NutzungsbereichGebSA'] is not None else
        self.NUTZUNGSBEREICH_SONSTIGE if not self.LAGE_BY_ID[x['LageEinheit']] == self.LAGE_FREIFLAECHE else None,
      'plz': x['Plz'],
      'ort': x['Ort'],
      'strasse': x['Strasse'],
      'hausnummer': self.parse_hausnummer(x['Hausnummer']),
      'lat': x['Breitengrad'],
      'long': x['Laengengrad'],
      'netzbetreiberPruefung': str(x['IsNBPruefungAbgeschlossen'] == self.NETZBETREIBERPRUEFUNG_GEPRUEFT_ID).lower(),
      'typ': self.LAGE_BY_ID[x['LageEinheit']],
      'module': x['AnzahlSolarModule'],
      'ausrichtung': x['HauptausrichtungSolarModuleBezeichnung'],
      'bruttoleistung_kW': x['Bruttoleistung'],
      'nettonennleistung_kW': x['Nettonennleistung'],
      'leistungsBegrenzung': self.LEISTUNGSBEGRENZUNG_BY_ID[x['Leistungsbegrenzung']] if x['Leistungsbegrenzung'] is not None else None,
      'EEGAusschreibung': str(x['EegZuschlag'] is not None).lower(),
      'einspeisung': x['VollTeilEinspeisungBezeichnung'],
      'mieterstrom': str(x['MieterstromAngemeldet'] == True).lower(),
    }
