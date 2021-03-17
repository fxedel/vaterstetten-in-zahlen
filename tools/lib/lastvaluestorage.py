import json
import os
from typing import TypeVar, Generic

dirname = os.path.dirname(__file__)
storage_dir = os.path.join(dirname, '..', 'lastvaluestorage')
os.makedirs(storage_dir, exist_ok = True)

T = TypeVar('T')

class LastValueStorage(Generic[T]):
  def __init__(self, name):
    self.storage_file = os.path.join(storage_dir, name + '.json')

  def get_last_values(self) -> T:
    try:
      with open(self.storage_file, 'r') as f:
        last_values: T = json.load(f)
        return last_values
    except FileNotFoundError:
      return None

  def write_last_values(self, values: T):
    with open(self.storage_file, 'w') as f:
      json.dump(values, f)
