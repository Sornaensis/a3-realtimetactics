// Full Scenario Logic

JTF_fnc_reviveGroups = {
	params ["_waveNum"];
	
	private _groups = allGroups select { ((_x getVariable [ "WaveInfo", ["",-1] ]) select 1) == _waveNum };
	
	{
		private _grp = _x;
		{
			(vehicle _x) hideObjectGlobal false;
			(vehicle _x) enableSimulationGlobal true;
			_x hideObjectGlobal false;
			_x enableSimulationGlobal true;
		} forEach ( units _grp);
	} forEach _groups;
	
	private _attackMrks = [];
	private _defendMrks = [];
	private _patrolMrks = [];
	
	{
		_x params [ "_mrkName", "_mrkList" ];
		for "_i" from 1 to ( (count _groups) * 2 ) do {
			private _mrk = format ["%1_%2_%3", _mrkName, _waveNum, _i ];
			
			if ( !( (getMarkerPos _mrk) isEqualTo [0,0,0] ) ) then {
				_mrkList pushBack _mrk;
			};
		};
	} forEach [ ["attack", _attackMrks], ["defend", _defendMrks], ["patrol", _patrolMrks] ];
	
	{
		private _grp = _x;
		
		private _mrk = selectRandom _attackMrks;
		private _pos = [ (getMarkerPos _mrk), 25 ] call CBA_fnc_randPos;
		private _radius = 75 + ( random 25 );
		
		[_grp] call CBA_fnc_clearWaypoints;
		[_grp, _pos, _radius] call CBA_fnc_taskAttack;
		
	} forEach ( _groups select { ((_x getVariable "WaveInfo") select 0) == "Attack" } );
	
	{
		private _grp = _x;
		
		private _mrk = selectRandom _defendMrks;
		private _pos = [ (getMarkerPos _mrk), 10 ] call CBA_fnc_randPos;
		private _radius = 60;
		
		[_grp] call CBA_fnc_clearWaypoints;
		[ _grp, _pos, _radius, 3, 0.4, 0.35 ] call CBA_fnc_taskDefend;
		
	} forEach ( _groups select { ((_x getVariable "WaveInfo") select 0) == "Defend" } );
	
	{
		private _grp = _x;
		
		private _mrk = selectRandom _patrolMrks;
		private _pos = [ (getMarkerPos _mrk), 0 ] call CBA_fnc_randPos;
		private _radius = 150 + ( random 45 );
		
		[_grp] call CBA_fnc_clearWaypoints;
		[ _grp, _pos, _radius, 9, "MOVE", "AWARE", "RED", "FULL", "STAG COLUMN", "this call CBA_fnc_searchNearby", [3, 6, 9]] call CBA_fnc_taskPatrol;
		
	} forEach ( _groups select { ((_x getVariable "WaveInfo") select 0) == "Patrol" } );
	
	
};

private _military = ["clear1"] call JTF_completeTask_keep;

waitUntil { scriptDone _military };

sleep 10;

BOZ_captured_military_complex = true;

[1] call JTF_fnc_reviveGroups;

private _yarum = ["occupy0"] call JTF_completeTask_keep;

waitUntil { scriptDone _yarum || triggerActivated wave_2_trigger };

[2] call JTF_fnc_reviveGroups;