params ["_group"];

private _ammocount = 0;

{
	{
		_x params ["","_count"];
		_ammocount = _ammocount + _count;
	} forEach (magazinesAmmoFull _x);		
} forEach (units _group);

_ammocount