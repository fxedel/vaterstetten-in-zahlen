import pollers.poller
import pollers.lraEbeArcgisImpfungen
import pollers.lraEbeArcgisImpfungenNachEinrichtung
import pollers.lraEbeArcgisInzidenz
import pollers.lraEbeArcgisInzidenzGemeinden
import pollers.lraEbeArcgisInzidenzAltersgruppen
import pollers.mastrPhotovoltaik

from typing import Dict, Type

all: Dict[str, Type[pollers.poller.Poller]] = {
  'mastrPhotovoltaik': pollers.mastrPhotovoltaik.Poller,
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgisInzidenz.Poller,
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgisInzidenzGemeinden.Poller,
  'lraEbeArcgisInzidenzAltersgruppen': pollers.lraEbeArcgisInzidenzAltersgruppen.Poller,
  'lraEbeArcgisImpfungen': pollers.lraEbeArcgisImpfungen.Poller,
  'lraEbeArcgisImpfungenNachEinrichtung': pollers.lraEbeArcgisImpfungenNachEinrichtung.Poller,
}
