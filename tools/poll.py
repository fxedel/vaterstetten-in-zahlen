from copy import deepcopy
import csv
import sys
import telebot
import traceback
from typing import List

import pollers

def read_csv_rows(file_name: str) -> List[dict]:
  with open(file_name, mode='r') as csv_file:
    csv_reader = csv.DictReader(csv_file)

    rows = []

    for row in csv_reader:
      rows.append(row)

    return rows

def write_csv_rows(file_name: str, csv_rows: List[dict]):
  with open(file_name, mode='w') as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames = csv_rows[0].keys(), dialect = 'unix', quoting = csv.QUOTE_MINIMAL)

    writer.writeheader()
    writer.writerows(csv_rows)


telegram_bot = None
telegram_debug_chatid = None
telegram_public_chatid = None

if len(sys.argv) == 1:
  # no telegram used
  pass
elif len(sys.argv) == 3 or len(sys.argv) == 4:
  telegram_token = sys.argv[1]
  telegram_debug_chatid = sys.argv[2]
  telegram_bot = telebot.TeleBot(telegram_token)

  if len(sys.argv) == 4:
    telegram_public_chatid = sys.argv[3]
  else:
    telegram_public_chatid = telegram_debug_chatid
else:
  print('Usage: [python] poll.py [<telegram-token> <telegram-chatid>]')
  exit(1)


failed = False

for key, poller in pollers.all.items():
  try:
    print('Executing poller ' + key)

    current_data = read_csv_rows(poller.get_csv_filename())
    new_data = poller.get_new_data(
      deepcopy(current_data),
      telegram_bot,
      telegram_public_chatid
    )

    if current_data == new_data:
      continue

    write_csv_rows(poller.get_csv_filename(), new_data)

  except Exception as e:
    print(traceback.format_exc())
    failed = True

    if telegram_bot != None:
      telegram_bot.send_message(telegram_debug_chatid, "Error: %s" % traceback.format_exc())

if failed:
  exit(1)



