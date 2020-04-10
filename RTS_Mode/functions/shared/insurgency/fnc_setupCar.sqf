params ["_car"];

INS_carClasses pushBack (typeOf _car);
deleteVehicle _car;