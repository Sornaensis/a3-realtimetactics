private _group = RTS_selectedGroup;
if ( isNull _group ) exitWith {};
if ( (_group getVariable ["morale", 0]) < 1 ) exitWith {};
if ( RTS_paused ) exitWith {};

while { count (_group getVariable ["commands",[]]) > 0 } do {
	[_group,true] call RTS_fnc_removeCommand;
};
terminate RTS_ui;
[false] call ace_spectator_fnc_cam;
[false] call RTS_fnc_ui;

private _unit = (leader _group);
selectPlayer (leader _group);

{
	_x commandMove (getPosATL _x);
	[_x] commandFollow _unit;
} forEach (units (group _unit));


RTS_commandAction = player addAction ["Command Mode", 
{
	private _pos = getPosATL player;
	private _dir = getDir player;
	_pos set [2, 5];
	private _group = group player;
	RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");
	player removeAction RTS_commandAction;
	player removeEventHandler ["killed", RTS_killedEH];
	selectPlayer RTS_commanderUnit;
	
	{
		_x commandMove (getPosATL _x);
		[_x] commandFollow (leader _group);
	} forEach (units _group);
	
	[true] call ace_spectator_fnc_cam;
	[true] call RTS_fnc_ui;
	ace_spectator_camera setPosATL _pos;
	ace_spectator_camera setDir _dir;
}];

RTS_killedEH = player addEventHandler ["killed", {
	params ["_unit"];
	selectPlayer RTS_commanderUnit;
	private _pos = getPosATL player;
	private _dir = getDir player;
	_pos set [2, 5];	
	private _livingUnits = (units (group _unit)) select { alive _x };
	if ( count _livingUnits > 0 ) then {
		private _leader = _livingUnits select 0;
		(group _unit) selectLeader _leader;
		{
			_x commandMove (getPosATL _x);
			[_x] commandFollow _leader;
		} forEach (units (group _leader));
	};
	
	RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");
	
	_unit removeAction RTS_commandAction;
	_unit removeEventHandler ["killed", RTS_killedEH];
	
	[true] call ace_spectator_fnc_cam;
	[true] call RTS_fnc_ui;
	ace_spectator_camera setPosATL _pos;
	ace_spectator_camera setDir _dir;
}];