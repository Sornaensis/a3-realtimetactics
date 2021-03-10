#include "../RTS_defines.hpp"

waitUntil { RTS_phase == "MAIN" };

RTS_cmdr = objnull;
if ( !isNil "RTS_commanderUnit" ) then {
	RTS_cmdr = RTS_commanderUnit;
};

RTS_opfor_units = allUnits select { simulationEnabled _x && _x != RTS_cmdr && side _x != civilian && !( (group _x) in RTS_commandingGroups ) };

RTS_revealSpotted = {
	RTS_cmdr = objnull;
	if ( !isNil "RTS_commanderUnit" ) then {
		RTS_cmdr = RTS_commanderUnit;
	};
	if ( RTS_commanding && !RTS_godseye ) then {
		private _opfor = RTS_opfor_units;
		{
			private _spots = _x;
			{
				_x hideObject false;
				(vehicle _x) hideObject false;
				_opfor = _opfor - [_x];
			} forEach _spots;
		} forEach (RTS_commandingGroups apply { _x getVariable ["spotted",[]] });
		
		{
			(vehicle _x) hideObject true;
			_x hideObject true;
		} forEach _opfor;
		
		_opfor_vehicles = [];
		{
			if ( simulationEnabled _x && count ((crew _x) select { alive _x } ) == 0 ) then {
				_x hideObject false;
			} else {
				_opfor_vehicles pushback _x;
			};
		} forEach RTS_opfor_vehicles;
		RTS_opfor_vehicles = _opfor_vehicles;
		_greenfor_vehicles = [];
		{
			if ( simulationEnabled _x && count ((crew _x) select { alive _x } ) == 0 ) then {
				_x hideObject false;
			} else {
				_greenfor_vehicles pushback _x;
			};
		} forEach RTS_greenfor_vehicles;
		RTS_greenfor_vehicles = _greenfor_vehicles; 
	};
};

// OPFOR check if they are spotted
RTS_spottingLoop = [] spawn {
	while {true} do {
		if ( RTS_commanding && !RTS_godseye ) then {
			private _enemies = RTS_opfor_units;
			{
				private _grp = _x;
				private _current = (_grp getVariable ["los_task", scriptNull]);
				if ( scriptDone _current || isNull _current ) then {
					private _script = ( [_grp,_enemies] spawn {
						params ["_group", "_enemies" ];
						private _leader = leader _group;
						private _veh = vehicle _leader;
						private _spotDistMax = ( if ( _veh isKindOf "TANK" ) then { 2000 } else { ( if ( _veh isKindOf "MAN" ) then { 1000 } else { 1500 } ) } );
						private _units = units _group;
						private _spotters = [];
						{
							private _enemy = _x;
							if ( ((vehicle _enemy) != _enemy) ) then {
								if ( side _enemy == RTS_sideEnemy ) then {
									RTS_opfor_vehicles pushBackUnique (vehicle _enemy);
								} else {
									if ( side _enemy == RTS_sideGreen || side _enemy == RTS_sidePlayer ) then {
										RTS_greenfor_vehicles pushBackUnique (vehicle _enemy);
									};
								};
							};
				
							private _near = _units select { !(terrainIntersectASL [eyePos _x, eyePos _enemy]) && (time - (_x getVariable ["last_spot",0])) > 8 };
							if ( count _near > 0 ) then {
								{
									_spotters pushbackunique _x;
								} forEach _near;
								(vehicle _enemy) setVariable ["spottedbyselectedgroup", grpnull];
								[_enemy, _near] call RTS_fnc_spotting;
							} else {
								private _spotted = _group getVariable ["spotted", []];
								_spotted deleteAt (_spotted find _enemy);
							};
						} forEach ( _enemies select { ((getPos _x) distance (getPos _leader)) < _spotDistMax } );
						{
							_x setVariable ["last_spot", time];
						} forEach _spotters;
						if ( count _spotters > 0 ) then {
							_group setVariable ["spotting_cycle_count", (_group getVariable ["spotting_cycle_count",0]) + 1 ];
						};
					});
					_grp setVariable ["los_task", _script];
				};
			} forEach RTS_commandingGroups;
		} else {
			{
				(vehicle _x) hideObject false;
				_x hideObject false;
			} forEach (allUnits select { simulationEnabled _x });
			{
				_x hideObject false;
			} forEach ( RTS_opfor_vehicles select { simulationEnabled _x } );
			{
				_x hideObject false;
			} forEach ( RTS_greenfor_vehicles select { simulationEnabled _x } );
		};
	};
};

RTS_reveal_deadMen = [] spawn {
	while { true } do {
		{
			_x hideObject false;
			(vehicle _x) hideObject false;
		} forEach allDeadMen;
		
		RTS_opfor_units = allUnits select { simulationEnabled _x && _x != RTS_cmdr && side _x != civilian && !( (group _x) in RTS_commandingGroups ) };
		
		sleep 5;
	};
};

/*
	RTS spotting helper functions
*/

RTS_enemyCoeff = {
	params ["_enemy"];
	
	private _veh = vehicle _enemy;
	private _coeff = 0.3; // Infantry are hard to spot
	
	if ( _veh != _enemy ) then {
		if ( _veh isKindOf "Tank" ) then {
			_coeff = 3.1;
		} else {
			if ( _veh isKindOf "APC" ) then {
				_coeff = 2.3;
			} else {
				if ( _veh isKindOf "Car" ) then {
					_coeff = 1.1;
				} else {
					if ( _veh isKindOf "StaticWeapon" ) then {
						_coeff = 0.7;
					};
				};
			};
		};
	};
	
	_coeff
};

RTS_spottingCoeff = {
	params ["_unit", "_distance"];
	
	private _thermal = _unit getVariable ["has_thermals", false];	
	
	// binoculars, rangefinders, vehicle optics, weapon optics, etc.
	private _opticQuality = _unit getVariable ["optic_quality", 1];
	private _grpveh = (group _x) getVariable ["owned_vehicle", objnull];
	
	private _speedCoeff = 1 max (speed (vehicle _x));
	
	if ( !isNull _grpveh ) then {
		if ( (vehicle _x) != _grpveh ) then {
			_opticQuality = 1;
		} else {
			_speedCoeff = (_speedCoeff / _opticQuality) max 1;
		};
	};
	
	private _range = 300 * _opticQuality * ( if ( _thermal ) then { 3 } else { 1 } );
	
	( ( if ( _thermal ) then { 3 } else { 2 } ) - (_distance / ( _range max 1 ) ) ) max 0.01
	
};


////////////////////////

RTS_fnc_spotting = {
	params ["_enemy","_spotters"];
	_hide = true;

	private _groups = [];
	private _enemyPos = eyePos _enemy;
	_shide = true;
	{
		private _xPos = eyePos _x;
		private _spotDistMax = ( if ( (vehicle _x) isKindOf "TANK" ) then { 3000 } else { ( if ( (vehicle _x) isKindOf "MAN" ) then { 1000 } else { 1500 } ) } );
		private _distance = [vehicle _x, vehicle _enemy] call CBA_fnc_getDistance;
		private _knowsAbout = (_x knowsAbout (vehicle _enemy)) max (_x knowsAbout _enemy);
		private _veh = vehicle _x;
		private _leader = _x == (leader (group _x));
		private _canSpot = ( if ( _veh != _x ) then { !(driver _veh != _x && effectiveCommander _veh !=  _x && gunner _x != _x) } else { _leader || ( _distance < 600 ) } );
		
		if ( _distance < _spotDistMax && _canSpot ) then {
	
			private _infrontOf = 
				( 
					if ( (vehicle _x) == _x && (vehicle _enemy) == _enemy ) then { 
						[vehicle _x, vehicle _enemy] call BIS_fnc_isInFrontOf
					} else { true } );
			
			if ( _infrontOf || _distance < 250 ) then {
				
				private _spottingThreshold = (
					if ( _distance < 150 ) then {
						0.1
					} else {
						if ( _distance < 300 ) then {
							0.3
						} else {
							if ( _distance < 500 ) then {
								0.6
							} else {
								0.8
							}
						}
					} ); 
					
				if ( _knowsAbout > 0.9 ) then {
					private _visibility = ( if ( !(((_x targetKnowledge (vehicle _enemy)) select 6) isEqualTo [0,0,0]) ) then {
												100 - (_x targetKnowledge (vehicle _enemy) select 5) 
											} else { 
												0 
											} 
										  );
					if (_knowsAbout > 2 && _visibility > _spottingThreshold*0.6 ) then { 
						_groups pushbackunique (group _x);
					} else {
						if ( _knowsAbout > 1.5 && _visibility > _spottingThreshold*0.9 ) then { 
							_groups pushbackunique (group _x);
						} else { 
							if ( _knowsAbout > 1 && _visibility > _spottingThreshold ) then { 
								_groups pushbackunique (group _x);
							};
						};
					};
				} else {
					if ( (random 1.0) > 0.5 ) then {
						private _visibility = [vehicle _x, "VIEW", vehicle _enemy] checkVisibility [_xPos, _enemyPos];		
						if ( _visibility > 0.9 ) then {
							private _unitCoeff = [_x, _distance] call RTS_spottingCoeff;
							private _spotCoeff = selectRandom [0.1,0.2,0.5,0.2,0.1,0.1,0.1,0.3,0.5,0.3];
							private _speedCoeff = 1 max (speed (vehicle _enemy));
							private _enemyCoeff = [_enemy] call RTS_enemyCoeff;
							_x setVariable ["last_spotted_info", [ "unit", _unitCoeff, 
																   "spot", _spotCoeff, 
																   "speed", _speedCoeff, 
																   "enemy", _enemyCoeff, 
																   "total", (_unitCoeff * _spotCoeff * _speedCoeff * _enemyCoeff)
																   ] ];
							(group _x) reveal [ (vehicle _enemy), _knowsAbout + (_unitCoeff * _spotCoeff * _speedCoeff * _enemyCoeff)  ];
						};
					};
				};
			};
		};
		
	} forEach _spotters;
	
	{
		private _group = _x;
		private _spotted = _group getVariable ["spotted", []];
		_spotted pushBackUnique _enemy;
		_group setVariable ["spotted", _spotted];
	} forEach _groups;
	
	{
		private _group = group _x;
		private _spots = _group getVariable ["spotted",[]];
		_spots deleteAt (_spots find _enemy);
	} forEach ( _spotters select { !( (group _x) in _groups ) } );
};

addMissionEventHandler ["Draw3D", RTS_revealSpotted];