#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\functions\shared\insurgency",
	[Q(INS_fnc_setupSquad),
	 Q(INS_fnc_setupGreenSquad),
     Q(INS_fnc_setupBlueSquad),
     Q(INS_fnc_setupCivilian),
	 Q(INS_fnc_setupSpy),
	 Q(INS_fnc_setupMG),
	 Q(INS_fnc_setupSniper),
	 Q(INS_fnc_setupCar),
	 Q(INS_fnc_setupAPC),
	 Q(INS_fnc_setupTank),
	 Q(INS_fnc_spawnMG),
	 Q(INS_fnc_spawnSpy),
	 Q(INS_fnc_spawnSquad),
	 Q(INS_fnc_spawnSniper),
	 Q(INS_fnc_spawnCar),
	 Q(INS_fnc_spawnEmptyCar),
	 Q(INS_fnc_spawnAPC),
	 Q(INS_fnc_spawnTank),
	 Q(INS_fnc_setupCaches),
	 Q(INS_fnc_spawnReinforcements),
	 Q(INS_fnc_spawnStartingUnits),
	 Q(INS_fnc_spawnRandomSoldier)]
] call RTS_setupFunction;