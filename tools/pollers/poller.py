import csv
import difflib
import io
import os
import time
import telebot
from typing import Callable, List, Optional


class Poller:
  def __init__(
    self,
    telegram_bot: Optional[telebot.TeleBot],
    telegram_public_chat_id: Optional[str],
    telegram_debug_chat_id: Optional[str],
  ):
    self.telegram_bot = telegram_bot
    self.telegram_public_chat_id = telegram_public_chat_id
    self.telegram_debug_chat_id = telegram_debug_chat_id

    self.data_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'data')
    self.cache_dir = os.path.join(self.data_dir, '.cache')

  def run(self):
    pass

  def read_csv_rows(self, file_name: str) -> List[dict]:
    with open(os.path.join(self.data_dir, file_name), mode='a') as csv_file:
      # create file if needed
      pass

    with open(os.path.join(self.data_dir, file_name), mode='r') as csv_file:
      csv_reader = csv.DictReader(csv_file)

      rows = []

      for row in csv_reader:
        rows.append(row)

      return rows

  def write_csv_rows(self, file_name: str, csv_rows: List[dict]):
    with open(os.path.join(self.data_dir, file_name), mode='w') as csv_file:
      writer = csv.DictWriter(csv_file, fieldnames = csv_rows[0].keys(), dialect = 'unix', quoting = csv.QUOTE_MINIMAL)

      writer.writeheader()
      writer.writerows(csv_rows)
      print('> Updated file \'%s\'' % file_name)

  def get_csv_diff(self, file_name: str, new_data: List[dict], context: int = 1) -> List[str]:
    with open(os.path.join(self.data_dir, file_name), mode='r') as file:
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

  def send_csv_diff_via_telegram(self, csv_diff: List[str]):
    if len(csv_diff) == 0:
      return

    if self.telegram_bot == None:
      return

    if self.telegram_public_chat_id == None:
      return

    data = ''.join(csv_diff)
    self.telegram_bot.send_message(
      self.telegram_public_chat_id,
      '```\n' + (data[:4080] if len(data) > 4080 else data) + '```',
      parse_mode = "Markdown"
    )

  def send_public_telegram_message(self, lines: list[str]):
    if len(lines) == 0:
      return

    if self.telegram_bot == None:
      return

    if self.telegram_public_chat_id == None:
      return

    self.telegram_bot.send_message(
      self.telegram_public_chat_id,
      '\n'.join(lines),
      parse_mode = "Markdown",
      disable_web_page_preview = True
    )


  def list_with_unique_key(self, list: List[dict], key_func: Callable[[dict], str], auto_increment: bool = False) -> dict[str, dict]:
    dicts_by_key: dict[str, List[dict]] = {}

    for item in list:
      key = key_func(item)

      if not key in dicts_by_key:
        dicts_by_key[key] = []

      dicts_by_key[key].append(item)

    dict_by_unique_key: dict[str, dict] = {}

    for (key, val) in dicts_by_key.items():
      if len(val) == 1:
        dict_by_unique_key[key] = val[0]
      elif auto_increment:
        for (i, item) in enumerate(val):
          unique_key = f'{key}-{i+1}'
          if unique_key in dict_by_unique_key:
            raise Exception(f'Auto-incremented key "{unique_key}" is not unique in list')
          dict_by_unique_key[unique_key] = item
      else:
        raise Exception(f'Key "{key}" is not unique in list')

    return dict_by_unique_key

  def dict_diff(self, before: dict[str, dict], after: dict[str, dict]) -> tuple[list[str], list[str], list[str]]:
    removed = []
    changed = []
    added = []

    for key in before:
      if not key in after:
        removed.append(key)
      elif before[key] != after[key]:
        changed.append(key)

    for key in after:
      if not key in before:
        added.append(key)

    return (removed, changed, added)

  def has_cache_file(self, file_name: str, ttl_s: int = None) -> bool:
    cache_file_name = os.path.join(self.cache_dir, file_name)

    if not os.path.isfile(cache_file_name):
      return False

    if ttl_s is None:
      return True

    stat = os.stat(cache_file_name)    
    age_s = time.time() - stat.st_mtime

    if age_s > ttl_s:
      # cache is expired
      return False

    return True
  
  def write_cache_file(self, file_name: str, content: str):
    cache_file_name = os.path.join(self.cache_dir, file_name)

    os.makedirs(os.path.dirname(cache_file_name), exist_ok = True)

    with open(cache_file_name, "w") as f:
      f.write(content)
