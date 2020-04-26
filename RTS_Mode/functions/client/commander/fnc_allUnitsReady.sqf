params ["_group","_mode"];

private _ready = true;
private _tightform = true;
private _unready = 0;
private _units = (units _group) select { alive _x };
private _distancefactor = ( count _units ) * 8.3;

if ( !isNil "_mode" ) then {
	if ( _mode == "PARTIAL" ) then {
		{
			if ( !_ready ) exitWith {};
			if ( _x == leader _group ) then {
				_ready = true;
			} else {
				_ready = _ready && ( moveToCompleted _x || moveToFailed _x || unitReady _x);	
			};
						
		} forEach _units;
	};
} else {
	{
		if ( _x == leader _group ) then {
			_ready = true;
		} else {
			private _unit = _x;
			private _unitready = unitReady _x && ( ((getPos _x) distance ((expectedDestination _x) select 0)) < 7);
			private _others = [ _units, [], { (getPos _x) distance (getPos _unit) }, "DESCEND"] call BIS_fnc_sortBy;
			
			if ( count _others > 0 ) then {
				private _other = _others select 0;
				_tightform = _tightform && (((getPos _other) distance (getPos _unit)) < _distancefactor );
			};
			
			if ( !_unitready ) then {
				_unready = _unready + 1;
			};
			
			if ( !(unitReady _x) && speed _x < 0.1 ) then {
				_x commandFollow (leader _group);
			};
			
			_ready = _ready && _unitready;
		};
	} forEach _units;
};

private _total = count _units;

if ( !_ready && _unready < ( ceil (_total/2) ) && _tightform && isNil "_mode" ) then {
	true
} else {
	_ready
}
