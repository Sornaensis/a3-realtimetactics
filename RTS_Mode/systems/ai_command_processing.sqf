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
		if ( isNil "_pausetime" ) then {
			_pausetime = 0;
		};
		{
			_x doWatch objnull;
			if ( _x != (leader _group) ) then {
				[_x] doFollow leader _group;
			};	
		} forEach (units _group);
		_group setFormDir ((leader _group) getDir _pos);
		if ( (vehicle (leader _group)) != (leader _group) && ( (group (driver (vehicle (leader _group)))) == _group ) ) then {
			[(driver (vehicle (leader _group))), _pos, _type, _speed, _behaviour, _pausetime] spawn {
				params ["_unit", "_pos", "_type", "_speed", "_behaviour","_pausetime"];
				_unit enableAi "MOVE";
				private _commands = (group _unit) getVariable ["commands", []];
				private _complete = false;
				private _group = group _unit;
				_unit doMove _pos;
				while { alive _unit && ((count _commands) > 0) && !_complete} do {
					_unit doMove _pos;
					(group _unit) setSpeedMode _speed;
					(group _unit) setBehaviour _behaviour;
					private _future = time + 15;
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
				if ( _type == "SEARCH" ) then {
					[_group, (_commands select 0) select 7,_pausetime] spawn {
					    params ["_group", "_building","_pausetime"];
					    private _leader = leader _group;
					    [_group] call CBA_fnc_clearWaypoints;
					
						{
							_x disableAI "COVER";
							_x setVariable ["subtasking", true];
							if ( _x !=  leader _group ) then {
								doStop _x;
							};
						} forEach (units _group);
					
					    // Prepare group to search
					    _group setFormDir ([_leader, _building] call BIS_fnc_dirTo);
					    
					    private _positions = _building buildingPos -1;
					    while {!(_positions isEqualTo []) && !(_group getVariable ["waypoint_canceled", false])} do {
					        // Update units in case of death
					        private _units = (units _group) - [leader _group];
							
					        // Abort search if the group has no units left
					        if (_units isEqualTo []) exitWith {};
					
					        // Send all available units to the next available position
					        {
					            if (_positions isEqualTo []) exitWith {};
			            		private _upos = _x getVariable ["searchPos", []];
			            		private _pos = _positions deleteAt 0;
				                _upos pushback _pos;
				                _x setVariable ["searchPos", _upos];
					        } forEach _units;
					        
					    };
					    
					    private _scripts = [];
					    {
						    private _script = [ _x, _x getVariable ["searchPos", []] ] spawn {
				    			params ["_unit", "_poses"];
				    			
				    			while { alive _unit && count _poses > 0 } do { 
					    			private _pos = _poses deleteAt 0;
					    			_unit moveTo _pos;
					    			private _ct = 0;
					    			private _done = false;
					    			while { alive _unit && !_done && _ct < 10 } do {
						    			_unit moveTo _pos;
						    			waitUntil { !(alive _unit) || speed _unit > 0 };
						    			sleep 3;
					    				waitUntil { !(alive _unit) || speed _unit == 0 || moveToCompleted _unit || moveToFailed _unit || unitReady _unit || ( (getPosATL _unit) distance _pos ) < 2 };
					    				if ( ( (getPosATL _unit) distance _pos ) > 2 ) then {
					    					_ct = _ct + 1;
					    				} else {
					    					if ( ( (getPosATL _unit) distance _pos ) < 2 ) then {
					    					 	_done = true;
					    					};
					    				};
					    				
					    				sleep 3;
					    				if ( ( !(moveToCompleted _unit) && !(moveToFailed _unit) ) && !_done && alive _unit && speed _unit == 0 ) then {
					    					private _newpos = (getPos _unit) findEmptyPosition [ 3, 6, "MAN"];
					    					_unit setPosATL _newpos;
					    				};
					    			};
					    		};
				    			_unit doFollow (leader (group _unit));
				    		};
			    			_scripts pushback _script;
				    		sleep 1;
				    	} forEach ( (units _group) - [leader _group]);
					    
					    waitUntil { (_group getVariable ["waypoint_canceled", false]) || [_group,"PARTIAL"] call RTS_fnc_allUnitsReady };
						
						{
							terminate _x;
						} forEach _scripts;
						
						_group setBehaviour "AWARE";
						(leader _group) doMove (getPos (leader _group));
						(leader _group) enableAI "COVER";
						{
							_x doWatch objnull;
							_x enableAI "COVER";
							_x setVariable ["subtasking", false];
							_x setVariable ["searchPos", nil];
							if ( _x != (leader _group) ) then {
								[_x] doFollow (leader _group);
							};
						} forEach (units _group);
						waitUntil { (_group getVariable ["waypoint_canceled", false]) || [_group] call RTS_fnc_allUnitsReady };
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
				} else {
					if ( _type == "GARRISON" ) then {
						[_group, (_commands select 0) select 7,_pausetime] spawn {
						    params ["_group", "_building","_pausetime"];
						    private _leader = leader _group;
						    [_group] call CBA_fnc_clearWaypoints;				    
						    {
						    	_x doMove (getPos _x);
								_x doWatch objnull;
								_x disableAI "COVER";
								_x setVariable ["subtasking", true];
								if ( _x != (leader _group) ) then {
									doStop _x;
								};
							} forEach (units _group);
							    
						    
						    private _positions = _building buildingPos -1;
						    private _units = units _group - [leader _group];
						    private _inbuilding = [];
						    private _scripts = [];
						    private _idx = 0;
						    
						    while { !(_units isEqualTo []) && !(_positions isEqualTo []) } do {
						    	private _unit = _units deleteAt 0;
						    	private _pos = _positions deleteAt _idx;
						    	
						    	_inbuilding pushback _unit;

					    		_unit moveTo _pos;
					    		// Gotta do everything the hard way
					    		private _script = [_unit,_pos] spawn {
					    			params ["_unit", "_pos"];
					    			_unit moveTo _pos;
					    			private _ct = 0;
					    			private _done = false;
					    			while { alive _unit && !_done && _ct < 10 } do {
						    			_unit moveTo _pos;
						    			waitUntil { !(alive _unit) || speed _unit > 0 };
						    			sleep 3;
					    				waitUntil { !(alive _unit) || speed _unit == 0 || moveToCompleted _unit || moveToFailed _unit || unitReady _unit || ( (getPosATL _unit) distance _pos ) < 2 };
					    				if ( ( (getPosATL _unit) distance _pos ) > 2 ) then {
					    					_ct = _ct + 1;
					    				} else {
					    					if ( ( (getPosATL _unit) distance _pos ) < 2 ) then {
					    					 	_done = true;
					    					};
					    				};
					    				
					    				if ( !_done && alive _unit ) then {
					    					private _newpos = (getPos _unit) findEmptyPosition [ 3, 6, "MAN"];
					    					titleText [format ["Set %1 to pos %2", _unit, _newpos], "PLAIN"];
					    					_unit setPosATL _newpos;
					    					
					    				};
					    			};
					    		};
					    		
					    		_scripts pushback _script;
					    		
						    	_idx = (
						    		if ( _idx == 0 ) then {
						    			(count _positions) - 1
						    		} else {
						    			( (count _positions) * 0.25 * ( (count _inbuilding) - 1) ) % (count _positions)
						    		}
						    	);
						    	sleep 1;
						    };
						    
						    if ( !(_positions isEqualTo []) ) then {
						    	_group move (selectRandom _positions);
						    };
						    
							(_group getVariable ["commands", []]) deleteAt 0;
							_group setVariable ["status", "GARRISONED" ]; 
						    waitUntil { (_group getVariable ["waypoint_canceled", false]) || ! ( (_group getVariable ["commands", []]) isEqualTo [] ) };
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
								
								{
									terminate _x;
								} forEach _scripts;
								
								[_group] call CBA_fnc_clearWaypoints;
								(leader _group) doMove (getPos (leader _group));
								{
									_x doWatch objnull;
									_x enableAI "COVER";
									_x setVariable ["subtasking", false];
									if ( _x != (leader _group) ) then {
										[_x] doFollow (leader _group);
									};
								} forEach (units _group);
								_group setVariable ["status", "WAITING" ]; 
							};
														
						};
					} else {
						_group move _pos;
						if ( _speed != "" ) then {
							_group setSpeedMode _speed;
						};
						if ( _combat == "" ) then {
							_combat = combatMode _group;
						};
						if ( _combat !=  "RED" ) then {
							_group setCombatMode _combat;
						} else {
							_group setCombatMode "YELLOW";
						};
						[_group, true] call RTS_fnc_autoCombat;
						_group enableAttack false;
						if ( _form != "" ) then {
							_group setFormation _form;
						};
						if ( _behaviour != "" ) then {
							_group setBehaviour _behaviour;
						};
						{
							_x doWatch objnull;
							if ( _x != (leader _group) ) then {
								_x doFollow (leader _group);
							};
						} forEach (units _group);
						[_group, _pos, _behaviour, _combat, _speed, _form, _pausetime] spawn {
							params ["_group", "_pos", "_behaviour", "_combat", "_speed", "_form", "_pausetime"];
							private _commands = _group getVariable ["commands", []];
							private _complete = false;
							while { ( ( count ((units _group) select { alive _x }) ) > 0 ) && ((count _commands) > 0) && !_complete} do {
								_group move _pos;
								{
									_x doWatch objnull;
									if ( _x != (leader _group) ) then {
										_x doFollow (leader _group);
									};
								} forEach (units _group);
								sleep 3;
								waitUntil { speed (leader _group) < 0.1; (_group getVariable ["waypoint_canceled", false]) || unitReady (leader _group) || ([getPosAtl (leader _group), _pos] call CBA_fnc_getDistance) < 5 || !((count (_group getVariable ["commands", []])) > 0) || !(alive (leader _group) ) };
								if ( _group getVariable ["waypoint_canceled", false] ) then { 
									_complete = true;
								};
								if ( alive (leader _group) && ([getPosAtl (leader _group), _pos] call CBA_fnc_getDistance) < 5 ) then {
									_complete = true;
								};
								_commands = _group getVariable ["commands", []];
							};
							waitUntil { (_group getVariable ["waypoint_canceled", false]) || [_group,"PARTIAL"] call RTS_fnc_allUnitsReady };
							(leader _group) doMove (getPos (leader _group));
							{
								_x doWatch objnull;
								if ( _x != (leader _group) ) then {
									[_x] doFollow (leader _group);
								};
							} forEach (units _group);
							waitUntil { _combat == "RED" || (_group getVariable ["waypoint_canceled", false]) || [_group] call RTS_fnc_allUnitsReady };
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
								if ( _combat == "RED" ) then {
									[_group] call RTS_fnc_autoCombat;
								} else {
									[_group,true] call RTS_fnc_autoCombat;
									_group setCombatMode _combat;
								};
								[_group] call RTS_fnc_removeCommand;
							};
						};
					};
				};
			};
		};
	};
} forEach RTS_commandingGroups;