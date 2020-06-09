/*

INSURGENCY: Strategic AI

Basic algorithm: Patrols and vehicle teams maneuver and assault.
				 Garrisons keep their heads low.

*/

INS_insurgentAI = [] spawn {
	while { true } do {	
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
					private _units = _interestingUnits select { side (group _x) != side _group && count ([_x,units _group,250] call CBA_fnc_getNearest) > 0 && ( _group knowsAbout _x ) > 1 };
					
					if ( count _units > 0 ) then {
						private _target = [_leader, _units] call CBA_fnc_getNearest;
						private _city = _group getVariable "ai_city";
						
						if ( !isNil "_city" ) then {
							_group setVariable ["ai_target_group", group _target];
							_group setVariable ["ai_dest", getPos _target];
							[_group, getPos _target, 80, _city] call doCounterAttack;
							diag_log (format ["Tasking %1 from garrison to counter attack against %2", _group, _target]);
						};
						
						_group setVariable ["ai_cooldown", time + 30]; 						
					};
				};
				case "PATROL": {
					private _units = _interestingUnits select { side (group _x) != side _group && count ([_x,units _group,1000] call CBA_fnc_getNearest) > 0 && ( _group knowsAbout _x ) > 1 };
					
					if ( count _units > 0 ) then {
						private _target = [_leader, _units] call CBA_fnc_getNearest;
						private _city = _group getVariable "ai_city";
						
						if ( !isNil "_city" ) then {
							_group setVariable ["ai_target_group", group _target];
							_group setVariable ["ai_dest", getPos _target];
							[_group, getPos _target, 80, _city] call doCounterAttack;
							diag_log (format ["Tasking %1 from patrol to counter attack against %2", _group, _target]);
						};
						
						_group setVariable ["ai_cooldown", time + 30]; 						
					};
				};
				case "COUNTER-ATTACK": {
					private _dest = _group getVariable "ai_dest";
					
					if ( ( (getPos (leader _group)) distance _dest ) < 100 ) then {
						private _targetGroup = _group getVariable "ai_target_group";
						private _retask = false;
						if ( !isNull _targetGroup ) then {
							if ( count ((units _group) select { alive _x }) > 0 ) then {
								if ( ( (getPos (leader _group)) distance (getPos (leader _targetGroup)) ) > 150 ) then {
									_group setVariable ["ai_dest", getPos (leader _targetGroup)];
									[_group, getPos (leader _targetGroup), 50 + (random 25), _group getVariable "ai_city"] call doCounterAttack;
									diag_log (format ["Refining %1's counter attack against %2", _group, _targetGroup]);
								};
							} else {
								_retask = true;
							};
						} else {
							_retask = true;
						};
						
						if ( _retask ) then {
							_group setVariable ["ai_status", "PATROL"];
							_group setVariable ["ai_dest", nil];
							_group setVariable ["ai_target_group", nil];
							private _zoneName = _group getVariable "ai_city";
							private _zone = [_zoneName] call INS_getZone;
							private _zoneMarker = _zone select 1;
							(getMarkerSize _zoneMarker) params ["_mx","_my"];
							private _zoneSize = (_mx max _my) * 1.2;
							private _buildings = ( (getMarkerPos _zoneMarker) nearObjects ["HOUSE", _zoneSize] ) 
												select { (count (_x buildingPos -1)) > 2 };
							[_group, getPos (selectRandom _buildings), 200 + (random 60), _zoneName] call setupAsPatrol;
							diag_log (format ["Retasking %1 as a patrol in %2", _group, _zoneName]);
						};
						
						_group setVariable ["ai_cooldown", time + 30]; 
					} else {
						_group setVariable ["ai_cooldown", time + 10]; 
					};
				};
				case "NONE": {
				};
				
			};
					
		} forEach (allGroups select { local _x && time > (_x getVariable ["ai_cooldown",0]) });
	};
};