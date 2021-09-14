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
			private _hiding = _group getVariable "hiding";
			private _initStr = _group getVariable "initial_strength";
			
			// vehicles always considered patrolling
			if ( vehicle _leader != _leader ) then {
				if ( _tasking == "GARRISON" ) then {
					_tasking = "PATROL";
				};
			};
			
			if ( isNil "_hiding" && !isNil "_initStr" ) then {
				// reduced strength units will hide in buildings
				private _threshold = (ceil (_initStr / 2)) max 1;
				private _tough = _group getVariable ["ai_tough", false];
				if ( _tough ) then {
					_threshold = (ceil (_initStr / 3)) max 1;
				};
				if ( count ( (units _group) select { alive _x } ) <= _threshold ) then {
					_group setVariable ["hiding", true];
					_group setVariable ["VCM_NORESCUE",true];
					_group setVariable ["VCM_NOFLANK",true];
					_group setVariable ["ai_status", "GARRISON"];
					_group setVariable ["ai_dest", nil];
					_group setVariable ["ai_target_group", nil];
					private _zoneName = _group getVariable "ai_city";
					private _zone = [_zoneName] call INS_getZone;
					private _zoneMarker = _zone select 1;
					(getMarkerSize _zoneMarker) params ["_mx","_my"];
					private _zoneSize = (_mx max _my)*1.5;
					private _side = side _group;
					private _players = (call INS_allPlayers) select { side (group _x) != _side };
					private _buildings = ( (getMarkerPos _zoneMarker) nearObjects ["HOUSE", _zoneSize] ) 
										select { (count (_x buildingPos -1)) > 2 
												&& count ([getPos _x, _players,250] call CBA_fnc_getNearest) == 0
												&& ((getPos _x) distance2d (getPos _leader)) < 800 };
					private _building = objnull;
					if ( _buildings isEqualTo [] ) then {
						_building = nearestBuilding (getPos _leader);
					} else {
						_building = selectRandom _buildings;
					};
					[_group] call CBA_fnc_clearWaypoints;
					[_group, getPos _building, 75 + (random 50), 2, 0, 1 ] call CBA_fnc_taskDefend;
					diag_log (format ["Casualties causing %1 to start hiding in %2", _group, _zoneName]);
				};
			};
			
			private _surrenderRoll = _group getVariable "surrender_rolled";
			
			if ( !isNil "_initStr" && isNil "_surrenderRoll" ) then {
				private _alive = (units _group) select { alive _x };
				if ( count _alive == 1 ) then {
					private _last = _alive # 0;
					if ( vehicle _last == _last && count ( [_last,(call INS_allPlayers) select { side (group _x) != side _group }, 75] call CBA_fnc_getNearest) > 0 ) then {
						private _tough = _group getVariable ["ai_tough", false];
						private _surrender = selectRandomWeighted [true,( if ( _tough ) then { 0.3 } else { 0.7 } ),false,0.5];
						if ( _surrender ) then {
							["ACE_captives_setSurrendered", [_last, true], _last] call CBA_fnc_targetEvent;
							_last setCaptive true;
							_last setVariable [ "ai_surrendered", true, true ];
							diag_log (format ["%1 surrendering to players.",_last]);
						};
						_group setVariable ["surrender_rolled",true];
					};
				};
			};
			
			_hiding = _group getVariable "hiding";
			
			if ( isNil "_hiding" ) then {			
				switch ( _tasking ) do {
					case "GARRISON": {
						private _units = _interestingUnits select { side (group _x) != side _group && count ([_x,units _group,35] call CBA_fnc_getNearest) > 0 && ( _group knowsAbout _x ) > 1 };
						
						if ( count _units > 0 ) then {
							private _target = [_leader, _units] call CBA_fnc_getNearest;
							private _city = _group getVariable "ai_city";
							
							if ( !isNil "_city" ) then {
								_group setVariable ["ai_target_group", group _target];
								_group setVariable ["ai_dest", getPos _target];
								[_group, getPos _target, 25, _city] call doCounterAttack;
								diag_log (format ["Tasking %1 from garrison to counter attack against %2", _group, _target]);
							};
							
							_group setVariable ["ai_cooldown", time + 10]; 						
						};
					};
					case "PATROL": {
						private _units = _interestingUnits select { side (group _x) != side _group && count ([_x,units _group,400] call CBA_fnc_getNearest) > 0 && ( _group knowsAbout _x ) > 1 };
						
						if ( count _units > 0 ) then {
							private _target = [_leader, _units] call CBA_fnc_getNearest;
							private _city = _group getVariable "ai_city";
							
							if ( !isNil "_city" ) then {
								_group setVariable ["ai_target_group", group _target];
								_group setVariable ["ai_dest", getPos _target];
								[_group, getPos _target, 150, _city] call doCounterAttack;
								diag_log (format ["Tasking %1 from patrol to counter attack against %2", _group, _target]);
							};
							
							_group setVariable ["ai_cooldown", time + 10]; 						
						};
					};
					case "COUNTER-ATTACK": {
						private _dest = _group getVariable ["ai_dest",getPos _leader];
						
						if ( !isNil "_dest" ) then {
							if ( ( (getPos (leader _group)) distance _dest ) < 100 ) then {
								private _targetGroup = _group getVariable ["ai_target_group",grpnull];
								private _retask = false;
								if ( !isNull _targetGroup ) then {
									if ( count ((units _group) select { alive _x }) > 0 ) then {
										if ( ( (getPos (leader _group)) distance (getPos (leader _targetGroup)) ) > 150 ) then {
											_group setVariable ["ai_dest", getPos (leader _targetGroup)];
											[_group, getPos (leader _targetGroup), 50 + (random 45), _group getVariable "ai_city"] call doCounterAttack;
											diag_log (format ["Refining %1's counter attack against %2", _group, _targetGroup]);
										};
									} else {
										_retask = true;
									};
								} else {
									_retask = true;
								};
								
								if ( _retask ) then {
									_group setVariable ["ai_status", "GARRISON"];
									_group setVariable ["ai_dest", nil];
									_group setVariable ["ai_target_group", nil];
									private _zoneName = _group getVariable "ai_city";
									private _zone = [_zoneName] call INS_getZone;
									private _zoneMarker = _zone select 1;
									(getMarkerSize _zoneMarker) params ["_mx","_my"];
									private _zoneSize = (_mx max _my) * 1.25;
									private _buildings = ( (getMarkerPos _zoneMarker) nearObjects ["HOUSE", _zoneSize] ) 
														select { (count (_x buildingPos -1)) > 2 };
									[_group, getPos (selectRandom _buildings), 75 + (random 50), _zoneName] call setupAsGarrison;
									diag_log (format ["Retasking %1 as a garrison in %2", _group, _zoneName]);
								};
								
								_group setVariable ["ai_cooldown", time + 10]; 
							} else {
								_group setVariable ["ai_cooldown", time + 10]; 
							};
						};
					};
					case "NONE": {
					};
					
				};
			} else {
				_group setVariable ["ai_cooldown", time + 10];
			};
					
		} forEach (allGroups select { local _x && time > (_x getVariable ["ai_cooldown",0]) && (_x getVariable ["rts_setup",grpnull]) isEqualTo grpnull });
	};
};