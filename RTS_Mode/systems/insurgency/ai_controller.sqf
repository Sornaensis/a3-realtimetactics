
setupAsGarrison = {
	params ["_group", "_marker", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "GARRISON"];
	_group setVariable ["ai_ciy", _city];
	[_group, getMarkerPos _marker, _radius, 2, 0.7, 0.6 ] call CBA_fnc_taskDefend;
};

setupAsPatrol = {
	params ["_group", "_marker", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "PATROL"];
	_group setVariable ["ai_ciy", _city];
	[_group, getMarkerPos _marker, _radius, 7, "MOVE", "SAFE", "RED", "NORMAL"] call CBA_fnc_taskPatrol;
};

doCounterAttack = {
	params ["_group", "_marker", "_radius","_city"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["ai_status", "COUNTER-ATTACK"];
	_group setVariable ["ai_ciy", _city];
	if ( vehicle (leader _group) != leader _group ) then {
		[_group, getMarkerPos _marker, _radius, 7, "MOVE", "COMBAT", "RED", "FULL"] call CBA_fnc_taskPatrol;
	} else {
		[_group, getMarkerPos _marker, _radius] call CBA_fnc_taskAttack;
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

waitUntil { INS_setupFinished };

INS_spawnedGreenfor = []; // greenfor hostile to all sides
INS_spawnedOpfor = [];    
INS_spawnedBlufor = [];   // greenfor hostile to east
INS_spawnedCivilians = [];

INS_spawnedUnitCap = 100; // maximum spawned soldiers
INS_civilianCap = 50;
INS_spawnDist = 800; // distance in meters from buildings a player shall be when we begin spawning units.
INS_despawn = 1200; // despawn units
INS_spawnPulse = 60; // seconds to pulse spawns
INS_initialSquads = 3; // spawn this many squads
INS_populationDensity = 15; // 15 men per square kilometer
							// units from adjacent control zones may assist one another
							// spontaneous reinforcing is also a possibility



getSpawnedSoldierCount = {
	(count INS_spawnedGreenfor) + (count INS_spawnedOpfor) + (count INS_spawnedBlufor)
};

INS_aiSpawner = addMissionEventHandler [ "EachFrame",
	{
		private _headlessClients = entities "HeadlessClient_F";
		private _humanPlayers = allPlayers - _headlessClients;
		// Spawn AI due to blufor player activity
		if ( (call getSpawnedSoldierCount) < INS_spawnedUnitCap ) then {
			{
				private _player = _x;
				private _zone = [getPos _player] call getNearestControlZone;
				
				if ( !isNil "_zone" ) then {
					
				};
			} forEach (_humanPlayers select { side _x == east });
		};
	}];