INS_lastHCs = [];

// basic load balancer
INS_getNextHC = {
	private _hcs = (call INS_headlessClients) - INS_lastHCs;
	
	if ( count _hcs == 0 ) then {
		INS_lastHCs = [];
		_hcs = call INS_headlessClients;
	};
	
	private _hc = _hcs deleteAt 0;
	
	INS_lastHCs pushbackunique _hc;
	
	_hc
};

// Despawn
[] spawn {
	while { true } do {
		private _humanPlayers = call INS_allPlayers;
		private _insurgents = ( if ( count ( _humanPlayers select { side _x == east }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
		private _unitSpawners = (_humanPlayers + _insurgents);
		{
			private _unit = _x;
			if ( !isPlayer _unit && !((_unit getVariable ["ins_side",objnull]) isEqualTo objnull) ) then {
			
				private _canBeSeen = false;
				private _unitPos = getPos _unit;
				
				{
					private _playerPos = getPos _x;
					private _zone = "AI";
					if ( isPlayer _x ) then {
						_zone = [_playerPos] call getNearestControlZone;
					};
					if ( (_unitPos distance2d _playerPos) > 1500 || isNil "_zone" ) then {
						if ( ([vehicle _x, vehicle _unit] call BIS_fnc_isInFrontOf) && !(terrainIntersect [eyePos _x,eyePos _unit]) ) then {
							_canBeSeen = true;		
						};
					} else {
						_canBeSeen = true;
					};
				} forEach _unitSpawners;
				
				if ( !_canBeSeen ) then {		
					deleteVehicle (vehicle _unit);
					deleteVehicle _unit;
				};
				
			};
		} forEach (allUnits + allDeadMen);
		
		{
			private _veh = _x;
			private _vehpos = getPos _x;
			if ( _veh getVariable ["spawned_vehicle", false] ) then {
				private _canBeSeen = false;
				{
					private _playerPos = getPos _x;
					private _zone = [_playerPos] call getNearestControlZone;
					if ( (_vehpos distance2d _playerPos) > 1500 || isNil "_zone" ) then {
						if ( ([_veh, vehicle _x] call BIS_fnc_isInFrontOf) && !(terrainIntersect [eyePos _x,_vehpos]) ) then {
							_canBeSeen = true;		
						};
					} else {
						_canBeSeen = true;
					};
				} forEach _unitSpawners;
				
				if ( !_canBeSeen ) then {		
					deleteVehicle _veh;
				};
			};
		} forEach (vehicles + allDead);
		
		// infinite fuel
		{
			private _veh = _x;
			private _driver = driver _veh;
			if ( (_veh getVariable ["spawned_vehicle", false]) || ( !(isNull _driver) && !(isPlayer _driver) ) ) then {
				_veh setFuel 1;
			};
		} forEach vehicles;
		
		{
			if ( !((_x getVariable ["ai_city",objnull]) isEqualTo objnull) ) then {
				if ( count ( (units _x) select { alive _x } ) == 0 ) then {
					deleteGroup _x;
				};
			};
		} forEach allGroups;
	};
};


INS_opforAiSpawner = addMissionEventHandler [ "EachFrame",
	{
		private _humanPlayers = call INS_allPlayers;
		private _insurgents = ( if ( count ( _humanPlayers select { side _x == east }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
		private _unitSpawners = ( (_humanPlayers select { side _x != east }) + _insurgents );
		
		private _headlessClients = call INS_headlessClients;
		
		// Spawn AI due to blufor player activity
		if ( (call getSpawnedSoldierCount) < INS_spawnedUnitCap ) then {
			{
				private _player = _x;
				
				if ( vehicle _player == _player || ( (getPosATL (vehicle _player)) select 2 ) < 800 ) then {
				
					private _pos = getPos _player;
					private _zone = [_pos] call getNearestControlZone;
					
					// record zone
					_player setVariable ["insurgency_zone", _zone];
					
					if ( !isNil "_zone" ) then {
						if ( [_zone] call INS_canZoneSpawnAndUpdate ) then {
							if ( ([_zone] call INS_getZoneDensity) < INS_populationDensity ) then {
								diag_log (format ["Can spawn at %1 with soldier density %2", _zone, ([_zone] call INS_getZoneDensity)]);
								private _soldierList = [_pos,_zone] call INS_spawnUnits;
								if ( !isNil "_soldierList" && !isNull (_soldierList select 0) ) then {
									_soldierList params ["_soldier", "_position"];
									private _task = selectRandomWeighted [setupAsGarrison,0.9,setupAsPatrol,0.2];
									private _radius = 75 + (random 50);
									if ( vehicle _soldier != _soldier ) then {
										_task = setupAsPatrol;
										_radius = 250 + (random 100);
									};
									// basic Headless client distribution + load balancing									
									private _hc = call INS_getNextHC;
									[-1, 
										{
											params ["_soldier","_position","_radius","_zone","_task","_hc"];
											if ( hasInterface ) exitWith {};
											if ( !local _hc ) exitWith {};
											[0, { params ["_grp","_owner"]; _grp setGroupOwner _owner },[group _soldier,clientOwner]] call CBA_fnc_globalExecute;	
											_this spawn {
												params ["_soldier","_position","_radius","_zone","_task","_hc"];
												waitUntil { local (group _soldier) };
												private _group = group _soldier;
												{
													_x call RTS_fnc_aiSkill;
												} forEach ( units _group );
												[_group, [_position, 25] call CBA_fnc_randPos, _radius, _zone] call _task;
												diag_log format ["Headless client tasking %1",_group];
											};
										}, [_soldier, _position,_radius,_zone,_task,_hc] ] call CBA_fnc_globalExecute;			
								};
							};
						};
					};
					
					// second nearest zone
					private _zone2 = [_pos] call getNearestControlZone2;
					if ( !isNil "_zone2" ) then {
						if ( [_zone2] call INS_canZoneSpawnAndUpdate ) then {
							if ( ([_zone2] call INS_getZoneDensity) < INS_populationDensity ) then {
								diag_log (format ["Can spawn at %1 with soldier density %2", _zone2, ([_zone2] call INS_getZoneDensity)]);
								private _soldierList = [_pos,_zone2] call INS_spawnUnits;
								if ( !isNil "_soldierList" && !isNull (_soldierList select 0) ) then {
									_soldierList params ["_soldier", "_position"];
									private _task = selectRandomWeighted [setupAsGarrison,0.9,setupAsPatrol,0.2];
									private _radius = 75 + (random 50);
									if ( vehicle _soldier != _soldier ) then {
										_task = setupAsPatrol;
										_radius = 250 + (random 100);
									};
									// basic Headless client distribution + load balancing									
									private _hc = call INS_getNextHC;
									[-1, 
										{
											params ["_soldier","_position","_radius","_zone2","_task","_hc"];
											if ( hasInterface ) exitWith {};
											if ( !local _hc ) exitWith {};
											[0, { params ["_grp","_owner"]; _grp setGroupOwner _owner },[group _soldier,clientOwner]] call CBA_fnc_globalExecute;	
											_this spawn {
												params ["_soldier","_position","_radius","_zone2","_task","_hc"];
												waitUntil { local (group _soldier) };
												private _group = group _soldier;
												{
													_x call RTS_fnc_aiSkill;
												} forEach ( units _group );
												[_group, [_position, 25] call CBA_fnc_randPos, _radius, _zone2] call _task;
												diag_log format ["Headless client tasking %1",_group];
											};
										}, [_soldier, _position,_radius,_zone2,_task,_hc] ] call CBA_fnc_globalExecute;									
									
								};
							};
						};
					};
				};
			} forEach _unitSpawners;
		};
		if ( (call getSpawnedCiviliansCount) < INS_civilianCap ) then {
			{
				private _player = _x;
				
				if ( vehicle _player == _player || ( (getPosATL (vehicle _player)) select 2 ) < 800 ) then {
				
					private _pos = getPos _player;
					private _zone = [_pos] call getNearestControlZone;
					
					// record zone
					_player setVariable ["insurgency_zone", _zone];
					
					if ( !isNil "_zone" ) then {
						if ( [_zone] call INS_canZoneSpawnCiviliansAndUpdate ) then {
							if ( ([_zone] call INS_getZoneCivilianDensity) < INS_civilianDensity ) then {
								diag_log (format ["Can spawn at %1 with civilian density %2", _zone, ([_zone] call INS_getZoneCivilianDensity)]);
								private _soldierList = [_pos,_zone] call INS_spawnCivilian;
								if ( !isNil "_soldierList" && !isNull (_soldierList select 0) ) then {
									_soldierList params ["_soldier", "_position"];
									private _task = selectRandomWeighted [setupAsCivilianGarrison,0.9,setupAsGarrison,0.1];
									_soldier setUnitPos "UP";
									_soldier setUnitPosWeak "UP";
									private _radius = 75 + (random 50);
									if ( vehicle _soldier != _soldier ) then {
										_task = setupAsPatrol;
										_radius = (1200 + random 100);
									};									
									[(group _soldier), [_position, 25] call CBA_fnc_randPos, _radius, _zone] call _task;
								};
							};
						};
					};
				};
			} forEach ( _humanPlayers + _insurgents );
		};
	}];