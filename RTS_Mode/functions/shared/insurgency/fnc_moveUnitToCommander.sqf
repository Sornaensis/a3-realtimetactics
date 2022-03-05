params ["_group"];

private _vehicles = [];

{
	_vehicles pushBackUnique (vehicle _x);
} forEach ( (units _group) select { alive _x } );

{
	private _pos = [getPos player, 10] call CBA_fnc_randPos;
	_x setPosATL ( _pos findEmptyPosition [ 3, 30, typeOf _x ] );
} forEach _vehicles;