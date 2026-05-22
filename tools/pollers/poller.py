import csv
import difflib
import io
import os
import re
import time
from html import escape as html_escape
from typing import Callable, List

from notifier import EmailNotifier


class Poller:
  def __init__(
    self,
    email_notifier: EmailNotifier,
    poller_name: str,
  ):
    self.email_notifier = email_notifier
    self.poller_name = poller_name

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

  def send_csv_diff_via_email(self, csv_diff: List[str]):
    if len(csv_diff) == 0:
      return

    data = ''.join(csv_diff)
    data = data[:12000] if len(data) > 12000 else data

    html_body = '<html><body><pre>' + html_escape(data) + '</pre></body></html>'

    self.email_notifier.send(
      level = 'INFO',
      poller_name = self.poller_name,
      subject = 'CSV diff',
      body = data,
      body_html = html_body,
    )

  def send_info_email(self, lines: list[str], subject: str = None):
    if len(lines) == 0:
      return

    chosen_subject = subject if subject else self.infer_subject_from_lines(lines, fallback = 'Update')

    plain_body = '\n'.join(lines)
    html_body = self.render_html_lines(lines)

    self.email_notifier.send(
      level = 'INFO',
      poller_name = self.poller_name,
      subject = chosen_subject,
      body = plain_body,
      body_html = html_body,
    )

  def send_error_email(self, lines: list[str], subject: str = None):
    if len(lines) == 0:
      return

    chosen_subject = subject if subject else self.infer_subject_from_lines(lines, fallback = 'Error state')

    plain_body = '\n'.join(lines)
    html_body = self.render_html_lines(lines)

    self.email_notifier.send(
      level = 'ERROR',
      poller_name = self.poller_name,
      subject = chosen_subject,
      body = plain_body,
      body_html = html_body,
    )

  def render_html_lines(self, lines: list[str]) -> str:
    rendered_lines = []

    for line in lines:
      if line == '':
        rendered_lines.append('<br>')
      else:
        rendered_lines.append(f'<div>{self.render_html_line(line)}</div>')

    return '<html><body>' + '\n'.join(rendered_lines) + '</body></html>'

  def render_html_line(self, line: str) -> str:
    bold = len(line) >= 2 and line.startswith('*') and line.endswith('*')
    if bold:
      line = line[1:-1]

    rendered = []
    last_index = 0

    for match in re.finditer(r'\[(.*?)\]\((.*?)\)', line):
      rendered.append(html_escape(line[last_index:match.start()]))
      rendered.append(
        '<a href="%s">%s</a>' % (
          html_escape(match.group(2), quote = True),
          html_escape(match.group(1)),
        )
      )
      last_index = match.end()

    rendered.append(html_escape(line[last_index:]))

    result = ''.join(rendered)
    if bold:
      result = f'<strong>{result}</strong>'

    return result

  def infer_subject_from_lines(self, lines: list[str], fallback: str) -> str:
    if len(lines) == 0:
      return fallback

    first_line = lines[0]
    first_line = re.sub(r'\[(.*?)\]\((.*?)\)', r'\1', first_line)
    first_line = first_line.replace('*', '').replace('`', '').strip()

    if len(first_line) == 0:
      return fallback

    return first_line[:120]

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
