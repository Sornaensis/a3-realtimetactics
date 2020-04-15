params ["_group", "_pos"];

private _commands = _group getVariable ["commands", []];

private _leader = leader _group;
private _veh = vehicle _leader;
private _driver = driver _veh;
private _newcommand = [];
if ( _veh != _leader && (group _driver) == _group ) then {
	if ( (count ( (crew (vehicle (leader _group))) select { group _x != _group && alive _x } )) == 0) then {
		_newcommand = [_pos,"DISMOUNT", "AWARE","","","FULL"];
	};
} else {
	_newcommand = [_pos,"MOUNT", "AWARE","","","FULL"];
};


_commands set [count _commands, _newcommand];

_group setVariable ["commands", _commands, true];