params ["_group", "_pos"];

_leaderPos = getPosATL (leader _group);
_leaderPos params ["_lx","_ly"];


if ( vehicle (leader _group) == leader _group ) then {
	(leader _group) setDir (_leaderPos getDir _pos);
	_group setFormDir (_leaderPos getDir _pos);
	{
		if ( _x != (leader _group) ) then {
			(getPosATL _x) params ["_xx","_yy"];
			_xdiff = _xx - _lx;
			_ydiff = _yy - _ly;
			
			_vector = [_leaderPos, [ _lx + _xdiff, _ly + _ydiff ], -1*(_leaderPos getDir _pos)] call CBA_fnc_vectRotate2D;
			_vector set [2,0];
			_newpos = _vector findEmptyPosition [0,10,"MAN"];
			_x setPosATL _newpos;
			
		};
	} forEach (units _group);
} else {
	_newpos = getPosATL (vehicle (leader _group));
	(vehicle (leader _group)) setDir (_leaderPos getDir _pos);
	(vehicle (leader _group)) setVectorUp (surfaceNormal _newpos);
	(vehicle (leader _group)) setPosATL _newpos;
};