params ["_locpos"];

private _buildings1 = [];
if ( !isNil "_locpos" ) then {
	_buildings1 = nearestObjects [ _locpos, ["House"], 1100] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 };
} else {
	{
		private _loc = _x;
		_loc params ["_name","_marker"];
		(getMarkerSize _marker) params ["_mx","_my"];
		{
			_buildings1 pushbackUnique _x;
		} forEach (nearestObjects [ getMarkerPos _marker, ["House"], _mx max _my] select { ((position _x) inArea _marker) && ( count ([_x] call BIS_fnc_buildingPositions)) > 0 });
	} forEach (INS_controlAreas select { ((_x select 2) select 0) < -24 });
};

_tankcount = floor (random [INS_tankMin, INS_tankMid, INS_tankMax]);
_apccount = floor (random [INS_apcMin, INS_apcMid, INS_apcMax]);
_carcount = floor (random [INS_carMin, INS_carMid, INS_carMax]);

for "_i" from 1 to _apccount do {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	private _road = (_pos nearRoads 800) call BIS_fnc_selectRandom;
	[getPosATL _road] call INS_fnc_spawnAPC;
};

for "_i" from 1 to _tankcount do {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	private _road = (_pos nearRoads 800) call BIS_fnc_selectRandom;
	[getPosATL _road] call INS_fnc_spawnTank;
};

for "_i" from 1 to _carcount do {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	private _road = (_pos nearRoads 800) call BIS_fnc_selectRandom;
	[getPosATL _road] call INS_fnc_spawnCar;
};


// Spawn Units

_squadcount = floor (random [INS_squadMin, INS_squadMid, INS_squadMax]);
_mgcount = floor (random [INS_mgMin, INS_mgMid, INS_mgMax]);
_snipercount = floor (random [INS_sniperMin, INS_sniperMid, INS_sniperMax]);
_spycount = floor (random [INS_spyMin, INS_spyMid, INS_spyMax]);

for "_i" from 1 to _squadcount do {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	[_pos] call INS_fnc_spawnSquad;
};

for "_i" from 1 to _mgcount do {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	[_pos] call INS_fnc_spawnMG;
};

for "_i" from 1 to _snipercount do {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	[_pos] call INS_fnc_spawnMG;
};

for "_i" from 1 to _spycount do {
	private _pos = (getPosATL (_buildings1 call BIS_fnc_selectRandom)) findEmptyPosition [0,50,"MAN"];
	[_pos] call INS_fnc_spawnSpy;
};