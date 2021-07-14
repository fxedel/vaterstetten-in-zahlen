from arcgis.features import FeatureLayer
from datetime import datetime
from interface import implements
import os
import telebot
from typing import List, Optional

import pollers.poller

class InzidenzPoller(implements(pollers.poller.Poller)):
  def get_csv_filename(self) -> str:
    return os.path.join(pollers.poller.data_dir, 'corona-fallzahlen', 'arcgisInzidenzLandkreis.csv')

  def get_new_data(
    self,
    current_data: List[dict],
    telegram_bot: Optional[telebot.TeleBot],
    telegram_chat_id: Optional[str]
  ) -> List[dict]:
    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Landkreis_Inzidenztabelle/FeatureServer/0")

    data = layer.query(order_by_fields='Datum_Meldung')

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(current_data):
      raise Exception('Queried data has less items (%d) than current data (%d)' % (len(data), len(current_data)))

    rows = list(map(lambda x: {
      'datum': datetime.utcfromtimestamp(x.attributes['Datum_Meldung'] / 1000).strftime('%Y-%m-%d'),
      'neuPositiv': str(x.attributes['positiv_neu']),
      'inzidenz7tage': str(round(x.attributes['inzidenz_letzte7Tage'], 2)),
    }, data.features))

    if telegram_bot != None and telegram_chat_id != None and rows != current_data:
      last_row = rows[-1]
      lines = [
        '*Corona-Update für den Landkreis Ebersberg*',
        '_7-Tage-Inzidenz:_ *' + last_row['inzidenz7tage'] + '*',
        '_Neue Fälle zum Vortag:_ *' + last_row['neuPositiv'] + '*',
        '_Stand:_ *' + last_row['datum'] + '*',
      ]
      telegram_bot.send_message(
        telegram_chat_id,
        '\n'.join(lines),
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )

    return rows

class InzidenzGemeindenPoller(implements(pollers.poller.Poller)):
  def get_csv_filename(self) -> str:
    return os.path.join(pollers.poller.data_dir, 'corona-fallzahlen', 'arcgisInzidenzGemeinden.csv')

  def get_new_data(
    self,
    current_data: List[dict],
    telegram_bot: Optional[telebot.TeleBot],
    telegram_chat_id: Optional[str]
  ) -> List[dict]:
    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Gemeinden_Inzidenztabelle/FeatureServer/0")

    data = layer.query(order_by_fields='Ort, Datum_Meldung')

    if len(data) == 0:
      raise Exception('Queried data is empty')

    if len(data) < len(current_data):
      raise Exception('Queried data has less items (%d) than current data (%d)' % (len(data), len(current_data)))

    rows = list(map(lambda x: {
      'datum': datetime.utcfromtimestamp(x.attributes['Datum_Meldung'] / 1000).strftime('%Y-%m-%d'),
      'ort': x.attributes['Ort'],
      'neuPositiv': str(x.attributes['positiv_neu']),
      'inzidenz7tage': str(round(x.attributes['inzidenz_letzte7Tage'], 2)),
    }, data.features))

    if telegram_bot != None and telegram_chat_id != None and rows != current_data:
      rows_vaterstetten = list(filter(lambda x: x['ort'] == 'Vaterstetten', rows))
      last_row = rows_vaterstetten[-1]
      lines = [
        '*Corona-Update für Vaterstetten*',
        '_7-Tage-Inzidenz:_ *' + last_row['inzidenz7tage'] + '*',
        '_Neue Fälle zum Vortag:_ *' + last_row['neuPositiv'] + '*',
        '_Stand:_ *' + last_row['datum'] + '*',
      ]
      telegram_bot.send_message(
        telegram_chat_id,
        '\n'.join(lines),
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )

    return rows
