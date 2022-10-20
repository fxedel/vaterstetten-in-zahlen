from arcgis.features import FeatureLayer
from arcgis.features.feature import Feature
import os
import time
from typing import List

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/service_a22606ef95d34115b9b209cc73bd6c55/FeatureServer/0")

    start = time.time()
    data = layer.query(order_by_fields='Name,Jahr_num')
    print('> Queried data in %.1fs' % (time.time() - start))

    features = data.features
    features = [x for x in features if is_not_empty(x)]
    features = [x for x in features if is_real_schule(x)]

    if len(features) == 0:
      raise Exception('Queried data is empty')

    self.handle_data_actual([x for x in features if not is_prognose(x)])
    self.handle_data_prognose([x for x in features if is_prognose(x)])

  def handle_data_actual(self, features: List[Feature]):
    csv_filename = os.path.join('schulen', 'arcgisSchueler.csv');
    current_rows = self.read_csv_rows(csv_filename)

    if len(features) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(features), len(current_rows)))

    if len(features) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(features), len(current_rows)))

    rows = [feature_to_row_actual(x) for x in features]

    csv_diff = self.get_csv_diff(csv_filename, rows)
    self.send_csv_diff_via_telegram(csv_diff)
    self.write_csv_rows(csv_filename, rows)

  def handle_data_prognose(self, features: List[Feature]):
    csv_filename = os.path.join('schulen', 'arcgisSchuelerPrognose2022.csv');
    current_rows = self.read_csv_rows(csv_filename)

    if len(features) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(features), len(current_rows)))

    if len(features) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(features), len(current_rows)))

    rows = [feature_to_row_prognose(x) for x in features]

    csv_diff = self.get_csv_diff(csv_filename, rows)
    self.send_csv_diff_via_telegram(csv_diff)
    self.write_csv_rows(csv_filename, rows)


def is_not_empty(feature: Feature):
  attrs = feature.attributes.copy()

  if attrs['schuler_gesamt'] != None and attrs['schuler_gesamt'] > 0:
    return True

  if attrs['num_klassen'] != None and attrs['num_klassen'] > 0:
    return True

  return False

def is_real_schule(feature: Feature):
  attrs = feature.attributes.copy()

  if attrs['Name'] in ['Gym Auspendler', 'RS Auspendler']:
    return False

  return True

def is_prognose(feature: Feature):
  return feature.attributes['kommentare'] == 'PROG'

def feature_to_row_actual(feature: Feature):
  attrs = feature.attributes.copy()

  return {
    'schule': attrs['Name'],
    'schuljahresbeginn': attrs['Jahr_num'],
    'schueler': attrs['schuler_gesamt'],
    'klassen': attrs['num_klassen'],
  }

def feature_to_row_prognose(feature: Feature):
  attrs = feature.attributes.copy()

  return {
    'schule': attrs['Name'],
    'schuljahresbeginn': attrs['Jahr_num'],
    'schueler': attrs['schuler_gesamt'],
  }
