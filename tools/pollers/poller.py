from interface import Interface
import os
import telebot
from typing import List, Optional

data_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'data')

class Poller(Interface):
  def get_csv_filename(self) -> str:
    pass

  def get_new_data(
    self,
    current_data: List[dict],
    telegram_bot: Optional[telebot.TeleBot],
    telegram_chat_id: Optional[str]
  ) -> List[dict]:
    pass
