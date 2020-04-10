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

if ( (vehicle (leader _group) == leader _group) && ((count _positions) >= (count (units _group))) ) then {
	
	(leader _group) setPosATL _pos;
	
	_index = 0;
	{
		if ( _x != (leader _group) ) then {
			doStop _x;
			if (_index == _i) then {
				_index = _index + 1;
			};
			_x setPosATL (_positions select _index);
		};
		_index = _index + 1;
	} forEach (units _group);
};