import pollers.poller
import pollers.lraEbeArcgis
import pollers.lraEbeArcgisImpfungen
import pollers.lraEbeImpfzentrum

from typing import Callable, ClassVar, Dict, Type

all: Dict[str, Type[pollers.poller.Poller]] = {
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgis.InzidenzPoller,
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgis.InzidenzGemeindenPoller,
  'lraEbeArcgisImpfungen': pollers.lraEbeArcgisImpfungen.Poller,
  # 'lraEbeImpfzentrum': pollers.lraEbeImpfzentrum.Poller
}
