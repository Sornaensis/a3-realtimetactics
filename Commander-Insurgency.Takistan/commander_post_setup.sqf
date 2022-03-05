{
	private _grp = _x;
	if ( ((_grp getVariable "RTS_Setup") # 1) == "Mortar" && isNull (_grp getVariable ["command_element",grpnull]) ) then {
				
		private _leader = leader _grp;
		private _veh = vehicle _leader;
		private _loadout = getUnitLoadout _leader;
		
		private _spawnpos = (getPos (leader _grp)) findEmptyPosition [5,20, "MAN"];
		private _soldier = [_spawnpos] call INS_fnc_spawnSpy;
		
		private _unit = (createGroup east) createUnit [ typeOf _leader, (getPos _leader) findEmptyPosition [ 0, 20, "MAN" ], [], 0, "NONE" ];
		_unit setUnitLoadout _loadout;
		
		private _mortar = (typeof _veh) createVehicle ((getPos _veh) findEmptyPosition [ 0, 20, "MAN" ]);
		
		
		deleteVehicle _leader;
		deleteVehicle _veh;
		
		_grp = group _unit;
		
		private _soldierGroup = group _soldier;
		_grp setVariable ["RTS_Setup", [_grp, "Mortar", _soldierGroup, "\A3\ui_f\data\map\markers\nato\o_support.paa", "o_support"], true];
		_soldierGroup setVariable ["RTS_setup", [_soldierGroup, "Spotter", grpnull, "\A3\ui_f\data\map\markers\nato\o_support.paa", "o_support"], true];
		
		_grp setVariable ["command_element", _soldierGroup, true];
		_soldierGroup setVariable [ "iscommander", true, false];
		_soldierGroup setVariable [ "subordinates", [_grp], false];
		
		_unit assignAsGunner _mortar;
		_unit moveInGunner _mortar;
		_unit disableAI "MOVE";
		
	};
} forEach ( allgroups select { count (_x getVariable ["RTS_Setup",[]]) > 0 } );

[] call RTS_fnc_setupAllGroups;
