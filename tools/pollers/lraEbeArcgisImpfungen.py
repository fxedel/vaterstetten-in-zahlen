from arcgis.features import FeatureLayer
from datetime import datetime
import os

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('corona-impfungen', 'arcgisImpfungen.csv');
    current_rows = self.read_csv_rows(csv_filename)

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Gesamtsummen_Impfmeldungen_Öffentlich/FeatureServer/0")

    data = layer.query(order_by_fields='Meldedatum')

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(current_rows):
      raise Exception('Queried data has less items (%d) than current data (%d)' % (len(data), len(current_rows)))

    rows = list(map(lambda x: {
      'datum': datetime.utcfromtimestamp(x.attributes['Meldedatum'] / 1000).strftime('%Y-%m-%d'),
      'erstimpfungen': str(x.attributes['Erstimpfungen_SUM']),
      'zweitimpfungen': str(x.attributes['Zweitimpfungen_SUM']),
      'impfdosen': str(x.attributes['Impfungen_SUM']),
      'impfdosenNeu': str(x.attributes['Impfungen_Tag']) if x.attributes['Impfungen_Tag'] != x.attributes['Impfungen_SUM'] else 'NA',
    }, data.features))

    if current_rows == rows:
      return

    if self.telegram_bot != None and self.telegram_chat_id != None:
      last_row = rows[-1]

      lines = [
        '*Impf-Update für den Landkreis Ebersberg*',
        '_Erstimpfungen_: *%s*' % last_row['erstimpfungen'],
        '_Zweitimpfungen_: *%s*' % last_row['zweitimpfungen'],
        '_Verabreichte Impfdosen_: *%s*' % last_row['impfdosen'],
        '_Neu verabreichte Impfdosen zum Vortag_: *%s*' % last_row['impfdosenNeu'],
        ' | '.join([
          '[LRA Impfzentrum](https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/)',
          '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de/?tab=coronaImpfungen)',
        ])
      ]

      self.telegram_bot.send_message(
        self.telegram_chat_id,
        '\n'.join(lines),
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )

    self.write_csv_rows(csv_filename, rows)
