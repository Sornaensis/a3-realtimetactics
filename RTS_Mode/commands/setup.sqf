#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\commands",
	[Q(RTS_fnc_setDirection),
	Q(RTS_fnc_loadOrUnload),
	Q(RTS_fnc_placeUnit),
	Q(RTS_fnc_addMountOrDismountCommand),
	Q(RTS_fnc_addUnloadOrLoadCommand),
	Q(RTS_fnc_addCombatMoveCommand),
	Q(RTS_fnc_addSlowMoveCommand),
	Q(RTS_fnc_addFastMoveCommand),
	Q(RTS_fnc_addMoveCommand),
	Q(RTS_fnc_commandGetInBuilding),
	Q(RTS_fnc_commandSearchBuilding),
	Q(RTS_fnc_putInBuilding)]
] call RTS_setupFunction;