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
	[_group, getMarkerPos _marker, _radius, 2, 0.5, 1 ] call CBA_fnc_taskDefend;
	_group setVariable ["VCM_NOFLANK",true];
	_group setVariable ["VCM_NORESCUE",true];
};

setupAsPatrol = {
	params ["_group", "_marker", "_radius"];
	[_group] call CBA_fnc_clearWaypoints;
	_group setVariable ["opfor_status", "PATROL"];
	[_group, getMarkerPos _marker, _radius, 7, "MOVE", "CARELESS", "RED", "NORMAL"] call CBA_fnc_taskPatrol;
	_group setVariable ["VCM_NOFLANK",false];
	_group setVariable ["VCM_NORESCUE",false];
};

waitUntil { RTS_objectivesSetupDone };

RTS_enemyGroups = [];

{
	if ( count (_x getVariable ["RTS_setup", []]) > 0 ) then {
		RTS_enemyGroups pushback _x;
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

// About 20% reserves to start, then task counterattacks and such from there
RTS_targetReserveCoeff = 20;

RTS_ai_commander = [] spawn  {
	while { true } do {
		private _reserveGroups = call reserveGroups;
		private _totalGroups = call totalStrength;
		
		private _reserveCoeff = floor ( (count _reserveGroups) / ( (count _totalGroups) max 1 ) * 100 );
		
		// Dole groups out to objectives
		if ( _reserveCoeff >= RTS_targetReserveCoeff ) then {
			private _taskGroup = selectRandom _reserveGroups;
			
			private _nearestObj = [leader _taskGroup, [RTS_enemySideObjectives,{_x select 1}] call CBA_fnc_filter] call CBA_fnc_getNearest;
			
			( [ getMarkerSize _nearestObj,{ _x * 3.5 }] call CBA_fnc_filter ) params ["_mx","_my"];
			
			// TODO: Assess task state			
			[_taskGroup, _nearestObj, _mx max _my] call setupAsPatrol;			
		};	
		
		sleep 10;
	};
};