params ["_player"];

if ( side _player == west && isNull (RTS_commanders select 0) ) then {
	RTS_commanders set [0, _player];
	RTS_commanderPhases set [0, "DEPLOY"];
};

if ( side _player == east && isNull (RTS_commanders select 2) ) then {
	RTS_commanders set [2, _player];
	RTS_commanderPhases set [2, "DEPLOY"];
};

if ( side _player == resistance && isNull (RTS_commanders select 1) ) then {
	RTS_commanders set [1, _player];
	RTS_commanderPhases set [1, "DEPLOY"];
};