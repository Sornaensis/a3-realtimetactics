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
		
		// Spawn AI due to blufor player activity
		if ( (call getSpawnedSoldierCount) < INS_spawnedUnitCap ) then {
			{
				private _player = _x;
				
				if ( vehicle _player == _player || ( (getPosATL (vehicle _player)) select 2 ) < 800 ) then {
				
					private _pos = getPos _player;
					private _zone = [_pos] call getNearestControlZone;
					
					if ( !isNil "_zone" ) then {
						// record zone
						_player setVariable ["insurgency_zone", _zone];
						if ( [_zone] call INS_canZoneSpawnAndUpdate ) then {
							if ( ([_zone] call INS_getZoneDensity) < INS_populationDensity ) then {
								diag_log (format ["Can spawn at %1 with soldier density %2", _zone, ([_zone] call INS_getZoneDensity)]);
								private _soldierList = [_pos,_zone] call INS_spawnUnits;
								if ( !isNil "_soldierList" ) then {
									_soldierList params ["_soldier", "_position"];
									private _task = selectRandomWeighted [setupAsGarrison,0.9,setupAsPatrol,0.2];
									private _radius = 75 + (random 50);
									if ( vehicle _soldier != _soldier ) then {
										_task = setupAsPatrol;
										_radius = 400 + (random 150);
									};
									private _group = group _soldier;
									[_group, [_position, 25] call CBA_fnc_randPos, _radius, _zone] call _task;
									diag_log (format ["Headless client tasking %1",_group]);
								};			
							};
						};
					} else {
						_player setVariable ["insurgency_zone", nil];
					};
					
					// second nearest zone
					private _zone2 = [_pos] call getNearestControlZone2;
					if ( !isNil "_zone2" ) then {
						if ( [_zone2] call INS_canZoneSpawnAndUpdate ) then {
							if ( ([_zone2] call INS_getZoneDensity) < INS_populationDensity ) then {
								diag_log (format ["Can spawn at %1 with soldier density %2", _zone, ([_zone] call INS_getZoneDensity)]);
								private _soldierList = [_pos,_zone2] call INS_spawnUnits;
								if ( !isNil "_soldierList" ) then {
									_soldierList params ["_soldier", "_position"];
									private _task = selectRandomWeighted [setupAsGarrison,0.9,setupAsPatrol,0.2];
									private _radius = 75 + (random 50);
									if ( vehicle _soldier != _soldier ) then {
										_task = setupAsPatrol;
										_radius = 400 + (random 150);
									};
									private _group = group _soldier;
									[_group, [_position, 25] call CBA_fnc_randPos, _radius, _zone] call _task;
									diag_log (format ["Headless client tasking %1",_group]);
								};
							};
						};
					};
				};
			} forEach _unitSpawners;
		};
		
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
	};
};