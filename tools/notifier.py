import os
import smtplib
from email.message import EmailMessage
from typing import Optional


def env_bool(name: str, default: bool) -> bool:
  value = os.environ.get(name)

  if value is None:
    return default

  return value.strip().lower() in ['1', 'true', 'yes', 'on']


class EmailNotifier:
  def __init__(self):
    self.smtp_host = os.environ.get('SMTP_HOST')
    self.smtp_port = int(os.environ.get('SMTP_PORT', '587'))
    self.smtp_username = os.environ.get('SMTP_USERNAME')
    self.smtp_password = os.environ.get('SMTP_PASSWORD')
    self.smtp_use_starttls = env_bool('SMTP_USE_STARTTLS', True)
    self.smtp_use_ssl = env_bool('SMTP_USE_SSL', False)

    self.from_address = os.environ.get('MAIL_FROM_ADDRESS')
    self.to_addresses = [x.strip() for x in os.environ.get('MAIL_TO_ADDRESSES', '').split(',') if x.strip()]

  def is_configured(self) -> bool:
    return (
      self.smtp_host is not None
      and self.from_address is not None
      and len(self.to_addresses) > 0
    )

  def send(
    self,
    level: str,
    poller_name: str,
    subject: str,
    body: str,
    body_html: Optional[str] = None,
  ):
    if not self.is_configured():
      return

    tags = [
      f'[{level.upper()}]',
      f'[POLLER:{poller_name}]',
    ]
    full_subject = ' '.join(tags + [subject]).strip()

    message = EmailMessage()
    message['Subject'] = full_subject
    message['From'] = self.from_address
    message['To'] = ', '.join(self.to_addresses)
    message.set_content(body)

    if body_html is not None:
      message.add_alternative(body_html, subtype='html')

    if self.smtp_use_ssl:
      with smtplib.SMTP_SSL(self.smtp_host, self.smtp_port) as smtp:
        self._login_if_needed(smtp)
        smtp.send_message(message)
      return

    with smtplib.SMTP(self.smtp_host, self.smtp_port) as smtp:
      if self.smtp_use_starttls:
        smtp.starttls()

      self._login_if_needed(smtp)
      smtp.send_message(message)

  def _login_if_needed(self, smtp: smtplib.SMTP):
    if self.smtp_username is None:
      return

    smtp.login(self.smtp_username, self.smtp_password)
