import pollers.poller
import pollers.bayernwerkEnergiemonitor
import pollers.lfstatFortschreibungJahre
import pollers.lfstatFortschreibungQuartale
import pollers.lraEbeArcgisImpfungen
import pollers.lraEbeArcgisInzidenz
import pollers.lraEbeArcgisInzidenzGemeinden
import pollers.lraEbeArcgisSchueler
import pollers.lraEbeArcgisSchuelerNachWohnort
from pollers.mastrPhotovoltaik import MastrPhotovoltaikPoller
from pollers.mastrSpeicher import MastrSpeicherPoller
import pollers.overpassStreets

from typing import Dict, Type

all: Dict[str, Type[pollers.poller.Poller]] = {
  'bayernwerkEnergiemonitor': pollers.bayernwerkEnergiemonitor.Poller,
  'lfstatFortschreibungJahre': pollers.lfstatFortschreibungJahre.Poller,
  'lfstatFortschreibungQuartale': pollers.lfstatFortschreibungQuartale.Poller,
  'mastrSpeicher': MastrSpeicherPoller,
  'mastrPhotovoltaik': MastrPhotovoltaikPoller,
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgisInzidenz.Poller,
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgisInzidenzGemeinden.Poller,
  'lraEbeArcgisImpfungen': pollers.lraEbeArcgisImpfungen.Poller,
  'lraEbeArcgisSchueler': pollers.lraEbeArcgisSchueler.Poller,
  'lraEbeArcgisSchuelerNachWohnort': pollers.lraEbeArcgisSchuelerNachWohnort.Poller,
  'overpassStreets': pollers.overpassStreets.Poller,
}
