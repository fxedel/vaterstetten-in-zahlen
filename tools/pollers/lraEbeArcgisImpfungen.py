from arcgis.features import FeatureLayer
from arcgis.features.feature import Feature
from datetime import datetime
import os
import time

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('corona-impfungen', 'arcgisImpfungen.csv');
    current_rows = self.read_csv_rows(csv_filename)

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Gesamtsummen_Impfmeldungen_Öffentlich/FeatureServer/0")

    start = time.time()
    data = layer.query(order_by_fields='Meldedatum')
    print('> Queried data in %.1fs' % (time.time() - start))

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(current_rows):
      raise Exception('Queried data has less items (%d) than current data (%d)' % (len(data), len(current_rows)))

    rows = list(map(feature_to_row, data.features))

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

def feature_to_row(feature: Feature):
  attrs = feature.attributes.copy()

  if attrs['Impfungen_Tag'] == attrs['Impfungen_SUM']:
    attrs['Impfungen_Tag'] = 'NA'
  elif attrs['Impfungen_Tag'] <= -10000:
    raise Exception('Implausible data: %s' % feature)
  elif attrs['Impfungen_Tag'] >= 10000:
    raise Exception('Implausible data: %s' % feature)

  return {
    'datum': datetime.utcfromtimestamp(attrs['Meldedatum'] / 1000).strftime('%Y-%m-%d'),
    'erstimpfungen': str(attrs['Erstimpfungen_SUM']),
    'zweitimpfungen': str(attrs['Zweitimpfungen_SUM']),
    'drittimpfungen': str(attrs['Drittimpfungen_SUM']),
    'impfdosen': str(attrs['Impfungen_SUM']),
    'impfdosenNeu': str(attrs['Impfungen_Tag']),
  }
