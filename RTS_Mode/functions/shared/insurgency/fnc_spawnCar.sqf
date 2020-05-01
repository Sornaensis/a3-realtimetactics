params ["_pos","_side"];

private _nosetup = false;

if ( isNil "_side" ) then {
	_side = east;
} else {
	_nosetup = true;
};

private _soldier = [_pos,nil,_side] call INS_fnc_spawnRandomSoldier;

private _type = (INS_carClasses call BIS_fnc_selectRandom);
private _carpos = (_pos findEmptyPosition [0,50,_type]);
private _car = _type createVehicle _carpos;
_car setVectorUp (surfaceNormal _carpos);

private _grp = group _soldier;
[units _grp] allowGetIn true;
_soldier assignAsDriver _car;
_soldier moveInDriver _car;	

if ( !_nosetup ) then {
	_grp setVariable ["RTS_setup", [_grp, getText (configFile >> "CfgVehicles" >> _type >> "displayName"), grpnull, "\A3\ui_f\data\map\markers\nato\o_motor_inf.paa", "o_motor_inf"],true];
};

_soldier