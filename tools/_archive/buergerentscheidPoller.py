#!/usr/bin/env python

import csv
import io
import json
import os
from pathlib import Path
import requests
import sys
import traceback
from urllib.parse import urlparse

def read_file(path: str) -> str:
  file = Path(path)
  if not file.is_file():
    return None

  with open(path, 'r') as reader:
    return reader.read()

def pull_updates(url: str) -> str:
  req = requests.get(url)
  req.encoding = 'utf8'

  if req.status_code != 200:
    raise Exception('Can\'t access URL ' + url + ': Status code ' + str(req.status_code))

  dirname = os.path.dirname(__file__)
  data_dir = os.path.join(dirname, '..', 'data', 'buergerentscheid-windkraft-ebersberger-forst', 'raw')

  filename = os.path.basename(urlparse(url).path)
  filepath = os.path.join(data_dir, filename)

  existing_content = read_file(filepath)
  if req.text == existing_content:
    # no update
    return None

  with open(filepath, 'w') as writer:
    writer.write(req.text)

  return req.text

def pull_updates_gesamt():
  return pull_updates('https://okvote.osrz-akdb.de/OK.VOTE_OB/16052021/09175000/html5/Open-Data-Kreis-Buergerentscheid-Bayern1481.csv')

def pull_updates_gemeinden():
  return pull_updates('https://okvote.osrz-akdb.de/OK.VOTE_OB/16052021/09175000/html5/Open-Data-Kreis-Buergerentscheid-Bayern1483.csv')


if len(sys.argv) == 1:
  pull_updates_gesamt()
  pull_updates_gemeinden()

elif len(sys.argv) == 3 or len(sys.argv) == 4:
  import telebot

  telegram_token = sys.argv[1]
  telegram_debug_chatid = sys.argv[2]
  telegram_public_chatid = sys.argv[2] # defaults to debug

  if len(sys.argv) == 4:
    telegram_public_chatid = sys.argv[3]

  telegram_bot = telebot.TeleBot(telegram_token)

  try:
    data = pull_updates_gesamt()

    if data != None:
      f = io.StringIO(data)
      csv_reader = csv.DictReader(f, delimiter = ";")

      csv_data = list(csv_reader)

      msg = '\n'.join([
        '<strong>UPDATE Wahlergebnisse Bürgerentscheid Ebersberger Forst</strong>',
        'Neue CSV-Daten sind angekommen (<a href="https://okvote.osrz-akdb.de/OK.VOTE_OB/16052021/09175000/html5/OpenDataInfo.html">Quelle</a>):'
        '<pre>' + json.dumps(csv_data, indent = 2) + '</pre>',
        'Dokumentation der Felder:',
        '- A1: Wahlberechtigte ohne Sperrvermerk W',
        '- A2: Wahlberechtigte mit Sperrvermerk W',
        '- A3: Wahlberechtigte nicht im Wählerverzeichnis',
        '- A: Wahlberechtigte insgesamt',
        '- B: Wähler',
        '- B1: Wähler mit Wahlschein',
        '- C04: Gültige Stimmen',
        '- C03: Ungültige Stimmen',
        '- C01: ?? (evtl. D1, also JA?)',
        '- C02: ?? (evtl. D2, also NEIN?)',
        '- D1: JA',
        '- D2: NEIN',
        '',
        'Offizielle Ergebnisse zu finden bei <a href="https://okvote.osrz-akdb.de/OK.VOTE_OB/16052021/09175000/html5/KreisBuergerentscheid_Bayern_148_Kreis_Landkreis_Ebersberg.html">OK.VOTE</a>.'
      ])

      telegram_bot.send_message(telegram_public_chatid, msg, parse_mode = "HTML")

  except Exception as e:
    telegram_bot.send_message(telegram_debug_chatid, ("Error: %s" % traceback.format_exc())[0:4096])

  try:
    data = pull_updates_gemeinden()

    # no telegram update here

  except Exception as e:
    telegram_bot.send_message(telegram_debug_chatid, ("Error: %s" % traceback.format_exc())[0:4096])

else:
  print('Usage: [python] urlPoller.py [<telegram-token> <telegram-debug-chatid> [<telegram-public-chatid>]]')
  exit(1)
