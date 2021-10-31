import csv
import os
import sys
import traceback
from typing import List
import telebot

telegram_bot = None
telegram_debug_chatid = None
telegram_public_chatid = None

data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')

if len(sys.argv) == 3 or len(sys.argv) == 4:
  telegram_token = sys.argv[1]
  telegram_debug_chatid = sys.argv[2]
  telegram_bot = telebot.TeleBot(telegram_token)

  if len(sys.argv) == 4:
    telegram_public_chatid = sys.argv[3]
  else:
    telegram_public_chatid = telegram_debug_chatid
else:
  print('Usage: [python] dailySummary.py [<telegram-token> <telegram-debug-chatid> [<telegram-public-chatid>]]')
  exit(1)


def read_csv_rows(file_name: str) -> List[dict]:
  with open(os.path.join(data_dir, file_name), mode='r') as csv_file:
    csv_reader = csv.DictReader(csv_file)

    rows = []

    for row in csv_reader:
      rows.append(row)

    return rows

try:
  lines = []

  rows_gemeinden = read_csv_rows(os.path.join('corona-fallzahlen', 'arcgisInzidenzGemeinden.csv'))
  rows_vaterstetten = list(filter(lambda x: x['ort'] == 'Vaterstetten', rows_gemeinden))
  lines += [
    '*Corona-Zahlen für Vaterstetten*',
    '_7-Tage-Inzidenz:_ *' + rows_vaterstetten[-1]['inzidenz7tage'] + '*',
    '_Neue Fälle zum Vortag:_ *' + rows_vaterstetten[-1]['neuPositiv'] + '*',
    '_Stand:_ *' + rows_vaterstetten[-1]['datum'] + '*',
    '',
  ]

  rows_landkreis = read_csv_rows(os.path.join('corona-fallzahlen', 'arcgisInzidenzLandkreis.csv'))
  lines += [
    '*Corona-Zahlen für den Landkreis Ebersberg*',
    '_7-Tage-Inzidenz:_ *' + rows_landkreis[-1]['inzidenz7tage'] + '*',
    '_Neue Fälle zum Vortag:_ *' + rows_landkreis[-1]['neuPositiv'] + '*',
    '_Stand:_ *' + rows_landkreis[-1]['datum'] + '*',
    '',
  ]

  rows_impfungen = read_csv_rows(os.path.join('corona-impfungen', 'arcgisImpfungen.csv'))
  lines += [
    '*Impfungen im Landkreis Ebersberg*',
    '_Erstimpfungen_: *%s*' % rows_impfungen[-1]['erstimpfungen'],
    '_Zweitimpfungen_: *%s*' % rows_impfungen[-1]['zweitimpfungen'],
    '_Drittimpfungen_: *%s*' % rows_impfungen[-1]['drittimpfungen'],
    '_Verabreichte Impfdosen_: *%s*' % rows_impfungen[-1]['impfdosen'],
    '_Stand:_ *%s*' % rows_impfungen[-1]['datum'],
    '',
  ]

  lines += [
    '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de)',
  ]

  telegram_bot.send_message(
    telegram_public_chatid,
    '\n'.join(lines),
    parse_mode = "Markdown",
    disable_web_page_preview = True
  )

  pass

except Exception as e:
  print(traceback.format_exc())

  telegram_bot.send_message(telegram_debug_chatid, "Exception in dailySummary: %s" % (traceback.format_exc()))

  exit(1)
