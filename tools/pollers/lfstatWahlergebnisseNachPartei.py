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
      rows = []
      rows += self.get_rows_bundestagswahl()
      rows += self.get_rows_europawahl()
      rows += self.get_rows_landtagswahl()
      rows += self.get_rows_gemeinderatswahl()
    except pollers.genesisClient.TemporaryGenesisError as e:
      print(f'> Ignoring temporary GENESIS error: {e}')
      return

    csv_filename = os.path.join('wahlen', 'lfstatWahlergebnisseNachPartei.csv')
    current_rows = self.read_csv_rows(csv_filename)

    if len(rows) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(rows), len(current_rows)))

    if len(rows) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(rows), len(current_rows)))

    csv_diff = self.get_csv_diff(csv_filename, rows)
    self.send_csv_diff_via_telegram(csv_diff)
    self.write_csv_rows(csv_filename, rows)

  def get_rows_bundestagswahl(self):
    table_name = '14111-003z'
    wahl = 'Bundestagswahl'

    start = time.time()
    table_data_csv = self.genesis_client.tablefile(
      name = table_name,
      startyear = 1900,
      regionalvariable = "GEMEIN",
      regionalkey = "09175132",
      classifyingvariable1 = "STIMLW",
      classifyingkey1 = "ZWEITSTIMME"
    )
    print('> Queried data for table %s (%s) in %.1fs' % (table_name, wahl, time.time() - start))

    df = pd.read_csv(io.StringIO(table_data_csv), delimiter = ";")

    df = df[df['3_Auspraegung_Label'] != 'Insgesamt']
    df = df[df['GUESTI__Gueltige_Stimmen__Anzahl'] != '-']
    
    if len(df) == 0:
      raise Exception('Queried data is empty')

    rows = [{
      'Wahl': wahl,
      'Wahltag': datetime.strptime(x['Zeit'], '%d.%m.%Y').strftime('%Y-%m-%d'),
      'Stimmbezirk': 'Gesamt',
      'ParteiCode': x['3_Auspraegung_Code'],
      'ParteiLabel': x['3_Auspraegung_Label'],
      'Stimmentyp': str(x.get('2_Auspraegung_Code', '')).capitalize(),
      'Stimmen': x['GUESTI__Gueltige_Stimmen__Anzahl'],
    } for x in df.to_dict('records')]

    return rows
  
  def get_rows_europawahl(self):
    table_name = '14211-003z'
    wahl = 'Europawahl'

    start = time.time()
    table_data_csv = self.genesis_client.tablefile(
      name = table_name,
      startyear = 1900,
      regionalvariable = "GEMEIN",
      regionalkey = "09175132"
    )
    print('> Queried data for table %s (%s) in %.1fs' % (table_name, wahl, time.time() - start))

    df = pd.read_csv(io.StringIO(table_data_csv), delimiter = ";")
    
    df = df[df['2_Auspraegung_Label'] != 'Insgesamt']
    df = df[df['GUESTI__Gueltige_Stimmen__Anzahl'] != '-']
    
    if len(df) == 0:
      raise Exception('Queried data is empty')

    rows = [{
      'Wahl': wahl,
      'Wahltag': datetime.strptime(x['Zeit'], '%d.%m.%Y').strftime('%Y-%m-%d'),
      'Stimmbezirk': 'Gesamt',
      'ParteiCode': x['2_Auspraegung_Code'],
      'ParteiLabel': x['2_Auspraegung_Label'],
      'Stimmentyp': '',
      'Stimmen': x['GUESTI__Gueltige_Stimmen__Anzahl'],
    } for x in df.to_dict('records')]

    return rows
  
  def get_rows_landtagswahl(self):
    table_name = '14311-003z'
    wahl = 'Landtagswahl'
    
    start = time.time()
    table_data_csv_gesamtstimmen = self.genesis_client.tablefile(
      name = table_name,
      startyear = 1900,
      regionalvariable = "GEMEIN",
      regionalkey = "09175132",
      classifyingvariable1 = "STIMLW",
      classifyingkey1 = "GESAMTSTIMME"
    )
    print('> Queried data for table %s (%s, GESAMTSTIMME) in %.1fs' % (table_name, wahl, time.time() - start))

    df_gesamtstimmen = pd.read_csv(io.StringIO(table_data_csv_gesamtstimmen), delimiter = ";")
  
    start = time.time()
    table_data_csv_erststimmen = self.genesis_client.tablefile(
      name = table_name,
      startyear = 1900,
      regionalvariable = "GEMEIN",
      regionalkey = "09175132",
      classifyingvariable1 = "STIMLW",
      classifyingkey1 = "ERSTSTIMME"
    )
    print('> Queried data for table %s (%s, ERSTSTIMME) in %.1fs' % (table_name, wahl, time.time() - start))

    df_erststimmen = pd.read_csv(io.StringIO(table_data_csv_erststimmen), delimiter = ";")
    
    df = pd.concat([df_gesamtstimmen, df_erststimmen], ignore_index = True, sort = False)
    
    df = df[df['3_Auspraegung_Label'] != 'Insgesamt']
    df = df[df['GUESTI__Gueltige_Stimmen__Anzahl'] != '-']
    
    df['GUESTI__Gueltige_Stimmen__Anzahl_ERSTSTIMME'] = df.apply(lambda x:
      int(x['GUESTI__Gueltige_Stimmen__Anzahl'].replace('-', '0')) if x['2_Auspraegung_Code'] == 'ERSTSTIMME' else 0,
    axis = 1)
    df['GUESTI__Gueltige_Stimmen__Anzahl_GESAMTSTIMME'] = df.apply(lambda x:
      int(x['GUESTI__Gueltige_Stimmen__Anzahl'].replace('-', '0')) if x['2_Auspraegung_Code'] == 'GESAMTSTIMME' else 0,
    axis = 1)

    df = df.groupby(['Zeit', '3_Auspraegung_Code', '3_Auspraegung_Label'], as_index = False, sort = False).aggregate('sum')
    df['2_Auspraegung_Code'] = 'ZWEITSTIMME'
    df['GUESTI__Gueltige_Stimmen__Anzahl'] = df['GUESTI__Gueltige_Stimmen__Anzahl_GESAMTSTIMME'] - df['GUESTI__Gueltige_Stimmen__Anzahl_ERSTSTIMME']

    if len(df) == 0:
      raise Exception('Queried data is empty')

    rows = [{
      'Wahl': wahl,
      'Wahltag': datetime.strptime(x['Zeit'], '%d.%m.%Y').strftime('%Y-%m-%d'),
      'Stimmbezirk': 'Gesamt',
      'ParteiCode': x['3_Auspraegung_Code'],
      'ParteiLabel': x['3_Auspraegung_Label'],
      'Stimmentyp': str(x.get('2_Auspraegung_Code', '')).capitalize(),
      'Stimmen': x['GUESTI__Gueltige_Stimmen__Anzahl'],
    } for x in df.to_dict('records')]

    return rows
  
  def get_rows_gemeinderatswahl(self):
    table_name = '14431-003z'
    wahl = 'Gemeinderatswahl'
  
    start = time.time()
    table_data_csv = self.genesis_client.tablefile(
      name = table_name,
      startyear = 1900,
      regionalvariable = "GEMEIN",
      regionalkey = "09175132"
    )
    print('> Queried data for table %s (%s) in %.1fs' % (table_name, wahl, time.time() - start))

    df = pd.read_csv(io.StringIO(table_data_csv), delimiter = ";")

    df = df[df['2_Auspraegung_Label'] != 'Insgesamt']
    df = df[df['GEWSTI__Gewichtete_Stimmen__Anzahl'] != '-']

    if len(df) == 0:
      raise Exception('Queried data is empty')

    rows = [{
      'Wahl': wahl,
      'Wahltag': datetime.strptime(x['Zeit'], '%d.%m.%Y').strftime('%Y-%m-%d'),
      'Stimmbezirk': 'Gesamt',
      'ParteiCode': x['2_Auspraegung_Code'],
      'ParteiLabel': x['2_Auspraegung_Label'],
      'Stimmentyp': '',
      'Stimmen': x['GEWSTI__Gewichtete_Stimmen__Anzahl'],
    } for x in df.to_dict('records')]

    return rows
  