#!/usr/bin/env python

from bs4 import BeautifulSoup
import csv
from datetime import date
import os
import re
import requests
import sys
import traceback


def parse_website() -> dict:
  req = requests.get('https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/')

  if req.status_code != 200:
    raise Exception('Can\'t access webpage: Status code ' + str(req.status_code))

  data = {
    'datum': date.today().isoformat(),
    'erstimpfungen': 'NA',
    'zweitimpfungen': 'NA',
    'erstimpfungenAb80': 'NA',
    'zweitimpfungenAb80': 'NA',
    'erstimpfungenHausaerzte': 'NA',
    'zweitimpfungenHausaerzte': 'NA',
    'registriert': 'NA',
  }

  soup = BeautifulSoup(req.text, 'html.parser')

  h3_impfstatistik = soup.find(name = 'h3', text = 'Impfstatistik')
  regex = re.compile(
    r'Erstimpfung(en)?:\s+(?P<erstimpfungen>\d+)\s*'
    r'(davon über 80 Jahre\*?:\s+(?P<erstimpfungenAb80>\d+))?\s*'
    r'(davon Impfungen bei Haus- und Fachärzten:\s+(?P<erstimpfungenHausaerzte>\d+))?\s*'
    r'Zweitimpfung(en)?:\s+(?P<zweitimpfungen>\d+)\s*'
    r'(davon über 80 Jahre\*?:\s+(?P<zweitimpfungenAb80>\d+))?\s*'
    r'(davon Impfungen bei Haus- und Fachärzten:\s+(?P<zweitimpfungenHausaerzte>\d+))?\s*'
  )
  match = regex.search(h3_impfstatistik.parent.text)

  if match == None:
    raise Exception('Regex could not find data in web page')

  for key, value in match.groupdict().items():
    if value != None:
      data[key] = value

  return data

def has_new_values(current_values: dict, last_values: dict) -> bool:
  for key, value in current_values.items():
    if key != 'datum' and value != 'NA' and value != last_values[key]:
      return True
  return False

def get_csv_string(values: dict) -> str:
  return '%(datum)s,%(erstimpfungen)s,%(zweitimpfungen)s,%(erstimpfungenAb80)s,%(zweitimpfungenAb80)s,%(erstimpfungenHausaerzte)s,%(zweitimpfungenHausaerzte)s,%(registriert)s' % values


def read_csv_rows(file_name: str) -> list:
  with open(file_name, mode='r') as csv_file:
    csv_reader = csv.DictReader(csv_file)

    rows = []

    for row in csv_reader:
      rows.append(row)

    return rows

def write_csv_rows(file_name: str, csv_rows: list):
  with open(file_name, mode='w') as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames = csv_rows[0].keys(), dialect = 'unix', quoting = csv.QUOTE_MINIMAL)

    writer.writeheader()
    writer.writerows(csv_rows)

def write_updates_to_file() -> str:
  dirname = os.path.dirname(__file__)
  file_name = os.path.join(dirname, '..', 'data', 'lra-ebe-corona', 'impfungenLkEbe.csv')

  csv_rows = read_csv_rows(file_name)

  last_csv_row = csv_rows[-1]
  current_values = parse_website()

  print(current_values)

  if (not has_new_values(current_values, last_csv_row)):
    print('No changes in vaccination data compared to last CSV row.')
    return None

  # either update last row (on same day) or add new row
  if last_csv_row['datum'] == current_values['datum']:
    for key, value in current_values.items():
      if value != "NA":
        last_csv_row[key] = value
  else:
    csv_rows.append(current_values)

  write_csv_rows(file_name, csv_rows)

  updated_csv_string = get_csv_string(csv_rows[-1])

  return updated_csv_string

def send_updates_to_telegram(telegram_token: str, telegram_chatid: str):
  import telebot

  telegram_bot = telebot.TeleBot(telegram_token)

  try:
    csv_string = write_updates_to_file()

    if (csv_string != None):
      telegram_bot.send_message(telegram_chatid, '`%s`' % csv_string, parse_mode = "MarkdownV2")

      links = ' \| '.join([
        '[LRA Impfzentrum](https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/)',
        '[Commits](https://github.com/fxedel/vaterstetten-in-zahlen/commits/master)',
        '[Production](https://vaterstetten-in-zahlen.de/)',
      ])
      telegram_bot.send_message(telegram_chatid, links, parse_mode = "MarkdownV2", disable_web_page_preview = True)

  except Exception as e:
    telegram_bot.send_message(telegram_chatid, "Error: %s" % traceback.format_exc())
    exit(1)


if len(sys.argv) == 1:
  write_updates_to_file()

elif len(sys.argv) == 3:
  send_updates_to_telegram(telegram_token=sys.argv[1], telegram_chatid=sys.argv[2])

else:
  print('Usage: [python] urlPoller.py [<telegram-token> <telegram-chatid>]')
  exit(1)
