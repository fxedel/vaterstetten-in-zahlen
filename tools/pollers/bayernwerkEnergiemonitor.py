import os
import time

import requests
import pollers.poller

REGION_CODE = '09175'

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('energie', 'bayernwerkEnergiemonitorLandkreis.csv');
    old_rows = self.read_csv_rows(csv_filename)

    url = f'https://api-energiemonitor.eon.com/historic-data?regionCode={REGION_CODE}'
    print (f'> Query {url}')
    start = time.time()
    res = requests.get(url)
    print('> Queried data in %.1fs' % (time.time() - start))

    if res.status_code != 200:
        raise Exception('Can\'t access webpage: Status code ' + str(res.status_code))

    data = res.json()

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(old_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(data), len(old_rows)))

    if len(data) > len(old_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(data), len(old_rows)))

    rows = []
    for item in data:

      erzeugung = item['feedIn'] + item['energyIntoGrid']
      feedInOther = item['feedInPerCluster'].get('others', 0)
      feedInNonRenewable = erzeugung - item['feedInRenewables']
      feedInOtherRenewable = (feedInOther - feedInNonRenewable)

      row = {
        'datum': item['dayAsString'],
        'verbrauch_kWh': item['consumption'],
        'verbrauchPrivat_kWh': item['consumptionPerCluster']['domestic'],
        'verbrauchGewerbe_kWh': item['consumptionPerCluster']['industrial'],
        'verbrauchOeffentlich_kWh': item['consumptionPerCluster']['public'],
        'erzeugung_kWh': erzeugung,
        'erzeugungErneuerbar_kWh': item['feedInRenewables'],
        'erzeugungBiomasse_kWh': item['feedInPerCluster'].get('bio', 0),
        'erzeugungSolar_kWh': item['feedInPerCluster'].get('solar', 0),
        'erzeugungWasserkraft_kWh': item['feedInPerCluster'].get('water', 0),
        'erzeugungWind_kWh': item['feedInPerCluster'].get('wind', 0),
        'erzeugungAndereErneuerbar_kWh': feedInOtherRenewable,
        'erzeugungNichtErneuerbar_kWh': feedInNonRenewable,
        'netzeinspeisung_kWh': item['energyIntoGrid'],
        'netzbezug_kWh': item['energyFromGrid'],
        'ueberschuss': item['energyExcessCounter'],
      }

      for key in row:
        if key.endswith('_kWh') and row[key] != None:
          row[key] = round(row[key], 3)
      
      rows.append(row)

    self.write_csv_rows(csv_filename, rows)
    new_rows = self.read_csv_rows(csv_filename)

    # detect changes
    key_func = lambda x: f"{x['datum']}"
    old_rows_by_key = self.list_with_unique_key(old_rows, key_func, auto_increment = True)
    new_rows_by_key = self.list_with_unique_key(new_rows, key_func, auto_increment = True)
    (keys_removed, keys_changed, keys_added) = self.dict_diff(old_rows_by_key, new_rows_by_key)
  
    if len(keys_removed) > 0:
      lines = []
      lines.append('*Energie-Monitordaten gelöscht*')
      lines += keys_removed

      lines = list(map(lambda x: x.replace('_', '\_'), lines))

      if len(lines) > 1:
        lines.append(' | '.join([
          # '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de/?tab=)',
          f'[Commits](https://github.com/fxedel/vaterstetten-in-zahlen/commits/master/data/{csv_filename})',
        ]))
        self.send_public_telegram_message(lines)

