import io
import numpy as np
import os
import pandas as pd
import time

import pollers.poller
import pollers.genesisClient

class Poller(pollers.poller.Poller):
  def run(self):
    genesis_client = pollers.genesisClient.Client(
      username = os.environ['GENESIS_LFSTAT_USERNAME'],
      password = os.environ['GENESIS_LFSTAT_PASSWORD'],
      base_url = pollers.genesisClient.BASE_URL_LFSTAT_BAYERN
    )

    start = time.time()
    try:
      table_data_csv = genesis_client.tablefile(
        name = '12411-009z',
        startyear = 1900,
        regionalvariable = "GEMEIN",
        regionalkey = "09175132"
      )
      print('> Queried data in %.1fs' % (time.time() - start))
    except pollers.genesisClient.TemporaryGenesisError as e:
      print(f'> Ignoring temporary GENESIS error: {e}')
      return

    df = pd.read_csv(io.StringIO(table_data_csv), delimiter = ";")

    if len(df) == 0:
      raise Exception('Queried data is empty')
    
    df['stichtag'] = df['time'].astype(str) + '-' + df['1_variable_attribute_code'].map(lambda x: {
      'SQUART01': '03-31',
      'SQUART02': '06-30',
      'SQUART03': '09-30',
      'SQUART04': '12-31',
    }[x])
    df['column'] = df['3_variable_attribute_code'].map(lambda x: {
      np.nan: 'bevoelkerung',
      'GESM': 'maennlich',
      'GESW': 'weiblich',
    }[x])

    # filter out rows with empty data
    df = df[df['value'] != '...']

    df = df.pivot(
      index = 'stichtag',
      columns = 'column',
      values = 'value'
    )

    rows = [{
      'stichtag': stichtag,
      'erhebungsart': 'fortschreibung',
      'bevoelkerung': x['bevoelkerung'],
      'maennlich': x['maennlich'],
      'weiblich': x['weiblich'],
    } for (stichtag, x) in df.to_dict('index').items()]

    csv_filename = os.path.join('einwohner', 'lfstatFortschreibungQuartale.csv');
    current_rows = self.read_csv_rows(csv_filename)

    if len(rows) < len(current_rows) * (1/1.5):
      raise Exception('Queried data has much less items (%d) than current data (%d)' % (len(rows), len(current_rows)))

    if len(rows) > len(current_rows) * 1.5:
      raise Exception('Queried data has much more items (%d) than current data (%d)' % (len(rows), len(current_rows)))

    csv_diff = self.get_csv_diff(csv_filename, rows)
    self.send_csv_diff_via_telegram(csv_diff)
    self.write_csv_rows(csv_filename, rows)
