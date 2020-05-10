/*

INSURGENCY: Strategic AI

Basic algorithm: Patrols and vehicle teams maneuver and assault.
				 Garrisons keep their heads low.

*/

INS_insurgentAI = addMissionEventHandler [ "EachFrame",
{	
		private _humanPlayers = call INS_allPlayers;
		private _insurgents = ( if ( count ( _humanPlayers select { side _x == east }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
		private _unitSpawners = ( (_humanPlayers select { side _x != east }) + _insurgents );
		
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
			
			// vehicles always considered patrolling
			if ( vehicle _leader != _leader ) then {
				if ( _tasking == "GARRISON" ) then {
					_tasking = "PATROL";
				};
			};
			
			switch ( _tasking ) do {
				case "GARRISON": {
					private _units = _interestingUnits select { side _x != side _group && count ([_x,units _group,250] call CBA_fnc_getNearest) > 0 && ( _group knowsAbout _x ) > 0.5 };
					
					if ( count _units > 0 ) then {
						private _target = [_leader, _units] call CBA_fnc_getNearest;
						private _city = _group getVariable "ai_city";
						
						if ( !isNil "_city" ) then {
							_group setVariable ["ai_target_group", group _target];
							[_group, getPos _target, 80, _city] call doCounterAttack;
							diag_log (format ["Tasking %1 from garrison to counter attack against %2", _group, _target]);
						};
						
						_group setVariable ["ai_cooldown", time + 30]; 						
					};
				};
				case "PATROL": {
					private _units = _interestingUnits select { side _x != side _group && count ([_x,units _group,1000] call CBA_fnc_getNearest) > 0 && ( _group knowsAbout _x ) > 0.5 };
					
					if ( count _units > 0 ) then {
						private _target = [_leader, _units] call CBA_fnc_getNearest;
						private _city = _group getVariable "ai_city";
						
						if ( !isNil "_city" ) then {
							_group setVariable ["ai_target_group", group _target];
							[_group, getPos _target, 80, _city] call doCounterAttack;
							diag_log (format ["Tasking %1 from patrol to counter attack against %2", _group, _target]);
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