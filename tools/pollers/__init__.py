import pollers.poller
import pollers.lraEbeArcgisImpfungen
import pollers.lraEbeArcgisImpfungenNachEinrichtung
import pollers.lraEbeArcgisInzidenz
import pollers.lraEbeArcgisInzidenzGemeinden
import pollers.lraEbeArcgisInzidenzAltersgruppen
from pollers.mastrPhotovoltaik import MastrPhotovoltaikPoller
from pollers.mastrSpeicher import MastrSpeicherPoller

from typing import Dict, Type

all: Dict[str, Type[pollers.poller.Poller]] = {
  'mastrSpeicher': MastrSpeicherPoller,
  'mastrPhotovoltaik': MastrPhotovoltaikPoller,
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgisInzidenz.Poller,
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgisInzidenzGemeinden.Poller,
  'lraEbeArcgisInzidenzAltersgruppen': pollers.lraEbeArcgisInzidenzAltersgruppen.Poller,
  'lraEbeArcgisImpfungen': pollers.lraEbeArcgisImpfungen.Poller,
  'lraEbeArcgisImpfungenNachEinrichtung': pollers.lraEbeArcgisImpfungenNachEinrichtung.Poller,
}
