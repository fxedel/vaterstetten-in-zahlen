from arcgis.features import FeatureLayer
from arcgis.features.feature import Feature
from datetime import datetime
import os
import time
from typing import Any, List

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('corona-impfungen', 'arcgisImpfungen.csv');
    current_rows = self.read_csv_rows(csv_filename)

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/EBE_Gesamtsummen_Impfmeldungen_Öffentlich/FeatureServer/0")

    start = time.time()
    data = layer.query(order_by_fields='Meldedatum')
    print('> Queried data in %.1fs' % (time.time() - start))

    features = data.features
    features = list(filter(lambda x: int(x.attributes['ObjectId']) >= 1989, features)) # 1-497, 498-994, 995-1491, 1492-1988, 1989-2485

    if len(features) == 0:
      raise Exception('Queried data is empty')

    if len(features) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(features), len(current_rows)))

    if len(features) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(features), len(current_rows)))

    apply_manual_fixes(features)
    check_cumulative_plausability(features)

    rows = list(map(feature_to_row, features))
    self.write_csv_rows(csv_filename, rows)

def apply_manual_fixes(features: List[Feature]):
  for feature in features:
    attrs = feature.attributes
    datum = timestamp_to_iso_date(attrs['Meldedatum'])
    
    if datum == '2022-06-03':
      replace_attr_value(feature, 'Erstimpfungen_SUM', 101217, 102217)
      replace_attr_value(feature, 'Impfungen_SUM', 304205, 305205)
      replace_attr_value(feature, 'Impfungen_Tag', -976, 1000-976)
    elif datum == '2022-06-04':
      replace_attr_value(feature, 'Impfungen_Tag', 1016, 16)
    elif datum == '2022-09-07':
      # a data update states and an unusal high amount of new vaccinations on 2022-09-07
      # and a negative number of new vaccinations on 2022-09-10;
      # this seems like an error, so we stick to the old data for these days
      replace_attr_value(feature, 'Erstimpfungen_SUM', 102301, 102297)
      replace_attr_value(feature, 'Zweitimpfungen_SUM', 104861, 104851)
      replace_attr_value(feature, 'Drittimpfungen_SUM', 92164, 92141)
      replace_attr_value(feature, 'Viertimpfungen_SUM', 9499, 9203)
      replace_attr_value(feature, 'Impfungen_SUM', 308825, 308492)
      replace_attr_value(feature, 'Impfungen_Tag', 363, 30)
    elif datum == '2022-09-09':
      replace_attr_value(feature, 'Erstimpfungen_SUM', 102303, 102299)
      replace_attr_value(feature, 'Zweitimpfungen_SUM', 104861, 104851)
      replace_attr_value(feature, 'Drittimpfungen_SUM', 92176, 92153)
      replace_attr_value(feature, 'Viertimpfungen_SUM', 9519, 9223)
      replace_attr_value(feature, 'Impfungen_SUM', 308859, 308526)
    elif datum == '2022-09-10':
      replace_attr_value(feature, 'Erstimpfungen_SUM', 102303, 102299)
      replace_attr_value(feature, 'Zweitimpfungen_SUM', 104862, 104852)
      replace_attr_value(feature, 'Drittimpfungen_SUM', 92189, 92166)
      replace_attr_value(feature, 'Viertimpfungen_SUM', 9537, 9241)
      replace_attr_value(feature, 'Impfungen_SUM', 308891, 308558)
    elif datum == '2022-09-12':
      replace_attr_value(feature, 'Impfungen_Tag', -238, 95)
    elif datum == '2022-10-21':
      replace_attr_value(feature, 'Zweitimpfungen_SUM', 104889, 104883)
      replace_attr_value(feature, 'Impfungen_SUM', 312623, attrs['Impfungen_SUM']-104889+104883)

def ensure_attr_value(feature: Feature, attr_key: str, value: Any):
  if feature.attributes[attr_key] != value:
    raise Exception('Expected %s to be %s, but is %s:\n%s' % (attr_key, value, feature.attributes[attr_key], attrs_to_str(feature.attributes)))

def replace_attr_value(feature: Feature, attr_key: str, old_val: Any, new_val: Any):
  ensure_attr_value(feature, attr_key, old_val)
  feature.attributes[attr_key] = new_val

def check_cumulative_plausability(features: List[Feature]):
  cumulative_attributes = [
    'Erstimpfungen_SUM',
    'Zweitimpfungen_SUM',
    'Drittimpfungen_SUM',
    'Viertimpfungen_SUM',
    'Impfungen_SUM',
  ]

  for i, feature in enumerate(features):
    for attr_name in cumulative_attributes:
      if feature.attributes[attr_name] is None:
        continue

      datum = timestamp_to_iso_date(feature.attributes['Meldedatum'])
      value = feature.attributes[attr_name]

      # known error, but don't know how to fix them
      if datum == "2022-02-17" and attr_name == "Erstimpfungen_SUM":
        continue
      if datum == "2022-03-05" and attr_name == "Drittimpfungen_SUM":
        continue

      j = i - 1
      while j >= 0:
        feature_old = features[j]
        datum_old = timestamp_to_iso_date(feature_old.attributes['Meldedatum'])
        value_old = feature_old.attributes[attr_name]

        if not value_old is None:
          if value_old > value:
            raise Exception('Implausible data (non-cumulative %s): %s (%s) to %s (%s)' % (attr_name, value_old, datum_old, value, datum))
          break

        j -= 1

def feature_to_row(feature: Feature):
  attrs = feature.attributes.copy()

  if attrs['Impfungen_Tag'] == attrs['Impfungen_SUM']:
    attrs['Impfungen_Tag'] = 'NA'
  elif attrs['Impfungen_Tag'] <= -10:
    raise Exception('Implausible data: %s' % feature)
  elif attrs['Impfungen_Tag'] >= 10000:
    raise Exception('Implausible data: %s' % feature)

  prefixes = ['Erst', 'Zweit', 'Dritt', 'Viert']

  if not sum([attrs[prefix + 'impfungen_SUM'] for prefix in prefixes]) == attrs['Impfungen_SUM']:
    raise Exception('Implausible data (Impfungen_SUM): %s' % feature.attributes)

  return {
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'erstimpfungen': str(attrs['Erstimpfungen_SUM']),
    'zweitimpfungen': str(attrs['Zweitimpfungen_SUM']),
    'drittimpfungen': str(attrs['Drittimpfungen_SUM']),
    'viertimpfungen': str(attrs['Viertimpfungen_SUM']),
    'impfdosen': str(attrs['Impfungen_SUM']),
    'impfdosenNeu': str(attrs['Impfungen_Tag']),
  }

def timestamp_to_iso_date(timestamp: int) -> str:
  return datetime.utcfromtimestamp(timestamp / 1000).strftime('%Y-%m-%d')

def attrs_to_str(attrs: dict) -> str:
  str = 'ObjectId %s from %s:\n' % (attrs['ObjectId'], timestamp_to_iso_date(attrs['Meldedatum']))

  for key in attrs:
    if key in ['ObjectId', 'Meldedatum']:
      continue

    str += '%s: %s\n' % (key, attrs[key])

  return str
