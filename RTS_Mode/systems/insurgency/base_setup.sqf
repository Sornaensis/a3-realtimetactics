INS_baseMarker = "opfor_restriction";
INS_baseVehicleSetup = [];

{
	private _vehicle = _x;
	private _vehicleInfo = [typeOf _vehicle, direction _vehicle, getPosATL _vehicle, _vehicle getVariable ["respawn_time",120]];
	_vehicle setVariable ["info_offset",_forEachIndex];
	_vehicle setVariable ["base_veh", true];
	INS_baseVehicleSetup pushback _vehicleInfo;
	_vehicle addEventHandler ["GetIn", {
		params ["_vehicle", "_role", "_unit", "_turret"];
		if ( !(_vehicle getVariable ["spawned_vehicle", false]) ) then {
			_vehicle setVariable ["spawned_vehicle", true, true];
		};		
	}];
} forEach ( vehicles select { ( _x isKindOf "AIR" || _x isKindOf "CAR" || _x isKindOf "TANK" ) && _x inArea INS_baseMarker });


(getMarkerSize INS_baseMarker) params ["_mx","_my"];
private _baseSize = (_mx max _my);

{
	_x allowDamage false;
	_x removeAllEventHandlers "Hit";
	_x removeAllEventHandlers "HandleDamage";
	_x removeAllEventHandlers "HitPart";	
} forEach ( ((getMarkerPos INS_baseMarker) nearObjects ["HOUSE", _baseSize]) select { _x inArea INS_baseMarker });

fob_flag hideObjectGlobal true;
INS_initFobFlagPos = getPosATL fob_flag;
publicVariable "INS_initFobFlagPos";

INS_fobDeployed = false;
publicVariable "INS_fobDeployed";