INS_spawnedUnitCap = 150; // maximum spawned soldiers
INS_civilianCap = 50;
INS_spawnDist = 800; // distance in meters from buildings a player shall be when we begin spawning units.
INS_despawn = 1200; // despawn units this distance from players when they cannot be seen and their zone is inactive
INS_spawnPulse = 8; // seconds to pulse spawns
INS_initialSquads = 3; // spawn this many squads
INS_civilianDensity = 11;
INS_carDensity = 7;
INS_populationDensity = 17; 


// track soldier casualties so zones aren't always fully respawning
INS_cityCasualtyTracker = []; // [ [ name, count, timestamp ] ]

// track spawn times
INS_aiSpawnTable = []; //  [  [ name, timestamp ] ]
INS_civSpawnTable = [];

// Spawn a patrol in an active zone
// pulse patrols between 300-500 seconds
// after each pulse increase time by 200-340
INS_patrolTable = []; // [ [ name, pulse, timestamp (-1 for inactive) ] ]

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
		if ( _zoneDisp < -51 ) then {
			_retSide = east;
		} else {
			if ( _zoneDisp < -24 ) then {
				_retSide = east;
			} else {
				if ( _zoneDisp <= 0 ) then {
					_retSide = resistance;	
				} else {
					if ( _zoneDisp <= 24 ) then {
						_retSide = resistance;
					} else {
						if ( _zoneDisp < 51 ) then {
							_retSide = resistance;
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
	(allUnits + allDeadMen) select { !(((group _x) getVariable ["ai_city",objnull]) isEqualTo objnull) && (_x getVariable ["ins_side",civilian]) != civilian }
};

getSpawnedCiviliansCount = {
	count (call getSpawnedCivilians)
};

getSpawnedCivilians = {
	(allUnits + allDeadMen) select { !(((group _x) getVariable ["ai_city",objnull]) isEqualTo objnull) && (_x getVariable ["ins_side",east]) == civilian }
};

getZoneSoldiers = {
	params ["_zoneName"];
	
	(call getSpawnedSoldiers) select { ((group _x) getVariable ["ai_city",""]) isEqualTo _zoneName}
};

getZoneCars = {
	params ["_zoneName"];
	
	(vehicles select { (_x getVariable ["ai_city",""]) isEqualTo _zoneName })
};

getZoneGroups = {
	params ["_zoneName"];
	
	allGroups select { (_x getVariable ["ai_city",""]) isEqualTo _zoneName}
};

INS_getZoneCarDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size; // sq m
	
	private _cars = count ([_zoneName] call getZoneCars);
	
	_cars/(_size/1000/1000)
};

INS_getZoneCivilianDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size; // sq m
	
	private _population = count ( (allUnits + allDeadMen) select { ((getPos _x) distance (getMarkerPos _marker)) < ((_mx max _my)*1.6) && !isPlayer _x && (_x getVariable ["ins_side",east]) == civilian } );
	private _nominalPop = count ((allUnits + allDeadMen) select { !isPlayer _x && (_x getVariable ["ins_side",east]) == civilian && ((group _x) getVariable ["ai_city",""]) == _zoneName });
	
	(_population max _nominalPop)/(_size/1000/1000)
	
};

// density for soldiers

INS_zoneMaxPop = {
	params ["_zone"];
	
	private _marker = _zone select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size/1000/1000; // sq m
	
	floor (_size * INS_populationDensity)
};

INS_getZoneDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = (_size*_size) max 562500; // sq m
	
	private _population = count ((allUnits + allDeadMen) select { ((getPos _x) distance (getMarkerPos _marker)) < ((_mx max _my)*1.8) && !isPlayer _x && (_x getVariable ["ins_side",civilian]) != civilian });
	private _nominalPop = count ((allUnits + allDeadMen) select { !isPlayer _x && (_x getVariable ["ins_side",civilian]) != civilian && ((group _x) getVariable ["ai_city",""]) == _zoneName });
	
	private _popAdjust = 0;
	
	private _casIndex = INS_cityCasualtyTracker findIf { (_x # 0) == _zoneName };
	if ( _casIndex != -1 ) then {
		private _casualties = INS_cityCasualtyTracker # _casIndex;
		
		if ( time < ( (_casualties # 2 ) + 7200 ) ) then {
			private _count = _casualties # 1;
			_popAdjust = _count min (floor (([_location] call INS_zoneMaxPop) * 0.75));
		};
	};
	
	( (_population max _nominalPop) + _popAdjust )/(_size/1000/1000)
	
};

INS_canZoneSpawnCiviliansAndUpdate = {
	params ["_zoneName"];
	
	private _canSpawn = true;
	private _zones = INS_civSpawnTable select { (_x select 0) == _zoneName };
	
	if ( count _zones == 0 ) then {
		INS_civSpawnTable pushback [ _zoneName, time ];
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

INS_canZoneSpawnAndUpdate = {
	params ["_zoneName"];
	
	private _canSpawn = true;
	private _zones = INS_aiSpawnTable select { (_x select 0) == _zoneName };
	
	if ( count _zones == 0 ) then {
		INS_aiSpawnTable pushback [ _zoneName, time ];
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

getNearestControlZone2 = {
	params ["_pos"];
	
	private _inrestricted = false;
	
	{
		if ( _pos inArea _x ) then {
			_inrestricted = true;
		};
	} forEach RTS_restrictionZone;
	
	if ( _inrestricted ) exitWith {  };
	
	private _zone = [_pos] call getNearestControlZone;
	
	private _marker = [_pos, ( INS_controlAreas select { (_x select 0) != _zone } ) apply { _x select 1 }] call CBA_fnc_getNearest;
	
	private _location = (INS_controlAreas select { (_x select 1) == _marker });
	
	(_location select 0) select 0
};

INS_spawnCivilian = {
	params ["_pos","_zoneName"];
	
	private _zone = [_zoneName] call INS_getZone;
	
	private _zonePos = getMarkerPos (_zone select 1);
	
	(getMarkerSize (_zone select 1)) params ["_mx","_my"];
	private _zoneSize = (_mx max _my)*1.8;
	
	private _otherCivs = allUnits select { (_x getVariable ["ins_side",east]) == civilian };
	
	private _buildings = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select 
							{ 
								(count (_x buildingPos -1) > 2) 
								&& count ([position _x, _otherCivs,50] call CBA_fnc_getNearest) == 0
								&& ((position _x) distance _pos) < 1600	};
	
	if ( count _buildings == 0) exitWith { };
	
	_pos = (selectRandom _buildings) buildingPos 1;
	
	private _spawnfunc = selectRandomWeighted ["Civ",1,"Car",0.22];
	
	private _leader = objnull;
	
	switch ( _spawnfunc ) do {
		case "Civ": {
			_leader = [_pos,createGroup civilian] call INS_fnc_spawnRandomSoldier;
		};
		case "Car": {
			_leader = [_pos,civilian] call INS_fnc_spawnCar;
		};
	};
	
	(group _leader) setVariable ["ai_city", _zoneName, true];
	
	{
		_x setVariable ["ins_side", civilian, true];
	} forEach (units (group _leader));
	
	if ( vehicle _leader != _leader ) then {
		(vehicle _leader) setVariable ["spawned_vehicle", true];
	};
	
	(group _leader) deleteGroupWhenEmpty true;
	
	diag_log format ["Spawned %1 civilian at %2 (%3)",count (units (group _leader)),_pos,_zoneName];
	
	private _carDensity = [_zoneName] call INS_getZoneCarDensity;
	// try to spawn a car
	if ( _carDensity < INS_carDensity ) then {
		private _car = [getPos (selectRandom _buildings), true] call INS_fnc_spawnEmptyCar;
		_car setVariable ["ai_city", _zoneName];
		_car setVariable ["spawned_vehicle", true];
		diag_log format ["Spawned a car at %1 (%2)",_pos,_zoneName];
	};
	
	[_leader,_pos]
};

INS_spawnUnits = {
	params ["_pos","_zoneName"];
	
	private _zone = [_zoneName] call INS_getZone;
	
	private _zoneMarker = (_zone select 1);
	private _zonePos = getMarkerPos _zoneMarker;
	
	(getMarkerSize _zoneMarker) params ["_mx","_my"];
	private _zoneSize = (_mx max _my) * 1.6;
		
	private _side = [[_zone] call INS_zoneDisposition] call INS_greenforDisposition;
	private _enemySoldiers = allUnits select { side (group _x) != civilian && side (group _x) != _side };
	private _friendlySoldiers = allUnits select { side (group _x) == _side && side (group _x) != civilian };
	
	private _players = (call INS_allPlayers) select { side (group _x) != _side };
	
	private _spawnlocs = [];
	
	private _spawntype = selectRandomWeighted ["Squad",1,"APC",0.09,"Tank",0.01];
	private _spawnfunc = {};
	
	switch ( _spawntype ) do {
		case "Squad":{
			_spawnfunc = INS_fnc_spawnSquad;		
			_spawnlocs = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select 
							{ (count (_x buildingPos -1) > 2) 
								&& ((position _x) distance _pos) < 1600
								&& !((position _x) inArea "opfor_restriction")
								&& count ([position _x, _players,400] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _friendlySoldiers,100] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _enemySoldiers,800] call CBA_fnc_getNearest) == 0 };
		};
		case "APC": {
			_spawnfunc = INS_fnc_spawnAPC;
			_spawnlocs =  (_zonePos nearRoads _zoneSize) select 
							{  !((position _x) inArea "opfor_restriction")
								&& ((position _x) distance _pos) < 1600
								&& count ([position _x, _players,400] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _friendlySoldiers,120] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _enemySoldiers,800] call CBA_fnc_getNearest) == 0 };
		};
		case "Tank":{
			_spawnfunc = INS_fnc_spawnTank;
			_spawnlocs =  (_zonePos nearRoads _zoneSize) select 
							{  !((position _x) inArea "opfor_restriction")
								&& ((position _x) distance _pos) < 1600
								&& count ([position _x, _players,500] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _friendlySoldiers,120] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _enemySoldiers,800] call CBA_fnc_getNearest) == 0 };
		};
	};
	
	if ( count _spawnlocs == 0) exitWith { };
	
	private _spawnpos = (selectRandom _spawnlocs) buildingPos 1;
	
	private _leader = [_spawnpos,_side,true] call _spawnfunc;
	if ( side _leader == west ) then {
		(group _leader) setVariable ["Experience", selectRandomWeighted ["MILITIA",0.2,"GREEN",0.5, "VETERAN", 0.3]];
	} else {
		(group _leader) setVariable ["Experience", selectRandomWeighted ["MILITIA",0.1,"GREEN",0.4,"VETERAN",0.7]];
	};
	(group _leader) setVariable ["ai_city", _zoneName, true];
	if ( vehicle _leader == _leader ) then {
		(group _leader) setVariable ["initial_strength", count (units (group _leader))];
	};
	{
		_x setVariable ["ins_side", _side, true];
		_x call RTS_fnc_aiSkill;
	} forEach (units (group _leader));
	
	if ( vehicle _leader != _leader ) then {
		(vehicle _leader) setVariable ["spawned_vehicle", true, true];
	};
	
	(group _leader) deleteGroupWhenEmpty true;
	
	diag_log format ["Spawned %1 units of side %2 at %3 (%4)",count (units (group _leader)),_side,_spawnpos,_zoneName];
	
	[_leader,_spawnpos]
};


// Spawn soldiers within a town
INS_spawnTownGarrison = {
	params ["_zone", "_pos" ];
	if ( ([_zone] call INS_getZoneDensity) < INS_populationDensity ) then {
		diag_log (format ["Can spawn at %1 with soldier density %2", _zone, ([_zone] call INS_getZoneDensity)]);
		private _soldierList = [_pos,_zone] call INS_spawnUnits;
		if ( !isNil "_soldierList" ) then {
			_soldierList params ["_soldier", "_position"];
			private _task = selectRandomWeighted [setupAsGarrison,0.5,setupAsFullGarrison,0.5,setupAsFullGarrison,0.5,setupAsPatrol,0.3];
			private _radius = 75 + (random 50);
			if ( vehicle _soldier != _soldier ) then {
				_task = setupAsPatrol;
				_radius = 400 + (random 250);
			};
			private _group = group _soldier;
			private _zoneAct = [_zone] call INS_getZone;
			private _zoneMarker = _zoneAct select 1;
			(getMarkerSize _zoneMarker) params ["_mx","_my"];
			private _zoneSize = (_mx max _my) * 1.6;
			private _buildings = ( (getMarkerPos _zoneMarker) nearObjects ["HOUSE", _zoneSize] ) 
								select { (count (_x buildingPos -1)) > 2 };
			[_group, getPos (selectRandom _buildings), _radius, _zone] call _task;
			diag_log (format ["Headless client tasking %1 as %2",_group, _group getVariable "ai_status"]);
		};	
	};		
};


// Spawn soldiers attacking a town
INS_spawnPatrol = {
	private _zoneName = _this;
	private _zone = [_zoneName] call INS_getZone;
	private _zoneMark = _zone select 1;
	private _zonePos = getMarkerPos _zoneMark;
	(getMarkerSize _zoneMark) params ["_mx","_my"];
	private _zoneSize = (_mx max _my)*2.7;
	
	private _zoneSide = [[_zone] call INS_zoneDisposition] call INS_greenforDisposition;
	private _sides = [east,west,resistance];
	private _sideList = [];
	{
		private _side = _x;
		if ( _side == west ) then {
			_sideList pushback _side;
			_sideList pushback 0.2;
		} else {
			if ( _side == _zoneSide ) then {
				_sideList pushback _side;
				_sideList pushback 2;
			} else {
				_sideList pushback _side;
				_sideList pushback 0.6;
			};
		};
	} forEach _sides;
	private _side = selectRandomWeighted _sideList;
	diag_log (format ["Attempting to spawn patrol of side %1 at %2", _side, _zoneName]);
	
	private _sqdCt = selectRandomWeighted [1,0.1,2,0.7,3,0.5,4,0.1];
	private _carCt = selectRandomWeighted [0,0.1,1,0.7,2,0.6,3,0.2];
	
	if ( _side == west ) then {
		_sqdCt = 1;
		_carCt = 1;
	};
	
	private _carFunc = selectRandomWeighted [INS_fnc_spawnAPC,1,INS_fnc_spawnTank,0.1];
	
	private _enemySoldiers = allUnits select { side (group _x) != civilian && side (group _x) != _side };
	private _friendlySoldiers = allUnits select { side (group _x) == _side && side (group _x) != civilian };
	private _players = (call INS_allPlayers) select { side (group _x) != _side };
		
	private _targets = ( _players select { side (group _x) != _side && ([getPos _x] call getNearestControlZone) == _zoneName }) + ( ([_zoneName] call getZoneSoldiers) select { side (group _x) != _side } );
	if ( count _targets == 0 ) exitWith {};	
	
	private _didspawn = false;
	
	private _roads = (_zonePos nearRoads _zoneSize);
	for "_i" from 1 to _sqdCt do {
		private _tries = 0;
		private _sqdRoads = _roads select { !(_x inArea "opfor_restriction")
								&& count ([position _x, _players,700] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _players,1600] call CBA_fnc_getNearest) > 0
								&& count ([position _x, _friendlySoldiers,400] call CBA_fnc_getNearest) == 0
								&& count ([position _x, _enemySoldiers,800] call CBA_fnc_getNearest) == 0 };
		
		if ( count _sqdRoads > 0 ) then {
			private _pos = getPos (selectRandom _sqdRoads);
			private _target = leader (group (selectRandom _targets));
			private _leader = [_pos,_side,true] call INS_fnc_spawnSquad;
			private _group = group _leader;
			_group setVariable ["initial_strength", count (units _group)];
			if ( side _leader == west ) then {
				_group setVariable ["Experience", selectRandomWeighted ["MILITIA",0.3,"GREEN",0.6, "VETERAN", 0.3]];
			} else {
				_group setVariable ["Experience", selectRandomWeighted ["MILITIA",0.1,"GREEN",0.7,"VETERAN",0.5]];
			};
			_group setVariable ["ai_city", _zoneName, true];
			_group setVariable ["ai_status", "COUNTER-ATTACK"];
			_group setVariable ["ai_target_group", group _target];
			
			
			{
				_x setVariable ["ins_side", _side, true];
				_x call RTS_fnc_aiSkill;
			} forEach (units _group);
			
			_group setVariable ["ai_dest", getPos _target];
			[_group, getPos _target, 80, _zoneName] call doCounterAttack;
			_didspawn = true;
			diag_log (format ["Spawned patrol of %1 men attacking %2", count (units _group), _target]);
		};
	};
	
	if ( _carCt == 0 && _didSpawn && _side == west ) then {
		[-1,
		{
			params ["_city"];
			if (!hasInterface) exitWith {};
			if ( side (group player) != west ) exitWith {};
			systemChat (format ["HUMINT: Friendly milita operating in the vicinity of %1", _city]);
		},[_zoneName]] call CBA_fnc_globalExecute;
	};
	
	if ( _carCt == 0 ) exitWith {};
	if ( count _roads > 0 ) then {
	
		for "_i" from 1 to _carCt do {
			private _sqdRoads =  _roads select 
								{  !((position _x) inArea "opfor_restriction")
									&& count ([position _x, _players,700] call CBA_fnc_getNearest) == 0
									&& count ([position _x, _players,1600] call CBA_fnc_getNearest) > 0
									&& count ([position _x, _friendlySoldiers,400] call CBA_fnc_getNearest) == 0
									&& count ([position _x, _enemySoldiers,800] call CBA_fnc_getNearest) == 0 };
			if ( count _sqdRoads > 0 ) then {
				private _road = selectRandom _sqdRoads;
			
				private _target = leader (group (selectRandom _targets));
				private _leader = [getPos _road,_side,true] call _carFunc;
				private _group = group _leader;
				(vehicle _leader) setVariable ["spawned_vehicle", true, true];
				if ( side _leader == west ) then {
					_group setVariable ["Experience", selectRandomWeighted ["MILITIA",0.3,"GREEN",0.6, "VETERAN", 0.3]];
				} else {
					_group setVariable ["Experience", selectRandomWeighted ["MILITIA",0.1,"GREEN",0.7,"VETERAN",0.5]];
				};
				_group setVariable ["ai_city", _zoneName, true];
				_group setVariable ["ai_status", "COUNTER-ATTACK"];
				_group setVariable ["ai_target_group", group _target];
				
				{
					_x setVariable ["ins_side", _side, true];
					_x call RTS_fnc_aiSkill;
				} forEach (units _group);
				
				_group setVariable ["ai_dest", getPos _target];
				[_group, getPos _target, 100, _zoneName] call doCounterAttack;
				_didSpawn = true;
				diag_log (format ["Spawned vehicle of type %1 men attacking %2", vehicle _leader, _target]);
			};
		};
	};
	
	if ( _didSpawn && _side == west ) then {
		[-1,
		{
			params ["_city"];
			if (!hasInterface) exitWith {};
			if ( side (group player) != west ) exitWith {};
			systemChat (format ["HUMINT: Friendly milita operating in the vicinity of %1", _city]);
		},[_zoneName]] call CBA_fnc_globalExecute;
	};
	
};


if ( !isServer ) exitWith {};

waitUntil { time > 0 };
waitUntil { INS_setupFinished };

INS_killedHandler = addMissionEventHandler ["EntityKilled", {
	params ["_unit", "_killer", "_instigator", "_useEffects"];
	
	// casualities persist for ~20 minutes
	if ( !(((group _unit) getVariable ["ai_city", objnull]) isEqualTo objnull) && (_unit getVariable ["ins_side", east]) != civilian ) then {
		private _city = (group _unit) getVariable "ai_city";
		private _index = INS_cityCasualtyTracker findIf { (_x # 0) == _city };
		
		// first blood
		if ( _index == -1 ) then {
			INS_cityCasualtyTracker pushback [ _city, 1, time ];
		} else {
			private _cas = INS_cityCasualtyTracker # _index;
			private _time = _cas # 2;
			// reset counter after 2 hours
			if ( time > _time + 7200 ) then {
				_cas set [1, 1];
				_cas set [2, time];
			} else {
				private _ct = _cas # 1;
				_cas set [1, _ct + 1];
				_cas set [2, time];
			};
		};
	};
	
	if ( side _instigator != east && isPlayer _instigator && !(_unit in (call INS_allPlayers)) ) then {
		if ( !(_unit in INS_spies) && ( (_unit getVariable ["ins_side", east]) == east || (_unit getVariable ["ins_side", east]) == resistance ) ) then {
			private _city = (group _unit) getVariable ["ai_city",""];
			if ( _city != "" ) then {
				private _zone = [_city] call INS_getZone;
				private _zoneparams = zone select 2;
				private _disp = _zoneparams select 0;
				_zoneparams set [0, _disp + 0.5];
				publicVariable "INS_controlAreas";
			};
		};
		if ( _unit in INS_spies || (_unit getVariable ["ins_side", east]) == west || (_unit getVariable ["ins_side", east]) == civilian ) then {
			private _city = (group _unit) getVariable ["ai_city",""];
			
			if ( _unit in INS_spies ) then {
				_city = [getPos _unit] call getNearestControlZone;
				if ( isNil "_city" ) then {
					_city = "";
				};
			};
			
			if ( _city != "" ) then {
				private _zone = [_city] call INS_getZone;
				private _zoneparams = _zone select 2;
				private _aggression = _zoneparams select 3;
				private _disp = _zoneparams select 0;
				_zoneparams set [3, _aggression + 10];
				_zoneparams set [0, _disp - 5];
				publicVariable "INS_controlAreas";				
				[-1,
				{
					params ["_city"];
					if ( !hasInterface ) exitWIth {};
					if ( side (group player) != west ) exitWith {};
					sleep 4 + ( floor (random 3) );
					systemChat (format ["HUMINT Reports: Collateral damage has damaged coalition efforts in the town of %1",_city]);
				}, [_city]] call CBA_fnc_globalExecute;
			};
		};
	};
	
}];

addMissionEventHandler ["BuildingChanged", {
	params ["_previousObject", "_newObject", "_isRuin"];
	
	if ( count (_previousObject buildingPos -1) > 2 ) then {
		private _blufor = ( (call INS_allPlayers) select { side _x == west && ( (getPos _x) distance2d (getPos _newObject) ) < 1500 } );
		private _opforPlyr = ( (call INS_allPlayers) select { side _x == east && ( (getPos _x) distance2d (getPos _newObject) ) < 800 } );
		private _opfor = allUnits select { !((group _x) getVariable ["rts_setup",objnull] isEqualTo objnull) && ( (getPos _x) distance2d (getPos _newObject) ) < 800 };
		
		if ( count _blufor > 0 && count (_opforPlyr + _opfor) == 0 ) then {
			
			private _zoneparams = _zone select 2;
			private _aggression = _zoneparams select 3;
			private _disp = _zoneparams select 0;
			if ( _isRuin ) then {
				_zoneparams set [3, _aggression + 15];
				_zoneparams set [0, _disp - 10];
			} else {
				_zoneparams set [3, _aggression + 5];
				_zoneparams set [0, _disp - 5];
			};
			publicVariable "INS_controlAreas";
			
			[-1,
			{
				params ["_city"];
				if ( !hasInterface ) exitWIth {};
				if ( side (group player) != west ) exitWith {};
				sleep 4 + ( floor (random 3) );
				systemChat (format ["HUMINT Reports: Collateral damage has damaged coalition efforts in the town of %1",_city]);
			}, [_zone select 0]] call CBA_fnc_globalExecute;
		};
	};
}];

INS_bluforMission = "NONE";
publicVariable "INS_bluforMission";
INS_previousTaskComplete = 0;
INS_taskZone = "";
INS_currentMission = 0;
INS_truckMarker = createMarker ["ins_truck_marker",[0,0,0]];
INS_truckMarker setMarkerShape "ICON";
INS_truckMarker setMarkerText "AID Vehicle";
INS_truckMarker setMarkerColor "ColorBlue";
INS_truckMarker setMarkerType "select";
INS_truckMarker setMarkerAlpha 0;
publicVariable "INS_truckMarker";
INS_aidMissionLocated = -1;
INS_aidPackageLocated = -1;
INS_aidCrateType = "Land_transport_crates_EP1";
INS_aidCrate = objnull;
INS_currentMissionName = { format ["blufor_task_%1",INS_currentMission] };

INS_missionMonitor = addMissionEventHandler [ "EachFrame",
	{
		if ( INS_bluforMission == "NONE" ) then {
			// Setup aid delivery mission
			
			if ( ( time > (INS_previousTaskComplete + 400) || INS_currentMission == 0 ) && count (call INS_allPlayers) > 0 ) then {
				if ( INS_currentMission > 0 ) then {
					[call INS_currentMissionName,west] call BIS_fnc_deleteTask;
				}; // We'll go ahead and keep a running tally of all missions conducted
				INS_currentMission = INS_currentMission + 1;
				private _truckClass = "rhssaf_un_ural";
				private _zones = INS_controlAreas select { ([_x] call INS_zoneDisposition) > -24 && ([_x] call INS_zoneDisposition) < 51 };
				
				_zones = [ _zones, [], { (getMarkerPos (_x select 1)) distance (getMarkerPos "truck_spawn")}, "ASCEND"] call BIS_fnc_sortBy;
				
				private _threeNearest = [];

				for "_i" from 0 to 2 do {
					if ( (count _zones) > _i ) then {
						_threeNearest pushback (_zones select _i);
					};
				};
				
				private _zone = selectRandom _threeNearest;
				private _name = _zone select 0;
				private _marker = _zone select 1;
				(getMarkerSize _marker) params ["_mx","_my"];
				private _road = selectRandom ((getMarkerPos _marker) nearRoads (_mx max _my));
				private _truckMarkerPos = getMarkerPos "truck_spawn";
				private _truckPos = _truckMarkerPos findEmptyPosition [0,20,_truckClass];
				
				while { ! ( isOnRoad _truckPos ) } do {
					_truckPos = _truckPos findEmptyPosition [0,30,_truckClass];
				};

				INS_taskZone = _name;
				INS_aidTruck = _truckClass createVehicle _truckPos;
				publicVariable "INS_aidTruck";
				INS_bluforMission = "AID";
				publicVariable "INS_bluforMission";
				INS_truckMarker setMarkerPos (getPos INS_aidTruck);
				
				[west, [call INS_currentMissionName], 
					[ 
						format ["<marker name='ins_truck_marker'>Deliver AID</marker> from Coalition airfield to the town of %1<br/><br/>Secure the town before bringing in the supplies.<br/><br/>Once the aid truck reaches the RP, wait for civilians to come begin collecting the supplies.",_name],
						"Deliver AID",
						"aidMarker"],
						getPos _road, 1, 3, true] call BIS_fnc_taskCreate;	
			};
		} else {
			switch ( INS_bluforMission ) do {
				case "AID": {
					INS_truckMarker setMarkerPos (getPos INS_aidTruck);
					if ( INS_aidPackageLocated == -1 && ((getPos INS_aidTruck) distance ((call INS_currentMissionName) call BIS_fnc_taskDestination)) < 75 ) then {
						INS_aidPackageLocated = time;
						
						[-1, 
						{
							if ( !hasInterface ) exitWith {};
							if ( side player == east ) exitWith {};
							titleText ["AID Truck has reached RP", "PLAIN"];
						}] call CBA_fnc_globalExecute;
						
						[] spawn {
							waitUntil { count ([INS_aidTruck, vehicles select { speed _x > 0 && isPlayer (driver _x) && side (driver _x) == west },200] call CBA_fnc_getNearest) == 0 && speed INS_aidTruck == 0 };
							[-1, 
								{
									if ( !hasInterface ) exitWith {};
									if ( side player == east ) exitWith {};
									if ( ((getPos player) distance (getPos INS_aidTruck)) > 200 ) exitWith {};
									titleText ["Unloading AID supplies...", "PLAIN"];
								}] call CBA_fnc_globalExecute;
							
							private _diroffset = (vectorDir INS_aidTruck) vectorMultiply -2;						
							
							private _pos = ((getPos INS_aidTruck) vectorAdd _diroffset) findEmptyPosition [0,15,INS_aidCrateType];
							
							if ( _pos isEqualTo [0,0,0] || _pos isEqualTo [] || _pos isEqualTo [0,0] ) then {
								_pos = ((getPos INS_aidTruck) vectorAdd _diroffset) findEmptyPosition [0,30,INS_aidCrateType];
							};
							
							INS_aidCrate = INS_aidCrateType createVehicle _pos;
							INS_aidCrate setDir (direction INS_aidTruck);
							
							diag_log (format ["Spawned Civilian AID at %1", _pos]);
						};
					} else {
						if ( !isNull INS_aidCrate && INS_aidPackageLocated > 0 && time > ( INS_aidPackageLocated + 5 ) && INS_aidMissionLocated == -1 ) then {
							INS_aidMissionLocated = time;
							private _civvies = [ ([INS_taskZone] call getSpawnedCivilians) select { !(_x getVariable ["aid_tasked", false]) }, [], { (getPos _x) distance (getPos INS_aidTruck) }, "ASCEND"] call BIS_fnc_sortBy;
							private _civamt = floor ( ( 5 + ( random ( (count _civvies) / 2 ) ) ) min (count _civvies) );
							diag_log (format ["Tasking AID COLLECTION to %1 civilians out of %2", _civamt, count _civvies]);
							
							[-1, 
							{
								if ( !hasInterface ) exitWith {};
								if ( side player == east ) exitWith {};
								if ( ((getPos player) distance (getPos INS_aidTruck)) > 200 ) exitWith {};
								titleText ["AID Truck awaiting rendezvous with locals.", "PLAIN"];
							}] call CBA_fnc_globalExecute;
							
							if ( count _civvies >= _civamt ) then {
								for "_i" from 0 to (_civamt-1) do {
									private _civ = _civvies select _i;
									_civ setVariable ["aid_tasked", true];
									[group _civ] call CBA_fnc_clearWaypoints;
									private _pos = ([getPos INS_aidCrate,5] call CBA_fnc_randPos) findEmptyPosition [2,20,"MAN"];
									_civ doMove _pos;
									if ( random 1 > 0.2 ) then {
										(group _civ) setSpeedMode "FULL";
									};
									diag_log (format ["Tasking AID COLLECTION to %1 at position %2", _civ, _pos]);
								};
							};
						} else {
							if ( INS_aidMissionLocated > 0 && 
								( time > (INS_aidMissionLocated + 300) 
									|| count ([INS_aidCrate, allUnits select { (_x getVariable ["aid_tasked",false]) }, 50] call CBA_fnc_getNearest) >= floor ( count (allUnits select { (_x getVariable ["aid_tasked",false]) }) ) / 2 )  ) then {
																
								private _zonearea = [INS_taskZone] call INS_getZone;
								private _marker = _zonearea select 1;
								(getMarkerSize _marker) params ["_mx","_my"];
								private _houses = ((getMarkerPos _marker) nearObjects [ "HOUSE", _mx max _my]) select { (count (_x buildingPos -1) > 2) };
								
								{
									private _civ = _x;
									_civ setVariable ["aid_tasked", nil];
									[group _civ, getPos (selectRandom _houses), 75, INS_taskZone] call setupAsCivilianGarrison;
									(group _civ) setSpeedMode "LIMITED";
									diag_log (format ["De-tasking %1 from aid collection", _civ]);
								} forEach ( allUnits select { side _x == civilian && (_x getVariable ["aid_tasked",false]) } );
								
								deleteVehicle INS_aidCrate;
								INS_taskZone = "";
								INS_previousTaskComplete = time;
								INS_aidTruck setVariable ["spawned_vehicle", true];
								INS_aidCrate = objnull;
								INS_aidTruck = nil;
								INS_bluforMission = "NONE";
								publicVariable "INS_bluforMission";
								
								INS_aidMissionLocated = -1;
								INS_aidPackageLocated = -1;
								
								private _zone = (INS_controlAreas select { (_x select 0) == INS_taskZone }) select 0;
								private _zoneparams = _zone select 2;
								private _disp = _zoneparams select 0;
								_zoneparams set [0, _disp + 35];
								publicVariable "INS_controlAreas";
								
								
								[call INS_currentMissionName,"SUCCEEDED"] call BIS_fnc_taskSetState;
							} else {
								if ( (getDammage INS_aidTruck) > 0.8 ) then {
									INS_aidMissionLocated = -1;
									INS_aidPackageLocated = -1;
									
									private _zonearea = [INS_taskZone] call INS_getZone;
									private _marker = _zonearea select 1;
									(getMarkerSize _marker) params ["_mx","_my"];
									private _houses = ((getMarkerPos _marker) nearObjects [ "HOUSE", _mx max _my]) select { (count (_x buildingPos -1) > 2) };
									
									{
										private _civ = _x;
										_civ setVariable ["aid_tasked", nil];
										[group _civ, getPos (selectRandom _houses), 75, INS_taskZone] call setupAsCivilianGarrison;
										diag_log (format ["De-tasking %1 from aid collection", _civ]);
									} forEach ( allUnits select { side _x == civilian && (_x getVariable ["aid_tasked",false]) } );
									
									deleteVehicle INS_aidCrate;
									INS_taskZone = "";
									INS_previousTaskComplete = time;
									INS_aidTruck setVariable ["spawned_vehicle", true];
									INS_aidCrate = objnull;
									INS_aidTruck = nil;
									INS_bluforMission = "NONE";
									
									private _zone = (INS_controlAreas select { (_x select 0) == INS_taskZone }) select 0;
									private _zoneparams = _zone select 2;
									private _aggr = _zoneparams select 3;
									_zoneparams set [0, _aggr + 5];
									publicVariable "INS_controlAreas";
									
									INS_taskZone = "";
									
									[-1,
									{
										params ["_city"];
										sleep 4;
										titleText [format ["HUMINT indicates scrapped AID efforts have increased anti-coalition senitment in %1",_city],"PLAIN"];
									},[_zone select 0]] call CBA_fnc_globalExecute;
									
									[call INS_currentMissionName,"FAILED"] call BIS_fnc_taskSetState;
								};
							};
						};
					};
				};
			};
		};
		
	}];

// Alert players to the other's activities
INS_sigIntHumInt = [] spawn {
	
	// Sigint reveals opfor activity for blufor
	INS_sigIntTimeout = 240;
	INS_sigIntLast = 0;
	
	// humint will reveal threat levels etc once implemented
	
	
	INS_nearZoneOrNull = {
		params ["_pos"];
		private _zone = [_pos] call getNearestControlZone;
		
		if ( isNil "_zone" ) exitWith {
			objnull
		};
		
		_zone
	};
	
	while { true } do {
		// Sigint
		if ( time > (INS_sigIntLast + INS_sigIntTimeout) ) then {
			INS_sigIntLast = time;
			
			private _opforgroups = allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) };
			private _bluforgroups = allGroups select { (side _x) == west && isPlayer (leader _x) };
			
			private _opforlocations  = _opforgroups  apply { selectRandom (
																			( (units _x) apply { 
																					[getPos _x] call INS_nearZoneOrNull 
																				}
																			 	) select { !(_x isEqualTo objnull) }
																			 ) };
			private _bluforlocations = _bluforgroups apply { selectRandom (((units _x) apply { [getPos _x] call INS_nearZoneOrNull }) select { !(_x isEqualTo objnull) }) };
			
			diag_log (format ["Opfor intel from: %1", _bluforlocations]);
			
			// alert blufor players
			if ( count _opforlocations > 0 ) then {
				private _oploc = selectRandom _opforlocations;
				if ( !isNil "_oploc" ) then {
					if ( !(_oploc isEqualTo objnull)  ) then {
						[-1,
						{
							params ["_city"];
							if (!hasInterface) exitWith {};
							if ( side player != west ) exitWith {};
							systemChat (format ["SIGINT: Insurgent activity in the vicinity of %1", _city]);
						},[_oploc]] call CBA_fnc_globalExecute;					
					};
				};
			};
			
			// alert opfor player
			if ( count _bluforlocations > 0 ) then {
				private _bluloc = selectRandom _bluforlocations;
				
				if ( !isNil "_bluloc" ) then {
					if ( !(_bluloc isEqualTo objnull) ) then {
						[-1,
						{
							params ["_city"];
							if (!hasInterface) exitWith {};
							if ( side player != east ) exitWith {};
							systemChat (format ["SIGINT: Coalition forces are operating near %1", _city]);
						},[_bluloc]] call CBA_fnc_globalExecute;
					};
				};
			};
			
		};
	};

};


INS_capZones = []; // [ [ zone name, side, time ] ]

INS_getCapZone = {
	params ["_name"];
	
	private _capzone = objnull;
	
	for "_i" from 0 to ((count INS_capZones ) - 1) do {
		private _cap = INS_capZones select _i;
		
		if ( (_cap select 0) isEqualTo _name ) exitWith {
			_capzone = _cap
		};
	};
	
	if ( _capzone isEqualTo objnull ) then {
		_capzone = [ _name, civilian, -1 ];
		INS_capZones pushback _capzone;
	};
	
	_capzone	
};

INS_insurgencyZoneCapping = [] spawn {
	while { true } do {
		private _humanPlayers = call INS_allPlayers;
		private _insurgents = ( if ( count ( _humanPlayers select { side _x == west }) > 0 ) then { ( allGroups select { !( (_x getVariable ["rts_setup", objnull]) isEqualTo objnull ) } ) apply { leader _x } } else { [] });
		private _unitSpawners = ( _humanPlayers + _insurgents );
		
		{
			private _zone = _x;
			private _name = _zone select 0;
			private _marker = _zone select 1;
			private _priorColor = markerColor _marker;
			if ( [_zone] call INS_zoneIsGreen ) then {
				_marker setMarkerColor "ColorGreen";
			} else {
				if ( [_zone] call INS_zoneIsOpfor ) then {
					_marker setMarkerColor "ColorRed";
				} else {
					_marker setMarkerColor "ColorBlue";
				};
			};
			private _disp = (_zone select 2) select 0;
			private _agg = (_zone select 2) select 3;
			// cap zone to aggression
			if ( _disp > (100 - _agg) ) then {
				(_zone select 2) set [0, 100 - _agg];
				publicVariable "INS_controlAreas";
			};
			
			// zone has been capped
			if ( _priorColor != (markerColor _marker) ) then {
				[-1,
					{
						params ["_name","_color"];
						if ( !hasInterface ) exitWith {};
						
						switch ( _color ) do {
							case "ColorRed": {
								systemChat (format ["SIGINT: %1 has been captured by Insurgent forces.", _name]);
							};
							case "ColorGreen": {
								systemChat (format ["SIGINT: %1 is now under the control of local militias.", _name]);
							};
							case "ColorBlue": {
								systemChat (format ["SIGINT: %1 has been pacified by Coalition forces.", _name]);
							};
						};
					},[_name,markerColor _marker]] call CBA_fnc_globalExecute;
			};
			
			
			private _capzone = [_name] call INS_getCapZone;
			private _beingCapped = false;
			
			{
				private _unit = _x;
				private _side = side _unit;
				private _otherUnits = allUnits select { side _x != civilian && side _x != _side && (getPos _x) inArea _marker };
				
				// zone is being capped
				if ( count _otherUnits == 0 ) then {
					_beingCapped = true;
					_capzone params ["","_capside","_captime"];
					if ( _capside == _side ) then {
						if ( time > ( _captime + 180 ) ) then {
							diag_log (format ["%1 is being capped by %2", _name, _side]);
							_capzone set [2, time];
							private _zoneparams = _zone select 2;
							
							private _zoneadjustment = 0;
							
							switch ( _side ) do {
								case east: {
									_zoneadjustment = -5;
								};
								case west: {
									_zoneadjustment = 5;
								};
							};
							
							_zoneparams params ["_disp"];
							_zoneparams set [0, ((_disp + _zoneadjustment) min 100) max -100 ];
							publicVariable "INS_controlAreas";
						};
					} else {
						_capzone set [1, _side];
						_capzone set [2, time];
						diag_log (format ["%1 is being capped by %2", _name, _side]);
					};
				};
				
			} forEach ( _unitSpawners select { side _x != civilian && (getPos _x) inArea _marker } );
			
			if ( !_beingCapped ) then {
				_capzone set [1, civilian];
				_capZone set [2, -1];
			};
			
		} forEach INS_controlAreas;
	};
};