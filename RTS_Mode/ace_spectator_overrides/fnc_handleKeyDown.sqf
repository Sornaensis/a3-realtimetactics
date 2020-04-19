#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"

params ["","_key","_shift","_ctrl","_alt"];

// Handle map toggle
if (_key == DIK_M) exitWith {
    [] call FUNC(ui_toggleMap);
};

if ( _key == DIK_BACKSLASH ) exitWith {
	if ( !RTS_focusingOnUnit && !isNull RTS_selectedGroup ) then {
		RTS_focusingOnUnit = true;
		
		private _pos = [];
		
		if ( ( (getPos ace_spectator_camera) distance (getPos (leader RTS_selectedGroup)) ) > 150 ) then {
			_pos = [getPos (leader RTS_selectedGroup), 90] call CBA_fnc_randPos;	
			while { ( _pos distance (getPos (leader RTS_selectedGroup)) ) < 10 } do {
				_pos = [getPos (leader RTS_selectedGroup), 90] call CBA_fnc_randPos;
			};		
		} else {
			_pos = getPosATL ace_specator_camera;
		};
		
		_pos set [2, 50 min ( (getPos ace_spectator_camera) select 2 )];
		ace_spectator_camera setPosATL _pos;
		[leader RTS_selectedGroup] call ace_spectator_fnc_setFocus;
	};
	true
};

// Handle very fast speed
if (_key == DIK_LALT) exitWith {
    [true] call FUNC(cam_toggleSlow);
    true
};

if ( _key == DIK_TAB && RTS_Phase == "MAIN" ) exitWith {
	if ( RTS_canPause && !RTS_pausing ) then {
		RTS_pausing = true;
		
		if ( !RTS_paused ) then {
			RTS_paused = true;
			{
				_x enableSimulation false;
			} forEach allunits;
			{
				_x enableSimulation false;
			} forEach vehicles;
			{
				_x enableSimulation false;
			} forEach allDead;
			{
				_x enableSimulation false;
			} forEach ( entities [[], ["Logic"], true] );
		} else {
			RTS_paused = false;
			{
				_x enableSimulation true;
			} forEach allunits;
			{
				_x enableSimulation true;
			} forEach vehicles;
			{
				_x enableSimulation true;
			} forEach allDead;
			{
				_x enableSimulation true;
			} forEach ( entities [[], ["Logic"], true] );
		};
	};
};

// Handle escape menu
if (_key == DIK_ESCAPE) exitWith {
    if (GVAR(uiMapVisible)) then {
    	[] call FUNC(ui_toggleMap);
    } else {
        private _displayType = ["RscDisplayInterrupt","RscDisplayMPInterrupt"] select isMultiplayer;
        SPEC_DISPLAY createDisplay _displayType;
    };
    true
};

// Movement commands

if ( _key == DIK_T && _shift ) exitWith {
	private _group = RTS_selectedGroup;
	if ( !(isNull _group) ) then {
		private _leader = leader _group;
		private _leaderPos = eyePos _leader;
		private _mousepos = screenToWorld getMousePosition;
		_mousepos set [2, 2];
		private _cursorpos = ATLtoASL _mousepos;
		private _visibilityView = ([vehicle _leader, "VIEW"] checkVisibility [_leaderPos, _cursorpos]);
		
		private _info = format ["Distance: %1<br/>Heading: %2<br/>Visibility: %3", 
													[_cursorpos, _leaderPos] call CBA_fnc_getDistance,
													_leaderPos getDir _mousepos,
													_visibilityView * 100];
		RTS_command = ["Check Vis.", 
						{
							params ["_group", "_pos"];
							_group setFormDir ((leader _group) getDir _pos);
							{
								_x doWatch objnull;
								_x doWatch _pos;
							} forEach (units _group);
						}, _mousepos, _info];
	};
	true
};

if ( _key == DIK_E || _key == DIK_R 
	|| _key == DIK_T || _key == DIK_SPACE ) exitWith {
	if ( isNil "RTS_command" ) then {
		[_key, _alt, _shift, _ctrl] call RTS_fnc_setCommand;
	};
	true
};

// Remove newest waypoint

if ( _key == DIK_BACKSPACE && !RTS_backspace ) exitWith {
	private _group =  RTS_selectedGroup;
	if !( isNull _group ) then {
		RTS_backspace = true;
		private _commands = _group getVariable ["commands", []];
		if (( count _commands ) == 1) then {
			[_group,true] call RTS_fnc_removeCommand;
		} else {
			private _newcommands = [];
			for "_i" from 0 to ((count _commands) - 2) do {
				_newcommands set [count _newcommands, _commands select _i];
			};
			_group setVariable ["commands", _newcommands, true];
		};
	};
	true
};

// Remove current waypoint

if ( _key == DIK_DELETE && !RTS_delete ) exitWith {
	private _group =  RTS_selectedGroup;
	if !( isNull _group ) then {
		RTS_delete = true;
		private _commands = _group getVariable ["commands", []];
		if (( count _commands ) > 0) then {
			[_group,true] call RTS_fnc_removeCommand;
		};
	};
	true
};

if ( _key == DIK_H ) exitWith {
	if ( !RTS_helpKey ) then {
		RTS_helpKey = true;
		RTS_showHelp = !RTS_showHelp;
	};
	true
};


// Formation Selection

if ( _key == DIK_F && !RTS_formationChoose && (isNil "RTS_command") ) exitWith {
	RTS_formationChoose = true;
	RTS_command = ["Set Formation",{},nil,"<t align='left'>1 - Staggered Column</t><br/><t align='left'>2 - Column</t><br/><t align='left'>3 - Wedge</t><br/><t align='left'>4 - Line</t><br/><t align='left'>5 - Echelon R</t><br/><t align='left'>6 - Echelon L</t><br/><t align='left'>7 - Vee</t><br/><t align='left'>8 - File</t><br/><t align='left'>9 - Diamond</t>"];
	true
};

// Combat mode selection

if ( _key == DIK_C && !RTS_combatChoose && (isNil "RTS_command") ) exitWith {
	RTS_combatChoose = true;
	RTS_command = ["Set Combat Mode",{}, nil, "<t align='left'>1 - Return Fire</t><br/><t align='left'>2 - Fire at Will</t><br/><t align='left'>3 - CQC</t>"];
	true
};

// Stance selection

if ( _key == DIK_V && !RTS_stanceChoose && (isNil "RTS_command") ) exitWith {
	RTS_stanceChoose = true;
	RTS_command = ["Set Stance", {}, nil, "<t align='left'>1 - Discretion</t><br/><t align='left'>2 - Up</t><br/><t align='left'>3 - Crouch</t><br/><t align='left'>4 - Prone</t>"];
	true
};

// Buildingpos selection

if ( _key == DIK_X && !RTS_buildingposChoose && (isNil "RTS_command") ) exitWith {
	RTS_buildingposChoose = true;
	RTS_selectedBuilding = nearestObject [(screenToWorld getMousePosition), "House"];
	
	if ( _shift ) then {
		RTS_command = ["Search Building", { _this call RTS_fnc_commandSearchBuilding }, nil, ""];
	} else {
		RTS_command = ["Get In Building", 
						{ 
							if ( RTS_phase == "DEPLOY" ) then {
								_this call RTS_fnc_putInBuilding;
							} else {
								_this call RTS_fnc_commandGetInBuilding;
							};						
						}, nil, ""];
	};
	true
};

if ( _key == DIK_P && (RTS_Phase == "MAIN" || RTS_phase == "INITIALORDERS") ) exitWith {
	if ( RTS_commanding && !(isNull RTS_selectedGroup) && !RTS_issuingPause ) then {
		RTS_issuingPause = true;
		
		private _group = RTS_selectedGroup;
		private _commands = RTS_selectedGroup getVariable ["commands", []];
		private _pausetime = _group getVariable ["pause_remaining", 0];;
		
		if ( count _commands > 1 ) then {
			private _currentCommand = _commands select (count _commands - 1);
			
			// Already pausing
			if ( count _currentCommand > 6 ) then {
				_pausetime = _currentCommand select 6;
			} else {
				_pausetime = 0;
			};
		};
		
		
		if ( _pausetime >= 300 ) then {
			_pausetime = 0;
		} else {
			if ( _pausetime >= 240 ) then {
				_pausetime = 300;
			} else {
				if ( _pausetime >= 120 ) then {
					_pausetime = 240;
				} else {
					if ( _pausetime >= 90 ) then {
						_pausetime = 120;
					} else {
						if ( _pausetime >= 60 ) then {
							_pausetime = 90;
						} else {
							if ( _pausetime >= 30 ) then {
								_pausetime = 60;
							} else {
								if ( _pausetime >= 15 ) then {
									_pausetime = 30;
								} else {
									if ( _pausetime >= 0 ) then {
										_pausetime = 15;
									};	
								};		
							};	
						};		
					};	
				};
			};
		};
		
		if ( count _commands > 1 ) then {
			private _currentCommand = _commands select (count _commands - 1);
			
			// Already pausing
			if ( count _currentCommand > 6 ) then {
				_currentCommand set [6, _pausetime];
			} else {
				_currentCommand pushback _pausetime;
			};
		} else {
			_group setVariable ["pause_remaining", _pausetime];
			if ( count _commands < 1 ) then {
				[_group, getPos (leader _group)] call RTS_fnc_addMoveCommand;
			};
		};
	};
	true	
};

if ( _key == DIK_GRAVE && RTS_Phase == "MAIN" && !RTS_paused ) exitWith {
	if ( RTS_commanding && !(isNull RTS_selectedGroup) ) then {
		call RTS_fnc_takeControlOfUnit;
	} else {
		if ( RTS_commanding && isNull RTS_selectedGroup ) then {
			terminate RTS_ui;
			[false] call ace_spectator_fnc_cam;
			[false] call RTS_fnc_ui;
			selectPlayer RTS_commanderUnit;
		};
	};
	true
};

if( RTS_stanceChoose ) exitWith {
	private _group = RTS_selectedGroup;
	if !(isNull _group) then {
		private _mode = "";
		switch ( _key ) do {
			case DIK_1: { _mode = "AUTO" };
			case DIK_2: { _mode = "UP" };
			case DIK_3: { _mode = "MIDDLE" };
			case DIK_4: { _mode = "DOWN" };
		};
		
		if ( _mode != "" ) then {
			{
				_x setUnitPos _mode;
			} forEach (units _group);
		};
	};
	true
};

if( RTS_combatChoose ) exitWith {
	private _group = RTS_selectedGroup;
	if !(isNull _group) then {
		private _mode = "";
		switch ( _key ) do {
			case DIK_1: { _mode = "GREEN" };
			case DIK_2: { _mode = "YELLOW" };
			case DIK_3: { _mode = "RED" };
		};
		
		if ( _mode != "" ) then {
			private _commands = _group getVariable ["commands", []];
			if ( count _commands > 0 ) then {
				(_commands select ((count _commands) - 1)) set [3, _mode];
			};
			if ( count _commands < 2 ) then {
				if ( (count _commands) == 0 && _mode == "RED" ) then {
					_group setCombatMode _mode;
					[_group] call RTS_fnc_autoCombat;
				} else {
					if ( _mode != "RED" ) then {
						_group setCombatMode _mode;
						[_group,true] call RTS_fnc_autoCombat;
					};
				};	
			};
		};
	};
	true
};


if( RTS_formationChoose ) exitWith {
	private _group = RTS_selectedGroup;
	if !(isNull _group) then {
		private _form = "";
		switch ( _key ) do {
			case DIK_1: { _form = "STAG COLUMN" };
			case DIK_2: { _form = "COLUMN" };
			case DIK_3: { _form = "WEDGE" };
			case DIK_4: { _form = "LINE" };
			case DIK_5: { _form = "ECH RIGHT" };
			case DIK_6: { _form = "ECH LEFT" };
			case DIK_7: { _form = "VEE" };
			case DIK_8: { _form = "FILE" };
			case DIK_9: { _form = if ( (count ((units _group) select {alive _x})) == 4 ) then { "DIAMOND" } else { "" } };
		};
		
		if ( _form != "" ) then {
			private _commands = _group getVariable ["commands", []];
			if ( count _commands > 0 ) then {
				(_commands select ((count _commands) - 1)) set [4, _form];
			};
			if ( count _commands < 2 ) then {
				_group setFormation _form;
			};
		};
	};
	true
};