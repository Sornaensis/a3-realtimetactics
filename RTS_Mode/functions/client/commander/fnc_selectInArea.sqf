params ["_start","_current"];
(screenToWorld _start) params ["_sx","_sy"];
(screenToWorld _current) params ["_mx","_my"];
private _sizeXY = [ (_mx max _sx) - (_mx min _sx), (_my max _sy) - (_my min _sy) ];
if ( (_sizeXY select 0) > 1.2 && (_sizeXY select 1) > 1.2 ) then {
	private _midPoint = [ (_mx+_sx)/2, (_my+_sy)/2, 0 ];
	private _units = [];
	{
		_units set [count _units, _x];
	} forEach (allunits select 
				{ (side _x == RTS_sidePlayer) && 
					([  _midPoint, 
						_sizeXY, 
						getPosATL (vehicle _x) 
					 ] call BIS_fnc_isInsideArea) } );
	
	if ( count _units > 0 ) then {
		private _unit =  ([[ (_mx+_sx)/2, (_my+_sy)/2, 0 ],_units] call CBA_fnc_getNearest);
		RTS_selectedGroup = 
			if ( vehicle _unit == _unit ) then {
				group _unit
			} else {
				group ((crew (vehicle _unit)) select 0)
			};
	};
};