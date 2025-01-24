from datetime import datetime
import io
from typing import Optional
import os
import pandas as pd
import telebot
import time

import pollers.poller
import pollers.genesisClient

class Poller(pollers.poller.Poller):
  genesis_client: pollers.genesisClient.Client

  def __init__(
    self,
    telegram_bot: Optional[telebot.TeleBot],
    telegram_public_chat_id: Optional[str],
    telegram_debug_chat_id: Optional[str],
  ):
    super().__init__(telegram_bot, telegram_debug_chat_id, telegram_public_chat_id)

    self.genesis_client = pollers.genesisClient.Client(
      username = os.environ['GENESIS_LFSTAT_USERNAME'],
      password = os.environ['GENESIS_LFSTAT_PASSWORD'],
      base_url = pollers.genesisClient.BASE_URL_LFSTAT_BAYERN
    )

  def run(self):

    try:
      rows_wahlberechtigte = []
      rows_wahlberechtigte += self.get_wahlberechtigte_rows('14111-001z', 'Bundestagswahl')
      rows_wahlberechtigte += self.get_wahlberechtigte_rows('14211-001z', 'Europawahl')
      rows_wahlberechtigte += self.get_wahlberechtigte_rows('14311-001z', 'Landtagswahl')
      rows_wahlberechtigte += self.get_wahlberechtigte_rows('14431-001z', 'Gemeinderatswahl')

      rows_gueltige_stimmen = []
      rows_gueltige_stimmen += self.get_gueltige_stimmen_rows('14111-002z', 'Bundestagswahl')
      rows_gueltige_stimmen += self.get_gueltige_stimmen_rows('14211-002z', 'Europawahl')
      rows_gueltige_stimmen += self.get_gueltige_stimmen_rows('14311-002z', 'Landtagswahl')
      rows_gueltige_stimmen += self.get_gueltige_stimmen_rows('14431-002z', 'Gemeinderatswahl')
    except pollers.genesisClient.TemporaryGenesisError as e:
      print(f'> Ignoring temporary GENESIS error: {e}')
      return
    
    if (len(rows_wahlberechtigte) != len(rows_gueltige_stimmen)):
      raise Exception('inequal row count')
        
    rows = []
    for (x, y) in zip(rows_wahlberechtigte, rows_gueltige_stimmen):
      if not (x['Wahl'] == y['Wahl'] and x['Wahltag'] == y['Wahltag']):
        print(x, y)
        raise Exception('inequal rows order')

      rows.append(x | y)

    csv_filename = os.path.join('wahlen', 'lfstatWahlergebnisseAllgemein.csv')
    current_rows = self.read_csv_rows(csv_filename)

    if len(rows) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(rows), len(current_rows)))

    if len(rows) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(rows), len(current_rows)))

    csv_diff = self.get_csv_diff(csv_filename, rows)
    self.send_csv_diff_via_telegram(csv_diff)
    self.write_csv_rows(csv_filename, rows)
  
  def get_wahlberechtigte_rows(self, table_name, wahl):
    start = time.time()
    table_data_csv = self.genesis_client.tablefile(
      name = table_name,
      startyear = 1900,
      regionalvariable = "GEMEIN",
      regionalkey = "09175132"
    )
    print('> Queried data for table %s (%s) in %.1fs' % (table_name, wahl, time.time() - start))

    df = pd.read_csv(io.StringIO(table_data_csv), delimiter = ";")

    if len(df) == 0:
      raise Exception('Queried data is empty')
  
    rows = [{
      'Wahl': wahl,
      'Wahltag': datetime.strptime(x['Zeit'], '%d.%m.%Y').strftime('%Y-%m-%d'),
      'Stimmbezirk': 'Gesamt',
      'Wahlberechtigte': x['WSBER1__Wahlberechtigte__Anzahl'],
      'Waehler': x['WAEHLR__Wahlberechtigte__Anzahl'],
    } for x in df.to_dict('records')]

    return rows

  def get_gueltige_stimmen_rows(self, table_name, wahl):
    start = time.time()
    table_data_csv = self.genesis_client.tablefile(
      name = table_name,
      startyear = 1900,
      regionalvariable = "GEMEIN",
      regionalkey = "09175132"
    )
    print('> Queried data for table %s (%s) in %.1fs' % (table_name, wahl, time.time() - start))

    df = pd.read_csv(io.StringIO(table_data_csv), delimiter = ";")
    
    if wahl == 'Bundestagswahl':
      df = df[df['2_Auspraegung_Code'] == 'ZWEITSTIMME']
    elif wahl == 'Landtagswahl':
      df['GUESTI__Gueltige_Stimmen__Anzahl_ERSTSTIMME'] = df.apply(lambda x:
        int(x['GUESTI__Abgegebene_Stimmen__Anzahl'].replace('-', '0')) if x['2_Auspraegung_Code'] == 'ERSTSTIMME' else 0,
      axis = 1)
      df['GUESTI__Gueltige_Stimmen__Anzahl_GESAMTSTIMME'] = df.apply(lambda x:
        int(x['GUESTI__Abgegebene_Stimmen__Anzahl'].replace('-', '0')) if x['2_Auspraegung_Code'] == 'GESAMTSTIMME' else 0,
      axis = 1)
      df['UNGSTI__Gueltige_Stimmen__Anzahl_ERSTSTIMME'] = df.apply(lambda x:
        int(x['UNGSTI__Gueltige_Stimmen__Anzahl'].replace('-', '0')) if x['2_Auspraegung_Code'] == 'ERSTSTIMME' else 0,
      axis = 1)
      df['UNGSTI__Gueltige_Stimmen__Anzahl_GESAMTSTIMME'] = df.apply(lambda x:
        int(x['UNGSTI__Gueltige_Stimmen__Anzahl'].replace('-', '0')) if x['2_Auspraegung_Code'] == 'GESAMTSTIMME' else 0,
      axis = 1)

      df = df.groupby('Zeit', as_index = False, sort = False).aggregate('sum')
      df['2_Auspraegung_Code'] = 'ZWEITSTIMME'
      df['GUESTI__Gueltige_Stimmen__Anzahl'] = df['GUESTI__Gueltige_Stimmen__Anzahl_GESAMTSTIMME'] - df['GUESTI__Gueltige_Stimmen__Anzahl_ERSTSTIMME']
      df['UNGSTI__Gueltige_Stimmen__Anzahl'] = df['UNGSTI__Gueltige_Stimmen__Anzahl_GESAMTSTIMME'] - df['UNGSTI__Gueltige_Stimmen__Anzahl_ERSTSTIMME']
    elif wahl == 'Gemeinderatswahl':
      df['GUESTI__Gueltige_Stimmen__Anzahl'] = df['STIZ02__Abgegebene_Stimmzettel__Anzahl']
      df['UNGSTI__Gueltige_Stimmen__Anzahl'] = df['STIZ03__Gueltige_Stimmzettel__Anzahl']

    if len(df) == 0:
      raise Exception('Queried data is empty')
  
    rows = [{
      'Wahl': wahl,
      'Wahltag': datetime.strptime(x['Zeit'], '%d.%m.%Y').strftime('%Y-%m-%d'),
      'Stimmbezirk': 'Gesamt',
      'Stimmentyp': str(x.get('2_Auspraegung_Code', '')).capitalize(),
      'GueltigeStimmen': x['GUESTI__Gueltige_Stimmen__Anzahl'],
      'UngueltigeStimmen': x['UNGSTI__Gueltige_Stimmen__Anzahl'],
    } for x in df.to_dict('records')]

    return rows
