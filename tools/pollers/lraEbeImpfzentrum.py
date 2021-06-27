from bs4 import BeautifulSoup
from datetime import date
from interface import implements
import os
import re
import requests
import telebot
from typing import List, Optional

import pollers.poller

class Poller(implements(pollers.poller.Poller)):
  def get_csv_filename(self) -> str:
    return os.path.join(pollers.poller.data_dir, 'corona-impfungen', 'impfungenLandkreis.csv')

  def get_new_data(
    self,
    current_data: List[dict],
    telegram_bot: Optional[telebot.TeleBot],
    telegram_chat_id: Optional[str]
  ) -> List[dict]:
    req = requests.get('https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/')

    if req.status_code != 200:
      raise Exception('Can\'t access webpage: Status code ' + str(req.status_code))


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

    new_row = {
      'datum': date.today().isoformat(),
      'erstimpfungen': 'NA',
      'zweitimpfungen': 'NA',
      'erstimpfungenAb80': 'NA',
      'zweitimpfungenAb80': 'NA',
      'erstimpfungenHausaerzte': 'NA',
      'zweitimpfungenHausaerzte': 'NA',
      'registriert': 'NA',
    }
    last_row = current_data[-1]

    is_new_data = False

    for key, value in match.groupdict().items():
      if value != None:
        new_row[key] = value

        if value != last_row[key]:
          is_new_data = True

    if not is_new_data:
      return current_data


    if new_row['datum'] != last_row['datum']:
      current_data.append(new_row)
    else:
      # update last row rather than appending a new row
      for key, value in new_row.items():
        if value != "NA":
          last_row[key] = value


    if telegram_bot != None and telegram_chat_id != None:
      lines = [
        '*Impf-Update für den Landkreis Ebersberg*',
      ]

      descriptions = {
        'erstimpfungen': 'Erstimpfungen',
        'erstimpfungenAb80': 'davon Über-80-Jährige',
        'erstimpfungenHausaerzte': 'davon bei Hausärzten',
        'zweitimpfungen': 'Zweitimpfungen',
        'zweitimpfungenAb80': 'davon Über-80-Jährige',
        'zweitimpfungenHausaerzte': 'davon bei Hausärzten',
      }

      for key, description in descriptions.items():
        if new_row[key] != 'NA':
          lines.append('_' + description + '_: *' + new_row[key] + '*')

      lines.append(' | '.join([
        '[LRA Impfzentrum](https://lra-ebe.de/aktuelles/informationen-zum-corona-virus/impfzentrum/)',
        '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de/?tab=coronaImpfungen)',
      ]))

      telegram_bot.send_message(
        telegram_chat_id,
        '\n'.join(lines),
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )


    return current_data

