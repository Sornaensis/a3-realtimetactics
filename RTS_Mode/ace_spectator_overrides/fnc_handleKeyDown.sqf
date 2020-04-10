#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"

params ["","_key","_shift","_ctrl","_alt"];

// Handle map toggle
if (_key == DIK_M) exitWith {
    [] call FUNC(ui_toggleMap);
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
		
		private _info = format ["Distance: %1\nHeading: %2\nVisibility: %3", 
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
	|| _key == DIK_T || _key == DIK_G || _key == DIK_SPACE ) exitWith {
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
			[_group] call RTS_fnc_removeCommand;
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


// Formation Selection

if ( _key == DIK_F && !RTS_formationChoose && (isNil "RTS_command") ) exitWith {
	RTS_formationChoose = true;
	RTS_command = ["Set Formation",{},nil,"1 - Staggered Column\n2 - Column\n3 - Wedge\n4 - Line\n5 - Echelon R\n6 - Echelon L\n7 - Vee\n8 - File\n9 - Diamond"];
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
			_group setFormation _form;
		};
	};
	true
};

// Combat mode selection

if ( _key == DIK_C && !RTS_combatChoose && (isNil "RTS_command") ) exitWith {
	RTS_combatChoose = true;
	RTS_command = ["Set Combat Mode",{}, nil, "1 - Hold Fire\n2 - Return Fire\n3 - Fire at Will"];
	true
};

if( RTS_combatChoose ) exitWith {
	private _group = RTS_selectedGroup;
	if !(isNull _group) then {
		private _mode = "";
		switch ( _key ) do {
			case DIK_1: { _mode = "BLUE" };
			case DIK_2: { _mode = "GREEN" };
			case DIK_3: { _mode = "YELLOW" };
		};
		
		if ( _mode != "" ) then {
			_group setCombatMode _mode;
		};
	};
	true
};

// Stance selection

if ( _key == DIK_V && !RTS_stanceChoose && (isNil "RTS_command") ) exitWith {
	RTS_stanceChoose = true;
	RTS_command = ["Set Stance", {}, nil, "1 - Discretion\n2 - Up\n3 - Crouch\n4 - Prone"];
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

// Buildingpos selection

if ( _key == DIK_X && !RTS_buildingposChoose && (isNil "RTS_command") ) exitWith {
	RTS_buildingposChoose = true;
	RTS_selectedBuilding = nearestObject [(screenToWorld getMousePosition), "House"];
	RTS_command = ["Get In Building", 
					{ 
						if ( RTS_phase == "DEPLOY" ) then {
							_this call RTS_fnc_putInBuilding;
						} else {
							_this call RTS_fnc_commandGetInBuilding;
						};						
					}, nil, ""];
	true
};

if ( _key == DIK_P && (RTS_Phase == "MAIN" || RTS_phase == "INITIALORDERS") ) exitWith {
	if ( RTS_commanding && !(isNull RTS_selectedGroup) && !RTS_issuingPause ) then {
		RTS_issuingPause = true;
		
		private _commands = RTS_selectedGroup getVariable ["commands", []];
		
		if ( count _commands > 0 ) then {
			private _currentCommand = _commands select (count _commands - 1);
			
			// Already pausing
			if ( count _currentCommand > 6 ) then {
				private _pausetime = _currentCommand select 6;
				if ( _pausetime == 300 ) then {
					_currentCommand set [6, 0];
				} else {
					if ( _pausetime == 240 ) then {
						_currentCommand set [6, 300];
					} else {
						if ( _pausetime == 120 ) then {
							_currentCommand set [6, 240];
						} else {
							if ( _pausetime == 90 ) then {
								_currentCommand set [6, 120];
							} else {
								if ( _pausetime == 60 ) then {
									_currentCommand set [6, 90];
								} else {
									if ( _pausetime == 30 ) then {
										_currentCommand set [6, 60];
									} else {
										if ( _pausetime == 15 ) then {
											_currentCommand set [6, 30];
										} else {
											if ( _pausetime == 0 ) then {
												_currentCommand set [6, 15];
											} else {
												
											};	
										};		
									};	
								};		
							};	
						};
					};
				};
			} else {
				_currentCommand pushBack 15;
			};
		};
	};
	true	
};

if ( _key == DIK_GRAVE && RTS_Phase == "MAIN" && !RTS_paused ) exitWith {
	if ( RTS_commanding && !(isNull RTS_selectedGroup) ) then {
		while { count (RTS_slectedGroup getVariable ["commands",[]]) > 0 } do {
			[RTS_selectedGroup] call RTS_fnc_removeCommand;
		};
		terminate RTS_ui;
		[false] call ace_spectator_fnc_cam;
		[false] call RTS_fnc_ui;
		selectPlayer (leader RTS_selectedGroup);
		RTS_killedEH = player addEventHandler ["killed", {
			private _pos = getPosATL player;
			private _dir = getDir player;
			_pos set [2, 5];
			private _leader = ((units (group player)) select { alive _x }) select 0;
			(group player) selectLeader _leader;
			{
				_x commandMove (getPosATL _x);
				[_x] commandFollow (group _leader);
			} forEach (units (group _leader));
			RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");
			player removeAction RTS_commandAction;
			player removeEventHandler ["killed", RTS_killedEH];
			selectPlayer RTS_commanderUnit;
			[true] call ace_spectator_fnc_cam;
			[true] call RTS_fnc_ui;
			ace_spectator_camera setPosATL _pos;
			ace_spectator_camera setDir _dir;
		}];

		RTS_commandAction = player addAction ["Command Mode", 
		{
			private _pos = getPosATL player;
			private _dir = getDir player;
			_pos set [2, 5];
			private _group = group player;
			{
				_x commandMove (getPosATL _x);
				[_x] commandFollow (leader _group);
			} forEach (units _group);
			RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");
			player removeAction RTS_commandAction;
			player removeEventHandler ["killed", RTS_killedEH];
			selectPlayer RTS_commanderUnit;
			[true] call ace_spectator_fnc_cam;
			[true] call RTS_fnc_ui;
			ace_spectator_camera setPosATL _pos;
			ace_spectator_camera setDir _dir;
		}];
	};
	true
};

