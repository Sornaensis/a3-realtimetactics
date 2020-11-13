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
				private _group = _x;
				private _units = units _group;
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
		
					private _near = _units select { ((_x knowsAbout (vehicle _enemy)) max (_x knowsAbout _enemy)) > 0.5 && ((getPos _x) distance (getPos _enemy)) < 2000 && !(terrainIntersect [eyePos _x, eyePos _enemy]) };
					if ( count _near > 0 ) then {
						(vehicle _enemy) setVariable ["spottedbyselectedgroup", grpnull];
						[_enemy, _near] call RTS_fnc_spotting;
					};
				} forEach _enemies;
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


RTS_fnc_spotting = {
	params ["_enemy","_spotters"];
	_hide = true;

	private _groups = [];
	private _enemyPos = eyePos _enemy;
	_shide = true;
	{
		private _xPos = eyePos _x;
		private _spotDistMax = ( if ( (vehicle _x) isKindOf "TANK" ) then { 2000 } else { 1000 } );
		private _distance = [vehicle _x, vehicle _enemy] call CBA_fnc_getDistance;
		private _knowsAbout = (_x knowsAbout (vehicle _enemy)) max (_x knowsAbout _enemy);
		
		if ( _distance < _spotDistMax && _knowsAbout > 0.5 ) then {
	
			private _infrontOf = [vehicle _x, vehicle _enemy] call BIS_fnc_isInFrontOf; 
			
			if ( _infrontOf ) then {
					private _visibility = [vehicle _x, "VIEW", vehicle _enemy] checkVisibility [_xPos, _enemyPos];		
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
								0.95
							}
						}
					} ); 
				
				private _weSpotted = false;
				
				// True to hide False to show
				if (_knowsAbout > 1.2 && _visibility > _spottingThreshold*0.9 ) then { 
					_groups pushbackunique (group _x);
				} else {
					if ( _knowsAbout > 0.7 && _visibility > _spottingThreshold ) then { 
						_groups pushbackunique (group _x);
					} else { 
						if ( _knowsAbout > 0.5 && _visibility > _spottingThreshold*1.2 ) then { 
							_groups pushbackunique (group _x);
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