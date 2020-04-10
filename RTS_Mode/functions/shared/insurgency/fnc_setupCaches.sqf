_cities = (nearestLocations [ getMarkerPos "map_center", ["NameCityCapital","NameCity","NameVillage"], 13000]) select { (position _x) inArea "opfor_ao" };

_targetcities = nearestLocations [ position (_cities call BIS_fnc_selectRandom), ["NameCityCapital","NameCity","NameVillage"], 4500 ]  select { (position _x) inArea "opfor_ao" };

// CACHE 1
_cachecity = _targetcities call BIS_fnc_selectRandom;

INS_cacheMarker1 = [format ["__cache___%1-%2", text _cachecity,time], [position _cachecity, 125] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", format ["Destroy Cache Near %1", text _cachecity], "PERSIST"] call CBA_fnc_createMarker;

// Spawn Cache
_buildings1 = nearestObjects [ position _cachecity, ["House"], 3000] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 };
_buildingPos = ([_buildings1 call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom;
INS_cache1 = "CUP_GuerillaCacheBox" createVehicle [0,0,0];
INS_cache1 setPosATL _buildingPos;

// CACHE 2
_cities = (nearestLocations [ getMarkerPos "map_center", ["NameCityCapital","NameCity","NameVillage"], 13000]) select { (position _x) inArea "opfor_ao"};

_targetcities = nearestLocations [ position (_cities call BIS_fnc_selectRandom), ["NameCityCapital","NameCity","NameVillage"], 4500 ]  select { (position _x) inArea "opfor_ao" && (([position _x,getPosATL INS_cache1] call CBA_fnc_getDistance) > 1000 ) };
_cachecity = _targetcities call BIS_fnc_selectRandom;

INS_cacheMarker2 = [format ["__cache___%1-%2", text _cachecity,time], [position _cachecity, 125] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", format ["Destroy Cache Near %1", text _cachecity], "PERSIST"] call CBA_fnc_createMarker;
INS_cacheMarker2 setMarkerAlpha 0;

// Spawn Cache
_buildings = nearestObjects [ position _cachecity, ["House"], 3000] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 };
_buildingPos = ([_buildings call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom;
INS_cache2 = "CUP_GuerillaCacheBox" createVehicle [0,0,0];
INS_cache2 setPosATL _buildingPos;

INS_cache1 addEventHandler [ "killed", 
{ 
	INS_caches = INS_caches - 1; 
	publicVariable "INS_caches";
	INS_cacheMarker1 setMarkerAlpha 0;
	INS_cacheMarker2 setMarkerAlpha 1;
	_distance = 925 - (INS_intelLevel*25);
	_markername = format ["__cache___marker_intel_%1-%2", _distance, INS_caches + 1];
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

[position INS_cache1] call INS_fnc_spawnStartingUnits;