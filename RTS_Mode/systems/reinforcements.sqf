#include "..\RTS_defines.hpp"

waitUntil { !isNil "RTS_missionTimeElapsedSoFar" };

private _friendlyReinforcements = ( switch ( RTS_sidePlayer ) do {
										case west: { RTS_bluforStaticReinforcements };
										case east: { RTS_opforStaticReinforcements };
										case resistance: { RTS_greenforStaticReinforcements };
									});
private _enemyReinforcements = [];

if ( RTS_SingleCommander ) then {
	_enemyReinforcements = ( switch ( RTS_sideEnemy ) do {
										case west: { RTS_bluforStaticReinforcements };
										case east: { RTS_opforStaticReinforcements };
									});
};


missionTime = {
	private _time = 0;
	if ( !isNil "RTS_missionTimeStarted" ) then {
		_time = RTS_missionTimeElapsedSoFar + time - RTS_missionTimeStarted;
	} else {
		_time = RTS_missionTimeElapsedSoFar;
	};
	_time
};

assignToVehicle = {
	params ["_vehicle", "_unit", "_info"];
		
	if ( count _info > 0 ) then {
	
		switch ( _info select 0 ) do {
			case "driver": {
				_unit assignAsDriver _vehicle;
				_unit moveInDriver _vehicle;	
			};
			case "Cargo": {
				if ( count _info > 1 ) then {
					_unit assignAsCargoIndex [ _vehicle, _info select 1];
					_unit moveInCargo [ _vehicle, _info select 1];
				} else {
					_unit assignAsCargo _vehicle;
					_unit moveInCargo _vehicle;
				};
			};
			case "Turret": {
				_unit assignAsTurret [ _vehicle, _info select 1 ];
				_unit moveInTurret [ _vehicle, _info select 1 ];
			};
			default {
				hintSilent str _info;
			};
		};
	};
};

spawnReinforcements = {
	params ["_unitData","_side"];
	
	// Create leader and recreate group
	
	{
		_x params ["", "_setup", "_vehicle", "_leader", "_otherUnits"];
		
		_vehicle params ["_vehicleType","_vehiclePos","_vehicleDir","_weaponCargo","_magazineCargo"];
		
		
		private _vehicleUnit = objnull;

		if ( !isNil "_vehicleType" ) then {
			_vehicleUnit = _vehicleType createVehicle [0,0,0];
			_vehicleUnit hideObjectGlobal true;
			_vehicleUnit setPosATL _vehiclePos;
			_vehicleUnit setDir _vehicleDir;
			clearWeaponCargo _vehicleUnit;
			clearMagazineCargo _vehicleUnit;
			
			{
				_vehicleUnit addWeaponCargo [ _x, (_weaponCargo select 1) select _forEachIndex];
			} forEach (_weaponCargo select 0);
			{
				_vehicleUnit addMagazineCargo [ _x, (_magazineCargo select 1) select _forEachIndex];
			} forEach (_magazineCargo select 0);
			_vehicleUnit enableSimulationGlobal false;
		};
		
		
		_leader params ["_leaderPos", "_leaderDir", "_leaderType", "_leaderLoadout", "_leaderVehicleInfo"];
		
		private _leaderUnit = (createGroup [_side, true]) createUnit [ _leaderType, [0,0,0], [], 0, "FORM" ];
		private _group = group _leaderUnit;
		_leaderUnit hideObjectGlobal true;
		_leaderUnit setPosATL ( _leaderPos findEmptyPosition [0,10,"MAN"] );
		_leaderUnit setDir _leaderDir;
		_leaderUnit setUnitLoadout _leaderLoadout;
		_group selectLeader _leaderUnit;
		
		_x set [0, _group];
		_setup set [0, _group];
		
		if ( !isNull _vehicleUnit ) then {
			_group addVehicle _vehicleUnit;
			[_vehicleUnit,_leaderUnit,_leaderVehicleInfo] call assignToVehicle;
		};
		
		_leaderUnit enableSimulationGlobal false;
		
		{
			_x params [ "_unitPos", "_unitDir", "_unitType", "_unitLoadout", "_unitVehicleInfo"];
			private _unit = _group createUnit [ _unitType, [0,0,0], [], 0, "FORM"];
			_unit hideObjectGlobal true;
			_unit setPosATL ( _unitPos findEmptyPosition [0,10,"MAN"] );
			_unit setDir _unitDir;
			_unit setUnitLoadout _unitLoadout;
			if ( !isNull _vehicleUnit ) then {
				[_vehicleUnit,_unit,_unitVehicleInfo] call assignToVehicle;
			};
			_unit enableSimulationGlobal false;
			
		} forEach _otherUnits;
	} forEach _unitData;
	
	{
		_x params ["_group", "_setup", "_vehicle", "_leader", "_otherUnits"];
		
		private _leaderIndex = _setup select 2;
		if ( _leaderIndex != -1 ) then {
			_setup set [2, (_unitData select _leaderIndex) select 0];
			_group setVariable ["HasRadio", true];
			(_setup select 2) setVariable ["HasRadio", true];
		} else {
			_setup set [2, grpnull];
		};
		_group setVariable ["RTS_setup", _setup];
	} forEach _unitData;
	
	if ( _side == RTS_sidePlayer ) then {
		{
			_x params ["_group","_setup"];
		
			{
				_x hideObjectGlobal false;
				(vehicle _x) hideObjectGlobal false;
				_x enableSimulationGlobal true;
				(vehicle _x) enableSimulationGlobal true;
			} forEach (units _group);			
			
			_setup call RTS_fnc_groupSetupRTS;
		} forEach _unitData;
	};
		
	call disableFriendlyCollision;	
};

reinforcementsTimeLoop = {
	params ["_reinforcements","_side"];
	
	for "_i" from 0 to ((count _reinforcements) - 1) do {
		(_reinforcements select _i) params ["","_time","_unitData"];
		waitUntil { sleep 0.5; (call missionTime) >= _time };
		[_unitData,_side] call spawnReinforcements; // serial
		playSound "Alarm";
		[ "Reinforcements", "Arrived" ] spawn BIS_fnc_infoText;
	};
};

RTS_friendlyReinforcementLoop = ([_friendlyReinforcements select { (_x select 0) == "TIME" },RTS_sidePlayer]) spawn reinforcementsTimeLoop;
RTS_enemyReinforcementLoop = ([_enemyReinforcements select { (_x select 0) == "TIME" },RTS_sideEnemy]) spawn reinforcementsTimeLoop;