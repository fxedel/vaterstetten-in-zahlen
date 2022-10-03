from typing import Any, List, Optional
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

    features = data.features
    features = list(filter_ignored(features))
    features = list(filter_duplicate_days(features))
    apply_manual_fixes(features)
    check_cumulative_plausability(features)

    rows_nach_einrichtung = list(map(map_nach_einrichtung, features))
    rows_nach_einrichtung_file = os.path.join('corona-impfungen', 'arcgisImpfungenNachEinrichtung.csv')
    rows_nach_einrichtung_diff = self.get_csv_diff(rows_nach_einrichtung_file, rows_nach_einrichtung)
    if len(rows_nach_einrichtung_diff) > 0:
      self.write_csv_rows(rows_nach_einrichtung_file, rows_nach_einrichtung)

      if self.telegram_bot != None and self.telegram_chat_id != None:
        data = ''.join(rows_nach_einrichtung_diff)
        self.telegram_bot.send_message(
          self.telegram_chat_id,
          '```\n' + (data[:4080] if len(data) > 4080 else data) + '```',
          parse_mode = "Markdown"
        )

    rows_nach_geschlecht = list(itertools.chain.from_iterable(map(map_nach_geschlecht, features)))
    rows_nach_geschlecht_file = os.path.join('corona-impfungen', 'arcgisImpfungenNachGeschlecht.csv')
    rows_nach_geschlecht_diff = self.get_csv_diff(rows_nach_geschlecht_file, rows_nach_geschlecht)
    if len(rows_nach_geschlecht_diff) > 0:
      self.write_csv_rows(rows_nach_geschlecht_file, rows_nach_geschlecht)

      if self.telegram_bot != None and self.telegram_chat_id != None:
        data = ''.join(rows_nach_geschlecht_diff)
        self.telegram_bot.send_message(
          self.telegram_chat_id,
          '```\n' + (data[:4080] if len(data) > 4080 else data) + '```',
          parse_mode = "Markdown"
        )

    rows_nach_alter = list(itertools.chain.from_iterable(map(map_nach_alter, features)))
    rows_nach_alter_file = os.path.join('corona-impfungen', 'arcgisImpfungenNachAlter.csv')
    rows_nach_alter_diff = self.get_csv_diff(rows_nach_alter_file, rows_nach_alter)
    if len(rows_nach_alter_diff) > 0:
      self.write_csv_rows(rows_nach_alter_file, rows_nach_alter)

      if self.telegram_bot != None and self.telegram_chat_id != None:
        data = ''.join(rows_nach_alter_diff)
        self.telegram_bot.send_message(
          self.telegram_chat_id,
          '```\n' + (data[:4080] if len(data) > 4080 else data) + '```',
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

def filter_ignored(features: List[Feature]):
  ignored_days = {
    'Impfzentrum': [],
    'Praxis': [
      '2022-09-07', # just a duplicate of 2022-09-26
    ],
    'Kreisklinik': [],
  }

  return filter(lambda feature: not timestamp_to_iso_date(feature.attributes['Meldedatum']) in ignored_days[feature.attributes['Einrichtung']], features)

def apply_manual_fixes(features: List[Feature]):
  for feature in features:
    attrs = feature.attributes # just a shorthand to make following statements shorter
    datum = timestamp_to_iso_date(attrs['Meldedatum'])
    einrichtung = attrs['Einrichtung']

    if einrichtung == 'Impfzentrum':
      if datum == '2021-07-24':
        # Summing I2_Alter* attributes up actually gives 37181.
        replace_attr_value(feature, 'I2_SummeAlter', 37180, 37181) 
      elif datum == '2021-08-24':
        # I2_Alter50_60 has an extra 0
        replace_attr_value(feature, 'I2_Alter50_60', 80570, 8057)
        replace_attr_value(feature, 'I2_SummeAlter', 116664, attrs['I2_SummeAlter']-80570+8057)
      elif datum == '2021-09-13':
        # I1_Alter80 has the same value as I1_Alter70_80, so this is probably a copy-and-paste error since I1_Alter80 must be between 7693 and 7695, looking at previous and following day.
        ensure_attr_value(feature, 'I1_Alter70_80', 7335)
        replace_attr_value(feature, 'I1_Alter80', 7335, attrs['I1_SummeGeschlecht']-(attrs['I1_SummeAlter']-attrs['I1_Alter80']))
        replace_attr_value(feature, 'I1_SummeAlter', 51211, attrs['I1_SummeGeschlecht'])
        ensure_attr_value(feature, 'I1_SummeGeschlecht', 51569)
        # Furthermore, I2_Alter* are all zero, but should be None/NA.
        replace_attr_value(feature, 'I2_Alter20', 0, None)
        replace_attr_value(feature, 'I2_Alter20_30', 0, None)
        replace_attr_value(feature, 'I2_Alter30_40', 0, None)
        replace_attr_value(feature, 'I2_Alter40_50', 0, None)
        replace_attr_value(feature, 'I2_Alter50_60', 0, None)
        replace_attr_value(feature, 'I2_Alter60_70', 0, None)
        replace_attr_value(feature, 'I2_Alter70_80', 0, None)
        replace_attr_value(feature, 'I2_Alter80', 0, None)
        replace_attr_value(feature, 'I2_SummeAlter', 0, None)
      elif datum == '2021-09-14':
        # Summing I2_Alter* attributes up actually gives 46627.
        replace_attr_value(feature, 'I2_SummeAlter', 46622, 46627)
      elif datum == '2021-10-04':
        # Impfungen_proTyp is simply wrong
        ensure_attr_value(feature, 'Erstimpfungen_proTyp', 52739)
        ensure_attr_value(feature, 'Zweitimpfungen_proTyp', 48486)
        ensure_attr_value(feature, 'Drittimpfungen_proTyp', 511)
        replace_attr_value(feature, 'Impfungen_proTyp', 105989, attrs['Erstimpfungen_proTyp']+attrs['Zweitimpfungen_proTyp']+none_to_zero(attrs['Drittimpfungen_proTyp']))
        # I2_* attributes have just the same values as I1_* attributes.
        replace_attr_value(feature, 'I2_Weiblich', attrs['I1_Weiblich'], None)
        replace_attr_value(feature, 'I2_Maennlich', attrs['I1_Maennlich'], None)
        replace_attr_value(feature, 'I2_Divers', attrs['I1_Divers'], None)
        replace_attr_value(feature, 'I2_SummeGeschlecht', attrs['I1_SummeGeschlecht'], None)
        replace_attr_value(feature, 'I2_Alter20', attrs['I1_Alter20'], None)
        replace_attr_value(feature, 'I2_Alter20_30', attrs['I1_Alter20_30'], None)
        replace_attr_value(feature, 'I2_Alter30_40', attrs['I1_Alter30_40'], None)
        replace_attr_value(feature, 'I2_Alter40_50', attrs['I1_Alter40_50'], None)
        replace_attr_value(feature, 'I2_Alter50_60', attrs['I1_Alter50_60'], None)
        replace_attr_value(feature, 'I2_Alter60_70', attrs['I1_Alter60_70'], None)
        replace_attr_value(feature, 'I2_Alter70_80', attrs['I1_Alter70_80'], None)
        replace_attr_value(feature, 'I2_Alter80', attrs['I1_Alter80'], None)
        replace_attr_value(feature, 'I2_SummeAlter', attrs['I1_SummeAlter'], None)
      elif datum == '2021-10-12':
        # I2_Alter* are all zero, but should be None/NA.
        replace_attr_value(feature, 'I2_Alter20', 0, None)
        replace_attr_value(feature, 'I2_Alter20_30', 0, None)
        replace_attr_value(feature, 'I2_Alter30_40', 0, None)
        replace_attr_value(feature, 'I2_Alter40_50', 0, None)
        replace_attr_value(feature, 'I2_Alter50_60', 0, None)
        replace_attr_value(feature, 'I2_Alter60_70', 0, None)
        replace_attr_value(feature, 'I2_Alter70_80', 0, None)
        replace_attr_value(feature, 'I2_Alter80', 0, None)
        replace_attr_value(feature, 'I2_SummeAlter', 0, None)
      elif datum == '2021-12-05':
        # I3_Maennlich is zero, but I3_Weiblich and I3_Divers are not
        ensure_attr_value(feature, 'I3_Weiblich', 10339)
        replace_attr_value(feature, 'I3_Maennlich', 0, attrs['I3_SummeAlter']-attrs['I3_Weiblich']-attrs['I3_Divers'])
        ensure_attr_value(feature, 'I3_Divers', 7)
        replace_attr_value(feature, 'I3_SummeGeschlecht', 10346, attrs['I3_SummeAlter'])
        ensure_attr_value(feature, 'I3_SummeAlter', 19642)
      elif datum == '2021-12-13':
        ensure_attr_value(feature, 'Erstimpfungen_proTyp', 58185)
        ensure_attr_value(feature, 'Zweitimpfungen_proTyp', 54102)
        ensure_attr_value(feature, 'Drittimpfungen_proTyp', 27028)
        replace_attr_value(feature, 'Impfungen_proTyp', 142629, attrs['Erstimpfungen_proTyp']+attrs['Zweitimpfungen_proTyp']+attrs['Drittimpfungen_proTyp'])
        ensure_attr_value(feature, 'I1_Weiblich', 30736)
        replace_attr_value(feature, 'I1_Maennlich', 30736, attrs['I1_SummeAlter'] - attrs['I1_Weiblich'] - attrs['I1_Divers'])
        ensure_attr_value(feature, 'I1_Divers', 27)
        replace_attr_value(feature, 'I1_SummeGeschlecht', 61499, attrs['I1_SummeAlter'])
        ensure_attr_value(feature, 'I1_SummeAlter', 58169)
      elif datum == '2022-03-10':
        # I2_Maennlich is probably just missing a digit
        ensure_attr_value(feature, 'Zweitimpfungen_proTyp', 60500)
        ensure_attr_value(feature, 'I2_Weiblich', 31429)
        replace_attr_value(feature, 'I2_Maennlich', 2907, 29047)
        ensure_attr_value(feature, 'I2_Divers', 23)
        replace_attr_value(feature, 'I2_SummeGeschlecht', 34359, attrs['I2_SummeGeschlecht']-2907+29047)
        # I2_Alter50_60 was 9684 the day before and 9686 the after, so 9658 probably has mixed up digits
        replace_attr_value(feature, 'I2_Alter50_60', 9658, 9685)
        replace_attr_value(feature, 'I2_SummeAlter', 60472, attrs['I2_SummeAlter']-9658+9685)
      elif datum == '2022-04-11':
        replace_attr_value(feature, 'I3_Divers', 18, 19)
        replace_attr_value(feature, 'I3_SummeGeschlecht', 55484, attrs['I3_SummeGeschlecht']-18+19)
      elif datum == '2022-05-30':
        replace_attr_value(feature, 'I2_Alter30_40', 8148, 8158)
        replace_attr_value(feature, 'I2_SummeAlter', 60925, attrs['I2_SummeAlter']-8148+8158)
      elif datum == '2022-06-03':
        replace_attr_value(feature, 'Erstimpfungen_proTyp', 61287, 62287)
        replace_attr_value(feature, 'Impfungen_proTyp', 181203, attrs['Impfungen_proTyp']-61287+62287)
        replace_attr_value(feature, 'I1_Weiblich', 31782, 32782)
        replace_attr_value(feature, 'I1_SummeGeschlecht', 61287, attrs['I1_SummeGeschlecht']-31782+32782)
      elif datum == '2022-06-22':
        replace_attr_value(feature, 'I4_Alter80', 1208, 1208 - attrs['I4_SummeAlter'] + attrs['Viertimpfungen_proTyp'])
        replace_attr_value(feature, 'I4_SummeAlter', 3142, attrs['Viertimpfungen_proTyp'])
      elif datum == '2022-08-13':
        replace_attr_value(feature, 'I1_Alter30_40', 6840, 8028)
        replace_attr_value(feature, 'I1_SummeAlter', 61139, attrs['I1_SummeAlter']-6840+8028)
      elif datum == '2022-08-27':
        replace_attr_value(feature, 'I4_Alter40_50', 254, 154)
        replace_attr_value(feature, 'I4_SummeAlter', 4321, attrs['Viertimpfungen_proTyp'])


    elif einrichtung == 'Praxis':
      if datum == '2021-04-21':
        # I1_*, I2_* are all zero, but should be None/NA.
        replace_attr_value(feature, 'I1_Weiblich', 0, None)
        replace_attr_value(feature, 'I1_Maennlich', 0, None)
        replace_attr_value(feature, 'I1_Divers', 0, None)
        replace_attr_value(feature, 'I1_SummeGeschlecht', 0, None)
        replace_attr_value(feature, 'I1_Alter20', 0, None)
        replace_attr_value(feature, 'I1_Alter20_30', 0, None)
        replace_attr_value(feature, 'I1_Alter30_40', 0, None)
        replace_attr_value(feature, 'I1_Alter40_50', 0, None)
        replace_attr_value(feature, 'I1_Alter50_60', 0, None)
        replace_attr_value(feature, 'I1_Alter60_70', 0, None)
        replace_attr_value(feature, 'I1_Alter70_80', 0, None)
        replace_attr_value(feature, 'I1_Alter80', 0, None)
        replace_attr_value(feature, 'I1_SummeAlter', 0, None)
        replace_attr_value(feature, 'I2_Weiblich', 0, None)
        replace_attr_value(feature, 'I2_Maennlich', 0, None)
        replace_attr_value(feature, 'I2_Divers', 0, None)
        replace_attr_value(feature, 'I2_SummeGeschlecht', 0, None)
        replace_attr_value(feature, 'I2_Alter20', 0, None)
        replace_attr_value(feature, 'I2_Alter20_30', 0, None)
        replace_attr_value(feature, 'I2_Alter30_40', 0, None)
        replace_attr_value(feature, 'I2_Alter40_50', 0, None)
        replace_attr_value(feature, 'I2_Alter50_60', 0, None)
        replace_attr_value(feature, 'I2_Alter60_70', 0, None)
        replace_attr_value(feature, 'I2_Alter70_80', 0, None)
        replace_attr_value(feature, 'I2_Alter80', 0, None)
        replace_attr_value(feature, 'I2_SummeAlter', 0, None)

    elif einrichtung == 'Kreisklinik':
      if datum == '2022-02-17':
        # first vaccinations were 735 the day before and after
        replace_attr_value(feature, 'Erstimpfungen_proTyp', 725, 735)
        replace_attr_value(feature, 'Impfungen_proTyp', 1723, attrs['Impfungen_proTyp']-725+735)

def ensure_attr_value(feature: Feature, attr_key: str, value: Any):
  if feature.attributes[attr_key] != value:
    raise Exception('Expected %s to be %s, but is %s:\n%s' % (attr_key, value, feature.attributes[attr_key], attrs_to_str(feature.attributes)))

def replace_attr_value(feature: Feature, attr_key: str, old_val: Any, new_val: Any):
  ensure_attr_value(feature, attr_key, old_val)
  feature.attributes[attr_key] = new_val

def check_cumulative_plausability(features: List[Feature]):
  cumulative_attributes = [
    'Erstimpfungen_proTyp',
    'Zweitimpfungen_proTyp',
    'Drittimpfungen_proTyp',
    'Viertimpfungen_proTyp',
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
    'I4_Weiblich',
    'I4_Maennlich',
    'I4_Divers',
    'I4_SummeGeschlecht',
    'I4_Alter20',
    'I4_Alter20_30',
    'I4_Alter30_40',
    'I4_Alter40_50',
    'I4_Alter50_60',
    'I4_Alter60_70',
    'I4_Alter70_80',
    'I4_Alter80',
    'I4_SummeAlter',
  ]

  for i, feature in enumerate(features):
    for attr_name in cumulative_attributes:
      if feature.attributes[attr_name] is None:
        continue

      datum = timestamp_to_iso_date(feature.attributes['Meldedatum'])
      value = feature.attributes[attr_name]

      if datum == '2022-03-05':
        if attr_name == 'Drittimpfungen_proTyp' or attr_name.startswith('I3'):
          # this seems to be a data correction, where fourth vaccinations were wrongly counted as third vaccinations
          continue

      j = i - 1
      while (j >= 0 and feature.attributes['Einrichtung'] == features[j].attributes['Einrichtung']):
        feature_old = features[j]
        datum_old = timestamp_to_iso_date(feature_old.attributes['Meldedatum'])
        value_old = feature_old.attributes[attr_name]

        if not value_old is None:
          if value_old > value:
            raise Exception('Implausible data (non-cumulative %s): %s (%s) to %s (%s)' % (attr_name, value_old, datum_old, value, datum))
          break

        j -= 1


def map_nach_einrichtung(feature: Feature):
  attrs = feature.attributes.copy()

  prefixes = ['Erst', 'Zweit', 'Dritt', 'Viert']

  for i, prefix in enumerate(prefixes):
    col_impfungen = prefix + 'impfungen_proTyp'
    col_sum_geschlecht = 'I%d_SummeGeschlecht' % (i+1)
    col_sum_alter = 'I%d_SummeAlter' % (i+1)

    # SummeGeschlecht and SummeAlter may be off by one or two days, which should be less than 4000 vaccinations.
    # Furthermore, they might me a little bit (up to 20 vaccinations) ahead (probably because of slightly different times of survey).

    if attrs[col_sum_geschlecht] != None and not attrs[col_impfungen] + 20 >= attrs[col_sum_geschlecht] >= attrs[col_impfungen] - 4000:
      raise Exception('Implausible data (%s and %s): %s' % (col_sum_geschlecht, col_impfungen, attrs_to_str(feature.attributes)))

    if attrs[col_sum_alter] != None and not attrs[col_impfungen] + 20 >= attrs[col_sum_alter] >= attrs[col_impfungen] - 4000:
      raise Exception('Implausible data (%s and %s): %s' % (col_sum_alter, col_impfungen, attrs_to_str(feature.attributes)))

  if not sum([none_to_zero(attrs[prefix + 'impfungen_proTyp']) for prefix in prefixes]) == none_to_zero(attrs['Impfungen_proTyp']):
    raise Exception('Implausible data (Impfungen_proTyp): %s' % attrs_to_str(feature.attributes))

  row = {
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'einrichtung': str(attrs['Einrichtung']),
    'erstimpfungen': none_to_na(attrs['Erstimpfungen_proTyp']),
    'zweitimpfungen': none_to_na(attrs['Zweitimpfungen_proTyp']),
    'drittimpfungen': str(none_to_zero(attrs['Drittimpfungen_proTyp'])),
    'viertimpfungen': str(none_to_zero(attrs['Viertimpfungen_proTyp'])),
    'impfdosen': str(attrs['Impfungen_proTyp']),
  }

  return row

def map_nach_geschlecht(feature: Feature):
  attrs = feature.attributes.copy()

  if sum([none_to_zero(attrs['I%d_SummeGeschlecht' % (i+1)]) for i in range(0, 4)]) == 0:
    return []

  geschlechter = ['Weiblich', 'Maennlich', 'Divers']

  for i in range(0, 4):
    col_prefix = 'I%d_' % (i+1)
    col_sum_geschlecht = 'I%d_SummeGeschlecht' % (i+1)

    if none_to_zero(attrs[col_sum_geschlecht]) != sum([none_to_zero(attrs[col_prefix + column]) for column in geschlechter]):
      raise Exception('Implausible data (%s wrong): %s' % (col_sum_geschlecht, attrs_to_str(feature.attributes)))

  return [{
    'datum': timestamp_to_iso_date(attrs['Meldedatum']),
    'einrichtung': str(attrs['Einrichtung']),
    'geschlecht': geschlecht,
    'erstimpfungen': none_to_na(attrs['I1_' + geschlecht]),
    'zweitimpfungen': none_to_na(attrs['I2_' + geschlecht]),
    'drittimpfungen': str(none_to_zero(attrs['I3_' + geschlecht])),
    'viertimpfungen': str(none_to_zero(attrs['I4_' + geschlecht])),
  } for geschlecht in geschlechter]

def map_nach_alter(feature: Feature):
  attrs = feature.attributes.copy()

  if sum([none_to_zero(attrs['I%d_SummeAlter' % (i+1)]) for i in range(0, 4)]) == 0:
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

  for i in range(0, 4):
    col_prefix = 'I%d_' % (i+1)
    col_sum_alter = 'I%d_SummeAlter' % (i+1)

    if none_to_zero(attrs[col_sum_alter]) != sum([none_to_zero(attrs[col_prefix + column]) for column, _ in altersgruppen.items()]):
      raise Exception('Implausible data (%s wrong): %s' % (col_sum_alter, attrs_to_str(feature.attributes)))

  datum = timestamp_to_iso_date(attrs['Meldedatum'])

  return [{
    'datum': datum,
    'einrichtung': str(attrs['Einrichtung']),
    'altersgruppe': altersgruppe,
    'erstimpfungen': none_to_na(attrs['I1_' + column]),
    'zweitimpfungen': none_to_na(attrs['I2_' + column]),
    'drittimpfungen': none_to_na(attrs['I3_' + column]) if datum >= '2021-09-20' else str(none_to_zero(attrs['I3_' + column])), # third vaccinations started on 2021-09-20
    'viertimpfungen': none_to_na(attrs['I4_' + column]) if datum >= '2022-02-14' else str(none_to_zero(attrs['I4_' + column])), # third vaccinations started on 2022-02-14
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

def attrs_to_str(attrs: dict) -> str:
  str = 'OBJECTID %s from %s:\n' % (attrs['OBJECTID'], timestamp_to_iso_date(attrs['Meldedatum']))

  for key in attrs:
    if key in ['OBJECTID', 'Meldedatum']:
      continue

    str += '%s: %s\n' % (key, attrs[key])

  return str
