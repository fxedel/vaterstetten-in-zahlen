import argparse
import dotenv
import os
import telebot
import time
import traceback

import pollers

dotenv.load_dotenv()

parser = argparse.ArgumentParser(
  usage = "%(prog)s [OPTIONS]",
  description = "Poll new data"
)

parser.add_argument(
  '-p', '--pollers',
  metavar = 'POLLER',
  action = 'extend',
  nargs = '+',
  help = 'Pollers to execute, defaults to all pollers. Available pollers: %s' % ', '.join(pollers.all.keys())
)

args = parser.parse_args()

telegram_bot = None

telegram_token = os.environ.get('TELEGRAM_TOKEN')
telegram_debug_chat_id = os.environ.get('TELEGRAM_DEBUG_CHAT_ID')
telegram_public_chat_id = os.environ.get('TELEGRAM_PUBLIC_CHAT_ID')

if telegram_token:
  telegram_bot = telebot.TeleBot(os.environ['TELEGRAM_TOKEN'])

if telegram_debug_chat_id and not telegram_public_chat_id:
  telegram_public_chat_id = telegram_debug_chat_id

needed_pollers = pollers.all

if args.pollers:
  needed_pollers = {}

  if args.pollers == ['hourly']:
    args.pollers = pollers.hourly
  elif args.pollers == ['daily']:
    args.pollers = pollers.daily

  for name in args.pollers:
    if not name in pollers.all:
      print('Unknown poller %s' % name)
      exit(1)

    needed_pollers[name] = pollers.all[name]

failed = False

for key, pollerClass in needed_pollers.items():
  try:
    print('Executing poller %s:' % key)

    start = time.time()
    poller = pollerClass(telegram_bot, telegram_public_chat_id, telegram_debug_chat_id)
    poller.run()

    end = time.time()
    print ('> Done after %.1fs.' % (end - start))

  except Exception as e:
    end = time.time()
    print('> Exception after %.1fs:' % (end - start))
    print(traceback.format_exc())
    failed = True

    if telegram_bot != None:
      lines = []
      lines.append(f"Exception in poller {key} after {(end - start):.1f}s: `{type(e).__name__}: {e}`")
      lines.append("[GitHub Actions](https://github.com/fxedel/vaterstetten-in-zahlen/actions) | [GitHub Action Run](https://github.com/fxedel/vaterstetten-in-zahlen/actions/runs/%s)" % os.getenv('GITHUB_RUN_ID'))
      telegram_bot.send_message(
        telegram_debug_chat_id,
        ('\n'.join(lines))[:4096],
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )

if failed:
  exit(1)



