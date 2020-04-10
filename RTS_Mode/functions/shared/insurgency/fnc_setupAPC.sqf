params ["_apc"];

INS_apcClasses pushBack (typeOf _apc);
deleteVehicle _apc;