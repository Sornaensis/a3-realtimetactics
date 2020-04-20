#include "../../../RTS_Defines.hpp"

{
	private _params = _x getVariable ["RTS_setup", []];
	if ( (count _params) > 0 ) then {
		_params call RTS_fnc_groupSetupRTS;
	};
} forEach (allGroups select { side _x == RTS_sidePlayer });

if ( RTS_SingleCommander ) then {
	{
		private _group = _x;
		
		if ( !(_group in RTS_enemyGroups) ) then {
			RTS_enemyGroups pushbackunique _group;
		
			{
				[_x] call RTS_setupUnit;
			} forEach ( units _group );			
			
		};
		
	} forEach (allGroups select { side _x == RTS_sideEnemy });
};

call disableFriendlyFire;

RTS_groupSetupComplete = true;