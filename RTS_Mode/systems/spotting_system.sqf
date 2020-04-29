#include "../RTS_defines.hpp"

waitUntil { RTS_phase == "MAIN" };

RTS_revealSpotted = {
	private _opfor = allUnits select { (side _x == RTS_sideEnemy) || (side _x == RTS_sideGreen) };
	{
		private _spots = _x;
		{
			_x hideObject false;
			_opfor = _opfor - [_x];
		} forEach _spots;
	} forEach (RTS_commandingGroups apply { _x getVariable ["spotted",[]] });
	
	{
		_x hideObject true;
	} forEach _opfor;
};

// OPFOR check if they are spotted
RTS_spottingLoop = [] spawn { 
	while {true} do {
		if ( RTS_commanding && !RTS_godseye ) then {
			private _spotters = allUnits select { (group _x) in RTS_commandingGroups };
			{
				private _group = _x;
				{
					private _enemy = _x;
					if ( ((vehicle _enemy) != _enemy) ) then {
						if ( side _enemy == RTS_sideEnemy ) then {
							RTS_opfor_vehicles pushBackUnique (vehicle _enemy);
						} else {
							if ( side _enemy == RTS_sideGreen ) then {
								RTS_greenfor_vehicles pushBackUnique (vehicle _enemy);
							};
						};
					};
		
					(vehicle _enemy) setVariable ["spottedbyselectedgroup", grpnull];
					[_enemy, _spotters select { ((getPos _x) distance (getPos _enemy)) < 2000 && !(terrainIntersect [eyePos _x, eyePos _enemy]) }] call RTS_fnc_spotting;
				} forEach (units _group);
	
			} forEach ( allGroups select { (side _x == RTS_sideEnemy) || (side _x == RTS_sideGreen) } );
			_opfor_vehicles = [];
			{
				if ( count ((crew _x) select { alive _x } ) == 0 ) then {
					_x hideObject false;
				} else {
					_opfor_vehicles pushback _x;
				};
			} forEach RTS_opfor_vehicles;
			RTS_opfor_vehicles = _opfor_vehicles;
			_greenfor_vehicles = [];
			{
				if ( count ((crew _x) select { alive _x } ) == 0 ) then {
					_x hideObject false;
				} else {
					_greenfor_vehicles pushback _x;
				};
			} forEach RTS_greenfor_vehicles;
			RTS_greenfor_vehicles = _greenfor_vehicles; 
		} else {
			{
				(vehicle _x) hideObject false;
				_x hideObject false;
			} forEach (allunits select { side _x != RTS_sidePlayer } );
			{
				_x hideObject false;
			} forEach RTS_opfor_vehicles;
			{
				_x hideObject false;
			} forEach RTS_greenfor_vehicles;
		};
	};
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
	params ["_enemy","_spotters"];
	_hide = true;

	private _groups = [];
	private _enemyPos = eyePos _enemy;
	_shide = true;
	{
		private _xPos = eyePos _x;
		private _terrainBlocked = terrainIntersect [_xPos, _enemyPos];
		private _spotDistMax = ( if ( (vehicle _x) isKindOf "TANK" ) then { 2000 } else { 1000 } );
		private _distance = [vehicle _x, vehicle _enemy] call CBA_fnc_getDistance;
		
		if ( !_terrainBlocked && _distance < _spotDistMax ) then {
		
			private _visibility = [vehicle _x, "VIEW", vehicle _enemy] checkVisibility [_xPos, _enemyPos];
			private _dirTo = _x getRelDir _enemy;
			private _infrontOf = [vehicle _x, vehicle _enemy] call BIS_fnc_isInFrontOf; 
			private _knowsAbout = (_x knowsAbout (vehicle _enemy)) max (_x knowsAbout _enemy);
			
			// So, at 150 meters or less, any unit can be spotted even if they are just 10% visible
			// At 150-300 0.5
			// At 300-500 0.8
			private _spottingThreshold = (
				if ( _distance < 150 ) then {
					0.1
				} else {
					if ( _distance < 300 ) then {
						0.5
					} else {
						if ( _distance < 500 ) then {
							0.8
						} else {
							1
						}
					}
				} ); 
			
			if ( _infrontOf && !_terrainBlocked && _distance < _spotDistMax && _visibility > _spottingThreshold ) then {
				(group _x) reveal [_enemy, ( _knowsAbout + 0.1 ) max 4 ];
			};
			
			private _weSpotted = false;
			
			// True to hide False to show
			if (_knowsAbout > 0.7 && _visibility > _spottingThreshold*0.9 && !_terrainBlocked ) then { 
				_groups pushbackunique (group _x);
			} else {
				if ( _knowsAbout > 0.5 && _visibility > _spottingThreshold && !_terrainBlocked ) then { 
					_groups pushbackunique (group _x);
				} else { 
					if ( _knowsAbout > 0.2 && _visibility > _spottingThreshold*1.2 && !_terrainBlocked ) then { 
						_groups pushbackunique (group _x);
					} else {
						if ( _visibility > _spottingThreshold  && !_terrainBlocked && _infrontOf && _knowsAbout < 0.6 ) then {
							(group _x) reveal [_enemy, _knowsAbout + ([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.09,0.1,0.1,0.1,0.1,0.09,0.3,0.09,0.1,0.2] call BIS_fnc_selectRandom)];
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
		_group setVariable ["spotted",(_group getVariable ["spotted", []]) - [_enemy]];
	} forEach ( _spotters select { !( (group _x) in _groups ) } );
};

addMissionEventHandler ["Draw3D", RTS_revealSpotted];