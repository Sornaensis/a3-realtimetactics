params ["_start"];

_i = 0;
_markers = [];
_mark = format ["%1_deploy_%2", _start, _i]; 
(getMarkerSize _mark) params ["_mx", "_my"];

while { _mx + _my != 0 } do {
	_markers set [count _markers, _mark];
	_i = _i + 1;		
	_mark = format ["%1_deploy_%2", _start, _i];
	_mx = (getMarkerSize _mark) select 0;
	_my = (getMarkerSize _mark) select 1;
};
_markers