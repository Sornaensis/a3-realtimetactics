params ["_pos","_side"];

private _nosetup = false;

if ( isNil "_side" ) then {
	_side = east;
} else {
	_nosetup = true;
};

private _radius = 150;
private _players = (call INS_allPlayers) select { side _x != _side };
while { !(isOnRoad _pos) || count ([_pos, _players,350] call CBA_fnc_getNearest) > 0 } do {
	private _roads = _pos nearRoads _radius;
	if ( count _roads > 0 ) then {
		_pos = (getPos (selectRandom _roads));
	} else {
		_radius = _radius + 50;
	};
};

_soldier = [_pos,nil,_side] call INS_fnc_spawnRandomSoldier;
_gunner = [_pos,group _soldier] call INS_fnc_spawnRandomSoldier;
_cmdr = [_pos,group _soldier] call INS_fnc_spawnRandomSoldier;

_type = (INS_tankClasses call BIS_fnc_selectRandom);
_carpos = (_pos findEmptyPosition [0,20,_type]);
_car = _type createVehicle _carpos;
_car setVectorUp (surfaceNormal _carpos);

_grp = group _soldier;
[units _grp] allowGetIn true;
_soldier assignAsDriver _car;
_soldier moveInDriver _car;

_cmdr assignAsCommander _car;
_cmdr moveInCommander _car;

_gunner assignAsGunner _car;
_gunner moveInGunner _car;

if ( !_nosetup ) then {
	_grp setVariable ["RTS_setup", [_grp, getText (configFile >> "CfgVehicles" >> _type >> "displayName"), grpnull, "\A3\ui_f\data\map\markers\nato\o_armor.paa", "o_armor"],true];
};

_soldier