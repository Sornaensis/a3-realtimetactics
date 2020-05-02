INS_spawnedGreenfor = []; // greenfor hostile to all sides
INS_spawnedOpfor = [];    
INS_spawnedBlufor = [];   // greenfor hostile to east
INS_spawnedCivilians = [];

INS_spawnedUnitCap = 100; // maximum spawned soldiers
INS_civilianCap = 50;
INS_spawnDist = 800; // distance in meters from buildings a player shall be when we begin spawning units.
INS_despawn = 1200; // despawn units this distance from players when they cannot be seen and their zone is inactive
INS_spawnPulse = 20; // seconds to pulse spawns
INS_initialSquads = 3; // spawn this many squads
INS_populationDensity = 15; // 15 men per square kilometer
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
				_retSide = selectRandomWeighted [east,0.8,resistance,0.25,west,0.1];
			} else {
				if ( _zoneDisp <= 0 ) then {
					_retSide = selectRandomWeighted [east,0.4,resistance,0.6,west,0.2];	
				} else {
					if ( _zoneDisp <= 24 ) then {
						_retSide = selectRandomWeighted [east,0.2,resistance,0.55,west,0.4];
					} else {
						if ( _zoneDisp < 51 ) then {
							_retSide = selectRandomWeighted [resistance 0.2,west 0.8];
						};
					};
				};
			};
		};
	};
	
	_retSide
};

getSpawnedSoldierCount = {
	(count INS_spawnedGreenfor) + (count INS_spawnedOpfor) + (count INS_spawnedBlufor)
};

getSpawnedSoldiers = {
	INS_spawnedGreenfor + INS_spawnedOpfor + INS_spawnedBlufor
};

getZoneSoldiers = {
	params ["_zoneName"];
	
	(call getSpawnedSoldiers) select { ((group _x) getVariable ["ai_city",""]) == _zoneName}
};

getZoneDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size; // sq m
	
	private _spawnedUnits = [_zoneName] call getZoneSoldiers;
	
	(count _spawnedUnits)/(_size/1000*1000)
	
};

INS_canZoneSpawnAndUpdate = {
	params ["_zoneName"];
	
	private _canSpawn = true;
	private _zones = INS_aiSpawnTable select { (_x select 0) == _zoneName };
	
	if ( count _zones == 0 ) then {
		_zones pushback [ _zoneName, time ];
	} else {
		private _zone = _zones select 0;
		
		if ( time > ( (_zone select 0) + INS_spawnPulse ) ) then {
			_zone set [1, time];
		} else {
			_canSpawn = false;
		};
	};
	
	_canSpawn
};

INS_activeZones = {
	private _players = (call INS_allPlayers) select { (_x getVariable ["insurgency_zone",""]) != "" };
	private _zones = []
	
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
	
	private _buildings = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select { count (_x buildingPos -1) > 2 };
	private _building = selectRandom _buildings;
	
	private _spawnfunc = selectRandomWeighted [INS_fnc_spawnSquad,0.9,INS_fnc_spawnCar,0.1,INS_fnc_spawnAPC,0.05,INC_fnc_spawnTank,0.001];
	
	private _leader = [getPos _building,_side] call _spawnfunc;
	(group _leader) setVariable ["ai_ciy", _zoneName];
	
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