import pollers.poller
import pollers.bayernwerkEnergiemonitor
import pollers.lraEbeArcgisImpfungen
import pollers.lraEbeArcgisImpfungenNachEinrichtung
import pollers.lraEbeArcgisInzidenz
import pollers.lraEbeArcgisInzidenzGemeinden
import pollers.lraEbeArcgisInzidenzAltersgruppen
import pollers.lraEbeArcgisSchueler
import pollers.lraEbeArcgisSchuelerNachWohnort
from pollers.mastrPhotovoltaik import MastrPhotovoltaikPoller
from pollers.mastrSpeicher import MastrSpeicherPoller
import pollers.overpassStreets

from typing import Dict, Type

all: Dict[str, Type[pollers.poller.Poller]] = {
  'bayernwerkEnergiemonitor': pollers.bayernwerkEnergiemonitor.Poller,
  'mastrSpeicher': MastrSpeicherPoller,
  'mastrPhotovoltaik': MastrPhotovoltaikPoller,
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgisInzidenz.Poller,
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgisInzidenzGemeinden.Poller,
  'lraEbeArcgisInzidenzAltersgruppen': pollers.lraEbeArcgisInzidenzAltersgruppen.Poller,
  'lraEbeArcgisImpfungen': pollers.lraEbeArcgisImpfungen.Poller,
  'lraEbeArcgisImpfungenNachEinrichtung': pollers.lraEbeArcgisImpfungenNachEinrichtung.Poller,
  'lraEbeArcgisSchueler': pollers.lraEbeArcgisSchueler.Poller,
  'lraEbeArcgisSchuelerNachWohnort': pollers.lraEbeArcgisSchuelerNachWohnort.Poller,
  'overpassStreets': pollers.overpassStreets.Poller,
}
