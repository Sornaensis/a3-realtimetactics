params ["_spy"];

INS_spySetups pushBack [typeof _spy, getUnitLoadout _spy];
deleteVehicle _spy;