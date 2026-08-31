import hashlib
import json
import math
import os
import re
import requests
import time
from typing import List

import pollers.poller

overpass_api_url = 'https://overpass-api.de/api/interpreter'

class GenericOverpassPoller(pollers.poller.Poller):
  def query_overpass_from_file(self, file_name: str) -> dict:
    query_path = os.path.join(os.path.dirname(__file__), 'overpass', file_name)

    with open(query_path) as file:        
      overpass_query = file.read()
      overpass_data = self.query_overpass(overpass_query)

      return overpass_data

  def query_overpass(self, query: str) -> dict:
    query_hash = hashlib.md5(query.encode('utf8')).hexdigest()

    # cache is mainly used for local development, where you don't want to call the Overpass API every time you change the poller
    cache_file_name = os.path.join('kinderbetreuung', f'overpass-{query_hash}.geojson')

    if not self.has_cache_file(cache_file_name, ttl_s = 7*24*60*60):
      print('> Cache file not present or outdated, querying Overpass API at %s …' % overpass_api_url)

      start = time.time()
      res = requests.post(
        overpass_api_url,
        data = {'data': query},
        headers = {'Accept-Charset': 'utf-8;q=0.7,*;q=0.7'},
      ) # takes about 150s
      print('> Downloaded OpenStreetMap data in %.1fs' % (time.time() - start))

      if res.status_code != 200:
        raise Exception(f'Overpass API returned unexpected status code: {res.status_code} {res.reason}')

      data = res.json()

      if 'remark' in data and data['remark'] != None and len(data['remark']) > 0:
        raise Exception(f"Overpass API returned unexpected remark: {data['remark']}")

      self.write_cache_file(cache_file_name, res.text)

      return data

    with open(os.path.join(self.cache_dir, cache_file_name), mode='r') as file:
      data = json.load(file)
      return data
