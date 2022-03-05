params ["_group"];

private _mat = 0;
private _man = 0;

private _veh = _group getVariable ["owned_vehicle", objnull];

if ( !(isNull _veh) ) then {
	if ( alive _veh ) then {
		if ( _veh isKindOf "Tank" ) then {
			_mat = _mat + 100;
		} else {
			if ( _veh isKindOf "APC" ) then {
				_mat = _mat + 50;
			} else {
				if ( _veh isKindOf "Car" ) then {
					_mat = _mat + 10;
				};
				if ( _veh isKindOf "StaticWeapon" ) then {
					_mat = _mat + 10;
				};
			};
		};
	};
};

{
	if ( alive _x ) then {
		_mat = _mat + 2;
		_man = _man + 1;
	};
} forEach ( units _group );

[ _mat, _man ]