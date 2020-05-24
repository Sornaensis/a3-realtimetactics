#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\functions\shared",
	[Q(RTS_fnc_aiSkill),
	 Q(RTS_fnc_spawnCrate)]
] call RTS_setupFunction;
