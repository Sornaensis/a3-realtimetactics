params ["_minx","_miny","_maxx","_maxy","_mark"];

(getPosATL player) params ["_px","_py","_pz"];

_set = false;

if ( _px > _maxx ) then {
	_px = _maxx;
	_set = true;
};
if ( _px < _minx ) then {
	_px = _minx;
	_set = true;
};
if ( _py > _maxy ) then {
	_py = _maxy;
	_set = true;
};
if ( _py < _miny ) then {
	_py = _miny;
	_set = true;
};

if _set then {
	player setPosATL [_px,_py,_pz];
};