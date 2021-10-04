from arcgis.features import FeatureLayer
from datetime import datetime
import os
import telebot
from typing import List, Optional

import pollers.poller

class InzidenzPoller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('corona-fallzahlen', 'arcgisInzidenzLandkreis.csv');
    current_rows = self.read_csv_rows(csv_filename)

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Landkreis_Inzidenztabelle/FeatureServer/0")

    data = layer.query(order_by_fields='Datum_Meldung')

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(current_rows):
      raise Exception('Queried data has less items (%d) than current data (%d)' % (len(data), len(current_rows)))

    rows = list(map(lambda x: {
      'datum': datetime.utcfromtimestamp(x.attributes['Datum_Meldung'] / 1000).strftime('%Y-%m-%d'),
      'neuPositiv': str(x.attributes['positiv_neu']),
      'inzidenz7tage': str(round(x.attributes['inzidenz_letzte7Tage'], 2)),
    }, data.features))

    if current_rows == rows:
      return

    if self.telegram_bot != None and self.telegram_chat_id != None:
      last_row = rows[-1]
      lines = [
        '*Corona-Update für den Landkreis Ebersberg*',
        '_7-Tage-Inzidenz:_ *' + last_row['inzidenz7tage'] + '*',
        '_Neue Fälle zum Vortag:_ *' + last_row['neuPositiv'] + '*',
        '_Stand:_ *' + last_row['datum'] + '*',
      ]
      self.telegram_bot.send_message(
        self.telegram_chat_id,
        '\n'.join(lines),
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )

    self.write_csv_rows(csv_filename, rows)

class InzidenzGemeindenPoller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('corona-fallzahlen', 'arcgisInzidenzGemeinden.csv');
    current_rows = self.read_csv_rows(csv_filename)

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Gemeinden_Inzidenztabelle_3/FeatureServer/0")

    data = layer.query(order_by_fields='Ort, Datum_Meldung')

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(current_rows):
      raise Exception('Queried data has less items (%d) than current data (%d)' % (len(data), len(current_rows)))

    rows = list(map(lambda x: {
      'datum': datetime.utcfromtimestamp(x.attributes['Datum_Meldung'] / 1000).strftime('%Y-%m-%d'),
      'ort': x.attributes['Ort'],
      'neuPositiv': str(x.attributes['positiv_neu']),
      'inzidenz7tage': str(round(x.attributes['inzidenz_letzte7Tage'], 2)),
    }, data.features))

    if current_rows == rows:
      return

    if self.telegram_bot != None and self.telegram_chat_id != None:
      rows_vaterstetten = list(filter(lambda x: x['ort'] == 'Vaterstetten', rows))
      last_row = rows_vaterstetten[-1]
      lines = [
        '*Corona-Update für Vaterstetten*',
        '_7-Tage-Inzidenz:_ *' + last_row['inzidenz7tage'] + '*',
        '_Neue Fälle zum Vortag:_ *' + last_row['neuPositiv'] + '*',
        '_Stand:_ *' + last_row['datum'] + '*',
      ]
      self.telegram_bot.send_message(
        self.telegram_chat_id,
        '\n'.join(lines),
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )

    self.write_csv_rows(csv_filename, rows)
