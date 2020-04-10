private _commanders = switch ( side player ) do {
						case west: { RTS_bluforHCModules };
						case east: { RTS_opforHCModules  };
						case resistance: { RTS_greenforHCModules };
						};
private _newCommanders = [];
private _commandgroup = createGroup sideLogic;

// Remove high commander modules
{
	private _logic = _commandgroup createUnit ["Logic", getPos _x, [],0,"NONE"];
	_logic setVariable ["commander", true, true];
	_logic synchronizeObjectsAdd (synchronizedObjects _x);
	_x synchronizeObjectsRemove (synchronizedObjects _x);
	_newCommanders set [count _newCommanders, _logic];
	deleteVehicle _x;
} forEach _commanders;

// Create command structure
{
	private _commandingMen = (synchronizedObjects _x) select { side _x == RTS_sidePlayer };
	
	// Can only have exactly one commander
	if ( (count _commandingMen) == 1 ) then {
		private _commandgroup = group (_commandingMen select 0);
		_commandgroup setVariable ["HasRadio", true];
		
		private _subordinates = [(synchronizedObjects _x) select { typeof _x == "HighCommandSubordinate" }, { synchronizedObjects _x }] call CBA_fnc_filter;
		
		private _subunits = []; 
		{
			_subunits = _subunits + _x;
		} forEach _subordinates;
		
		private _subgroups = [_subunits select { side _x == RTS_sidePlayer }, { group _x }] call CBA_fnc_filter;
		{
			private _setup = _x getVariable ["RTS_setup", [nil,nil,nil,nil,nil]];
			_setup set [2, _commandgroup];
			_x setVariable ["RTS_setup", _setup];
			_x setVariable ["HasRadio", true];
		} forEach _subgroups;
	};
} forEach _newCommanders;