params ["_mark"];

(getMarkerPos _mark) params ["_cx", "_cy"];
_center = [_cx,_cy];
(getMarkerSize _mark) params ["_mx","_my"];
_a1 = [_cx + _mx, _cy + _my];
_b1 = [_cx + _mx, _cy - _my];
_c1 = [_cx - _mx, _cy + _my];
_d1 = [_cx - _mx, _cy - _my];

_a = [_center, _a1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;
_b = [_center, _b1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;
_c = [_center, _c1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;
_d = [_center, _d1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;

_minx = _a select 0;
_miny = _a select 1;
_maxx = _minx;
_maxy = _miny;

{
	_x params ["_cx","_cy"];

	_minx = _minx min _cx;
	_miny = _miny min _cy;
	_maxx = _maxx max _cx;
	_maxy = _maxy max _cy;

} forEach [_b,_c,_d];

_ret = [_minx,_miny,_maxx,_maxy];

_ret