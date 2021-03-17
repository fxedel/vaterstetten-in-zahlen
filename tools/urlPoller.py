from bs4 import BeautifulSoup
from datetime import date
import re
import requests
import sys
import csv
import os

from lib.lastvaluestorage import LastValueStorage


def parse_website() -> dict:
  req = requests.get('https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/')

  if req.status_code != 200:
    raise Exception('Can\'t access webpage: Status code ' + str(req.status_code))

  soup = BeautifulSoup(req.text, 'html.parser')

  h3_impfstatistik = soup.find(name = 'h3', text = 'Impfstatistik')
  text_elems = h3_impfstatistik.find_all_next(string = re.compile('.+'), limit = 5)

  return {
    'datum': date.today().isoformat(),
    'erstimpfungen': re.compile('Erstimpfung:\s+(\d+)').findall(text_elems[1])[0],
    'zweitimpfungen': re.compile('Zweitimpfung:\s+(\d+)').findall(text_elems[3])[0],
    'erstimpfungenAb80': re.compile('davon über 80 Jahre:\s+(\d+)').findall(text_elems[2])[0],
    'zweitimpfungenAb80': re.compile('davon über 80 Jahre:\s+(\d+)').findall(text_elems[4])[0],
    'onlineanmeldungen': 'NA',
  }


def get_new_values(previous_values: dict) -> dict:
  new_values = parse_website()
  
  if (new_values != previous_values):
    return new_values
  
  return None


def get_csv_string(values: dict) -> str:
  return '%(datum)s,%(erstimpfungen)s,%(zweitimpfungen)s,%(erstimpfungenAb80)s,%(zweitimpfungenAb80)s,%(onlineanmeldungen)s' % values


def send_updates_to_telegram(telegram_token: str, telegram_chatid: str):
  import telebot

  telegram_bot = telebot.TeleBot()

  vacc_storage: LastValueStorage[dict] = LastValueStorage('vaccinations')
  previous_values = vacc_storage.get_last_values()

  try:
    values = get_new_values(previous_values)
    if (values != None):
      csv_string = get_csv_string(values)

      telegram_bot.send_message(telegram_chatid, '`%s`' % csv_string, parse_mode = "MarkdownV2")
      telegram_bot.send_message(telegram_chatid, 'https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/')

      vacc_storage.write_last_values(values)

  except Exception as e:
    telegram_bot.send_message(telegram_chatid, "Error: {0}".format(e))


def get_last_csv_row(file_name: str) -> dict:
  with open(file_name, mode='r') as csv_file:
    csv_reader = csv.DictReader(csv_file)

    for row in csv_reader:
      continue
    
    return row # last processed row


def write_updates_to_file():
  dirname = os.path.dirname(__file__)
  file_name = os.path.join(dirname, '..', 'data', 'lra-ebe-corona', 'impfungenLkEbe.csv')

  previous_values = get_last_csv_row(file_name)
  values = get_new_values(previous_values)

  if (values != None):
    csv_string = get_csv_string(values)
    print(csv_string)

    with open(file_name, mode='a') as csv_file:
      csv_file.write(csv_string + '\n')


if len(sys.argv) == 3:
  send_updates_to_telegram(telegram_token=sys.argv[1], telegram_chatid=sys.argv[2])
elif len(sys.argv) == 1:
  write_updates_to_file()
else:
  print('Usage: [python] urlPoller.py [<telegram-token> <telegram-chatid>]')
  exit(1)
