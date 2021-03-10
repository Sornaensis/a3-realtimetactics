INS_cqbStarted = false;
publicVariable "INS_cqbStarted";

INS_cqbArea = "CQB Zone";
publicVariable "INS_cqbArea";
INS_cqbStarting = false;

INS_cqbDensity = [true,0.4,false,0.6]; // 40% of positions will have a soldier

INS_getCqbSoldiersAlive = {
	(allUnits) select { (alive _x) && (_x getVariable ["cqb_soldier", false]) };
};

INS_getCqbSoldiers = {
	(allUnits + allDeadMen) select { _x getVariable ["cqb_soldier", false] };
};

INS_startCqbTraining = {
	if ( INS_cqbStarting || INS_cqbStarted ) exitWith {};
	INS_cqbStarting = true;
	INS_cqbStarted = true;
	publicVariable "INS_cqbStarted";
	
	private _cqbPos = getMarkerPos INS_cqbArea;
	(getMarkerSize INS_cqbArea) params ["_mx","_my"];
	private _cqbSize = (_mx max _my);
	
	private _buildings = (_cqbPos nearObjects ["HOUSE", _cqbSize]) select { count (_x buildingPos -1) > 0 && _x inArea INS_cqbArea };
	
	private _positions = _buildings apply { _x buildingPos -1 }; // get all positions;
	
	private _allPositions = [];
	
	{
		private _bpos = _x;
		{
			_allPositions pushback _x;
		} forEach _bpos;
	} forEach _positions;
	
	{
		private _pos = _x;
		private _above = +_pos;
		private _checkPos = +_pos;
		_above set [2, (_above # 2) + 20];
		_checkPos set [2, (_checkPos # 2) + 1.7];
		
		private _isRoofTop = ([objnull, "VIEW"] checkVisibility [AGLToASL _checkPos, AGLToASL _above]) > 0;
		
		private _spawn = selectRandomWeighted INS_cqbDensity;
		if ( !_isRoofTop && _spawn ) then {
			private _group = createGroup east;
			private _setup = selectRandom (selectRandom INS_squadSetups);
			_setup params ["_type",""];
			private _soldier = _group createUnit [_type, [0,0,0], [], 0, "NONE"];
			_group setVariable ["Experience", "ELITE"];
			_soldier setPosATL _pos;
			_soldier call RTS_fnc_aiSkill;
			_soldier disableAI "PATH";
			_soldier disableAI "FSM";
			_soldier setVariable ["cqb_soldier", true];
			_solider setUnitPos "MIDDLE";
			_soldier setUnitPosWeak "MIDDLE";
			_group deleteGroupWhenEmpty true;
		};
	} forEach _allPositions;
	
	[-1,
	{
		if ( !hasInterface ) exitWith {};
		if ( side (group player) != west ) exitWith {};
		titleText ["CQB Training has started withing the CQB Zone!", "PLAIN"];
	}] call CBA_fnc_globalExecute;
	
	INS_cqbStarting = false;
	
	[] spawn {
		waitUntil { sleep 1; count (call INS_getCqbSoldiersAlive) == 0 || !INS_cqbStarted };
		INS_cqbStarted = false;
		publicVariable "INS_cqbStarted";
		[-1,
		{
			if ( !hasInterface ) exitWith {};
			if ( side (group player) != west ) exitWith {};
			titleText ["CQB Training has concluded.", "PLAIN"];
		}] call CBA_fnc_globalExecute;
		sleep 10;
		{
			deleteVehicle _x;
		} forEach (call INS_getCqbSoldiers);
	};
	
};

INS_cqbAreaReveal = [] spawn {
	while { true } do {
		waitUntil { INS_cqbStarted };
		
		while { INS_cqbStarted } do {
			{
				private _player = _x;
				{
					private _unit = _x;
					if ( (_unit knowsAbout _player) < 2.5 ) then {
						_unit reveal [ _player, 2.5 ];
					};
				} forEach ( (call INS_getCqbSoldiersAlive) select { ( (getPos _x) distance2d (getPos _player) ) < 100 } );
			} forEach ( (call INS_allPlayers) select { _x inArea INS_cqbArea } );
			sleep 5;
		};
	};
};