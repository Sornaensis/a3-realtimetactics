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
		private _unit = _x;
		if ( _x == leader _group ) then {
			_ready = true;
		} else {
			private _unitready = unitReady _x && ( ((getPos _x) distance ((expectedDestination _x) select 0)) < 7);
			private _others = [ _units, [], { (getPos _x) distance (getPos _unit) }, "DESCEND"] call BIS_fnc_sortBy;
			
			if ( count _others > 0 ) then {
				private _other = _others select 0;
				_tightform = _tightform && (((getPos _other) distance (getPos _unit)) < _distancefactor );
			};
			
			if ( !_unitready ) then {
				_unready = _unready + 1;
			};
			
			if ( unitReady _x || speed _x > 0 ) then {
				_x setVariable ["unreadyTime", nil];
			};
			
			_ready = _ready && _unitready;
		
			// dont teleport leaders around that's weird
			if ( ((getPos _unit) distance ((expectedDestination _unit) select 0)) > 3 && speed _x == 0 ) then {
				private _time = _x getVariable "unreadyTime";
				
				if ( isNil "_time" ) then {
					_x setVariable ["unreadyTime", time];
				} else {
					if ( time - _time > 15 ) then {
						_x setVariable ["unreadyTime", nil];
						private _newpos = (getPos _unit) findEmptyPosition [ 20, 50, "MAN"];
						if ( !(_newpos isEqualTo []) ) then {
							_unit setPosATL _newpos;
						};
						_x doMove ( (getPosATL (leader _group)) findEmptyPosition [5, 30, "MAN"]);
					};
				};
			};		
			
		};
		
		
	} forEach _units;
};

private _total = count _units;

if ( !_ready && _unready < ( ceil (_total/2) ) && _tightform && isNil "_mode" ) then {
	true
} else {
	_ready
}
