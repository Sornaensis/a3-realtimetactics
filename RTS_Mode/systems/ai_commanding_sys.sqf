/*

	AI Commander 

:Overview of basic algorithm

- Assign Garrison forces within side and global objectives
- - Garrison forces are tasked with defending and may not support other units
- Forces outside of any objective are marked as reserves and tasked individually afterwards
- - Reserve forces are initially tasked with patrolling a random objective within 300m, at
	3.5x the objective's radius. They are also marked for support.


::Tasking and Priorities

The AI system shall prefer attaining its own goals before attempting to deny the
player's goals. e.g. If an AI commander controls all of his occupy/clear objectives,
he will begin attacking enemy objectives.

::Defense

The AI will retask reserve groups first and then assaulting groups to defend
objectives that come under attack. The AI will attempt to keep 20% of its forces
in reserve if possible at the beginning of the mission.

:AI Dispositions

For certain missions it is helpful to assign AI dispositions for forces,
to fine tune their priorities and behaviours.

::Attack

The AI will prioritize enemy objectives and enemy casualties.

::Defense

The AI will prioritize friendly objectives and global objectives.
The AI will not attack enemy objectives.

*/

setupAsGarrison = {
	params ["_group", "_marker", "_radius"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["opfor_status", "GARRISON"];
	_group setVariable ["opfor_objective", _marker];
	[_group, getMarkerPos _marker, _radius, 2, 0.7, 0.6 ] call CBA_fnc_taskDefend;
	_group setVariable ["VCM_NOFLANK",true];
	_group setVariable ["VCM_NORESCUE",true];
};

setupAsPatrol = {
	params ["_group", "_marker", "_radius"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["opfor_status", "PATROL"];
	_group setVariable ["opfor_objective", _marker];
	[_group, getMarkerPos _marker, _radius, 7, "MOVE", "SAFE", "RED", "NORMAL"] call CBA_fnc_taskPatrol;
	_group setVariable ["VCM_NOFLANK",false];
	_group setVariable ["VCM_NORESCUE",false];
};

doCounterAttack = {
	params ["_group", "_marker", "_radius"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["opfor_status", "COUNTER-ATTACK"];
	_group setVariable ["opfor_objective", _marker];
	
	if ( vehicle (leader _group) != leader _group ) then {
		[_group, getMarkerPos _marker, _radius, 7, "MOVE", "COMBAT", "RED", "FULL"] call CBA_fnc_taskPatrol;
	} else {
		[_group, getMarkerPos _marker, _radius] call CBA_fnc_taskAttack;
	};
	_group setVariable ["VCM_NOFLANK",false];
	_group setVariable ["VCM_NORESCUE",true];
};

waitUntil { RTS_objectivesSetupInitial };

RTS_enemyGroups = [];
RTS_enemyTotalStrength = 0;

{
	if ( count (_x getVariable ["RTS_setup", []]) > 0 ) then {
		RTS_enemyGroups pushbackunique _x;
		RTS_enemyTotalStrength = RTS_enemyTotalStrength + (count (units _x));
	};
} forEach ( allGroups select { side _x == RTS_sideEnemy } );

private _leaders = [RTS_enemyGroups, { leader _x }] call CBA_fnc_filter;

{
	RTS_enemySideObjectives pushback _x;
} forEach RTS_allSidesObjectives;


// First setup garrisons of troops
private _occupy = [];

{
	_occupy pushback _x;
} forEach ( RTS_enemySideObjectives select { (_x select 0) == "occupy" || (_x select 0) == "clear" } );

{
	_x params ["", "_marker"];
	(getMarkerSize _marker) params ["_mx","_my"];
	{
		private _group = group _x;
		[ _group, _marker, _mx max _my ] call setupAsGarrison;
	} forEach ( _leaders select { _x inArea _marker } );	
	
} forEach _occupy;

{
	private _group = _x;
	if ( (_group getVariable ["opfor_status",objnull]) isEqualTo objnull ) then {
		_group setVariable ["opfor_status", "RESERVE" ];
	};
} forEach RTS_enemyGroups;

waitUntil { RTS_phase == "MAIN" };

totalStrength = {
	(RTS_enemyGroups select { count ( (units _x) select { alive _x } ) > 0 } )
};

reserveGroups = {
	( (call totalStrength) select { (_x getVariable ["opfor_status",""]) == "RESERVE" } )
};

sum_list = {
	private _ret = 0;
	{
		_ret = _ret + _x;	
	} forEach _this;	
	
	_ret
};

/*
	Objective statuses:
		- HELD // we have troops present and no enemies
		- CLEAR // no enemies present, neither our troops
		- UNDER ATTACK // our garrison troops are aware of enemies, and enemies are within 3x the radius of the objective of those units
		- NOT HELD // we have no troops present
		- COMPLETE // objective is considered finished
		- NOT COMPLETE // objective that is not completed
*/

assessObjective = {
	params ["_type","_marker","","_complete"];
	
	private _obj = _this;
	(getMarkerSize _marker) params ["_mx","_my"];
	private _radius = _mx max _my;
	private _status = "NOT HELD";
	
	private _troops = RTS_enemyGroups select { (_x getVariable "opfor_objective") == _marker };
	
	switch ( _type ) do {
		case "occupy": {
			// Do we know about nearby enemy units?
			private _underAttack = false;
			{
				private _unit = leader _x;
				{
					if ( (_unit knowsAbout _x) > 1.5 ) then {
						_underAttack = true;
					};
				} forEach (allUnits select { side _x == RTS_sidePlayer && ((getPos _x) distance2d (getPos _unit)) < _radius*2 });
				if ( _underAttack ) exitWith { _status = "UNDER ATTACK"; };				
			} forEach (_troops select { ((getPos (leader _x)) distance2d (getMarkerPos _marker)) < _radius*3 });
			
			if ( _status == "UNDER ATTACK" ) exitWith { _status };
			
			private _hasTroops = count _troops > 0;
			if ( _hasTroops && count (allUnits select { side _x == RTS_sidePlayer && ((getPos _x) distance2d (getMarkerPos _marker)) < _radius }) > 0 ) then {
				_status = "NOT HELD";
			} else {
				if ( !_hasTroops ) then {
					_status = "NOT HELD";
				} else {
					_status = "HELD";
				};
			};
		};
		case "clear": {
			// Do we know about nearby enemy units?
			private _underAttack = false;
			{
				private _unit = leader _x;
				{
					if ( (_unit knowsAbout _x) > 0.9 ) then {
						_underAttack = true;
					};
				} forEach (allUnits select { side _x == RTS_sidePlayer && ((getPos _x) distance2d (getPos _unit)) < _radius*3 });
				if ( _underAttack ) exitWith { _status = "UNDER ATTACK"; };				
			} forEach (_troops select { ((getPos (leader _x)) distance2d (getMarkerPos _marker)) < _radius*3 });
			
			if ( _status == "UNDER ATTACK" ) exitWith { _status };
			
			private _hasTroops = count _troops > 0;
			if ( _hasTroops && count (allUnits select { side _x == RTS_sidePlayer && ((getPos _x) distance2d (getMarkerPos _marker)) < _radius }) > 0 ) then {
				_status = "NOT HELD";
			} else {
				if ( count (allUnits select { side _x == RTS_sidePlayer && ((getPos _x) distance2d (getMarkerPos _marker)) < _radius }) > 0 ) then {
					_status = "NOT HELD";
				} else {
					_status = "CLEAR";
				};
			};
		};
		case "touch": {
			if ( !_complete ) then {
				private _inarea = _troops select { count ( (units _x) select { _x inArea _marker} ) > 0 };
				if ( count _inarea > 0 ) then {
					_obj set [3, true];
					_status = "COMPLETE";
				} else {
					_status = "NOT COMPLETE";
				};
			} else {
				_status = "COMPLETE";
			};
		};
	};		
	
	
	_status
};


// About 20% reserves to start, then task counterattacks and such from there
RTS_targetReserveCoeff = 20;

RTS_counterAttacks = [];

counterAttack = {
	params ["","_marker"];
		
	private _attacks = RTS_counterAttacks select { (_x select 0) == _marker };
	
	if ( count _attacks > 0 ) then {
		private _attack = _attacks select 0;
		private _attackTime = _attack select 1;
		
		if ( time > (_attackTime + 60) ) then { 
			_attack set [1, time];
			(getMarkerSize _marker) params ["_mx","_my"];
			private _radius = (_mx max _my) * 1.5;
			private _troops = RTS_enemyGroups select { (_x getVariable ["opfor_status",""]) == "RESERVE" };
			if ( count _troops == 0 ) then {
				private _troops = RTS_enemyGroups select { (_x getVariable ["opfor_status",""]) == "PATROL" };
			};
			
			if ( count _troops > 0 ) then {
				private _group = selectRandom _troops;
				[_group, _marker, _radius] call doCounterAttack;
			};
		};
	} else {
		(getMarkerSize _marker) params ["_mx","_my"];
		private _radius = (_mx max _my) * 1.5;
		private _troops = RTS_enemyGroups select { (_x getVariable ["opfor_status",""]) == "RESERVE" };
		if ( count _troops == 0 ) then {
			private _troops = RTS_enemyGroups select { (_x getVariable ["opfor_status",""]) == "PATROL" };
		};
		if ( count _troops > 0 ) then {
			private _group = selectRandom _troops;
			[_group, _marker, _radius] call doCounterAttack;
			RTS_counterAttacks pushback [_marker, time];
		};
	};
};

RTS_ai_commander = [] spawn  {
	while { true } do {
		// Assess our own objectives for attacks

		private _incompleteObjectives = ( [RTS_enemySideObjectives, { [_x, _x call assessObjective ] }] call CBA_fnc_filter ) 
										select {
													private _val = _x select 1;
													( _val == "UNDER ATTACK" || _val == "NOT HELD" || _val == "NOT COMPLETE" )
												};
		
		// focus on incomplete objectives
		if ( count _incompleteObjectives > 0 ) then {
			// focus on attacks
			private _attackPriorities = _incompleteObjectives select { (_x select 1) == "UNDER ATTACK" };
			
			{
				(_x select 0) call counterAttack;
			} forEach _attackPriorities;
			
			if ( count _attackPriorities == 0 ) then {
				private _defendPriorities = _incompleteObjectives select { (_x select 1) == "NOT HELD" };
				{
					(_x select 0) call counterAttack;
				} forEach _defendPriorities;
			};
			
		};
		
	
		// Task excess reserves when we have no other concerns
		private _reserveGroups = call reserveGroups;
		private _totalGroups = call totalStrength;
		
		private _reserveUnits = ([_reserveGroups, { count (units _x) }] call CBA_fnc_filter) call sum_list;
		private _totalUnits = ([_totalGroups, { count (units _x) }] call CBA_fnc_filter) call sum_list;
		
		private _reserveCoeff = floor ( _reserveUnits / (_totalUnits max 1) * 100 );
		
		if ( _reserveCoeff >= RTS_targetReserveCoeff ) then {
			private _taskGroup = selectRandom _reserveGroups;
			
			private _strength = count (units _taskGroup);
			
			if ( (floor ( (_reserveUnits - _strength) / (_totalUnits max 1) * 100 )) >= RTS_targetReserveCoeff ) then {
					
				private _nearestObj = [leader _taskGroup, [RTS_enemySideObjectives,{_x select 1}] call CBA_fnc_filter] call CBA_fnc_getNearest;
				
				( [ getMarkerSize _nearestObj,{ _x * 2.2 }] call CBA_fnc_filter ) params ["_mx","_my"];
						
				[_taskGroup, _nearestObj, _mx max _my] call setupAsPatrol;			
			};
		};	
		
		sleep 8;
	};
};