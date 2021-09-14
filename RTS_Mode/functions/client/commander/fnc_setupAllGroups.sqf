#include "../../../RTS_Defines.hpp"

{
	private _params = _x getVariable ["RTS_setup", []];
	if ( (count _params) > 0 ) then {
		_params call RTS_fnc_groupSetupRTS;
	};
} forEach (allGroups select { side _x == RTS_sidePlayer && simulationEnabled (leader _x) });

if ( RTS_SingleCommander ) then {
	 [RTS_sideEnemy,
	{
		{
			private _group = _x;
			
			if ( !(_group in RTS_enemyGroups) ) then {
				RTS_enemyGroups pushbackunique _group;
						
				{
					[_x] call RTS_setupUnit;
				} forEach ( units _group );		
				
				private _params = _group getVariable ["RTS_setup", []];
				
				if ( (count _params) > 0 ) then {
					_params params ["_group", "_description", "_commandelement", "_grouptexture", "_icon", "_exp", "_leaderfactor", "_opticQuality", "_thermals" ];
					
					if ( !isNil "_exp" ) then {
						_group setVariable [ "Experience", _exp ];
					};
					
					if ( !isNil "_leaderfactor" ) then {
						_group setVariable [ "LeaderFactor", _leaderfactor ];
					};
					
					{
						_x call RTS_fnc_aiSkill;
					} forEach ( units _group );			
				};
				
			};
			
		} forEach (allGroups select { side _x == RTS_sideEnemy });
		publicVariable "RTS_enemyGroups";
	} ] remoteExecCall [ "call", 2 ];
};

call disableFriendlyFire;

RTS_groupSetupComplete = true;