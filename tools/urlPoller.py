from bs4 import BeautifulSoup
from datetime import date
import re
import requests
import sys

from lib.lastvaluestorage import LastValueStorage

telegram_bot = None
telegram_chatid = None

if len(sys.argv) == 3:
  import telebot

  telegram_bot = telebot.TeleBot(sys.argv[1])
  telegram_chatid = sys.argv[2]
elif len(sys.argv) != 1:
  print('Usage: [python] urlPoller.py [<telegram-token> <telegram-chatid>]')
  exit(1)


try:
  req = requests.get('https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/')

  vacc_storage: LastValueStorage[dict] = LastValueStorage('vaccinations')

  if req.status_code != 200:
    raise Exception('Can\'t access webpage: Status code ' + str(req.status_code))

  soup = BeautifulSoup(req.text, 'html.parser')

  h3_impfstatistik = soup.find(name = 'h3', text = 'Impfstatistik')
  text_elems = h3_impfstatistik.find_all_next(string = re.compile('.+'), limit = 5)

  values = {
    'erstimpfungen': re.compile('Erstimpfung:\s+(\d+)').findall(text_elems[1])[0],
    'zweitimpfungen': re.compile('Zweitimpfung:\s+(\d+)').findall(text_elems[3])[0],
    'erstimpfungenAb80': re.compile('davon über 80 Jahre:\s+(\d+)').findall(text_elems[2])[0],
    'zweitimpfungenAb80': re.compile('davon über 80 Jahre:\s+(\d+)').findall(text_elems[4])[0],
  }

  if (vacc_storage.is_different_to_last_values(values)):
    csv_dict = values.copy()
    csv_dict['date'] = date.today().isoformat()
    csv_string = '%(date)s,%(erstimpfungen)s,%(zweitimpfungen)s,%(erstimpfungenAb80)s,%(zweitimpfungenAb80)s,NA' % csv_dict

    if (telegram_bot):
      telegram_bot.send_message(telegram_chatid, '`%s`' % csv_string, parse_mode = "MarkdownV2")
      telegram_bot.send_message(telegram_chatid, 'https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/')
    else:
      print(csv_string)

    vacc_storage.write_last_values(values)

except Exception as e:
  error = "Error: {0}".format(e)

  if (telegram_bot):
    telegram_bot.send_message(telegram_chatid, error)
  else:
    print(error)
    exit(1)
