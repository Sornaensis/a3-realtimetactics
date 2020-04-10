params ["_spy"];

INS_spyLoadouts pushBack (getUnitLoadout _spy);
INS_spyClasses pushBack (typeOf _spy);
deleteVehicle _spy;