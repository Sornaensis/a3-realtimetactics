#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\functions\shared\insurgency",
	[Q(INS_fnc_setupSoldier),
	 Q(INS_fnc_setupSpy),
	 Q(INS_fnc_setupLeader),
	 Q(INS_fnc_setupCar),
	 Q(INS_fnc_setupAPC),
	 Q(INS_fnc_setupTank),
	 Q(INS_fnc_spawnSoldier),
	 Q(INS_fnc_spawnSpy),
	 Q(INS_fnc_spawnLeader),
	 Q(INS_fnc_spawnCar),
	 Q(INS_fnc_spawnAPC),
	 Q(INS_fnc_spawnTank),
	 Q(INS_fnc_setupCaches),
	 Q(INS_fnc_spawnReinforcements),
	 Q(INS_fnc_spawnStartingUnits)]
] call RTS_setupFunction;