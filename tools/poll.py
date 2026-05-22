import argparse
import dotenv
import os
import time
import traceback
from html import escape as html_escape

import pollers
from notifier import EmailNotifier

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

email_notifier = EmailNotifier()

needed_pollers = pollers.all

if args.pollers:
  needed_pollers = {}

  if args.pollers == ['hourly']:
    args.pollers = pollers.hourly
  elif args.pollers == ['manually']:
    args.pollers = pollers.manually

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
    poller = pollerClass(email_notifier, key)
    poller.run()

    end = time.time()
    print ('> Done after %.1fs.' % (end - start))

  except Exception as e:
    end = time.time()
    print('> Exception after %.1fs:' % (end - start))
    print(traceback.format_exc())
    failed = True

    lines = []
    lines.append(f'Exception in poller {key} after {(end - start):.1f}s: {type(e).__name__}: {e}')

    run_id = os.getenv('GITHUB_RUN_ID')
    if run_id:
      lines.append(f'https://github.com/fxedel/vaterstetten-in-zahlen/actions/runs/{run_id}')
    else:
      lines.append('https://github.com/fxedel/vaterstetten-in-zahlen/actions')

    lines.append('')
    lines.append(traceback.format_exc())

    email_notifier.send(
      level = 'ERROR',
      poller_name = key,
      subject = 'Exception',
      body = '\n'.join(lines),
      body_html = '<html><body><pre>' + html_escape('\n'.join(lines)) + '</pre></body></html>',
    )

if failed:
  exit(1)



