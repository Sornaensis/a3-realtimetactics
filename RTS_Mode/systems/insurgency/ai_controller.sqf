setupAsGarrison = {
	params ["_group", "_pos", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "GARRISON"];
	_group setVariable ["ai_city", _city];
	[_group, _pos, _radius, 2, 0.7, 0 ] call CBA_fnc_taskDefend;
};

setupAsPatrol = {
	params ["_group", "_pos", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "PATROL"];
	_group setVariable ["ai_city", _city];
	[_group, _pos, _radius, 7, "MOVE", "SAFE", "RED", (if ( side _group == civilian ) then { "LIMITED" } else { "NORMAL" })] call CBA_fnc_taskPatrol;
};

doCounterAttack = {
	params ["_group", "_pos", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "COUNTER-ATTACK"];
	_group setVariable ["ai_city", _city];
	if ( vehicle (leader _group) != leader _group ) then {
		[_group, _pos, _radius, 7, "MOVE", "COMBAT", "RED", "FULL"] call CBA_fnc_taskPatrol;
	} else {
		[_group, _pos, _radius] call CBA_fnc_taskAttack;
	};
};

getNearestControlZone = {
	params ["_pos"];
	
	private _inrestricted = false;
	
	{
		if ( _pos inArea _x ) then {
			_inrestricted = true;
		};
	} forEach RTS_restrictionZone;
	
	if ( _inrestricted ) exitWith {  };
	
	private _marker = [_pos, INS_controlAreas apply { _x select 1 }] call CBA_fnc_getNearest;
	
	private _location = (INS_controlAreas select { (_x select 1) == _marker });
	
	(_location select 0) select 0
};

INS_opforAiDeSpawner = addMissionEventHandler [ "EachFrame",
	{
		private _humanPlayers = call INS_allPlayers;
		{
			private _unit = _x;
			if ( !isPlayer _unit && !((_unit getVariable ["ins_side",objnull]) isEqualTo objnull) ) then {
			
				private _canBeSeen = false;
				private _unitPos = getPos _unit;
				
				{
					private _playerPos = getPos _x;
					private _zone = [_playerPos] call getNearestControlZone;
					if ( (_unitPos distance2d _playerPos) > 1500 || isNil "_zone" ) then {
						if ( ([vehicle _x, vehicle _unit] call BIS_fnc_isInFrontOf) && !(terrainIntersect [eyePos _x,eyePos _unit]) ) then {
							_canBeSeen = true;		
						};
					} else {
						_canBeSeen = true;
					};
				} forEach _humanPlayers;
				
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
					if ( (_vehpos distance2d _playerPos) > 1500 ) then {
						if ( ([_veh, vehicle _x] call BIS_fnc_isInFrontOf) && !(terrainIntersect [eyePos _x,_vehpos]) ) then {
							_canBeSeen = true;		
						};
					} else {
						_canBeSeen = true;
					};
				} forEach _humanPlayers;
				
				if ( !_canBeSeen ) then {		
					deleteVehicle _veh;
				};
			};
		} forEach (vehicles + allDead);
		
		// infinite fuel
		{
			private _veh = _x;
			private _driver = driver _veh;
			if ( (_veh getVariable ["spawned_vehicle", false]) || ( !(isNull _driver) && side _driver != west ) ) then {
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
	}];


INS_opforAiSpawner = addMissionEventHandler [ "EachFrame",
	{
		private _humanPlayers = call INS_allPlayers;
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
								private _soldier = [_pos,_zone] call INS_spawnUnits;
								if ( !isNull _soldier ) then {
									private _task = selectRandomWeighted [setupAsGarrison,0.4,setupAsPatrol,0.8];
									[(group _soldier), [(getPos _soldier), 75] call CBA_fnc_randPos, 400, _zone] call _task;
								};
							};
						};
					};
				};
			} forEach (_humanPlayers select { side _x == west });
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
								private _soldier = [_pos,_zone] call INS_spawnCivilian;
								if ( !isNull _soldier ) then {
									private _task = selectRandomWeighted [setupAsGarrison,0.6,setupAsPatrol,0.4];
									[(group _soldier), [(getPos _soldier), 75] call CBA_fnc_randPos, 400, _zone] call _task;
								};
							};
						};
					};
				};
			} forEach (_humanPlayers select { side _x == west });
		};
	}];