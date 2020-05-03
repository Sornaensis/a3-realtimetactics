params ["_leader"];

INS_civilianSetups pushBack (typeof _leader);

{
	deleteVehicle _x;
} forEach (units (group _leader));