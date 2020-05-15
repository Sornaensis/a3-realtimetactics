// Despawn
INS_unitDespawner = [] spawn {
	while { true } do {
		private _humanPlayers = call INS_allPlayers;
		private _insurgents = ( if ( count ( _humanPlayers select { side _x == east }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
		private _unitSpawners = (_humanPlayers + _insurgents);
		{
			private _unit = _x;
			if ( !isPlayer _unit && !((_unit getVariable ["ins_side",objnull]) isEqualTo objnull) || !(alive _unit) ) then {
			
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
			if ( !((_x getVariable ["ai_city",objnull]) isEqualTo objnull) ) then {
				if ( count ( (units _x) select { alive _x } ) == 0 ) then {
					deleteGroup _x;
				};
			};
		} forEach allGroups;
	};
};

INS_vehicleDespawner = [] spawn {
	while { true } do {
		private _humanPlayers = call INS_allPlayers;
		private _insurgents = ( if ( count ( _humanPlayers select { side _x == east }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
		private _unitSpawners = (_humanPlayers + _insurgents);
		{
			private _veh = _x;
			private _vehpos = getPos _x;
			if ( _veh getVariable ["spawned_vehicle", false] || _veh isKindOf "WeaponHolder" || !(alive _x) ) then {
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
					if ( _veh isKindOf "WeaponHolder" ) then {
						clearWeaponCargo _veh; clearMagazineCargo _veh; clearItemCargo _veh;
					} else {					
						deleteVehicle _veh;
					};
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
		
	};
};

INS_hasHC = {
	count (entities "HeadlessClient_F") > 0
};

INS_hcRoundRobin = [];

INS_getNextHC = {
	private _headlessClients = (entities "HeadlessClient_F") - INS_hcRoundRobin;
	
	if ( _headlessClients isEqualTo [] ) then {
		INS_hcRoundRobin = [];
		_headlessClients = entities "HeadlessClient_F";
	};
	
	private _hc = _headlessClients # 0;
	
	INS_hcRoundRobin pushback _hc;
	
	_hc	
};

INS_opforAiSpawner = addMissionEventHandler ["EachFrame",
{
		private _humanPlayers = call INS_allPlayers;
		private _insurgents = ( if ( count ( _humanPlayers select { side _x == east }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
		private _unitSpawners = ( (_humanPlayers select { side _x != east }) + _insurgents );
				
		// Spawn AI due to blufor player activity
		if ( (call getSpawnedSoldierCount) < INS_spawnedUnitCap ) then {
			{
				private _player = _x;
				
				if ( vehicle _player == _player || ( (getPosATL (vehicle _player)) select 2 ) < 5 || ( (speed (vehicle _player) < 14 ) && ( (getPosATL (vehicle _player)) select 2 ) < 200 ) ) then {
				
					private _params = [];
					private _pos = getPos _player;
					private _zone = [_pos] call getNearestControlZone;
					private _zone2 = [_pos] call getNearestControlZone2;
					
					if ( !isNil "_zone" ) then {					
						// record zone
						_player setVariable ["insurgency_zone", _zone];
						if ( [_zone] call INS_canZoneSpawnAndUpdate ) then {
							private _density = [_zone] call INS_getZoneDensity;
							if ( _density < INS_populationDensity ) then {
								_params pushback [_zone,_pos];
							};
						};
					} else {
						_player setVariable ["insurgency_zone", nil];
					};
					
					if ( !isNil "_zone2" ) then {
						if ( [_zone2] call INS_canZoneSpawnAndUpdate ) then {
							private _density = [_zone2] call INS_getZoneDensity;
							if ( _density < INS_populationDensity ) then {
								_params pushback [_zone2,_pos];
							};
						};
					};
					
					// garrison spawn
					if ( !(_params isEqualTo []) ) then {
						if ( call INS_hasHC ) then {
							private _hc = call INS_getNextHC;
							[_params, _hc] spawn {
								params ["_params","_hc"];
								[_params, { { _x spawn INS_spawnTownGarrison; } forEach _this; }] remoteExecCall [ "call", _hc ];
							};
						} else {
							{
								_x call INS_spawnTownGarrison;
							} forEach _params;
						};
					};
					
					// patrol logic
					if ( !isNil "_zone" ) then {
						private _patrolZone = INS_patrolTable findIf { (_x select 0) isEqualTo _zone };
						
						if ( _patrolZone != -1 ) then {
							private _patrols = INS_patrolTable # _patrolZone;
							_patrols params ["","_pulse","_time"];
							// reset patrols after 2min zone absence
							if ( _time != -1 && time < (_time + _pulse) + 120 ) then {
								if ( time > (_time + _pulse) ) then {
									
									if ( _pulse > 4000 ) then {
										_pulse = 0;
									};
									
									_patrols set [1, _pulse + 300 + (floor (random 300))];
									_patrols set [2, time];
									if ( call INS_hasHC ) then {
										private _hc = call INS_getNextHC;
										[_zone, _hc] spawn {
											params ["_zone","_hc"];
											[_zone, { _this spawn INS_spawnPatrol; }] remoteExecCall [ "call", _hc ];
										};
									} else {
										_zone spawn INS_spawnPatrol;
									};
								};
							} else {
								_patrols set [1, 600 + (floor (random 240))];
								_patrols set [2, time];
							};
							
						} else {
							INS_patrolTable pushback [ _zone, -1, -1 ];
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
					
					if ( !isNil "_zone" ) then {
						if ( [_zone] call INS_canZoneSpawnCiviliansAndUpdate ) then {
							if ( ([_zone] call INS_getZoneCivilianDensity) < INS_civilianDensity ) then {
								diag_log (format ["Can spawn at %1 with civilian density %2", _zone, ([_zone] call INS_getZoneCivilianDensity)]);
								private _soldierList = [_pos,_zone] call INS_spawnCivilian;
								if ( !isNil "_soldierList" && !isNull (_soldierList select 0) ) then {
									_soldierList params ["_soldier", "_position"];
									private _task = selectRandomWeighted [setupAsCivilianGarrison,0.9,setupAsFullGarrison,0.7,setupAsPatrol,0.1];
									_soldier setUnitPos "UP";
									_soldier setUnitPosWeak "UP";
									private _radius = 75 + (random 50);
									if ( vehicle _soldier != _soldier ) then {
										_task = setupAsPatrol;
										_radius = (1200 + random 100);
									};
									private _zoneAct = [_zone] call INS_getZone;
									private _zoneMarker = _zoneAct select 1;
									(getMarkerSize _zoneMarker) params ["_mx","_my"];
									private _zoneSize = (_mx max _my) * 1.2;
									private _buildings = ( (getMarkerPos _zoneMarker) nearObjects ["HOUSE", _zoneSize] ) 
														select { (count (_x buildingPos -1)) > 2 };									
									[(group _soldier), getPos (selectRandom _building), _radius, _zone] call _task;
								};
							};
						};
					};
				};
			} forEach ( _humanPlayers + _insurgents );
		};
}];