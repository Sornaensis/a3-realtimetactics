params ["_pos"];

private _radius = 50;
while { !(isOnRoad _pos) } do {
	private _roads = _pos nearRoads 500;
	if ( count _roads > 0 ) then {
		_pos = (getPos (selectRandom _roads));
	} else {
		_radius = _radius + 50;
	};
};

private _type = (INS_carClasses call BIS_fnc_selectRandom);
private _carpos = (_pos findEmptyPosition [0,50,_type]);
private _car = _type createVehicle _carpos;
_car setVectorUp (surfaceNormal _carpos);

_car