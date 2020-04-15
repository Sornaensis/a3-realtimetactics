{ 
	private ["_group", "_status", "_commands"];
	_group = _x;
	_status = _group getVariable ["status", "WAITING"];
	_commands = _group getVariable ["commands", []];
	// Setup next waypoint
	if ( _status == "WAITING" && (count _commands) > 0 ) then {
		_group setVariable ["status", "OTM"];
		(_commands select 0) params ["_pos", "_type", "_behaviour", "_combat", "_form", "_speed"];
		private _pausetime = 0;
		if ( count (_commands select 0) > 6 ) then {
			_pausetime = (_commands select 0) select 6;
		};
		{
			_x doWatch objnull;
			[_x] doFollow leader _group;
		} forEach (units _group);
		_group setFormDir ((leader _group) getDir _pos);
		if ( (vehicle (leader _group)) != (leader _group) && ( (group (driver (vehicle (leader _group)))) == _group ) ) then {
			[(driver (vehicle (leader _group))), _pos, _type, _speed, _behaviour, _pausetime] spawn {
				params ["_unit", "_pos", "_type", "_speed", "_behaviour","_pausetime"];
				_unit enableAi "MOVE";
				private _commands = (group _unit) getVariable ["commands", []];
				private _complete = false;
				private _group = group _unit;
				while { alive _unit && ((count _commands) > 0) && !_complete} do {
					waitUntil { speed (vehicle _unit) == 0 };
					_unit doMove _pos;
					(group _unit) setSpeedMode _speed;
					(group _unit) setBehaviour _behaviour;
					_future = time + 8;
					waitUntil { (_group getVariable ["waypoint_canceled", false]) || speed (vehicle _unit) != 0 || (time > _future && !RTS_paused) };
					sleep 3;
					waitUntil { (_group getVariable ["waypoint_canceled", false]) || (speed (vehicle _unit) == 0 && !RTS_paused) || ([_unit, _pos] call CBA_fnc_getDistance) < 9 || !(alive _unit) };
					_complete = true;
					_commands = (group _unit) getVariable ["commands", []];
				};
				if ( _group getVariable ["waypoint_canceled", false] ) then { 
					_group setVariable ["waypoint_canceled", false ]; 
					_group setVariable ["status", "WAITING" ]; 
				} else {
					// Pause for variable seconds
					_unit disableAi "MOVE";
					_group setVariable ["status", "PAUSED" ];
					_pausetime = (if ( _pausetime > 0 ) then { _pausetime } else { _group getVariable ["pause_remaining", 0] });
					while { _pausetime > 0 } do {
						_group setVariable ["pause_remaining", _pausetime - 1];
						sleep 1;
						_pausetime = _group getVariable ["pause_remaining", 0];
						waitUntil { !RTS_paused };						
					};
					_group setVariable ["pause_remaining", 0];
					if ( _type == "TR UNLOAD") then {
						private _groups = [];
						{ 
							if ( !((group _x) in _groups ) && ((group _x) != (group _unit)) ) then {
								(group _x) leaveVehicle (vehicle _unit);
								commandGetOut (units (group _x));
								(units (group _x)) allowGetIn false;
								_groups set [count _groups, group _x];
								[group _x] call CBA_fnc_clearWaypoints;
								[group _x, (getPosATL (leader (group _x))) findEmptyPosition [0,40,"Man"] ] call RTS_fnc_addMoveCommand;
							};								
						} forEach (crew (vehicle _unit));
					};
					if ( _type == "DISMOUNT") then {
						(driver (vehicle (leader (group _unit)))) enableAI "MOVE";
						{
							_x disableAI "AUTOCOMBAT";
						} forEach (units (group _unit));
						(group _unit) leaveVehicle (vehicle _unit);
						commandGetOut (units (group _unit));
						(units (group _unit)) allowGetIn false;
						waitUntil { vehicle _unit == _unit };
						[group _unit] call CBA_fnc_clearWaypoints;
					};
					[group _unit] call RTS_fnc_removeCommand;
				};
			};
		} else {
			if ( _behaviour != "COMBAT" ) then {
				{
					_x disableAI "COVER";
					_x disableAI "AUTOTARGET";
					_x disableAI "FSM";
					_x disableAI "AUTOCOMBAT";
				} forEach (units _group);
			} else {
				{
					_x enableAI "AUTOCOMBAT";
				} forEach (units _group);
			};
			if ( _type == "GETIN" || _type == "MOUNT" ) then {
				(units _group) allowGetIn true;
				private _candidates = [];
				{
					if ( ! (isNil "_x") ) then {
						_candidates set [count _candidates, _x];
					};
				} forEach ([RTS_commandingGroups, 
									{ _x getVariable ["owned_vehicle", nil] }] call CBA_fnc_filter);
				private _cond = 
					if ( _type == "MOUNT" ) then {
							{ 	private _crew = (crew _x) select { alive _x }; 
								(count _crew) == 0 
							}
					} else { 
							{ true } 
					};
				private _wpveh = [_pos,[_pos, _candidates, 10, _cond] call CBA_fnc_getNearest] call CBA_fnc_getNearest;
				if ( ! isNil "_wpveh" ) then {
					private _wp =
						if (_type == "GETIN") then {
							{ 
								_x assignAsCargo _wpveh;
							} forEach ( units _group);
							[_group, getPosATL _wpveh, 0, "GETIN", _behaviour, _combat, _speed, _form, 
								"[group this] call RTS_fnc_removeCommand", [0,0,0], 0] call CBA_fnc_addWaypoint;
						} else {
							[_group, getPosATL _wpveh, 0, "GETIN", _behaviour, _combat, _speed, _form, 
								"[group this] call RTS_fnc_removeCommand; [group this] call RTS_fnc_autoCombat;", [0,0,0], 0] call CBA_fnc_addWaypoint;
						};
					_wp waypointAttachVehicle _wpveh;
				};
			} else {
				[_group, _pos, _behaviour, _combat, _speed, _form, _pausetime] spawn {
					params ["_group", "_pos", "_behaviour", "_combat", "_speed", "_form", "_pausetime"];
					private _commands = _group getVariable ["commands", []];
					private _complete = false;
					while { ( ( count ((units _group) select { alive _x }) ) > 0 ) && ((count _commands) > 0) && !_complete} do {
						(leader _group) doMove _pos;
						if ( _speed != "" ) then {
							_group setSpeedMode _speed;
						};
						if ( _combat != "" ) then {
							_group setCombatMode _combat;
						};
						if ( _form != "" ) then {
							_group setFormation _form;
						};
						if ( _behaviour != "" ) then {
							_group setBehaviour _behaviour;
						};
						{
							_x doWatch objnull;
							if ( _x != (leader _group) ) then {
								[_x] doFollow (leader _group);
							};
						} forEach (units _group);
						waitUntil { (_group getVariable ["waypoint_canceled", false]) || ([getPosAtl (leader _group), _pos] call CBA_fnc_getDistance) < 10 || !((count (_group getVariable ["commands", []])) > 0) || !(alive (leader _group) ) };
						if ( _group getVariable ["waypoint_canceled", false] ) then { 
							_complete = true;
						};
						if ( ([getPosAtl (leader _group), _pos] call CBA_fnc_getDistance) < 10 ) then {
							_complete = true;
						};
						_commands = _group getVariable ["commands", []];
					};
					if ( _group getVariable ["waypoint_canceled", false] ) then { 
						_group setVariable ["waypoint_canceled", false ]; 
						_group setVariable ["status", "WAITING" ];
					} else {
						// Pause for variable seconds
						_group setVariable ["status", "PAUSED" ];
						_pausetime = (if ( _pausetime > 0 ) then { _pausetime } else { _group getVariable ["pause_remaining", 0] });
						while { _pausetime > 0 } do {
							_group setVariable ["pause_remaining", _pausetime - 1];
							sleep 1;	
							_pausetime = _group getVariable ["pause_remaining", 0];
							waitUntil { !RTS_paused };							
						};
						_group setVariable ["pause_remaining", 0];
						[_group] call RTS_fnc_removeCommand;
					};
				};
			};
		};
	};
} forEach RTS_commandingGroups;