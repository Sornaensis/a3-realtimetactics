setupAsGarrison = {
	params ["_group", "_pos", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "GARRISON"];
	_group setVariable ["ai_ciy", _city];
	[_group, _pos, _radius, 2, 0.7, 0 ] call CBA_fnc_taskDefend;
};

setupAsPatrol = {
	params ["_group", "_pos", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "PATROL"];
	_group setVariable ["ai_ciy", _city];
	[_group, _pos, _radius, 7, "MOVE", "SAFE", "RED", "NORMAL"] call CBA_fnc_taskPatrol;
};

doCounterAttack = {
	params ["_group", "_pos", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "COUNTER-ATTACK"];
	_group setVariable ["ai_ciy", _city];
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
	
	if ( _inrestricted ) exitWith { nil };
	
	
	private _marker = [_pos, INS_controlAreas apply { _x select 1 }] call CBA_fnc_getNearest;
	
	private _location = (INS_controlAreas select { _x select 1 == _nearest });
	
	_location select 0
};

INS_opforAiDeSpawner = addMissionEventHandler [ "EachFrame",
	{
		private _humanPlayers = call INS_allPlayers;
		// Spawn AI due to blufor player activity
		{
			private _unit = _x;
			if ( !isPlayer _unit && !((_unit getVariable ["rts_setup",objnull]) isEqualTo objnull) ) then {
			
				private _canBeSeen = false;
				private _unitPos = eyePos _unit;
				
				{
					private _playerPos = eyePos _x;
					if ( (_unitPos distance _playerPos) > 1200 ) then {
						if ( ([vehicle _x, vehicle _unit] call BIS_fnc_isInFrontOf) && !(terrainIntersect [_playerPos,_unitPos]) ) then {
							_canBeSeen = true;		
						};
					} else {
						_canBeSeen = true;
					};
				} forEach _humanPlayers;
				
				if ( !_canBeSeen ) then {
					deleteVehicle _unit;
				};
				
			};
		} forEach allUnits;
	}];


INS_opforAiSpawner = addMissionEventHandler [ "EachFrame",
	{
		private _humanPlayers = call INS_allPlayers;
		// Spawn AI due to blufor player activity
		if ( (call getSpawnedSoldierCount) < INS_spawnedUnitCap ) then {
			{
				private _player = _x;
				
				if ( vehicle _player == _player || ( (getPosATL (vehicle _player)) select 2 ) < 25 ) then {
				
					private _pos = getPos _player;
					private _zone = [_pos] call getNearestControlZone;
					
					// record zone
					_player setVariable ["insurgency_zone", _zone];
					
					if ( !isNil "_zone" ) then {
						if ( [_zone] call INS_canZoneSpawnAndUpdate ) then {
							if ( ([_zone] call getZoneDensity) < INS_populationDensity ) then {
								private _soldier = [_pos,_zone] call INS_spawnUnits;
								private _task = selectRandomWeighted [setupAsGarrison,0.9,setupAsPatrol,0.65];
								[(group _soldier), [(getPos _soldier), 75] call CBA_fnc_randPos, 400, _zone] call _task;
							};
						};
					};
				};
			} forEach (_humanPlayers select { side _x == west });
		};
	}];