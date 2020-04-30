params ["_locpos"];
// Spawn tank, apc, car
_buildings1 = nearestObjects [ _locpos, ["House"], 1100] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 };

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