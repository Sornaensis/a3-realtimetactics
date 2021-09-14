params ["_group", "_pos"];

if ( vehicle (leader _group) == (leader _group) ) then {
	private _candidates = [];
	{
		if ( ! (isNil "_x") ) then {
			_candidates set [count _candidates, _x];
		};
	} forEach ([RTS_commandingGroups, 
						{ _x getVariable ["owned_vehicle", nil] }] call CBA_fnc_filter);
	private _cond =
				{ 	
					(_x emptyPositions "CARGO") >= (count (units _group))
				};
	
	private _veh = [_pos,[_pos, _candidates, 10, _cond] call CBA_fnc_getNearest] call CBA_fnc_getNearest;
	
	if ( !(isNil "_veh") ) then {
		
		if ( !(isNull (driver _veh)) ) then {
			if ( group (driver _veh) in RTS_commandingGroups ) then {
				(units _group) allowGetIn true;
				{
					_x moveInCargo _veh;
				} forEach (units _group);
			};
		};
	};
} else {
	_vehicle = vehicle (leader _group);
	_groups = [];
	{
		if ( (group _x) != _group && !((group _x) in _groups) ) then {
			_groups set [count _groups, group _x];
		};
	} forEach (crew _vehicle);
	
	_newpos = getPosATL _vehicle;
	{
		private _grp = _x;
		(units _grp) allowGetIn false;
		_leaderPos = getPosATL (leader _grp);
		_leaderPos params ["_lx","_ly"];
		
		_newpos = _newpos findEmptyPosition [0,10,"MAN"];
		_newpos params ["_nx","_ny"];
		
		(leader _x) setPosATL _newpos;
		
		{
			if ( _x != (leader _grp) ) then {
				(getPosATL _x) params ["_xx","_yy"];
				_xdiff = _xx - _lx;
				_ydiff = _yy - _ly;
				
				_newnewpos = [ _nx + _xdiff, _ny + _ydiff, 0 ];
				_newnewnewpos = _newnewpos findEmptyPosition [0,10,"MAN"];
				_x setPosATL _newnewnewpos;
				
			};
		} forEach (units _grp);
	} forEach _groups;
};