from typing import Dict, List, Optional
from arcgis.features import FeatureLayer
from arcgis.features.feature import Feature
from datetime import datetime
import itertools
import os

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/Covid19_Impfmeldungen_%c3%96ffentlich/FeatureServer/0")

    data = layer.query(order_by_fields='Einrichtung, Meldedatum, Impfungen_proTyp')

    if len(data) == 0:
      raise Exception('Queried data is empty')

    features_filtered = list(filter_duplicate_days(data.features))

    rows_nach_einrichtung = list(map(map_nach_einrichtung, features_filtered))
    self.write_csv_rows(os.path.join('corona-impfungen', 'arcgisImpfungenNachEinrichtung.csv'), rows_nach_einrichtung)

    rows_nach_geschlecht = list(itertools.chain.from_iterable(map(map_nach_geschlecht, features_filtered)))
    self.write_csv_rows(os.path.join('corona-impfungen', 'arcgisImpfungenNachGeschlecht.csv'), rows_nach_geschlecht)

    rows_nach_alter = list(itertools.chain.from_iterable(map(map_nach_alter, features_filtered)))
    self.write_csv_rows(os.path.join('corona-impfungen', 'arcgisImpfungenNachAlter.csv'), rows_nach_alter)

def filter_duplicate_days(features: List[Feature]):
  filtered = []

  for feature in features:
    if len(filtered) == 0 or timestamp_to_iso_date(filtered[-1].attributes['Meldedatum']) != timestamp_to_iso_date(feature.attributes['Meldedatum']):
      filtered.append(feature)
    else:
      filtered[-1] = feature

  return filtered

def map_nach_einrichtung(feature: Feature):
  attrs = feature.attributes.copy()

  row = {
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'einrichtung': str(attrs['Einrichtung']),
    'erstimpfungen': str(attrs['Erstimpfungen_proTyp']),
    'zweitimpfungen': str(attrs['Zweitimpfungen_proTyp']),
    'drittimpfungen': str(none_to_zero(attrs['Drittimpfungen_proTyp'])),
    'impfdosen': str(attrs['Impfungen_proTyp']),
  }

  if row['datum'] == '2021-10-04':
    # manual data fix, as impfdosen of this day is wrong
    row['impfdosen'] = str(attrs['Erstimpfungen_proTyp']+attrs['Zweitimpfungen_proTyp']+none_to_zero(attrs['Drittimpfungen_proTyp']))

  return row

def map_nach_geschlecht(feature: Feature):
  attrs = feature.attributes.copy()

  if attrs['I1_SummeGeschlecht'] is None or attrs['I1_SummeGeschlecht'] == 0:
    return []

  return [{
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'einrichtung': str(attrs['Einrichtung']),
    'geschlecht': geschlecht,
    'erstimpfungen': str(attrs['I1_' + geschlecht]),
    'zweitimpfungen': str(attrs['I2_' + geschlecht]),
    'drittimpfungen': str(none_to_zero(attrs['I3_' + geschlecht])),
  } for geschlecht in ['Weiblich', 'Maennlich', 'Divers']]

def map_nach_alter(feature: Feature):
  attrs = feature.attributes.copy()

  if attrs['I1_SummeAlter'] is None or attrs['I1_SummeAlter'] == 0:
    return []

  altersgruppen = {
    'Alter20': '0-19',
    'Alter20_30': '20-29',
    'Alter30_40': '30-39',
    'Alter40_50': '40-49',
    'Alter50_60': '50-59',
    'Alter60_70': '60-69',
    'Alter70_80': '70-79',
    'Alter80': '80+',
  }

  return [{
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'einrichtung': str(attrs['Einrichtung']),
    'altersgruppe': altersgruppe,
    'erstimpfungen': str(attrs['I1_' + column]),
    'zweitimpfungen': str(attrs['I2_' + column]),
    'drittimpfungen': str(none_to_zero(attrs['I3_' + column])),
  } for column, altersgruppe in altersgruppen.items()]

def timestamp_to_iso_date(timestamp: int) -> str:
  return datetime.utcfromtimestamp(timestamp / 1000).strftime('%Y-%m-%d')

def none_to_zero(num: Optional[int]) -> int:
  if num is None:
    return 0

  return num
