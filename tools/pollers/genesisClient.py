import requests

BASE_URL_DESTATIS = 'https://www-genesis.destatis.de/genesisWS/rest/2020' # Statistisches Bundesamt
BASE_URL_LFSTAT_BAYERN = 'https://www.statistikdaten.bayern.de/genesisWS/rest/2020' # Landesamt für Statistik Bayern

# API documentation: https://www-genesis.destatis.de/genesis/misc/GENESIS-Webservices_Einfuehrung.pdf

class Client:
  base_url: str
  username: str
  password: str

  def __init__(
    self,
    username: str,
    password: str,
    base_url: str = BASE_URL_DESTATIS,
  ) -> None:
    if username == None or len(username) == 0:
      raise Exception('username is missing')

    if password == None or len(password) == 0:
      raise Exception('username is missing')

    self.username = username
    self.password = password
    self.base_url = base_url.removesuffix('/')

  def http_request(
    self,
    path: str,
    params: dict,
  ) -> requests.Response:
    url = f'{self.base_url}/{path}'

    params = params.copy()
    params['username'] = self.username
    params['password'] = self.password

    response = requests.get(url, params = params, timeout = (5, 15))

    response.encoding = 'UTF-8'

    if 400 <= response.status_code <= 599:
      raise Exception(f'Invalid HTTP status {response.status_code} {response.reason}: {response.text}')

    return response
  
  def tablefile(
    self,
    name: str,
    **kwargs,
  ) -> str:
    params = {'name': name, 'format': 'ffcsv'} | kwargs
    res = self.http_request('data/tablefile', params)
    return res.text

