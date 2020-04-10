_sides = ["blufor","opfor","greenfor"];

{
	// Hide AO
	(format ["%1_ao", _x]) setMarkerAlphaLocal 0;
	// Hide Deployment
	private _i = 0;
	private _mark = format ["%1_deploy_%2", _x, _i];
	(getMarkerSize _mark) params ["_mx", "_my"];
	while { _mx + _my != 0 } do {
		_mark setMarkerAlphaLocal 0;
		_i = _i + 1;
		_mark = format ["%1_deploy_%2", _x, _i];
		_mx = (getMarkerSize _mark) select 0;
		_my = (getMarkerSize _mark) select 1;
	};
} forEach _sides;

_playerside = if ( side player == east ) then {
				"opfor"
			 } else {
			 	if ( side player == west ) then {
			 		"blufor"
			 	} else {
			 		if ( side player == resistance ) then {
			 			"greenfor"
			 		} else  { "" };
			 	};
			 };
			 
			 
// Create Area of Operations markers
private _aoMarker = (format ["%1_ao", _playerside]);
_aoMarker setMarkerAlphaLocal 0;

private _aoPos = getMarkerPos _aoMarker;
private _aoX = _aoPos select 0;
private _aoY = _aoPos select 1;
private _aoSize = getMarkerSize _aoMarker;
private _aoWidth = _aoSize select 0;
private _aoHeight = _aoSize select 1;

private _top = createMarkerLocal ["playerAOMarkerTop", [_aoX, _aoY + _aoHeight - 10] ];
private _bottom = createMarkerLocal ["playerAOMarkerBottom", [_aoX, _aoY - _aoHeight + 10] ];
private _left = createMarkerLocal ["playerAOMarkerLeft", [_aoX - _aoWidth + 10, _aoY] ];
private _right = createMarkerLocal ["playerAOMarkerRight", [_aoX + _aoWidth - 10, _aoY] ];

{
	_x setMarkerColorLocal (getMarkerColor _aoMarker);
	_x setMarkerBrushLocal "DiagGrid";
	_x setMarkerShape "RECTANGLE";
} forEach [_top, _bottom, _left, _right];

_top setMarkerSizeLocal [ _aoWidth, 10 ];
_bottom setMarkerSizeLocal [ _aoWidth, 10 ];
_left setMarkerSizeLocal [ 10, _aoHeight ];
_right setMarkerSizeLocal [ 10, _aoHeight ];