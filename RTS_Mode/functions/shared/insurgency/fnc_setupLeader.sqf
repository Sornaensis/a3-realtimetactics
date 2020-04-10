params ["_leader"];

INS_leaderLoadouts pushBack (getUnitLoadout _leader);
INS_leaderClasses pushBack (typeOf _leader);
deleteVehicle _leader;