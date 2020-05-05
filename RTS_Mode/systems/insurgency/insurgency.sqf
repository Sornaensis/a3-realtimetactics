INS_spawnedUnitCap = 100; // maximum spawned soldiers
INS_civilianCap = 50;
INS_spawnDist = 800; // distance in meters from buildings a player shall be when we begin spawning units.
INS_despawn = 1200; // despawn units this distance from players when they cannot be seen and their zone is inactive
INS_spawnPulse = 10; // seconds to pulse spawns
INS_initialSquads = 3; // spawn this many squads
INS_civilianDensity = 10;
INS_populationDensity = 24; 


INS_aiSpawnTable = []; //  [  [ name, timestamp ] ]
INS_civSpawnTable = [];

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
	(allUnits + allDeadMen) select { !(((group _x) getVariable ["ai_city",objnull]) isEqualTo objnull) && (_x getVariable ["ins_side",east]) != civilian }
};

getSpawnedCiviliansCount = {
	count (call getSpawnedCivilians)
};

getSpawnedCivilians = {
	(allUnits + allDeadMen) select { !(((group _x) getVariable ["ai_city",objnull]) isEqualTo objnull) && (_x getVariable ["ins_side",east]) == civilian }
};

getZoneSoldiers = {
	params ["_zoneName"];
	
	(call getSpawnedSoldiers) select { ((group _x) getVariable ["ai_city",""]) == _zoneName}
};

getZoneGroups = {
	params ["_zoneName"];
	
	allGroups select { (_x getVariable ["ai_city",""]) == _zoneName}
};

INS_getZoneCivilianDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size; // sq m
	
	private _population = count ( (allUnits + allDeadMen) select { ((getPos _x) distance (getMarkerPos _marker)) < ((_mx max _my)*1.8) && !isPlayer _x && (_x getVariable ["ins_side",east]) == civilian } );
	
	(_population)/(_size/1000/1000)
	
};

INS_getZoneDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size; // sq m
	
	private _population = count ((allUnits + allDeadMen) select { ((getPos _x) distance (getMarkerPos _marker)) < ((_mx max _my)*1.8) && !isPlayer _x && (_x getVariable ["ins_side",east]) != civilian });
	
	(_population)/(_size/1000/1000)
	
};

INS_canZoneSpawnCiviliansAndUpdate = {
	params ["_zoneName"];
	
	private _canSpawn = true;
	private _zones = INS_civSpawnTable select { (_x select 0) == _zoneName };
	
	if ( count _zones == 0 ) then {
		INS_civSpawnTable pushback [ _zoneName, time ];
	} else {
		private _zone = _zones select 0;
		
		if ( time > ( (_zone select 1) + (INS_spawnPulse/2) ) ) then {
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

INS_spawnCivilian = {
	params ["_pos","_zoneName"];
	
	private _zone = [_zoneName] call INS_getZone;
	
	private _zonePos = getMarkerPos (_zone select 1);
	
	(getMarkerPos (_zone select 1)) params ["_mx","_my"];
	private _zoneSize = (_mx max _my);
	
	private _buildings = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select { ((position _x) inArea (_zone select 1)) && (count (_x buildingPos -1) > 2) && ((position _x) distance _pos) < 1400 };
	
	if ( count _buildings == 0) exitWith { objnull };
	
	private _pos = (getPos (selectRandom _buildings));
	
	private _spawnfunc = selectRandomWeighted ["Civ",0.9,"Car",0.1];
	
	private _leader = objnull;
	
	if ( _spawnfunc == "Civ" ) then {
		_leader = [_pos,createGroup civilian] call INS_fnc_spawnRandomSoldier;
	} else {
		_leader = [_pos,civilian] call INS_fnc_spawnCar;
	};
	
	(group _leader) setVariable ["ai_city", _zoneName];
	
	{
		_x setVariable ["ins_side", civilian];
	} forEach (units (group _leader));
	
	if ( vehicle _leader != _leader ) then {
		(vehicle _leader) setVariable ["spawned_vehicle", true];
	};
	
	_leader
};

INS_spawnUnits = {
	params ["_pos","_zoneName"];
	
	private _zone = [_zoneName] call INS_getZone;
	
	private _zonePos = getMarkerPos (_zone select 1);
	
	(getMarkerPos (_zone select 1)) params ["_mx","_my"];
	private _zoneSize = (_mx max _my) * 1.2;
	
	private _side = [[_zone] call INS_zoneDisposition] call INS_greenforDisposition;
	
	private _buildings = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select { (count (_x buildingPos -1) > 2) && ((position _x) distance _pos) < 1400 };
	_buildings = _buildings select { count ([position _x, call INS_allPlayers,300] call CBA_fnc_getNearest) == 0 };
	if ( count _buildings == 0) exitWith { objnull };
	
	private _pos = getPos (selectRandom _buildings);
	private _tries = 0;
	
	while { _tries < 5 && count ([_pos, ([_zoneName] call getZoneSoldiers) select { side _x != _side },400] call CBA_fnc_getNearest) > 0 } do {
		_pos = getPos (selectRandom _buildings);
		_tries = _tries + 1;
	};
	
	if ( count ([_pos, ([_zoneName] call getZoneSoldiers) select { side _x != _side },400] call CBA_fnc_getNearest) > 0 ) exitWith { objnull };
	
	private _spawnfunc = selectRandomWeighted [INS_fnc_spawnSquad,0.9,INS_fnc_spawnAPC,0.05,INC_fnc_spawnTank,0.001];
	
	private _leader = [_pos,_side] call _spawnfunc;
	(group _leader) setVariable ["ai_city", _zoneName];
	
	{
		_x setVariable ["ins_side", _side];
		_x call RTS_fnc_aiSkill;
	} forEach (units (group _leader));
	
	if ( vehicle _leader != _leader ) then {
		(vehicle _leader) setVariable ["spawned_vehicle", true];
	};
	
	_leader
};


waitUntil { time > 0 };
waitUntil { INS_setupFinished };

INS_killedHandler = addMissionEventHandler ["EntityKilled", {
	params ["_unit", "_killer", "_instigator", "_useEffects"];
	
	if ( side _instigator == west && isPlayer _instigator && !(isPlayer _unit) ) then {
		if ( (_unit getVariable ["ins_side", east]) == east || (_unit getVariable ["ins_side", east]) == resistance ) then {
			private _city = (group _unit) getVariable ["ai_city",""];
			if ( _city != "" ) then {
				private _zone = [_city] call INS_getZone;
				private _zoneparams = zone select 2;
				private _disp = _zoneparams select 0;
				_zoneparams set [0, _disp + 0.5];
				publicVariable "INS_controlAreas";
			};
		};
		if ( (_unit getVariable ["ins_side", east]) == west || (_unit getVariable ["ins_side", east]) == civilian ) then {
			private _city = (group _unit) getVariable ["ai_city",""];
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
					sleep 4;
					titleText [format ["HUMINT Reports: Collateral damage has damaged coalition efforts in the town of %1",_city], "PLAIN"];
				}, [_city]] call CBA_fnc_globalExecute;
			};
		};
	};
	
}];

addMissionEventHandler ["BuildingChanged", {
	params ["_previousObject", "_newObject", "_isRuin"];
	
	if ( _isRuin ) then {
		private _zones = INS_controlAreas select { (position _newObject) inArea (_x select 1) };
		
		if ( count _zones > 0 && count (_previousObject buildingPos -1) > 2 ) then {
			private _zone = _zones select 0;
			private _zoneparams = _zone select 2;
			private _aggression = _zoneparams select 3;
			private _disp = _zoneparams select 0;
			_zoneparams set [3, _aggression + 5];
			_zoneparams set [0, _disp - 5];
			publicVariable "INS_controlAreas";
			
			[-1,
			{
				params ["_city"];
				sleep 4;
				titleText [format ["HUMINT Reports: Collateral damage has damaged coalition efforts in the town of %1",_city], "PLAIN"];
			}, [_city]] call CBA_fnc_globalExecute;
		};
	};
}];

INS_bluforMission = "NONE";
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
INS_currentMissionName = { format ["blufor_task_%1",INS_currentMission] };

INS_missionMonitor = addMissionEventHandler [ "EachFrame",
	{
		if ( INS_bluforMission == "NONE" ) then {
			// Setup aid delivery mission
			
			if ( ( time > (INS_previousTaskComplete + 180) || INS_currentMission == 0 ) && count (call INS_allPlayers) > 0 ) then {
				/*if ( INS_currentMission > 0 ) then {
					[call INS_currentMissionName,west] call BIS_fnc_deleteTask;
				};*/ // We'll go ahead and keep a running tally of all missions conducted
				INS_currentMission = INS_currentMission + 1;
				private _truckClass = "rhssaf_un_ural";
				private _zones = INS_controlAreas select { ([_x] call INS_zoneDisposition) > -24 };
				
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
				INS_bluforMission = "AID";
				INS_truckMarker setMarkerPos (getPos INS_aidTruck);
				INS_truckMarker setMarkerAlpha 1;
				
				[west, [call INS_currentMissionName], 
					[ 
						format ["<marker name='ins_truck_marker'>Deliver AID</marker> from Coalition airfield to the town of %1",_name],
						"Deliver AID",
						"aidMarker"],
						getPos _road, 1, 3, true] call BIS_fnc_taskCreate;	
			};
		} else {
			switch ( INS_bluforMission ) do {
				case "AID": {
					INS_truckMarker setMarkerPos (getPos INS_aidTruck);
					if ( ((getPos INS_aidTruck) distance ((call INS_currentMissionName) call BIS_fnc_taskDestination)) < 50 ) then {
						INS_previousTaskComplete = time;
						INS_truckMarker setMarkerAlpha 0;
						INS_aidTruck setVariable ["spawned_vehicle", true];
						INS_aidTruck = nil;
						INS_bluforMission = "NONE";
						
						private _zone = (INS_controlAreas select { (_x select 0) == INS_taskZone }) select 0;
						private _zoneparams = _zone select 2;
						private _disp = _zoneparams select 0;
						_zoneparams set [0, _disp + 15];
						publicVariable "INS_controlAreas";
						
						[call INS_currentMissionName,"SUCCEEDED"] call BIS_fnc_taskSetState;
					} else {
						if ( (getDammage INS_aidTruck) > 0.8 ) then {
							INS_previousTaskComplete = time;
							INS_truckMarker setMarkerAlpha 0;
							INS_aidTruck setVariable ["spawned_vehicle", true];
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
			private _disp = (_zone select 2) select 0;
			private _agg = (_zone select 2) select 3;
			// cap zone to aggression
			if ( _disp > (100 - _agg) ) then {
				(_zone select 2) set [0, 100 - _agg];
				publicVariable "INS_controlAreas";
			};
		} forEach INS_controlAreas;
	}];