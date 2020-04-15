{
	private _params = _x getVariable ["RTS_setup", []];
	if ( (count _params) > 0 ) then {
		_params call RTS_fnc_groupSetupRTS;
	};
} forEach (allGroups select { side _x == RTS_sidePlayer });

call disableFriendlyFire;