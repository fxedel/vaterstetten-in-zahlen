import csv
import difflib
import io
import os
import telebot
from typing import List, Optional

data_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'data')

class Poller:
  def __init__(
    self,
    telegram_bot: Optional[telebot.TeleBot],
    telegram_chat_id: Optional[str],
  ):
    self.telegram_bot = telegram_bot
    self.telegram_chat_id = telegram_chat_id

  def run(self):
    pass

  def read_csv_rows(self, file_name: str) -> List[dict]:
    with open(os.path.join(data_dir, file_name), mode='r') as csv_file:
      csv_reader = csv.DictReader(csv_file)

      rows = []

      for row in csv_reader:
        rows.append(row)

      return rows

  def write_csv_rows(self, file_name: str, csv_rows: List[dict]):
    with open(os.path.join(data_dir, file_name), mode='w') as csv_file:
      writer = csv.DictWriter(csv_file, fieldnames = csv_rows[0].keys(), dialect = 'unix', quoting = csv.QUOTE_MINIMAL)

      writer.writeheader()
      writer.writerows(csv_rows)
      print('> Updated file \'%s\'' % file_name)

  def get_csv_diff(self, file_name: str, new_data: List[dict], context: int = 1) -> List[str]:
    with open(os.path.join(data_dir, file_name),mode='r') as file:
      current_csv_content = file.read()

    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames = new_data[0].keys(), dialect = 'unix', quoting = csv.QUOTE_MINIMAL)
    writer.writeheader()
    writer.writerows(new_data)
    new_csv_content = output.getvalue()

    return list(difflib.unified_diff(
      current_csv_content.splitlines(True),
      new_csv_content.splitlines(True),
      file_name,
      n = context
    ))
