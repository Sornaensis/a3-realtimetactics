params ["_group","_deleted"];
if ( _group in RTS_commandingGroups ) then {
	private _commands = _group getVariable ["commands", []];
	if (count _commands > 0) then {
		(_commands select 0) params ["","_type", "_behaviour"];
		_tempcommands = [];
		for "_i" from 1 to ((count _commands) - 1) do {
			_tempcommands set [count _tempcommands, _commands select _i];
		};
		_group setVariable ["commands", _tempcommands, true];
		
		if ( !isNil "_deleted" ) then {
			_group setVariable ["waypoint_canceled", true];
			
			private _script = _group getVariable "mainScript";
			if ( !isNil "_script" ) then {
				terminate _script;
			};
			
			{
				terminate _x;
			} forEach ( _group getVariable ["subscripts", []]);
			
			if ( vehicle (leader _group) == (leader _group) && ( count _tempcommands == 0 ) ) then {
				[_group, getPos (leader _group)] call RTS_fnc_addMoveCommand;
			};
			
			_group setVariable ["status", "WAITING"];
		};
		
		if ( ( (vehicle (leader _group)) != (leader _group) ) && ( (group (driver (vehicle (leader _group)))) == _group ) && _type != "DISMOUNT" ) then {
			(driver (vehicle (leader _group))) disableAi "MOVE";
		} else {
			if ( _behaviour != "COMBAT" ) then {
				{
					_x enableAI "AUTOTARGET";
				} forEach (units _group);
			};
			{
				if (_type == "DISMOUNT") then {
					_x enableAI "MOVE";
				};
			} forEach (units _group);
			{
				if ( _x != (leader _group) ) then {
					_x doFollow (leader _group);
				};
			} forEach (units _group);
		};
	};
	if ( (count (waypoints _group)) > 0 ) then {
		[_group] call CBA_fnc_clearWaypoints;
	};
	
	if ( !(isNil "_deleted") && RTS_phase == "MAIN" && count (_group getVariable ["commands", []]) == 0 && ( (_group getVariable ["status", ""]) == "OTM" || (_group getVariable ["status", ""]) == "PAUSED" ) && !(_group getVariable ["waypoint_canceled", false]) ) then {
		if ( vehicle (leader _group) == (leader _group) ) then {
			[_group, getPos (leader _group)] call RTS_fnc_addMoveCommand;
		};
	} else {	
		_group setVariable ["pause_remaining", 0];
		if ( _group getVariable ["status", "WAITING"] != "HOLDING" ) then {
			_group setVariable ["status", "WAITING", false];
		} else {
			_group setVariable ["status", "HOLDING", false];
		};
	};
};