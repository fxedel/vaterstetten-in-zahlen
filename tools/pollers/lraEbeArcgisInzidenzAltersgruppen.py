from arcgis.features import FeatureLayer
from datetime import datetime
import os
import time

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('corona-fallzahlen', 'arcgisInzidenzAltersgruppen.csv');
    current_rows = self.read_csv_rows(csv_filename)

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Altersgruppen_Inzidenztabelle/FeatureServer/0")

    start = time.time()
    data = layer.query(order_by_fields='Meldedatum,Altersgruppe', return_all_records=True)
    print('> Queried data in %.1fs' % (time.time() - start))

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(data), len(current_rows)))

    if len(data) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(data), len(current_rows)))

    rows = list(map(lambda x: {
      'datum': datetime.utcfromtimestamp(x.attributes['Meldedatum'] / 1000).strftime('%Y-%m-%d'),
      'altersgruppe': str(x.attributes['Altersgruppe']).replace('A', ''), # A60-A79 -> 60-79
      'neuPositiv': str(x.attributes['AnzahlFall']),
      'inzidenz7tage': str(round(x.attributes['inzidenz_letzte7Tage'], 2)),
    }, data.features))

    csv_diff = self.get_csv_diff(csv_filename, rows)

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
