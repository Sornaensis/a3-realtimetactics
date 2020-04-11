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
selectPlayer (leader _group);
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