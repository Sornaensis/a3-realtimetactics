INS_cqbStarted = false;
publicVariable "INS_cqbStarted";

INS_cqbArea = "CQB Zone";
publicVariable "INS_cqbArea";
INS_cqbStarting = false;

/** Server Setting **/
INS_cqbMinimum = 10;
INS_cqbUseArea = false;
INS_cqbDensity = [true,0.25,false,0.75]; // 45% of positions will have a soldier
INS_civChance  = [0,0.9,1,0.1]; // 1 in 5 are civ

/** Client Editable Setting **/
INS_civilians = false;
publicVariable "INS_civilians";
INS_shootBack = false;
publicVariable "INS_shootBack";

INS_getCqbSoldiersAlive = {
	(allUnits) select { (alive _x) && (_x getVariable ["cqb_soldier", false]) };
};

INS_getCqbSoldiers = {
	(allUnits + allDeadMen) select { _x getVariable ["cqb_soldier", false] };
};

INS_unitPositions = (allUnits select { _x getVariable ["CQB_pos", false] }) apply { getPosATL _x };

{
	deleteVehicle _x;
} forEach ( allUnits select { _x getVariable ["CQB_pos", false] } );

INS_startCqbTraining = {
	if ( INS_cqbStarting || INS_cqbStarted ) exitWith {};
	INS_cqbStarting = true;
	INS_cqbStarted = true;
	publicVariable "INS_cqbStarted";
	
	private _allPositions = [];
	if ( INS_cqbUseArea ) then {
		private _cqbPos = getMarkerPos INS_cqbArea;
		(getMarkerSize INS_cqbArea) params ["_mx","_my"];
		private _cqbSize = (_mx max _my);
		
		private _buildings = (_cqbPos nearObjects ["HOUSE", _cqbSize]) select { count (_x buildingPos -1) > 0 && _x inArea INS_cqbArea };
		
		private _positions = _buildings apply { _x buildingPos -1 }; // get all positions;
		
		{
			private _bpos = _x;
			{
				_allPositions pushback _x;
			} forEach _bpos;
		} forEach _positions;
	} else {
		_allPositions = [INS_unitPositions] call CBA_fnc_shuffle;
	};
	
	{
		private _pos = _x;
		private _isRoofTop = false;
		
		if ( INS_cqbUseArea ) then {
			private _above = +_pos;
			private _checkPos = +_pos;
			_above set [2, (_above # 2) + 20];
			_checkPos set [2, (_checkPos # 2) + 1.7];
			
			_isRoofTop = ([objnull, "VIEW"] checkVisibility [AGLToASL _checkPos, AGLToASL _above]) > 0;
		};
			
		private _spawn = (count (call INS_getCqbSoldiersAlive) < INS_cqbMinimum) || selectRandomWeighted INS_cqbDensity;
		if ( !_isRoofTop && _spawn ) then {
			private _group = createGroup east;
			private _setup = selectRandom ( if ( INS_civilians ) 
										then { [selectRandom INS_squadSetups,INS_spySetups] select (selectRandomWeighted INS_civChance) } 
										else { selectRandom INS_squadSetups } );
			_setup params ["_type","_loadout"];
			private _soldier = _group createUnit [_type, [0,0,0], [], 0, "NONE"];
			_soldier setVariable ["cqb_soldier", true];
			_soldier setPosATL _pos;
			_soldier disableAI "PATH";
			_soldier disableAI "FSM";
			_group setVariable ["Experience", "MILITIA"];
			_group setVariable ["LeaderFactor", -5];
			_group setVariable ["Vcm_disable", true];
			_soldier setUnitLoadout _loadout;
			_soldier call RTS_fnc_aiSkill;
			if ( !INS_shootback ) then {
				{
					_soldier removeMagazines _x;
				} forEach ( magazines _soldier );
				private _weapon = primaryWeapon _soldier;
				removeAllWeapons _soldier;
				_soldier addWeapon _weapon;
			};
			private _soldierPosture = selectRandomWeighted [ "MIDDLE", 1, "UP", 0.4 ];
			_soldier setUnitPos _soldierPosture;
			_soldier setUnitPosWeak _soldierPosture;
			_group deleteGroupWhenEmpty true;
		};
	} forEach _allPositions;
	
	[-1,
	{
		if ( !hasInterface ) exitWith {};
		if ( side (group player) != west ) exitWith {};
		titleText ["CQB Training has started within the CQB Zone!", "PLAIN"];
	}] call CBA_fnc_globalExecute;
	
	INS_cqbStarting = false;
	
	[] spawn {
		waitUntil { sleep 1; count (call INS_getCqbSoldiersAlive) == 0 };
		INS_cqbStarted = false;
		publicVariable "INS_cqbStarted";
		[-1,
		{
			if ( !hasInterface ) exitWith {};
			if ( side (group player) != west ) exitWith {};
			titleText ["CQB Training has concluded.", "PLAIN"];
		}] call CBA_fnc_globalExecute;
		{
			deleteVehicle _x;
		} forEach (call INS_getCqbSoldiers);
	};
	
};

if ( !INS_cqbUseArea ) then {
	INS_fixCqbAI = addMissionEventHandler["EachFrame",
	{
		{
			private _player = _x;
			{
				private _unit = _x;
				if ( ([objnull, "VIEW"] checkVisibility [eyePos _unit, eyePos _player]) != 1 ) then {
					_unit forgetTarget _player;
				};
			} forEach ( (call INS_getCqbSoldiersAlive) select { ( (getPos _x) distance2d (getPos _player) ) < 100 } );
		} forEach ( (call INS_allPlayers) select { _x inArea INS_cqbArea } );
	}];
};

INS_cqbAreaReveal = [] spawn {
	while { true } do {
		waitUntil { INS_cqbStarted && INS_shootback && INS_cqbUseArea };
		
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