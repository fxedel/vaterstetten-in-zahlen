import os
import time

import requests
import pollers.poller

REGION_CODE = '09175'

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('energie', 'bayernwerkEnergiemonitorLandkreis.csv');
    current_rows = self.read_csv_rows(csv_filename)

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

    if len(data) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(data), len(current_rows)))

    if len(data) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(data), len(current_rows)))

    rows = []
    for item in data:

      feedInOther = item['feedInPerCluster'].get('others', 0)
      feedInNonRenewable = item['feedIn'] - item['feedInRenewables']
      feedInOtherRenewable = (feedInOther - feedInNonRenewable)

      row = {
        'datum': item['dayAsString'],
        'verbrauch_kWh': item['consumption'],
        'verbrauchPrivat_kWh': item['consumptionPerCluster']['domestic'],
        'verbrauchGewerbe_kWh': item['consumptionPerCluster']['industrial'],
        'verbrauchOeffentlich_kWh': item['consumptionPerCluster']['public'],
        'erzeugung_kWh': item['feedIn'],
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

    if self.telegram_bot != None and self.telegram_chat_id != None:
      csv_diff = self.get_csv_diff(csv_filename, rows, context = 0)
      data = ''.join(csv_diff)
      self.telegram_bot.send_message(
        self.telegram_chat_id,
        '```\n' + (data[:4080] if len(data) > 4080 else data) + '```',
        parse_mode = "Markdown"
      )

    self.write_csv_rows(csv_filename, rows)
