private _pos = getPosATL player;
private _dir = getDir player;
_pos set [2, 5];
private _group = group player;
RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");
player removeAction RTS_commandAction;
player removeEventHandler ["killed", RTS_killedEH];
selectPlayer RTS_commanderUnit;

{
	if ( vehicle _x != _x ) then {
		if ( driver (vehicle _x) == _x ) then {
			_x disableAI "MOVE";
		};
	};
	_x commandMove (getPosATL _x);
	[_x] commandFollow (leader _group);
} forEach (units _group);

[true] call ace_spectator_fnc_cam;
[true] call RTS_fnc_ui;
ace_spectator_camera setPosATL _pos;
ace_spectator_camera setDir _dir;
