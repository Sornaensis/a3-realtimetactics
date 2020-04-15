params ["_group", "_pos"];

private _commands = _group getVariable ["commands", []];

private _leader = leader _group;
private _veh = vehicle _leader;
private _driver = driver _veh;
private _newcommand = [];
if ( _veh != _leader && (group _driver) == _group ) then {
	_newcommand = [_pos,"TR UNLOAD", "AWARE","","","FULL"];
} else {
	_newcommand = [_pos,"GETIN", "AWARE","","","FULL"];
};


_commands set [count _commands, _newcommand];

_group setVariable ["commands", _commands, true];