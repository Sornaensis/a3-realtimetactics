params ["_soldier"];

INS_soldierLoadouts pushBack (getUnitLoadout _soldier);
INS_soldierClasses pushBack (typeOf _soldier);
deleteVehicle _soldier;