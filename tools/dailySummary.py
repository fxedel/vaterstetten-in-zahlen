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

  rows_energiemonitor = read_csv_rows(os.path.join('energie', 'bayernwerkEnergiemonitorLandkreis.csv'))
  lines += [
    '*Strom-Daten für den Landkreis Ebersberg*',
    f"_Stichtag:_ *{rows_energiemonitor[-1]['datum']}*",
    f"_Verbrauch:_ *{round(float(rows_energiemonitor[-1]['verbrauch_kWh'])/1000)} MWh*",
    f"_\tdavon Private Haushalte:_ *{round(float(rows_energiemonitor[-1]['verbrauchPrivat_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['verbrauchPrivat_kWh'])/float(rows_energiemonitor[-1]['verbrauch_kWh'])*100)}%)",
    f"_\tdavon Industrie & Gewerbe:_ *{round(float(rows_energiemonitor[-1]['verbrauchGewerbe_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['verbrauchGewerbe_kWh'])/float(rows_energiemonitor[-1]['verbrauch_kWh'])*100)}%)",
    f"_\tdavon öffentlich/kommunal:_ *{round(float(rows_energiemonitor[-1]['verbrauchOeffentlich_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['verbrauchOeffentlich_kWh'])/float(rows_energiemonitor[-1]['verbrauch_kWh'])*100)}%)",
    f"_Erzeugung:_ *{round(float(rows_energiemonitor[-1]['erzeugung_kWh'])/1000)} MWh*",
    f"_\tdavon nicht erneuerbar:_ *{round(float(rows_energiemonitor[-1]['erzeugungNichtErneuerbar_kWh'])/1000)} MWh*",
    f"_\tdavon erneuerbar:_ *{round(float(rows_energiemonitor[-1]['erzeugungErneuerbar_kWh'])/1000)} MWh*",
    f"_\t\tdavon Biomasse:_ *{round(float(rows_energiemonitor[-1]['erzeugungBiomasse_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['erzeugungBiomasse_kWh'])/float(rows_energiemonitor[-1]['erzeugungErneuerbar_kWh'])*100)}%)",
    f"_\t\tdavon Solar:_ *{round(float(rows_energiemonitor[-1]['erzeugungSolar_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['erzeugungSolar_kWh'])/float(rows_energiemonitor[-1]['erzeugungErneuerbar_kWh'])*100)}%)",
    f"_\t\tdavon Windkraft:_ *{round(float(rows_energiemonitor[-1]['erzeugungWind_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['erzeugungWind_kWh'])/float(rows_energiemonitor[-1]['erzeugungErneuerbar_kWh'])*100)}%)",
    f"_\t\tdavon Wasserkraft:_ *{round(float(rows_energiemonitor[-1]['erzeugungWasserkraft_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['erzeugungWasserkraft_kWh'])/float(rows_energiemonitor[-1]['erzeugungErneuerbar_kWh'])*100)}%)",
    f"_\t\tdavon weitere Erneuerbare:_ *{round(float(rows_energiemonitor[-1]['erzeugungAndereErneuerbar_kWh'])/1000)} MWh* ({round(float(rows_energiemonitor[-1]['erzeugungAndereErneuerbar_kWh'])/float(rows_energiemonitor[-1]['erzeugungErneuerbar_kWh'])*100)}%)",
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
