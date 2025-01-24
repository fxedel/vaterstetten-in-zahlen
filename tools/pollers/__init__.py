import pollers.poller
import pollers.bayernwerkEnergiemonitor
import pollers.lfstatFortschreibungJahre
import pollers.lfstatFortschreibungQuartale
import pollers.lfstatWahlergebnisseAllgemein
import pollers.lfstatWahlergebnisseNachPartei
import pollers.lraEbeArcgisImpfungen
import pollers.lraEbeArcgisInzidenz
import pollers.lraEbeArcgisInzidenzGemeinden
import pollers.lraEbeArcgisSchueler
import pollers.lraEbeArcgisSchuelerNachWohnort
from pollers.mastrPhotovoltaik import MastrPhotovoltaikPoller
from pollers.mastrSpeicher import MastrSpeicherPoller
import pollers.overpassStreets

from typing import Dict, List, Type

all: Dict[str, Type[pollers.poller.Poller]] = {
  'bayernwerkEnergiemonitor': pollers.bayernwerkEnergiemonitor.Poller,
  'lfstatFortschreibungJahre': pollers.lfstatFortschreibungJahre.Poller,
  'lfstatFortschreibungQuartale': pollers.lfstatFortschreibungQuartale.Poller,
  'lfstatWahlergebnisseAllgemein': pollers.lfstatWahlergebnisseAllgemein.Poller,
  'lfstatWahlergebnisseNachPartei': pollers.lfstatWahlergebnisseNachPartei.Poller,
  'lraEbeArcgisImpfungen': pollers.lraEbeArcgisImpfungen.Poller,
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgisInzidenz.Poller,
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgisInzidenzGemeinden.Poller,
  'lraEbeArcgisSchueler': pollers.lraEbeArcgisSchueler.Poller,
  'lraEbeArcgisSchuelerNachWohnort': pollers.lraEbeArcgisSchuelerNachWohnort.Poller,
  'mastrPhotovoltaik': MastrPhotovoltaikPoller,
  'mastrSpeicher': MastrSpeicherPoller,
  'overpassStreets': pollers.overpassStreets.Poller,
}

hourly: List[str] = [
  'bayernwerkEnergiemonitor',
  'lraEbeArcgisSchueler',
  'lraEbeArcgisSchuelerNachWohnort',
  'mastrPhotovoltaik',
  'mastrSpeicher',
  'overpassStreets',
]

daily: List[str] = [
  'lfstatFortschreibungJahre',
  'lfstatFortschreibungQuartale',
  'lfstatWahlergebnisseAllgemein',
  'lfstatWahlergebnisseNachPartei',
]
