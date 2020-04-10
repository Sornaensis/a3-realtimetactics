_cities = (nearestLocations [ getMarkerPos "map_center", ["NameCityCapital","NameCity","NameVillage"], 13000]) select { (position _x) inArea "opfor_ao" };

_targetcities = nearestLocations [ position (_cities call BIS_fnc_selectRandom), ["NameCityCapital","NameCity","NameVillage"], 4500 ]  select { (position _x) inArea "opfor_ao" };

_city = _targetcities call BIS_fnc_selectRandom;

_buildings1 = nearestObjects [ position _city, ["House"], 1100];

private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
private _road = (_pos nearRoads 600) call BIS_fnc_selectRandom;
if !(isNil "_road") then {
	[0,{ [_this] call INS_fnc_spawnLeader;
		 [_this] call INS_fnc_spawnCar; }, getPosATL _road] call CBA_fnc_globalExecute;
};

_group2 = (random [INS_groupChanceMin, INS_groupChanceMid, INS_groupChanceMax]) > 0.5;
_apc = (random [INS_apcChanceMin, INS_apcChanceMid, INS_apcChanceMax]) > 0.5;
_tank = (random [INS_tankChanceMin, INS_tankChanceMid, INS_tankChanceMax]) > 0.5;

if _apc then {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	private _road = (_pos nearRoads 600) call BIS_fnc_selectRandom;
	if !(isNil "_road") then {
		[0,{ [_this] call INS_fnc_spawnAPC }, getPosATL _road] call CBA_fnc_globalExecute;
	};
};

if _tank then {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	private _road = (_pos nearRoads 600) call BIS_fnc_selectRandom;
	if !(isNil "_road") then {
		[0,{ [_this] call INS_fnc_spawnTank }, getPosATL _road] call CBA_fnc_globalExecute;
	};
};

if _group2 then  {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	private _road = (_pos nearRoads 600) call BIS_fnc_selectRandom;
	if !(isNil "_road") then {
		[0,{ [_this] call INS_fnc_spawnLeader;
			 [_this] call INS_fnc_spawnCar }, getPosATL _road] call CBA_fnc_globalExecute;
	};
};

[] call RTS_fnc_setupAllGroups;