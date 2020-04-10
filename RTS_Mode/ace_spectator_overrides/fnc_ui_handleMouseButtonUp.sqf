#include "\z\ace\addons\spectator\script_component.hpp"

if ((_this select 1) == 1) then { 
	GVAR(holdingRMB) = false; 
};
if ((_this select 1) == 0) then {
	RTS_selecting = false; 
	[RTS_selectStart,getMousePosition] call RTS_fnc_selectInArea;
};