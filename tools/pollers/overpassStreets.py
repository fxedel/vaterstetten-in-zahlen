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

overpass_query_administrative = '''
[out:json][timeout:30];
area["boundary"="administrative"]["name"="Vaterstetten"]->.boundingarea;
way(area.boundingarea)["highway"]["highway"!="services"]["highway"!="bus_stop"]["name"]["area"!="yes"];
out geom;
'''

overpass_query_postal_code = '''
[out:json][timeout:180];
area["boundary"="postal_code"]["postal_code"~"^85591|85598|85599|85622|85646$"]->.postalcodes;

foreach.postalcodes->.postalcode(
  way(area.postalcode)["highway"]["highway"!="services"]["highway"!="bus_stop"]["name"]->.ways;
  
  .ways->._;
  convert way
    ::id = id(),
    postal_code = postalcode.set(t["postal_code"]);
  ._ out tags;
);
'''

wikidata_sparql_url = 'https://query-main.wikidata.org/bigdata/namespace/wdq/sparql'

# some street ways are not connected, e.g. due to special crossings with offset,
# but we treat them like they were connected since they belong to the same street
additional_street_connections = [
  {
    'name': 'Am Brunnen', # Baldham
    'way_ids': [171050646, 171050648]
  },
  {
    'name': 'Baldhamer Straße', # Vaterstetten
    'way_ids': [1106086414, 732181476]
  },
  {
    'name': 'Eulenweg', # Vaterstetten
    'way_ids': [677108478, 995789762]
  },
  {
    'name': 'Johann-Strauß-Straße', # Vaterstetten / Baldham
    'way_ids': [228444113, 4599506]
  },
  {
    'name': 'Marderstraße', # Baldham
    'way_ids': [24964491, 1065946913]
  },
  {
    'name': 'Frühlingstraße', # Baldham
    'way_ids': [132661382, 228569312]
  },
  {
    'name': 'Parsdorfer Straße', # Hergolding / Baldham-Dorf
    'way_ids': [228732169, 5107120]
  },
  {
    'name': 'Münchener Straße', # Parsdorf / Neufarn
    'way_ids': [715390238, 821797823]
  },
  {
    'name': 'Rosengasse', # Vaterstetten
    'way_ids': [171005871, 171005872]
  },
  {
    'name': 'Birkenweg', # Vaterstetten
    'way_ids': [437995861, 996089737]
  },
  {
    'name': 'Dreitorspitzstraße', # Vaterstetten
    'way_ids': [986852148, 157296419]
  },
  {
    'name': 'Weißdornweg', # Vaterstetten
    'way_ids': [1330430827, 1330430828]
  },
]

class Poller(pollers.poller.Poller):
  def run(self):
    streets = self.query_osm_streets()

    street_rows = [{
      'Name': street['name'],
      'NamensherkunftWikidata': '/'.join(street['name:etymology:wikidata']),
      'Postleitzahl': '/'.join(street['postal_codes']),
      'OSMWayIDs': '/'.join([str(id) for id in street['way_ids']]),
      'Geometry': street['geometry'],
    } for street in streets]
    csv_filename = os.path.join('verkehr', 'osmStrassen.csv')
    old_street_rows = self.read_csv_rows(csv_filename)
    self.write_csv_rows(csv_filename, street_rows)
    new_street_rows = self.read_csv_rows(csv_filename)

    wikidata_object_ids = list(set([item for street in streets for item in street['name:etymology:wikidata']]))
    wikidata_object_ids.sort(key = lambda x: int(x[1:]))

    etymologies = self.query_etymologies(wikidata_object_ids)
    etymologies.sort(key = lambda x: int(x['WikidataObjekt'][1:]))
    csv_filename = os.path.join('verkehr', 'wikidataNamensherkuenfte.csv')
    old_etymologies = self.read_csv_rows(csv_filename)
    self.write_csv_rows(csv_filename, etymologies)
    new_etymologies = self.read_csv_rows(csv_filename)

    # detect etymology changes
    etymology_key_func = lambda x: x['WikidataObjekt']
    old_etymologies_by_key = self.list_with_unique_key(old_etymologies, etymology_key_func)
    new_etymologies_by_key = self.list_with_unique_key(new_etymologies, etymology_key_func)
    (etymologies_removed, etymologies_changed, etymologies_added) = self.dict_diff(old_etymologies_by_key, new_etymologies_by_key)
  
    if len(etymologies_changed) > 0:
      lines = []
      lines.append('*Namensherkünfte geändert*')

      for key in etymologies_changed:
        old_value = old_etymologies_by_key[key]
        new_value = new_etymologies_by_key[key]

        fields = set(new_value.keys()).intersection(old_value.keys())
        fields = list(filter(lambda field: old_value[field] != new_value[field], fields))

        if len(fields) == 0:
          continue

        bezeichnung = key if 'Bezeichnung' in fields else new_value['Bezeichnung']
        field_texts = map(lambda field: f'{field} "{old_value[field]}" → "{new_value[field]}"', fields)
        lines.append(f"[{bezeichnung}](https://www.wikidata.org/wiki/{key}): {', '.join(field_texts)}")

      if len(lines) > 1:
        lines.append(' | '.join([
          '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de/?tab=strassennamen)',
          '[Commits](https://github.com/fxedel/vaterstetten-in-zahlen/commits/master/data/verkehr/wikidataNamensherkuenfte.csv)',
        ]))
        self.send_public_telegram_message(lines)

    # detect street changes
    street_key_func = lambda x: f"{x['Name']}-{x['Postleitzahl']}"
    old_street_rows_by_key = self.list_with_unique_key(old_street_rows, street_key_func, auto_increment = True)
    new_street_rows_by_key = self.list_with_unique_key(new_street_rows, street_key_func, auto_increment = True)
    (streets_removed, streets_changed, streets_added) = self.dict_diff(old_street_rows_by_key, new_street_rows_by_key)
  
    if len(streets_removed) + len(streets_changed) + len(streets_added) > 0:
      lines = []
      lines.append('*Straßen geändert*')

      etymology_to_string = lambda etymology: f"[{etymology['Bezeichnung']}](https://www.wikidata.org/wiki/{etymology['WikidataObjekt']}) ({etymology['Typ']})" if etymology != None else 'None'

      for key in streets_removed:
        lines.append(f'{key} entfernt')
      for key in streets_added:
        etymology = new_etymologies_by_key.get(new_street_rows_by_key[key]['NamensherkunftWikidata'])
        lines.append(f'{key} hinzugefügt: Namensherkunft = {etymology_to_string(etymology)}')
      for key in streets_changed:
        old_value = old_street_rows_by_key[key]
        new_value = new_street_rows_by_key[key]

        fields = set(new_value.keys()).intersection(old_value.keys())
        fields = list(filter(lambda field: field not in ['OSMWayIDs', 'Geometry'], fields))
        fields = list(filter(lambda field: old_value[field] != new_value[field], fields))

        if len(fields) == 0:
          continue

        field_texts = map(lambda field:
          f'Namensherkunft {etymology_to_string(old_etymologies_by_key.get(old_value[field]))} → {etymology_to_string(new_etymologies_by_key.get(new_value[field]))}' if field == 'NamensherkunftWikidata' else
          f'{field} "{old_value[field]}" → "{new_value[field]}"',
          fields)
        lines.append(f"{key} geändert: {', '.join(field_texts)}")

      if len(lines) > 1:
        lines.append(' | '.join([
          '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de/?tab=strassennamen)',
          '[Commits](https://github.com/fxedel/vaterstetten-in-zahlen/commits/master/data/verkehr/osmStrassen.csv)',
        ]))
        self.send_public_telegram_message(lines)

  def query_osm_streets(self) -> dict:
    data_administrative = self.query_osm(overpass_query_administrative)

    ways = {}

    for element in data_administrative['elements']:
      id = element['id']

      if element['type'] != 'way':
        print('> Warning: skipped non-way element: type = %s, id = %d' % (element['type'], id))
        continue

      if not 'highway' in element['tags']:
        print('> Warning: skipped non-highway element: id = %d' % (id))
        continue

      if element['tags']['highway'] in ['bus_stop']:
        print('> Warning: skipped element: id = %d, tags:highway = %s' % (id, element['tags']['highway']))
        continue

      if 'Geräumt' in element['tags']['name']:
        continue

      if id in ways:
        raise Exception(f'Duplicate way #{id}')
      else:
        ways[id] = element.copy()
        ways[id]['postal_codes'] = []

    data_postal_code = self.query_osm(overpass_query_postal_code)

    for element in data_postal_code['elements']:
      id = element['id']

      if id in ways:
        ways[id]['postal_codes'].append(element['tags']['postal_code'])

    for connection in additional_street_connections:
      for way_id in connection['way_ids']:
        if not way_id in ways:
          raise Exception(f'Additional street connection references now unknown way #{way_id}: {connection}')
        
        way = ways[way_id]
        if way['tags']['name'] != connection['name']:
          raise Exception(f"Additional street connection references way #{way_id} with name '{connection['name']}', but now has name '{way['tags']['name']}'")

    streets = []

    marked_ways = set()

    def find_reachable_ways(way):
      reachable_ways = [way]

      for way_id in ways:
        if way_id in marked_ways:
          continue

        other_way = ways[way_id]

        if way['tags']['name'] != other_way['tags']['name']:
          continue

        directly_connected = len(set(way['nodes']).intersection(set(other_way['nodes']))) > 0

        indirectly_connected = False
        for connection in additional_street_connections:
          if way['id'] in connection['way_ids'] and other_way['id'] in connection['way_ids']:
            indirectly_connected = True
            break

        if directly_connected or indirectly_connected:
          marked_ways.add(way_id)
          reachable_ways += find_reachable_ways(other_way)

      return reachable_ways

    for way_id in ways:
      if way_id in marked_ways:
        continue

      way = ways[way_id]
      marked_ways.add(way_id)

      street_ways = find_reachable_ways(way)

      name = way['tags']['name']
      etymologies = set([street_way['tags']['name:etymology:wikidata'] for street_way in street_ways if 'name:etymology:wikidata' in street_way['tags']])
      postal_codes = list(set([postal_code for street_way in street_ways for postal_code in street_way['postal_codes']]))
      postal_codes.sort()
      way_ids = [street_way['id'] for street_way in street_ways]
      way_ids.sort()

      geometry_sf = 'MULTILINESTRING ('
      for (i, street_way) in enumerate(street_ways):
        geometry_sf += '('

        for (j, node) in enumerate(street_way['geometry']):
          geometry_sf += f"{node['lon']} {node['lat']}"

          if j < len(street_way['geometry']) - 1:
            geometry_sf += ', '

        geometry_sf += ')'

        if i < len(street_ways) - 1:
          geometry_sf += ', '

      geometry_sf += ')'

      if len(etymologies) >= 2:
        raise Exception(f'Different etymologies: street name = {name}, postal_codes = {postal_codes}, etymologies = {etymologies}')

      if len(etymologies) >= 1:
        etymologies = etymologies.pop().split(';')
        invalid_etymologies = list(filter(lambda x: re.match('^Q\\d+$', x) == None, etymologies))
        if len(invalid_etymologies) > 0:
          raise Exception(f'Invalid etymologies: street name = {name}, postal_codes = {postal_codes}, invalid etymologies = {invalid_etymologies}')

      street = {
        'name': way['tags']['name'],
        'name:etymology:wikidata': etymologies,
        'postal_codes': postal_codes,
        'way_ids': way_ids,
        'geometry': geometry_sf,
      }
      streets += [street]

    streets.sort(key = lambda x: x['name'])

    return streets

  def query_osm(self, query: str) -> dict:
    query_hash = hashlib.md5(query.encode('utf8')).hexdigest()

    # cache is mainly used for local development, where you don't want to call the Overpass API every time you change the poller
    cache_file_name = os.path.join('verkehr', f'overpass-{query_hash}.geojson')

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

  def query_etymologies(self, wikidata_entity_ids: List[str]):
    chunk_size = 100

    etymologies = []

    for i in range(math.ceil(len(wikidata_entity_ids)/chunk_size)):
      wikidata_data = self.query_wikidata(wikidata_entity_ids[i*chunk_size:(i+1)*chunk_size])

      for element in wikidata_data['results']['bindings']:
        etymologies.append({
          'WikidataObjekt': shorten_wikidata_entity_reference(element['item']['value']),
          'Bezeichnung': element['itemLabel']['value'],
          'Beschreibung': element.get('itemDescription', {}).get('value'),
          'Typ': get_etymology_type(element),
          'Geschlecht': get_etymology_gender(element),
        })

    return etymologies

  def query_wikidata(self, wikidata_entity_ids: List[str]):
    query = build_sparql_query(wikidata_entity_ids)
    query_hash = hashlib.md5(query.encode('utf8')).hexdigest()

    # cache is mainly used for local development, where you don't want to call the Wikidata API every time you run the poller
    cache_file_name = os.path.join('verkehr', f'wikidata-sparql-{query_hash}.json')

    if not self.has_cache_file(cache_file_name, ttl_s = 7*24*60*60):
      print('> Cache file not present or outdated, querying Wikidata\'s SPARQL API at %s …' % wikidata_sparql_url)

      start = time.time()
      res = requests.get(
        wikidata_sparql_url,
        params = {
          'query': query,
          'format': 'json',
          # 'explain': 'details' # uncomment this for query performance investigation
        },
      ) # takes about 90s
      print('> Downloaded Wikidata data in %.1fs' % (time.time() - start))

      if res.status_code != 200:
        raise Exception(f'Wikidata API returned unexpected status code: {res.status_code} {res.reason}')

      self.write_cache_file(cache_file_name, res.text)
      return res.json()

    with open(os.path.join(self.cache_dir, cache_file_name), mode='r') as file:
      return json.load(file)

def get_etymology_type(element: dict) -> str:
  item = element['item']['value']
  types = element['types']['value'].split(', ')
  occupations = element['occupations']['value'].split(', ')

  if 'http://www.wikidata.org/entity/Q5' in types:
    # human

    if element['hasLocalConnection']['value'] != '0':
      return 'Personen mit Lokalbezug'

    if 'http://www.wikidata.org/entity/Q36834' in occupations and not item in [
      'http://www.wikidata.org/entity/Q9554', # Martin Luther, who is not mainly considered as a composer
    ]:
      return 'Komponisten'

    return 'andere Personen'

  if 'http://www.wikidata.org/entity/Q5113' in types:
    return 'Vögel'
  elif item in [
    'http://www.wikidata.org/entity/Q3031', # girl
  ]:
    return 'Sonstige' # would be otherwise categorized as "andere Tiere"
  elif 'http://www.wikidata.org/entity/Q729' in types or item in [
    'http://www.wikidata.org/entity/Q145201', # weasel, which are "organisms known by a particular common name"
  ]:
    return 'andere Tiere'

  if 'http://www.wikidata.org/entity/Q506' in types or 'http://www.wikidata.org/entity/Q886167' in types:
    return 'Blumen'
  if 'http://www.wikidata.org/entity/Q1364' in types or 'http://www.wikidata.org/entity/Q3314483' in types:
    return 'Früchte'
  elif 'http://www.wikidata.org/entity/Q10884' in types or 'http://www.wikidata.org/entity/Q757163' in types or item in [
    'http://www.wikidata.org/entity/Q4421', # forest
  ]:
    return 'Bäume'
  elif 'http://www.wikidata.org/entity/Q756' in types or item in [
    'http://www.wikidata.org/entity/Q80005', # fern
  ]:
    return 'andere Pflanzen'

  if 'http://www.wikidata.org/entity/Q8502' in types:
    # mountain
    return 'Berge'
  elif 'http://www.wikidata.org/entity/Q46831' in types:
    # mountain range
    return 'Berge'
  elif 'http://www.wikidata.org/entity/Q1061151' in types:
    # massif
    return 'Berge'

  if ('http://www.wikidata.org/entity/Q486972' in types or 'http://www.wikidata.org/entity/Q15284' in types) and not item == 'http://www.wikidata.org/entity/Q532':
    # human settlements and municipalities, excluding the generic 'village'
    return 'Ortsnamen'

  if 'http://www.wikidata.org/entity/Q24384' in types:
    # season
    return 'Jahreszeiten'

  if 'http://www.wikidata.org/entity/Q6999' in types:
    # astronomic object
    return 'Himmelskörper'

  if 'http://www.wikidata.org/entity/Q811979' in types:
    # architectural structure
    return 'Bauwerke'

  return 'Sonstige'

def get_etymology_gender(element: dict) -> str:
  types = element['types']['value'].split(', ')

  if not 'http://www.wikidata.org/entity/Q5' in types:
    # not even human
    return ''

  genders = element['genders']['value']

  if genders == 'http://www.wikidata.org/entity/Q6581097':
    return 'maennlich'
  if genders == 'http://www.wikidata.org/entity/Q6581072':
    return 'weiblich'
  if genders == '':
    return 'unbekannt'
  
  return 'andere'

def shorten_wikidata_entity_reference(uri: str) -> str:
  return uri.removeprefix('http://www.wikidata.org/entity/')

def build_sparql_query(wikidata_entity_ids: List[str]) -> str:
  query = '''
SELECT DISTINCT
  ?item
  ?itemLabel
  ?itemDescription
  (GROUP_CONCAT(DISTINCT ?type; SEPARATOR = ", ") AS ?types)
  (GROUP_CONCAT(DISTINCT ?typeLabel; SEPARATOR = ", ") AS ?typeLabels)
  (GROUP_CONCAT(DISTINCT ?occupation; SEPARATOR = ", ") AS ?occupations)
  (GROUP_CONCAT(DISTINCT ?occupationLabel; SEPARATOR = ", ") AS ?occupationLabels)
  (COUNT(DISTINCT ?localConnection) AS ?hasLocalConnection)
  (GROUP_CONCAT(DISTINCT ?gender; SEPARATOR = ", ") AS ?genders)
  (GROUP_CONCAT(DISTINCT ?genderLabel; SEPARATOR = ", ") AS ?genderLabels)
WHERE {
  VALUES ?item {'''
  query += ''.join([
    f'\n    wd:{id}' for id in wikidata_entity_ids
  ])
  query += '''
  }
  OPTIONAL {
    VALUES ?type {
      wd:Q5         # human
      wd:Q8502      # mountain
      wd:Q24384     # season
    }
    ?item (wdt:P31|wdt:P279) ?type.
  }
  OPTIONAL {
    VALUES ?type {
      wd:Q46831     # mountain range
      wd:Q1061151   # massif
      wd:Q15284     # municipality
      wd:Q486972    # human settlement
      wd:Q811979    # architectural structure
      wd:Q6999      # astronomic object
      wd:Q506       # flower (Blüte)
    }
    ?item (wdt:P31|wdt:P279)+ ?type.
  }
  OPTIONAL {
    VALUES ?type {
      wd:Q729       # animal
      wd:Q756       # plant
      wd:Q5113      # bird
      wd:Q10884     # tree
      wd:Q757163    # woody plant / Gehölz
      wd:Q1364      # fruit
      wd:Q3314483   # fruit, edible in the raw state
      wd:Q886167    # flower (Blume)
    }
    ?item (wdt:P171|wdt:P279)* ?type.
  }
  OPTIONAL {
    ?item (wdt:P106|wdt:P39) ?occupation.
  }
  OPTIONAL {
    VALUES ?localConnection {
      wd:Q542921    # Vaterstetten
      wd:Q804782    # Baldham
      wd:Q1980469   # Neufarn
      wd:Q2118817   # Purfing
      wd:Q15061740  # Weißenfeld
      wd:Q51879766  # Parsdorf
      wd:Q57521672  # mayor of Vaterstetten
      wd:Q115472007 # Hergolding
    }
    ?item (wdt:P19|wdt:P20|wdt:P39|wdt:P551|wdt:P937|wdt:P7153) ?localConnection.
  }
  OPTIONAL { ?item wdt:P21 ?gender. }
  SERVICE wikibase:label {
    bd:serviceParam wikibase:language "de".
    ?item rdfs:label ?itemLabel.
    ?item schema:description ?itemDescription.
  }
  SERVICE wikibase:label {
    bd:serviceParam wikibase:language "de".
    ?type rdfs:label ?typeLabel.
    ?occupation rdfs:label ?occupationLabel.
    ?gender rdfs:label ?genderLabel.
  }
}
GROUP BY ?item ?itemLabel ?itemDescription
ORDER BY ?item
'''

  return query
