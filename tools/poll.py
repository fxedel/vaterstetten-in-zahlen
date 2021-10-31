import sys
import telebot
import time
import traceback

import pollers

telegram_bot = None
telegram_debug_chatid = None
telegram_public_chatid = None

if len(sys.argv) == 1:
  # no telegram used
  pass
elif len(sys.argv) == 3 or len(sys.argv) == 4:
  telegram_token = sys.argv[1]
  telegram_debug_chatid = sys.argv[2]
  telegram_bot = telebot.TeleBot(telegram_token)

  if len(sys.argv) == 4:
    telegram_public_chatid = sys.argv[3]
  else:
    telegram_public_chatid = telegram_debug_chatid
else:
  print('Usage: [python] poll.py [<telegram-token> <telegram-debug-chatid> [<telegram-public-chatid>]]')
  exit(1)


failed = False

for key, pollerClass in pollers.all.items():
  try:
    print('Executing poller %s:' % key)

    start = time.time()
    poller = pollerClass(telegram_bot, telegram_public_chatid)
    poller.run()

    print ('> Done.')

  except Exception as e:
    end = time.time()
    print('> Exception after %.1fs:' % (end - start))
    print(traceback.format_exc())
    failed = True

    if telegram_bot != None:
      telegram_bot.send_message(telegram_debug_chatid, "Exception in poller %s after %.1fs: %s" % (key, (end - start), traceback.format_exc()))

if failed:
  exit(1)



