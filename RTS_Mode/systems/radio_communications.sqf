/// Simulate Radio Communications

waitUntil { RTS_phase == "MAIN" };

/// Nearby Unit comms
[] spawn {
	while { true } do {
		
		{
			[_x] spawn {
				params ["_group"];
				private _friendlyUnits = [getPosATL (leader _group), allunits select { side _x == RTS_sidePlayer }, 75] call CBA_fnc_getNearest;
				private _groups = [];
				{
					private _neargroup = (group _x);
					if ( !(_neargroup in _groups) && _neargroup != _group && !(isNull _neargroup) ) then {
						_groups set [count _groups, _x];
					};
				} forEach _friendlyUnits;
				
				{
					private _enemy = _x;
					private _knowledge = ( _group knowsAbout _x );
					if ( _knowledge > 0.5 ) then {
						{
							private _otherK = _x knowsAbout _enemy;
							if ( _otherK < _knowledge ) then  {
								_x reveal [_enemy, _otherK + ( ( _knowledge - _otherK ) * 0.8 )];
							};
						} forEach _groups;
					};
				} forEach ( allunits select { (side _x == RTS_sideEnemy) || (side _x == RTS_sideGreen) } );
				
			};
		} forEach RTS_commandingGroups;
		
		sleep 10;
	};
};

/// Radio comm  --  Upwards
[] spawn {
	while { true } do {
		{
			[_x] spawn {
				params ["_group"];
				private _command = _group getVariable ["command_element", grpnull];
				
				if (isNull _command) exitWith {};
				_group setVariable ["comms", "Radioing Command"];
				
				{
					private _enemy = _x;
					private _knowledge = ( _group knowsAbout _x );
					if ( _knowledge > 0.5 ) then {
							_otherK = _command knowsAbout _enemy;
							if ( _otherK < _knowledge ) then  {
								_x reveal [_enemy, _knowledge * 0.8];
							};
					};
				} forEach ( allunits select { (side _x == RTS_sideEnemy) || (side _x == RTS_sideGreen) } );
				_group setVariable ["comms", "None"];
				
			};
		} forEach (RTS_commandingGroups select { _x getVariable ["HasRadio", false] });
		
		sleep 20;
	};
};

/// Radio comm  --  Downwards
[] spawn {
	while { true } do {
		{
			[_x] spawn {
				params ["_group"];
				private _subunits = _group getVariable ["subordinates", []];
				
				if ( (count _subunits) == 0 ) exitWith {}; 
				_group setVariable ["comms", "Radioing Subordinates"];
				{
					private _enemy = _x;
					private _knowledge = ( _group knowsAbout _x );
					if ( _knowledge > 0.5 ) then {
						{
							private _otherK = _x knowsAbout _enemy;
							if ( _otherK < _knowledge ) then  {
								_x reveal [_enemy, _otherK + ( ( _knowledge - _otherK ) * 0.8 )];
							};
						} forEach _subunits;
					};
				} forEach ( allunits select { (side _x == RTS_sideEnemy) || (side _x == RTS_sideGreen) } );
				_group setVariable ["comms", "None"];
				
			};
		} forEach (RTS_commandingGroups select { _x getVariable ["HasRadio", false] });
		
		sleep 70;
	};
};

/// Radio comm  --  Cross company
[] spawn {
	while { true } do {
		{
			[_x] spawn {
				params ["_group"];
				if ( ! (isNull (_group getVariable ["command_element", grpnull])) ) exitWith {};
				_group setVariable ["comms", "Radioing Cross Company"];
				{
					private _enemy = _x;
					private _knowledge = ( _group knowsAbout _x );
					if ( _knowledge > 0.5 ) then {
						{
							private _otherK = _x knowsAbout _enemy;
							if ( _otherK < _knowledge ) then  {
								_x reveal [_enemy, _otherK + ( (_knowledge - _otherK) * 0.9 )];
							};
						} forEach ( RTS_commandingGroups select { isNull (_x getVariable ["command_element", grpnull]) } );
					};
				} forEach ( allunits select { (side _x == RTS_sideEnemy) || (side _x == RTS_sideGreen) } );
				_group setVariable ["comms", "None"];
				
			};
		} forEach (RTS_commandingGroups select { _x getVariable ["HasRadio", false] });
		
		sleep 120;
	};
};