params ["_pos","_notOnRoad"];

private _radius = 50;
if ( isNil "_notOnRoad" ) then {
	while { !(isOnRoad _pos) } do {
		private _roads = _pos nearRoads 500;
		if ( count _roads > 0 ) then {
			_pos = (getPos (selectRandom _roads));
		} else {
			_radius = _radius + 50;
		};
	};
};

private _type = (INS_carClasses call BIS_fnc_selectRandom);
private _carpos = (_pos findEmptyPosition [10,60,_type]);
private _car = _type createVehicle _carpos;
_car setPosATL _carpos;
_car setDir (random 360);
_car setVectorUp (surfaceNormal _carpos);

_car