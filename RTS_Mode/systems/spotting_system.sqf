#include "../RTS_defines.hpp"

waitUntil { RTS_phase == "MAIN" };

// OPFOR check if they are spotted
RTS_spottingLoop = [] spawn { 
	while {true} do { 
		if ( RTS_commanding && !RTS_godseye ) then {
			{
				private _group = _x;
				private _check = _group getVariable ["spottingCheck", nil];
				private _cont = true;
				if !( isNil "_check" ) then {
					_cont = if !( scriptDone _check) then { false } else { true };
				};
				if ( !_cont ) exitWith {};
				_group setVariable ["spottingCheck",
				[_group] spawn {
					params ["_group"];
					{
						private ["_enemy", "_hide", "_enemyPos"];
						_enemy = _x;
						if ( ((vehicle _enemy) != _enemy) && (side _enemy == RTS_sideEnemy ) ) then {
							if ( !((vehicle _enemy) in RTS_opfor_vehicles) ) then {
								RTS_opfor_vehicles pushBack (vehicle _enemy);
							} else {
								if ( !((vehicle _enemy) in RTS_greenfor_vehicles) && (side _enemy == RTS_sideGreen) ) then {
									RTS_greenfor_vehicles pushBack (vehicle _enemy);
								};
							};
						};
	
						(vehicle _enemy) setVariable ["spottedbyselectedgroup", grpnull];
						(vehicle _enemy) hideObject ([_enemy, allGroups select { side _x == RTS_sidePlayer }] call RTS_fnc_spotting);
					} forEach (units _group);
				}, false];
			} forEach ( allGroups select { (side _x == RTS_sideEnemy) || (side _x == RTS_sideGreen) } );
			_opfor_vehicles = [];
			{
				if ( count ((crew _x) select { alive _x } ) == 0 ) then {
					_x hideObject false;
				} else {
					_opfor_vehicles = _opfor_vehicles + [_x];
				};
			} forEach RTS_opfor_vehicles;
			RTS_opfor_vehicles = _opfor_vehicles;
			_greenfor_vehicles = [];
			{
				if ( count ((crew _x) select { alive _x } ) == 0 ) then {
					_x hideObject false;
				} else {
					_greenfor_vehicles = _greenfor_vehicles + [_x];
				};
			} forEach RTS_greenfor_vehicles;
			RTS_greenfor_vehicles = _greenfor_vehicles; 
		} else {
			{
				(vehicle _x) hideObject false;
				_x hideObject false;
			} forEach (allunits select { side _x != RTS_sidePlayer } );
		};
	} 
};

RTS_reveal_deadMen = [] spawn {
	while { true } do {
		{
			_x hideObject false;
			(vehicle _x) hideObject false;
		} forEach allDeadMen;
		
		sleep 5;
	};
};


RTS_fnc_spotting = {
	params ["_enemy","_groups"];
	_hide = true;
	{
		private _group = _x;
		private _spotters = units _group;
		private _enemyPos = eyePos _enemy;
		_shide = true;
		{
			private _xPos = eyePos _x;
			private _visibility = [vehicle _x, "VIEW", vehicle _enemy] checkVisibility [_xPos, _enemyPos];
			private _dirTo = _x getRelDir _enemy;
			private _infrontOf = [vehicle _x, vehicle _enemy] call BIS_fnc_isInFrontOf; 
			private _terrainBlocked = terrainIntersect [_xPos, _enemyPos];
			private _knowsAbout = (_x knowsAbout (vehicle _enemy)) max (_x knowsAbout _enemy);
			private _distance = [vehicle _x, vehicle _enemy] call CBA_fnc_getDistance;
			private _spottingThreshold = (1.08 - ( (175/_distance) * 0.78 )) max 0;  						
			_shide = if (_knowsAbout > 0.7 && _visibility > _spottingThreshold*0.9 && !_terrainBlocked )
						then { false } else {
							if ( _knowsAbout > 0.5 && _visibility > _spottingThreshold && !_terrainBlocked ) 
								then { false } else { 
								if ( _knowsAbout > 0.2 && _visibility > _spottingThreshold*1.2 && !_terrainBlocked ) then { 
									false 
								} else {
									if ( _visibility > _spottingThreshold  && !_terrainBlocked && _infrontOf && _knowsAbout < 0.6 ) then {
										(group _x) reveal [_enemy, _knowsAbout + ([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.09,0.1,0.1,0.1,0.1,0.09,0.3,0.09,0.1,0.2] call BIS_fnc_selectRandom)];
										_shide
									} else { _shide } 
								}
							}
						};
		} forEach _spotters;
		
	
		_spotted = _group getVariable ["spotted", []];
		if ( !_shide ) then {
			_spotted pushBackUnique _enemy;
			_group setVariable ["spotted", _spotted];
			_hide = false;
		} else {
			_group setVariable ["spotted", _spotted - [_enemy]];
		};
	} forEach _groups;
	_hide
};
