#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\functions\server",
	[Q(RTS_fnc_advancePhase),
	 Q(RTS_fnc_getAllHighCommandCommanders),
	 Q(RTS_fnc_setupCommander)]
] call RTS_setupFunction;