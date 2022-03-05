params ["_group"];

private _veh = _group getVariable "owned_vehicle";

if ( !((typeOf _veh) isKindOf "StaticWeapon") ) exitWith {};

if ( simulationEnabled _veh ) then {
	
	_group leaveVehicle _veh;
	commandGetOut (units _group);
	(units _group) allowGetIn false;
	
	{
		moveOut _x;
		_x enableAI "MOVE";
	} forEach ( units _group );
	
	[_veh, false] remoteExec ["enableSimulationGlobal", 2];
	[_veh, true] remoteExec ["hideObjectGlobal", 2];
	
} else {

	private _pos =  getPosATL (leader _group);

	_veh setPosATL _pos;
	
	[_veh, true] remoteExec ["enableSimulationGlobal", 2];

	(units _group) allowGetIn true;
	
	{
		_x moveInAny _veh;
	} forEach (units _group);

	[_veh, false] remoteExec ["hideObjectGlobal", 2];
};