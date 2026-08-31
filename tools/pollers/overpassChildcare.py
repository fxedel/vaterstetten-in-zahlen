import os

from pollers.overpassPoller import GenericOverpassPoller

overpass_api_url = 'https://overpass-api.de/api/interpreter'

class Poller(GenericOverpassPoller):
  def run(self):
    overpass_data = self.query_overpass_from_file('childcare.overpassql')

    childcare_rows = [{
      'Name': element['tags'].get('name'),
      'OSMType': element['type'],
      'OSMID': element['id'],
      'Latitude': element.get('lat') or element['center']['lat'],
      'Longitude': element.get('lon') or element['center']['lon'],
    } for element in overpass_data['elements']]
    csv_filename = os.path.join('kinderbetreuung', 'osmKitas.csv')
    old_childcare_rows = self.read_csv_rows(csv_filename)
    self.write_csv_rows(csv_filename, childcare_rows)
    new_childcare_rows = self.read_csv_rows(csv_filename)

    # detect childcare changes
    childcare_key_func = lambda x: f"{x['OSMID']}"
    old_childcare_rows_by_key = self.list_with_unique_key(old_childcare_rows, childcare_key_func, auto_increment = True)
    new_childcare_rows_by_key = self.list_with_unique_key(new_childcare_rows, childcare_key_func, auto_increment = True)
    (childcare_places_removed, childcare_places_changed, childcare_places_added) = self.dict_diff(old_childcare_rows_by_key, new_childcare_rows_by_key)
  
    if len(childcare_places_removed) + len(childcare_places_changed) + len(childcare_places_added) > 0:
      lines = []
      lines.append('*Kitas geändert*')

      for key in childcare_places_removed:
        lines.append(f'{key} entfernt')
      for key in childcare_places_added:
        lines.append(f'{key} hinzugefügt: Namensherkunft = {new_childcare_rows_by_key[key]}')
      for key in childcare_places_changed:
        old_value = old_childcare_rows_by_key[key]
        new_value = new_childcare_rows_by_key[key]

        fields = set(new_value.keys()).intersection(old_value.keys())
        fields = list(filter(lambda field: field not in ['OSMWayIDs', 'Geometry'], fields))
        fields = list(filter(lambda field: old_value[field] != new_value[field], fields))

        if len(fields) == 0:
          continue

        field_texts = map(lambda field: f'{field} "{old_value[field]}" → "{new_value[field]}"', fields)
        lines.append(f"{key} geändert: {', '.join(field_texts)}")

      if len(lines) > 1:
        lines.append(' | '.join([
          '[Vaterstetten in Zahlen](https://vaterstetten-in-zahlen.de/?tab=TODO)',
          '[Commits](https://github.com/fxedel/vaterstetten-in-zahlen/commits/master/data/kinderbetreeuung/osmKitas.csv)',
        ]))
        self.send_public_telegram_message(lines)
