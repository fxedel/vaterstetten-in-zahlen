import pollers.poller
import pollers.lraEbeArcgis
import pollers.lraEbeImpfzentrum

from typing import Dict

all: Dict[str, pollers.poller.Poller] = {
  'lraEbeArcgisInzidenz': pollers.lraEbeArcgis.InzidenzPoller(),
  'lraEbeArcgisInzidenzGemeinden': pollers.lraEbeArcgis.InzidenzGemeindenPoller(),
  'lraEbeImpfzentrum': pollers.lraEbeImpfzentrum.Poller()
}
