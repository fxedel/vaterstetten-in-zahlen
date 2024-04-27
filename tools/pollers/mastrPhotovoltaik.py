import os
import time

from pollers.mastrGeneric import MastrGenericPoller

class MastrPhotovoltaikPoller(MastrGenericPoller):

  def run(self):
    csv_filename = os.path.join('energie', 'mastrPhotovoltaik.csv');
    old_rows = self.read_csv_rows(csv_filename)

    start = time.time()
    data = self.query_with_pagination(
      filter = "Gemeinde~eq~'Vaterstetten'~and~Energieträger~eq~'%d'" % self.ENERGIETRAEGER_SOLARE_STRAHLUNGSENERGIE_ID,
      page_size = 500,
    )
    print('> Queried data in %.1fs' % (time.time() - start))

    data_filtered = list(filter(self.filter_vaterstetten, data))
    data_filtered = list(filter(self.filter_plausability, data_filtered))

    if len(data_filtered) < len(old_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(data_filtered), len(old_rows)))

    if len(data_filtered) > len(old_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(data_filtered), len(old_rows)))

    rows = list(map(self.map_row, data_filtered))
    rows = sorted(rows, key=lambda d: d['registrierungMaStR'])
    rows = sorted(rows, key=lambda d: d['inbetriebnahmeGeplant'] or '')
    rows = sorted(rows, key=lambda d: d['inbetriebnahme'] or 'Z')

    self.write_csv_rows(csv_filename, rows)
    new_rows = self.read_csv_rows(csv_filename)

    # detect changes
    key_func = lambda x: f"{x['MaStRId']}"
    old_rows_by_key = self.list_with_unique_key(old_rows, key_func, auto_increment = True)
    new_rows_by_key = self.list_with_unique_key(new_rows, key_func, auto_increment = True)
    (keys_removed, keys_changed, keys_added) = self.dict_diff(old_rows_by_key, new_rows_by_key)
  
    if len(keys_removed) > 0 or len(keys_changed) > 0 or len(keys_added) > 0:
      lines = []
      lines.append('*MaStR-Photovoltaik geändert*')

      for key in keys_removed:
        item = old_rows_by_key[key]
        lines.append(f'[{key}]({self.einheit_url(key)}) entfernt: name = "{item["name"]}"')
      for key in keys_added:
        item = new_rows_by_key[key]
        lines.append(f'[{key}]({self.einheit_url(key)}) hinzugefügt:')
        for (field, value) in item.items():
          if field in ['MaStRId', 'MaStRNummer', 'EEGAnlagenschluessel']:
            continue
          if value == '' or value == 'false':
            continue

          lines.append(f'{field} = {value}')
      for key in keys_changed:
        old_value = old_rows_by_key[key]
        new_value = new_rows_by_key[key]

        fields = set(new_value.keys()).intersection(old_value.keys())
        fields = list(filter(lambda field: field not in [], fields))
        fields = list(filter(lambda field: str(old_value[field]) != str(new_value[field]), fields))

        if set(fields).issubset(['EEGAnlagenschluessel', 'netzbetreiberPruefung']):
          continue

        if len(fields) == 0:
          continue

        field_texts = map(lambda field: f'{field} "{old_value[field]}" → "{new_value[field]}"', fields)
        lines.append(f"[{key}]({self.einheit_url(key)}) geändert:")
        lines += field_texts
      
      lines = list(map(lambda x: x.replace('_', '\_'), lines))

      if len(lines) > 1:
        lines.append(' | '.join([
          '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de/?tab=photovoltaik)',
          f'[Commits](https://github.com/fxedel/vaterstetten-in-zahlen/commits/master/data/{csv_filename})',
        ]))
        self.send_public_telegram_message(lines)

  def filter_plausability(self, x: dict) -> bool:
    if x['NutzungsbereichGebSA'] is not None and self.NUTZUNGSBEREICH_BY_ID[x['NutzungsbereichGebSA']] == self.NUTZUNGSBEREICH_HAUSHALT:
      if x['Bruttoleistung'] >= 200:
        print(f"> Ignored entity due to Bruttoleistung = {x['Bruttoleistung']} >= 200: Name '{x['EinheitName']}' ({self.einheit_url(x['Id'])})")
        # more than 200 kW is very unlikely for a simple household
        return False
      if x['Nettonennleistung'] >= 200:
        print(f"> Ignored entity due to Nettonennleistung = {x['Nettonennleistung']} >= 200: Name '{x['EinheitName']}' ({self.einheit_url(x['Id'])})")
        # more than 200 kW is very unlikely for a simple household
        return False

    inbetriebnahme = self.parse_date(x['InbetriebnahmeDatum'])
    if inbetriebnahme != None and inbetriebnahme < '2000-01-01':
      # the EEG was not even in force, this is probably wrong
      print(f"> Ignored entity due to inbetriebnahme = '{inbetriebnahme}' < '2000-01-01': Name '{x['EinheitName']}' ({self.einheit_url(x['Id'])})")
      return False

    return True
    
  def map_row(self, x: dict) -> dict:
    lage = self.LAGE_BY_ID[x['LageEinheit']]

    if lage == self.LAGE_STECKER:
      if x['AnzahlSolarModule'] > 2 and x['Nettonennleistung'] > 0.8:
        print(f"> Entity with LageEinheit = '{lage}' has AnzahlSolarModule = {x['AnzahlSolarModule']} > 2 and Nettonennleistung = {x['Nettonennleistung']} > 0.8, setting LageEinheit := '{self.LAGE_GEBAEUDE}': Name '{x['EinheitName']}' ({self.einheit_url(x['Id'])})")
        lage = self.LAGE_GEBAEUDE

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
        self.NUTZUNGSBEREICH_SONSTIGE if not lage == self.LAGE_FREIFLAECHE else None,
      'plz': x['Plz'],
      'ort': x['Ort'],
      'strasse': x['Strasse'],
      'hausnummer': self.parse_hausnummer(x['Hausnummer']),
      'lat': x['Breitengrad'],
      'long': x['Laengengrad'],
      'netzbetreiberPruefung': str(x['IsNBPruefungAbgeschlossen'] == self.NETZBETREIBERPRUEFUNG_GEPRUEFT_ID).lower(),
      'typ': lage,
      'module': x['AnzahlSolarModule'],
      'ausrichtung': x['HauptausrichtungSolarModuleBezeichnung'],
      'bruttoleistung_kW': x['Bruttoleistung'],
      'nettonennleistung_kW': x['Nettonennleistung'],
      'leistungsBegrenzung': self.LEISTUNGSBEGRENZUNG_BY_ID[x['Leistungsbegrenzung']] if x['Leistungsbegrenzung'] is not None else None,
      'EEGAusschreibung': str(x['EegZuschlag'] is not None).lower(),
      'einspeisung': x['VollTeilEinspeisungBezeichnung'],
      'mieterstrom': str(x['MieterstromAngemeldet'] == True).lower(),
    }
