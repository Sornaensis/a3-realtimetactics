params ["_group"];

if (isNil "RTS_selectedBuilding") exitWith {};

private _positions = [RTS_selectedBuilding] call BIS_fnc_buildingPositions;
if ((count _positions) == 0) exitWith {};
private _nearest = [_positions, { (worldToScreen _x) distance getMousePosition }] call CBA_fnc_filter;
private _i = -1;
private _least = 100;
{
	if ( _x < _least ) then {
		_least = _x;
		_i = _forEachIndex;
	};
} forEach _nearest;

private _pos = _positions select _i;

_commands = _group getVariable ["commands", []];

private _newcommand = [_pos,"GARRISON", "","","","NORMAL", nil, RTS_selectedBuilding ];

_commands set [count _commands, _newcommand];

_group setVariable ["commands", _commands, true];