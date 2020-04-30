private _cities = (nearestLocations [ getMarkerPos "map_center", ["NameCityCapital","NameCity","NameVillage"], 13000]) select { !((position _x) inArea "opfor_restriction") };

private _targetcities = (nearestLocations [ position (_cities call BIS_fnc_selectRandom), ["NameCityCapital","NameCity","NameVillage"], 4500 ]) select { !((position _x) inArea "opfor_restriction") };

// CACHE 1
private _cachecity = _targetcities call BIS_fnc_selectRandom;

INS_cacheMarker1 = [format ["__cache___%1-%2", text _cachecity,time], [position _cachecity, 125] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", format ["Destroy Cache Near %1", text _cachecity], "PERSIST"] call CBA_fnc_createMarker;

// Spawn Cache
private _buildings1 = (nearestObjects [ position _cachecity, ["House"], 3000] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 }) select { !((position _x) inArea "opfor_restriction") };
private _buildingPos = ([_buildings1 call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom;
INS_cache1 = "CUP_GuerillaCacheBox" createVehicle [0,0,0];
INS_cache1 setPosATL _buildingPos;

// CACHE 2
private _cities = (nearestLocations [ getMarkerPos "map_center", ["NameCityCapital","NameCity","NameVillage"], 13000]) select { !((position _x) inArea "opfor_restriction") };

private _targetcities = (nearestLocations [ position (_cities call BIS_fnc_selectRandom), ["NameCityCapital","NameCity","NameVillage"], 4500 ]  select { !((position _x) inArea "opfor_restriction") && (([position _x,getPosATL INS_cache1] call CBA_fnc_getDistance) > 1000 ) });
private _cachecity = _targetcities call BIS_fnc_selectRandom;

INS_cacheMarker2 = [format ["__cache___%1-%2", text _cachecity,time], [position _cachecity, 125] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", format ["Destroy Cache Near %1", text _cachecity], "PERSIST"] call CBA_fnc_createMarker;
INS_cacheMarker2 setMarkerAlpha 0;

// Spawn Cache
private _buildings = (nearestObjects [ position _cachecity, ["House"], 3000] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 }) select { !((position _x) inArea "opfor_restriction") };
private _buildingPos = ([_buildings call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom;
INS_cache2 = "CUP_GuerillaCacheBox" createVehicle [0,0,0];
INS_cache2 setPosATL _buildingPos;

INS_cache1 addEventHandler [ "killed", 
{ 
	INS_caches = INS_caches - 1; 
	publicVariable "INS_caches";
	INS_cacheMarker1 setMarkerAlpha 0;
	INS_cacheMarker2 setMarkerAlpha 1;
	private _distance = 925 - (INS_intelLevel*25);
	private _markername = format ["__cache___marker_intel_%1-%2", _distance, INS_caches + 1];
	while { ! ( (((getMarkerPos _markername) select 0) == 0 )
				&& (((getMarkerPos _markername) select 1) == 0 )
				&& (((getMarkerPos _markername) select 2) == 0 ) ) } do {
		deleteMarker _markername;
		INS_intelLevel = INS_intelLevel - 1;
		_distance = 925 - (INS_intelLevel*25);
		_markername = format ["__cache___marker_intel_%1-%2", _distance, INS_caches + 1];
	};
	[position INS_cache2] call INS_fnc_spawnStartingUnits;
	[-1, 
		{
			if ( player == opforCommander ) then {
				[] call RTS_fnc_setupAllGroups;
			};
		}] call CBA_fnc_globalExecute;
}];
INS_cache2 addEventHandler [ "killed", 
{ 
	INS_caches = INS_caches - 1; 
	publicVariable "INS_caches";
}];

private _camPos = [getPos INS_cache1,200] call CBA_fnc_randPos;

while { (_camPos distance (getPos INS_cache1)) < 100 } do {
	_camPos = [getPos INS_cache1,300] call CBA_fnc_randPos;
};

RTS_camTarget setMarkerPos (getPos INS_cache1);
RTS_camStart setMarkerPos _camPos;

private _commandbuildings = _buildings1 select { ((position _x) distance (position INS_cache1)) > 100 };

opforCommander setPosATL ( ([_commandbuildings call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom );

[position INS_cache1] call INS_fnc_spawnStartingUnits;