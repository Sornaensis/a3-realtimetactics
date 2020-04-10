params ["_tank"];

INS_tankClasses pushBack (typeOf _tank);
deleteVehicle _tank;