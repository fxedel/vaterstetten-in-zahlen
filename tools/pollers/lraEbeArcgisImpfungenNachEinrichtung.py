from typing import Dict, List, Optional
from arcgis.features import FeatureLayer
from arcgis.features.feature import Feature
from datetime import datetime
import itertools
import os
import time

import pollers.poller

class Poller(pollers.poller.Poller):
  def run(self):
    layer = FeatureLayer("https://services-eu1.arcgis.com/CZ1GXX3MIjSRSHoC/ArcGIS/rest/services/Covid19_Impfmeldungen_%c3%96ffentlich/FeatureServer/0")

    start = time.time()
    data = layer.query(order_by_fields='Einrichtung, Meldedatum, Impfungen_proTyp')
    print('> Queried data in %.1fs' % (time.time() - start))

    if len(data) == 0:
      raise Exception('Queried data is empty')

    features_filtered = list(filter_duplicate_days(data.features))
    apply_manual_fixes(features_filtered)
    check_cumulative_plausability(features_filtered)

    rows_nach_einrichtung = list(map(map_nach_einrichtung, features_filtered))
    rows_nach_einrichtung_file = os.path.join('corona-impfungen', 'arcgisImpfungenNachEinrichtung.csv')
    rows_nach_einrichtung_diff = self.get_csv_diff(rows_nach_einrichtung_file, rows_nach_einrichtung)
    if len(rows_nach_einrichtung_diff) > 0:
      self.write_csv_rows(rows_nach_einrichtung_file, rows_nach_einrichtung)

      if self.telegram_bot != None and self.telegram_chat_id != None:
        self.telegram_bot.send_message(
          self.telegram_chat_id,
          '```\n' + ''.join(rows_nach_einrichtung_diff) + '\n```',
          parse_mode = "Markdown"
        )

    rows_nach_geschlecht = list(itertools.chain.from_iterable(map(map_nach_geschlecht, features_filtered)))
    rows_nach_geschlecht_file = os.path.join('corona-impfungen', 'arcgisImpfungenNachGeschlecht.csv')
    rows_nach_geschlecht_diff = self.get_csv_diff(rows_nach_geschlecht_file, rows_nach_geschlecht)
    if len(rows_nach_geschlecht_diff) > 0:
      self.write_csv_rows(rows_nach_geschlecht_file, rows_nach_geschlecht)

      if self.telegram_bot != None and self.telegram_chat_id != None:
        self.telegram_bot.send_message(
          self.telegram_chat_id,
          '```\n' + ''.join(rows_nach_geschlecht_diff) + '\n```',
          parse_mode = "Markdown"
        )

    rows_nach_alter = list(itertools.chain.from_iterable(map(map_nach_alter, features_filtered)))
    rows_nach_alter_file = os.path.join('corona-impfungen', 'arcgisImpfungenNachAlter.csv')
    rows_nach_alter_diff = self.get_csv_diff(rows_nach_alter_file, rows_nach_alter)
    if len(rows_nach_alter_diff) > 0:
      self.write_csv_rows(rows_nach_alter_file, rows_nach_alter)

      if self.telegram_bot != None and self.telegram_chat_id != None:
        self.telegram_bot.send_message(
          self.telegram_chat_id,
          '```\n' + ''.join(rows_nach_alter_diff) + '\n```',
          parse_mode = "Markdown"
        )

def filter_duplicate_days(features: List[Feature]):
  filtered = []

  for feature in features:
    if len(filtered) == 0 or timestamp_to_iso_date(filtered[-1].attributes['Meldedatum']) != timestamp_to_iso_date(feature.attributes['Meldedatum']):
      filtered.append(feature)
    else:
      filtered[-1] = feature

  return filtered

def apply_manual_fixes(features: List[Feature]):
  for feature in features:
    attrs = feature.attributes # just a shorthand to make following statements shorter
    datum = timestamp_to_iso_date(attrs['Meldedatum'])
    einrichtung = attrs['Einrichtung']

    if einrichtung == 'Impfzentrum':
      if datum == '2021-07-24':
        # Summing I2_Alter* attributes up actually gives 37181.
        attrs['I2_SummeAlter'] = 37181 # used to be 37180
      elif datum == '2021-08-24':
        # I2_Alter50_60 has an extra 0
        attrs['I2_Alter50_60'] = 8057 # used to be 80570
        attrs['I2_SummeAlter'] = 44151
      elif datum == '2021-09-13':
        # I1_Alter80 has the same value as I1_Alter70_80, so this is probably a copy-and-paste error since I1_Alter80 must be between 7693 and 7695, looking at previous and following day.
        attrs['I1_Alter80'] = 7693
        attrs['I1_SummeAlter'] = 51569
        # Furthermore, I2_Alter* are all zero, but should be None/NA.
        attrs['I2_Alter20'] = None
        attrs['I2_Alter20_30'] = None
        attrs['I2_Alter30_40'] = None
        attrs['I2_Alter40_50'] = None
        attrs['I2_Alter50_60'] = None
        attrs['I2_Alter60_70'] = None
        attrs['I2_Alter70_80'] = None
        attrs['I2_Alter80'] = None
        attrs['I2_SummeAlter'] = None
      elif datum == '2021-09-14':
        # Summing I2_Alter* attributes up actually gives 46627.
        attrs['I2_SummeAlter'] = 46627 # used to be 46622
      elif datum == '2021-10-04':
        # Impfungen_proTyp is simply wrong
        attrs['Impfungen_proTyp'] = attrs['Erstimpfungen_proTyp']+attrs['Zweitimpfungen_proTyp']+none_to_zero(attrs['Drittimpfungen_proTyp'])
        # I2_* attributes have just the same values as I1_* attributes.
        attrs['I2_Weiblich'] = None
        attrs['I2_Maennlich'] = None
        attrs['I2_Divers'] = None
        attrs['I2_SummeGeschlecht'] = None
        attrs['I2_Alter20'] = None
        attrs['I2_Alter20_30'] = None
        attrs['I2_Alter30_40'] = None
        attrs['I2_Alter40_50'] = None
        attrs['I2_Alter50_60'] = None
        attrs['I2_Alter60_70'] = None
        attrs['I2_Alter70_80'] = None
        attrs['I2_Alter80'] = None
        attrs['I2_SummeAlter'] = None
      elif datum == '2021-10-12':
        # I2_Alter* are all zero, but should be None/NA.
        attrs['I2_Alter20'] = None
        attrs['I2_Alter20_30'] = None
        attrs['I2_Alter30_40'] = None
        attrs['I2_Alter40_50'] = None
        attrs['I2_Alter50_60'] = None
        attrs['I2_Alter60_70'] = None
        attrs['I2_Alter70_80'] = None
        attrs['I2_Alter80'] = None
        attrs['I2_SummeAlter'] = None
    elif einrichtung == 'Praxis':
      if datum == '2021-04-21':
        # I1_*, I2_* are all zero, but should be None/NA.
        attrs['I1_Weiblich'] = None
        attrs['I1_Maennlich'] = None
        attrs['I1_Divers'] = None
        attrs['I1_SummeGeschlecht'] = None
        attrs['I1_Alter20'] = None
        attrs['I1_Alter20_30'] = None
        attrs['I1_Alter30_40'] = None
        attrs['I1_Alter40_50'] = None
        attrs['I1_Alter50_60'] = None
        attrs['I1_Alter60_70'] = None
        attrs['I1_Alter70_80'] = None
        attrs['I1_Alter80'] = None
        attrs['I1_SummeAlter'] = None
        attrs['I2_Weiblich'] = None
        attrs['I2_Maennlich'] = None
        attrs['I2_Divers'] = None
        attrs['I2_SummeGeschlecht'] = None
        attrs['I2_Alter20'] = None
        attrs['I2_Alter20_30'] = None
        attrs['I2_Alter30_40'] = None
        attrs['I2_Alter40_50'] = None
        attrs['I2_Alter50_60'] = None
        attrs['I2_Alter60_70'] = None
        attrs['I2_Alter70_80'] = None
        attrs['I2_Alter80'] = None
        attrs['I2_SummeAlter'] = None

def check_cumulative_plausability(features: List[Feature]):
  cumulative_attributes = [
    'Erstimpfungen_proTyp',
    'Zweitimpfungen_proTyp',
    'Drittimpfungen_proTyp',
    'Impfungen_proTyp',
    'I1_Weiblich',
    'I1_Maennlich',
    'I1_Divers',
    'I1_SummeGeschlecht',
    'I1_Alter20',
    'I1_Alter20_30',
    'I1_Alter30_40',
    'I1_Alter40_50',
    'I1_Alter50_60',
    'I1_Alter60_70',
    'I1_Alter70_80',
    'I1_Alter80',
    'I1_SummeAlter',
    'I2_Weiblich',
    'I2_Maennlich',
    'I2_Divers',
    'I2_SummeGeschlecht',
    'I2_Alter20',
    'I2_Alter20_30',
    'I2_Alter30_40',
    'I2_Alter40_50',
    'I2_Alter50_60',
    'I2_Alter60_70',
    'I2_Alter70_80',
    'I2_Alter80',
    'I2_SummeAlter',
    'I3_Weiblich',
    'I3_Maennlich',
    'I3_Divers',
    'I3_SummeGeschlecht',
    'I3_Alter20',
    'I3_Alter20_30',
    'I3_Alter30_40',
    'I3_Alter40_50',
    'I3_Alter50_60',
    'I3_Alter60_70',
    'I3_Alter70_80',
    'I3_Alter80',
    'I3_SummeAlter',
  ]

  for i, feature in enumerate(features):
    for attr_name in cumulative_attributes:
      if feature.attributes[attr_name] is None:
        continue

      j = i - 1
      while (j >= 0 and feature.attributes['Einrichtung'] == features[j].attributes['Einrichtung']):
        if not features[j].attributes[attr_name] is None:
          if feature.attributes[attr_name] < features[j].attributes[attr_name]:
            raise Exception('Implausible data (non-cumulative %s): %s to %s' % (attr_name, features[j], feature))
          break
        j -= 1


def map_nach_einrichtung(feature: Feature):
  attrs = feature.attributes.copy()

  # SummeGeschlecht and SummeAlter may be off by one or two days, which should be less than 2000 vaccinations.
  # Furthermore, they might me a little bit (up to 20 vaccinations) ahead (probably because of slightly different times of survey).
  if attrs['I1_SummeGeschlecht'] != None and not attrs['Erstimpfungen_proTyp'] + 20 >= attrs['I1_SummeGeschlecht'] >= attrs['Erstimpfungen_proTyp'] - 2000:
    raise Exception('Implausible data (I1_SummeGeschlecht and Erstimpfungen_proTyp): %s' % feature)
  if attrs['I2_SummeGeschlecht'] != None and not attrs['Zweitimpfungen_proTyp'] + 20 >= attrs['I2_SummeGeschlecht'] >= attrs['Zweitimpfungen_proTyp'] - 2000:
    raise Exception('Implausible data (I2_SummeGeschlecht and Zweitimpfungen_proTyp): %s' % feature)
  if attrs['I3_SummeGeschlecht'] != None and not attrs['Drittimpfungen_proTyp'] + 20 >= attrs['I3_SummeGeschlecht'] >= attrs['Drittimpfungen_proTyp'] - 2000:
    raise Exception('Implausible data (I3_SummeGeschlecht and Drittimpfungen_proTyp): %s' % feature)
  if attrs['I1_SummeAlter'] != None and not attrs['Erstimpfungen_proTyp'] + 20 >= attrs['I1_SummeAlter'] >= attrs['Erstimpfungen_proTyp'] - 2000:
    raise Exception('Implausible data (I1_SummeAlter and Erstimpfungen_proTyp): %s' % feature)
  if attrs['I2_SummeAlter'] != None and not attrs['Zweitimpfungen_proTyp'] + 20 >= attrs['I2_SummeAlter'] >= attrs['Zweitimpfungen_proTyp'] - 2000:
    raise Exception('Implausible data (I2_SummeAlter and Zweitimpfungen_proTyp): %s' % feature)
  if attrs['I3_SummeAlter'] != None and not attrs['Drittimpfungen_proTyp'] + 20 >= attrs['I3_SummeAlter'] >= attrs['Drittimpfungen_proTyp'] - 2000:
    raise Exception('Implausible data (I3_SummeAlter and Drittimpfungen_proTyp): %s' % feature)

  row = {
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'einrichtung': str(attrs['Einrichtung']),
    'erstimpfungen': none_to_na(attrs['Erstimpfungen_proTyp']),
    'zweitimpfungen': none_to_na(attrs['Zweitimpfungen_proTyp']),
    'drittimpfungen': str(none_to_zero(attrs['Drittimpfungen_proTyp'])),
    'impfdosen': str(attrs['Impfungen_proTyp']),
  }

  return row

def map_nach_geschlecht(feature: Feature):
  attrs = feature.attributes.copy()

  if none_to_zero(attrs['I1_SummeGeschlecht']) == 0 and none_to_zero(attrs['I2_SummeGeschlecht']) == 0 and none_to_zero(attrs['I3_SummeGeschlecht']) == 0:
    return []

  geschlechter = ['Weiblich', 'Maennlich', 'Divers']

  if none_to_zero(attrs['I1_SummeGeschlecht']) != sum([none_to_zero(attrs['I1_' + column]) for column in geschlechter]):
    raise Exception('Implausible data (I1_SummeGeschlecht wrong): %s' % feature)
  if none_to_zero(attrs['I2_SummeGeschlecht']) != sum([none_to_zero(attrs['I2_' + column]) for column in geschlechter]):
    raise Exception('Implausible data (I2_SummeGeschlecht wrong): %s' % feature)
  if none_to_zero(attrs['I3_SummeGeschlecht']) != sum([none_to_zero(attrs['I3_' + column]) for column in geschlechter]):
    raise Exception('Implausible data (I3_SummeGeschlecht wrong): %s' % feature)

  return [{
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'einrichtung': str(attrs['Einrichtung']),
    'geschlecht': geschlecht,
    'erstimpfungen': none_to_na(attrs['I1_' + geschlecht]),
    'zweitimpfungen': none_to_na(attrs['I2_' + geschlecht]),
    'drittimpfungen': str(none_to_zero(attrs['I3_' + geschlecht])),
  } for geschlecht in geschlechter]

def map_nach_alter(feature: Feature):
  attrs = feature.attributes.copy()

  if none_to_zero(attrs['I1_SummeAlter']) == 0 and none_to_zero(attrs['I2_SummeAlter']) == 0 and none_to_zero(attrs['I3_SummeAlter']) == 0:
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

  if none_to_zero(attrs['I1_SummeAlter']) != sum([none_to_zero(attrs['I1_' + column]) for column, _ in altersgruppen.items()]):
    raise Exception('Implausible data (I1_SummeAlter wrong): %s' % feature)
  if none_to_zero(attrs['I2_SummeAlter']) != sum([none_to_zero(attrs['I2_' + column]) for column, _ in altersgruppen.items()]):
    raise Exception('Implausible data (I2_SummeAlter wrong): %s' % feature)
  if none_to_zero(attrs['I3_SummeAlter']) != sum([none_to_zero(attrs['I3_' + column]) for column, _ in altersgruppen.items()]):
    raise Exception('Implausible data (I3_SummeAlter wrong): %s' % feature)

  datum = timestamp_to_iso_date(attrs['Meldedatum'])

  return [{
    'datum': datum,
    'einrichtung': str(attrs['Einrichtung']),
    'altersgruppe': altersgruppe,
    'erstimpfungen': none_to_na(attrs['I1_' + column]),
    'zweitimpfungen': none_to_na(attrs['I2_' + column]),
    'drittimpfungen': none_to_na(attrs['I3_' + column]) if datum >= '2021-09-20' else str(none_to_zero(attrs['I3_' + column])), # third vaccinations started on 2021-09-20
  } for column, altersgruppe in altersgruppen.items()]

def timestamp_to_iso_date(timestamp: int) -> str:
  return datetime.utcfromtimestamp(timestamp / 1000).strftime('%Y-%m-%d')

def none_to_zero(num: Optional[int]) -> int:
  if num is None:
    return 0

  return num

def none_to_na(num: Optional[int]) -> str:
  if num is None:
    return 'NA'

  return str(num)
