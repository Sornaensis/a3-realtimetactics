/*

INSURGENCY: Strategic AI

Basic algorithm: Patrols and vehicle teams maneuver and assault.
				 Garrisons keep their heads low.

*/

INS_insurgentBrain = addMissionEventHandler [ "EachFrame",
{
	private _humanPlayers = call INS_allPlayers;
	private _insurgents = ( if ( count ( _humanPlayers select { side _x == east }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
	private _unitSpawners = ( (_humanPlayers select { side _x == west }) + _insurgents );
	
	private _interestingUnits = [];
	{
		{
			_interestingUnits pushbackunique _x;
		} forEach (units (group _x));
	} forEach _unitSpawners;
	
	// process group strategy
	{
		private _group = _x;
		private _leader = leader _group;
		private _tasking = _x getVariable ["ai_status","NONE"];
		
		switch ( _tasking ) do {
			case "GARRISON": {
			};
			case "PATROL": {
				private _units = _interestingUnits select { count ([_x,units _group,850] call CBA_fnc_getNearest) > 0 && ( _group knowsAbout _x ) > 1 };
				
				if ( count _units > 0 ) then {
					private _target = [_leader, _units] call CBA_fnc_getNearest;
					private _city = _group getVariable "ai_city";
					
					if ( !isNil "_city" ) then {
						_group setVariable ["ai_target_group", group _target];
						[_group, getPos _target, 200, _city] call doCounterAttack;
					};
					
					_group setVariable ["ai_cooldown", time + 30]; 						
				};
			};
			case "COUNTER-ATTACK": {
			};
			case "NONE": {
			};
			
		};
				
	} forEach (allGroups select { local _x && time > (_x getVariable ["ai_cooldown",0]) });

}];