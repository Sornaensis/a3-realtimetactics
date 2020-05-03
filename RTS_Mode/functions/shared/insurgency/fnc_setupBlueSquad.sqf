params ["_leader"];

private _setup = [];

_setup pushback [typeof _leader, getUnitLoadout _leader];

{
	_setup pushback [typeof _x, getUnitLoadout _x];	
} forEach ( (units (group _leader)) - [_leader]);

{
	deleteVehicle _x;
} forEach (units (group _leader));


INS_bluforSquadSetups pushBack _setup;