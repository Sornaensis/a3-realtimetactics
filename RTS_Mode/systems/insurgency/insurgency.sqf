INS_spawnedUnitCap = 100; // maximum spawned soldiers
INS_civilianCap = 50;
INS_spawnDist = 800; // distance in meters from buildings a player shall be when we begin spawning units.
INS_despawn = 1200; // despawn units this distance from players when they cannot be seen and their zone is inactive
INS_spawnPulse = 20; // seconds to pulse spawns
INS_initialSquads = 3; // spawn this many squads
INS_populationDensity = 22; // 15 men per square kilometer
							// units from adjacent control zones may assist one another
							// spontaneous reinforcing is also a possibility


INS_aiSpawnTable = []; //  [  [ name, timestamp ] ]

INS_getZone = {
	params ["_zoneName"];
	
	(INS_controlAreas select { _x select 0 == _zoneName }) select 0;
};

INS_zoneDisposition = {
	params ["_zone"];
	
	if ( _zone isEqualType "STRING" ) then {
		_zone = [_zone] call INS_getZone;
	};
	
	(_zone select 2) select 0
};

INS_zoneIsOpfor = {
	params ["_zone"];
	
	private _disposition = [_zone] call INS_zoneDisposition;
	
	(_disposition < -24)
};

INS_zoneIsGreen = {
	params ["_zone"];
	
	private _disposition = [_zone] call INS_zoneDisposition;
	
	(_disposition >= -24) && (_disposition < 51) 
};

INS_zoneIsBlue = {
	params ["_zone"];
	
	private _disposition = [_zone] call INS_zoneDisposition;
	
	(_disposition >= 51)
};

INS_greenforDisposition = {
	params ["_zoneDisp"];
	
	private _retSide = east;
	
	if ( _zoneDisp >= 51 ) then {
		_retSide = west;
	} else {
		if ( _zoneDisp <= -51 ) then {
			_retSide = east;
		} else {
			if ( _zoneDisp <= -24 ) then {
				_retSide = selectRandomWeighted [east,0.9,resistance,0.1,west,0.01];
			} else {
				if ( _zoneDisp <= 0 ) then {
					_retSide = selectRandomWeighted [east,0.1,resistance,0.9,west,0.01];	
				} else {
					if ( _zoneDisp <= 24 ) then {
						_retSide = selectRandomWeighted [east,0.01,resistance,0.1,west,0.9];
					} else {
						if ( _zoneDisp < 51 ) then {
							_retSide = selectRandomWeighted [resistance,0.1,west,0.9];
						};
					};
				};
			};
		};
	};
	
	_retSide
};

getSpawnedSoldierCount = {
	count (call getSpawnedSoldiers)
};

getSpawnedSoldiers = {
	(allUnits + allDeadMen) select { !(((group _x) getVariable ["ai_city",objnull]) isEqualTo objnull) }
};

getZoneSoldiers = {
	params ["_zoneName"];
	
	(call getSpawnedSoldiers) select { ((group _x) getVariable ["ai_city",""]) == _zoneName}
};

getZoneGroups = {
	params ["_zoneName"];
	
	allGroups select { (_x getVariable ["ai_city",""]) == _zoneName}
};


INS_getZoneDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size; // sq m
	
	private _spawnedUnits = [_zoneName] call getZoneSoldiers;
	
	(count _spawnedUnits)/(_size/1000/1000)
	
};

INS_canZoneSpawnAndUpdate = {
	params ["_zoneName"];
	
	private _canSpawn = true;
	private _zones = INS_aiSpawnTable select { (_x select 0) == _zoneName };
	
	if ( count _zones == 0 ) then {
		_zones pushback [ _zoneName, time ];
	} else {
		private _zone = _zones select 0;
		
		if ( time > ( (_zone select 1) + INS_spawnPulse ) ) then {
			_zone set [1, time];
		} else {
			_canSpawn = false;
		};
	};
	
	_canSpawn
};

INS_activeZones = {
	private _players = (call INS_allPlayers) select { (_x getVariable ["insurgency_zone",""]) != "" };
	private _zones = [];
	
	{
		_zones pushbackUnique _x;
	} forEach (_players apply { _x getVariable "insurgency_zone" });
	
	_zones
};

INS_spawnUnits = {
	params ["_pos","_zoneName"];
	
	private _zone = [_zoneName] call INS_getZone;
	
	private _zonePos = getMarkerPos (_zone select 1);
	
	(getMarkerPos (_zone select 1)) params ["_mx","_my"];
	private _zoneSize = (_mx max _my) * 1.8;
	
	private _side = [[_zone] call INS_zoneDisposition] call INS_greenforDisposition;
	
	private _buildings = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select { (count (_x buildingPos -1) > 2) && ((position _x) distance _pos) < 1400 };
	private _pos = (selectRandom _buildings) findEmptyPosition [10,50,"MAN"];
	private _tries = 0;
	
	while { _tries < 20 && count ([_pos, ([_zoneName] call getZoneSoldiers) select { side _x != _side },100] call CBA_fnc_getNearest) > 0 } do {
		_pos = (selectRandom _buildings) findEmptyPosition [10,50,"MAN"];
		_tries = _tries + 1;
	};
	
	if ( count ([_pos, ([_zoneName] call getZoneSoldiers) select { side _x != _side },100] call CBA_fnc_getNearest) > 0 ) exitWith { objnull };
	
	private _spawnfunc = selectRandomWeighted [INS_fnc_spawnSquad,0.9,INS_fnc_spawnCar,0.1,INS_fnc_spawnAPC,0.05,INC_fnc_spawnTank,0.001];
	
	private _leader = [_pos,_side] call _spawnfunc;
	(group _leader) setVariable ["ai_city", _zoneName];
	
	{
		_soldierList pushback _x;
	} forEach (units (group _leader));
	
	if ( vehicle _leader != _leader ) then {
		(vehicle _leader) setVariable ["spawned_vehicle", true];
	};
	
	diag_log (format ["Spawned group of %1 soldiers at %2", _side, _zoneName]);
	
	_leader
};


waitUntil { time > 0 };
waitUntil { INS_setupFinished };

INS_missionMonitor= addMissionEventHandler [ "EachFrame",
	{
		
	}];
	
INS_zoneColoring = addMissionEventHandler [ "EachFrame",
	{
		{
			private _zone = _x;
			private _marker = _zone select 1;
			if ( [_zone] call INS_zoneIsGreen ) then {
				_marker setMarkerColor "ColorGreen";
			} else {
				if ( [_zone] call INS_zoneIsOpfor ) then {
					_marker setMarkerColor "ColorRed";
				} else {
					_marker setMarkerColor "ColorBlue";
				};
			};
		} forEach INS_controlAreas;
	}];