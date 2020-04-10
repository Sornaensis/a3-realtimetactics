params ["_group", "_pos"];

_leaderPos = getPosATL (leader _group);
_leaderPos params ["_lx","_ly"];


if ( vehicle (leader _group) == leader _group ) then {
	_newpos = _pos findEmptyPosition [0,10,"MAN"];
	_newpos params ["_nx","_ny"];
	
	(leader _group) setPosATL _newpos;
	
	{
		if ( _x != (leader _group) ) then {
			(getPosATL _x) params ["_xx","_yy"];
			_xdiff = _xx - _lx;
			_ydiff = _yy - _ly;
			
			_newnewpos = [ _nx + _xdiff, _ny + _ydiff, 0 ];
			_newnewnewpos = _newnewpos findEmptyPosition [0,10,"MAN"];
			_x setPosATL _newnewnewpos;
			
		};
	} forEach (units _group);
} else {
	_newpos = _pos findEmptyPosition [0,10,typeOf (vehicle (leader _group))];
	(vehicle (leader _group)) setVectorUp (surfaceNormal _newpos);
	(vehicle (leader _group)) setPosATL _newpos;
};