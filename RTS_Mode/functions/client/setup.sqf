#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\functions\client",
	[Q(RTS_fnc_hideAllMarkers),
	 Q(RTS_fnc_isCommander),
	 Q(RTS_fnc_zoneRestrict),
	 Q(RTS_fnc_markerBoundaries)]
] call RTS_setupFunction;