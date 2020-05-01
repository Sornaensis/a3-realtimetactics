params ["_pos","_side"];

private _nosetup = false;

if ( isNil "_side" ) then {
	_side = east;
} else {
	_nosetup = true;
};

_soldier = [_pos,nil,_side] call INS_fnc_spawnRandomSoldier;
_gunner = [_pos,group _soldier] call INS_fnc_spawnRandomSoldier;

_type = (INS_apcClasses call BIS_fnc_selectRandom);
_carpos = (_pos findEmptyPosition [0,20,_type]);
_car = _type createVehicle _carpos;
_car setVectorUp (surfaceNormal _carpos);

_grp = group _soldier;
[units _grp] allowGetIn true;
_soldier assignAsDriver _car;
_soldier moveInDriver _car;

_gunner assignAsGunner _car;
_gunner moveInGunner _car;

if ( !_nosetup ) then {
	_grp setVariable ["RTS_setup", [_grp, getText (configFile >> "CfgVehicles" >> _type >> "displayName"), grpnull, "\A3\ui_f\data\map\markers\nato\o_mech_inf.paa", "o_mech_inf"],true];
};

_soldier