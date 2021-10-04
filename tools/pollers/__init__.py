import pollers.poller
import pollers.lraEbeArcgis
import pollers.lraEbeArcgisImpfungen
import pollers.lraEbeArcgisImpfungenNachEinrichtung
import pollers.lraEbeImpfzentrum

from typing import Dict, Type

all: Dict[str, Type[pollers.poller.Poller]] = {
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgis.InzidenzPoller,
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgis.InzidenzGemeindenPoller,
  'lraEbeArcgisImpfungen': pollers.lraEbeArcgisImpfungen.Poller,
  'lraEbeArcgisImpfungenNachEinrichtung': pollers.lraEbeArcgisImpfungenNachEinrichtung.Poller,
}
