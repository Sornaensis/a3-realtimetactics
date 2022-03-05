params ["_group"];

RTS_selectedGroup = grpNull;

RTS_commandingGroups deleteAt (RTS_commandingGroups find _group);

(_this call INS_fnc_calculateRefundRearmCost) params [ "_mat", "_man" ];

{
	deleteVehicle _x;
} forEach ( units _group );

private _veh = _group getVariable ["owned_vehicle", objnull];

if ( !(isNull _veh) ) then {
	deleteVehicle _veh;
};

INS_playerManpower = INS_playerManpower + _man;
publicVariable "INS_playerManpower";

INS_playerMaterials = INS_playerMaterials + _mat;
publicVariable "INS_playerMaterials";

