params ["_player", "_phase"];

if ( side _player == west && ((RTS_commanders select 0)==_player) ) then {
	RTS_commanderPhases set [0, _phase];
};

if ( side _player == east && ((RTS_commanders select 2)==_player) ) then {
	RTS_commanderPhases set [2, _phase];
};

if ( side _player == resistance && ((RTS_commanders select 1)==_player) ) then {
	RTS_commanderPhases set [1, _phase];
};	