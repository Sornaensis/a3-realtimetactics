#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\functions\client\commander",
	[Q(RTS_fnc_autoCombat),
	 Q(RTS_fnc_draw3dOrders),
	 Q(RTS_fnc_draw3dUnitIcons),
	 Q(RTS_fnc_getAllDeploymentMarkers),	
	 Q(RTS_fnc_groupSetupRTS),
	 Q(RTS_fnc_removeCommand),
	 Q(RTS_fnc_selectInArea),
	 Q(RTS_fnc_setCommand),
	 Q(RTS_fnc_setupAllGroups),
	 Q(RTS_fnc_setupAsSide),
	 Q(RTS_fnc_setupClass_Rifleman),
	 Q(RTS_fnc_setupClass_Marksman),
	 Q(RTS_fnc_takeControlOfUnit),
	 Q(RTS_fnc_getAmmoLevel),
	 Q(RTS_fnc_releaseControlOfUnit)]
] call RTS_setupFunction;