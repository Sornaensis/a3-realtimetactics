INS_spawnedUnitCap = 110; // maximum spawned soldiers
INS_civilianCap = 50;
INS_spawnDist = 800; // distance in meters from buildings a player shall be when we begin spawning units.
INS_despawn = 1200; // despawn units this distance from players when they cannot be seen and their zone is inactive
INS_spawnPulse = 4; // seconds to pulse spawns
INS_initialSquads = 3; // spawn this many squads
INS_civilianDensity = 8;
INS_populationDensity = 17; 


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
				_retSide = selectRandomWeighted [east,1,resistance,0.05];
			} else {
				if ( _zoneDisp <= 0 ) then {
					_retSide = selectRandomWeighted [resistance,1,west,0.05];	
				} else {
					if ( _zoneDisp <= 24 ) then {
						_retSide = selectRandomWeighted [resistance,1,west,0.1];
					} else {
						if ( _zoneDisp < 51 ) then {
							_retSide = selectRandomWeighted [resistance,0.1,west,1];
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
	
	private _population = count ( (allUnits + allDeadMen) select { ((getPos _x) distance (getMarkerPos _marker)) < ((_mx max _my)*1.3) && !isPlayer _x && (_x getVariable ["ins_side",east]) == civilian } );
	private _nominalPop = count ((allUnits + allDeadMen) select { !isPlayer _x && (_x getVariable ["ins_side",east]) == civilian && ((group _x) getVariable ["ai_city",""]) == _zoneName });
	
	(_population max _nominalPop)/(_size/1000/1000)
	
};

INS_getZoneDensity = {
	params ["_zoneName"];
	
	private _location = [_zoneName] call INS_getZone;
	private _marker = _location select 1;
	(getMarkerSize _marker) params ["_mx","_my"];
	
	private _size = (_mx max _my) * 1.8;
	_size = _size*_size; // sq m
	
	private _population = count ((allUnits + allDeadMen) select { ((getPos _x) distance (getMarkerPos _marker)) < ((_mx max _my)*1.3) && !isPlayer _x && (_x getVariable ["ins_side",east]) != civilian });
	private _nominalPop = count ((allUnits + allDeadMen) select { !isPlayer _x && (_x getVariable ["ins_side",east]) != civilian && ((group _x) getVariable ["ai_city",""]) == _zoneName });
	
	(_population max _nominalPop)/(_size/1000/1000)
	
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
	
	(getMarkerPos (_zone select 1)) params ["_mx","_my"];
	private _zoneSize = (_mx max _my)*1.8;
	
	private _buildings = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select { (count (_x buildingPos -1) > 2) && ((position _x) distance _pos) < 1400 };
	
	if ( count _buildings == 0) exitWith { };
	
	_pos = (getPos (selectRandom _buildings));
	
	private _spawnfunc = selectRandomWeighted ["Civ",1,"Car",0.01];
	
	private _leader = objnull;
	
	if ( _spawnfunc == "Civ" ) then {
		_leader = [_pos,createGroup civilian] call INS_fnc_spawnRandomSoldier;
	} else {
		_leader = [_pos,civilian] call INS_fnc_spawnCar;
	};
	
	(group _leader) setVariable ["ai_city", _zoneName, true];
	
	{
		_x setVariable ["ins_side", civilian, true];
	} forEach (units (group _leader));
	
	if ( vehicle _leader != _leader ) then {
		(vehicle _leader) setVariable ["spawned_vehicle", true];
	};
	
	diag_log format ["Spawned %1 civilian at %2 (%3)",count (units (group _leader)),_pos,_zoneName];
	
	[_leader,_pos]
};

INS_spawnUnits = {
	params ["_pos","_zoneName"];
	
	private _zone = [_zoneName] call INS_getZone;
	
	private _zoneMarker = (_zone select 1);
	private _zonePos = getMarkerPos _zoneMarker;
	
	(getMarkerPos _zoneMarker) params ["_mx","_my"];
	private _zoneSize = (_mx max _my) * 1.8;
	
	private _side = [[_zone] call INS_zoneDisposition] call INS_greenforDisposition;
	
	private _buildings = (_zonePos nearObjects [ "HOUSE", _zoneSize ]) select 
							{ (count (_x buildingPos -1) > 2) 
								&& ((position _x) distance _pos) < 1400
								&& ([position _x] call getNearestControlZone) isEqualType ""
								//&& (position _x) inArea _zoneMarker
								&& count ([_spawnpos, call INS_allPlayers,500] call CBA_fnc_getNearest) == 0
								&& count ([position _x, ([_zoneName] call getZoneSoldiers) select { (_x getVariable ["ins_side",east]) != _side },650] call CBA_fnc_getNearest) == 0 };
	if ( count _buildings == 0) exitWith { };
	
	_pos = getPos (selectRandom _buildings);
	
	private _spawnfunc = selectRandomWeighted [INS_fnc_spawnSquad,0.9,INS_fnc_spawnAPC,0.05,INC_fnc_spawnTank,0.005];

	private _spawnpos = ([_pos, 75] call CBA_fnc_randPos) findEmptyPosition [0,20,"MAN"];
	
	if (  _spawnpos isEqualTo [0,0,0] || _spawnpos isEqualTo []
	   || count ([_spawnpos, call INS_allPlayers,500] call CBA_fnc_getNearest) > 0 
	   || count ([_spawnpos, ([_zoneName] call getZoneSoldiers) select { (_x getVariable ["ins_side",east]) != _side },650] call CBA_fnc_getNearest) > 0 ) exitWith {  };
	
	private _leader = [_spawnpos,_side] call _spawnfunc;
	if ( side _leader == west ) then {
		(group _leader) setVariable ["Experience", selectRandomWeighted ["MILITIA",0.7,"GREEN",0.4], true];
	} else {
		(group _leader) setVariable ["Experience", selectRandomWeighted ["MILITIA",0.3,"GREEN",0.7,"VETERAN",0.4,"ELITE",0.01], true];
	};
	(group _leader) setVariable ["ai_city", _zoneName, true];
	
	{
		_x setVariable ["ins_side", _side, true];
	} forEach (units (group _leader));
	
	if ( vehicle _leader != _leader ) then {
		(vehicle _leader) setVariable ["spawned_vehicle", true];
	};
	
	diag_log format ["Spawned %1 units of side %2 at %3 (%4)",count (units (group _leader)),_side,_spawnpos,_zoneName];
	
	[_leader,_pos]
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
			private _blufor = ( (call INS_allPlayers) select { side _x == west } ) apply { [getPos _x] call getNearestControlZone };
			
			if ( (_zone select 0) in _blufor ) then {
				
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
				}, [_zone select 0]] call CBA_fnc_globalExecute;
			};
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
								_zoneparams set [0, _disp + 15];
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
							titleText [ format ["SIGINT: Insurgent activity in the vicinity of %1", _city], "PLAIN" ];
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
							titleText [ format ["SIGINT: Coalition forces are operating near %1", _city], "PLAIN" ];
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
								titleText [ format ["SIGINT: %1 has been captured by Insurgent forces.", _name], "PLAIN"];
							};
							case "ColorGreen": {
								titleText [ format ["SIGINT: %1 is now under the control of local militias.", _name], "PLAIN"];
							};
							case "ColorBlue": {
								titleText [ format ["SIGINT: %1 has been pacified by Coalition forces.", _name], "PLAIN"];
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