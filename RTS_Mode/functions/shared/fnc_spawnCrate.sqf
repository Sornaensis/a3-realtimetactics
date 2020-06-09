params ["_type","_pos","_group"];

private _crate = objnull;

switch ( _type ) do {
	case "MEDICAL": {
		_crate = "ACE_medicalSupplyCrate_advanced" createVehicle (_pos findEmptyPosition [2, 40, "ACE_medicalSupplyCrate_advanced"]);
	};
	case "AMMO": {
		_crate = "CUP_BAF_BasicAmmunitionBox" createVehicle (_pos findEmptyPosition [2, 40, "CUP_BAF_BasicAmmunitionBox"]);
		clearWeaponCargoGlobal _crate;
		clearMagazineCargoGlobal _crate;
		clearItemCargoGlobal _crate;
		clearBackpackCargoGlobal _crate;
		
		// populate crate with relevant ammunition
		private _magazines = [];
		private _launchers = [];
		{
			private _unit = _x;
			private _mags = [];
			{
				_mags pushbackunique _x;
			} forEach (magazines _unit);
			{
				_magazines pushback _x;
			} forEach _mags;
			{
				private _weapon = _x;
				if ( _weapon isKindOf "Launcher_Base_F" ) then {
					_launchers pushbackunique _x;
				};
			} forEach (weapons player);
		} forEach (units _group);
		
		{
			_crate addMagazineCargoGlobal [ _x, 5 ];
		} forEach _magazines;
		{
			_crate addWeaponCargoGlobal [ _x, 2 ];
		} forEach _launchers;
		
	};
	case "VEHICLE_AMMO": {
		_crate = "Box_NATO_AmmoVeh_F" createVehicle (_pos findEmptyPosition [2, 40, "Box_NATO_AmmoVeh_F"]);
	};
	case "FUEL": {
		_crate = "Boxloader_drumpallet_fuel" createVehicle (_pos findEmptyPosition [2, 40, "Boxloader_drumpallet_fuel"]);
		[[ _crate, 1000 ], { _this call ace_refuel_fnc_makeSource }] remoteExecCall ["call",2];
	};
};

if ( !(_crate isEqualTo objnull) ) then {
	[_crate, ["spawned_vehicle",true]] remoteExecCall ["setVariable", 2];
	[_crate, ["base_veh",true]] remoteExecCall ["setVariable", 2];
	if ( _type isEqualTo "AMMO" ) then {
		_crate setVariable ["crate_grp_src", _group, true];
		[-1, 
		{
			params ["_crate"];
			_crate addAction [
				"Put Away Ammo Crate",
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					(_target getVariable "crate_grp_src") setVariable ["INS_ammoCrateSpawned", -300, true];
					deleteVehicle _target;
				},
				nil,
				1.5,
				true,
				true,
				"",
				"((getPos player) distance (getPos arsenal_crate)) < 55",
				5,
				false,
				"",
				""
			];
		}, [_crate]] call CBA_fnc_globalExecute;
	};
};

