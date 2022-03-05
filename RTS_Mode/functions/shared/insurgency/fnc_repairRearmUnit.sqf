params ["_group"];

(_this call INS_fnc_calculateRefundRearmCost) params [ "_mat", "_man" ];

private _grpveh = _group getVariable ["owned_vehicle", objnull];

if ( !(isNull _grpveh) ) then {
	if ( alive _grpveh ) then {
		_grpveh setDamage 0;
		(getAllHitPointsDamage _grpveh) params [ "_hitpoints" ];
		
		{
			_grpveh setHitPointDamage [ _x, 0 ];
		} forEach _hitpoints;
	};
};

{
	_x setDammage 0;
	// rearm
} forEach ( (units _group) select { alive _x } );