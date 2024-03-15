from arcgis.features import FeatureLayer
from arcgis.features.feature import Feature
import os
import time

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    csv_filename = os.path.join('schulen', 'arcgisSchuelerNachWohnort.csv');
    current_rows = self.read_csv_rows(csv_filename)

    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/Herkunft/FeatureServer/1")

    start = time.time()
    data = layer.query(order_by_fields='Name_schule,Gemeinde_Herkunft,Jahr__als_zahl_')
    print('> Queried data in %.1fs' % (time.time() - start))

    features = [x for x in data.features if is_not_empty(x)]

    if len(features) == 0:
      raise Exception('Queried data is empty')

    if len(features) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(features), len(current_rows)))

    if len(features) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(features), len(current_rows)))

    rows = [feature_to_row(x) for x in features]

    # TODO: add proper diff message
    self.write_csv_rows(csv_filename, rows)

def is_not_empty(feature: Feature):
  attrs = feature.attributes.copy()

  if attrs['Anzahl'] != None:
    return True

  return False

def feature_to_row(feature: Feature):
  attrs = feature.attributes.copy()

  return {
    'schule': attrs['Name_schule'],  
    'wohnort': attrs['Gemeinde_Herkunft'],  
    'schuljahresbeginn': attrs['Jahr__als_zahl_'],
    'schueler': attrs['Anzahl'] or 0,
  }
