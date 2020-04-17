params ["_group"];

if (isNil "RTS_selectedBuilding") exitWith {};

private _positions = [RTS_selectedBuilding] call BIS_fnc_buildingPositions;

if ((count _positions) == 0) exitWith {};

_commands = _group getVariable ["commands", []];

private _newcommand = [getPos RTS_selectedBuilding, "SEARCH", "","","","LIMITED", nil, RTS_selectedBuilding];

_commands set [count _commands, _newcommand];

_group setVariable ["commands", _commands, true];