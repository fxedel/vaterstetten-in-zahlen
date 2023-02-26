import argparse
import os
import telebot
import time
import traceback

import pollers

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
parser.add_argument(
  '--telegram-token',
  help = 'Telegram bot token if messages should be sent, in the format \'[0-9]+:[0-9A-Za-z-]+\''
)
parser.add_argument(
  '--telegram-debug-chat-id',
  help = 'Telegram chat ID for debug messages'
)
parser.add_argument(
  '--telegram-public-chat-id',
  help = 'Telegram chat ID for public messages, defaults to debug chat id.'
)

args = parser.parse_args()

telegram_bot = None

if args.telegram_token :
  telegram_bot = telebot.TeleBot(args.telegram_token)

telegram_debug_chat_id = args.telegram_debug_chat_id
telegram_public_chat_id = args.telegram_public_chat_id

if telegram_debug_chat_id and not telegram_public_chat_id:
  telegram_public_chat_id = telegram_debug_chat_id

needed_pollers = pollers.all

if args.pollers:
  needed_pollers = {}

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
    poller = pollerClass(telegram_bot, telegram_public_chat_id)
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
      lines.append("Exception in poller %s after %.1fs: %s" % (key, (end - start), e))
      lines.append("[GitHub Actions](https://github.com/fxedel/vaterstetten-in-zahlen/actions) | [GitHub Action Run](https://github.com/fxedel/vaterstetten-in-zahlen/actions/runs/%s)" % os.getenv('GITHUB_RUN_ID'))
      telegram_bot.send_message(
        telegram_debug_chat_id,
        ('\n'.join(lines))[:4096],
        parse_mode = "Markdown",
        disable_web_page_preview = True
      )

if failed:
  exit(1)



