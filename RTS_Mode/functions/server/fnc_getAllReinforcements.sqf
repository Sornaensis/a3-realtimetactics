params ["_side"];

private _setups = [];

private _sideName = ( switch ( _side ) do {
					case west: { "blufor" };
					case east: { "opfor" };
					case resistance: { "greenfor" };
				});

for "_i" from 1 to 40 do {
	private _reinfVar = missionNameSpace getVariable [ format ["RTS_reinf_%1", _sideName, _i], []];
	if ( count _reinfVar > 0 ) then {
		_reinfVar params ["_logic", "_side", "_wave", "_type", "_time" ];
		_setups pushback [ [ _side, _wave, _type, _time ], _logic ];		
	};
};

if ( count _setups == 0 ) exitWith { [] };

private _reinforcementWaves = [];
private _numberOfWaves = 0;

{
	_x params ["_setup"];
	_numberOfWaves = _numberOfWaves max (_setup select 1);
} forEach _setups;

for "_i" from 1 to _numberOfWaves do {
	_reinforcementWaves pushback [
									"", // Type
									-1, // Time
									[]  // Unit data
								];
};

// Setup formation data for reinforcements
{
	_x params ["_setup","_logic"];
	
	_setup params ["_side","_waveNo","_type","_time"];
	
	private _wave = _reinforcementWaves select (_waveNo-1);
	
	_wave params ["_waveType","_waveTime","_unitData"];
	
	if ( _waveType == "" ) then {
		_wave set [0, _type];
	};
	
	if ( _waveTime == -1 ) then {
		_wave set [1, _time];
	};
	
	private _groups = ([synchronizedObjects _logic, { group _x }] call CBA_fnc_filter); 
		
	/*
		Reinforcement unit data structure
		
		
		[ group,
			RTS_setup,
			[ vehicleType, vehiclePos, vehicleDir, weaponCargo, magazineCargo ],
			[ leaderPos, leaderDir, leaderUnit, leaderLoadout, leaderVehiclePosInfo ],
			[ [ unit1Pos, unit1Dir, unit1Unit, unit1Loadout, unit1VehiclePosInfo ],
				...
			]
		]
	*/
	
	{
		private _group = _x;
		
		private _leader = leader _group;
				
		private _vehicleData = [];
		
		if ( vehicle _leader != _leader ) then {
			private _vehicle = vehicle _leader;
			_vehicleData = [
							typeOf _vehicle, getPosATL _vehicle, getDir _vehicle,
							getWeaponCargo _vehicle, getMagazineCargo _vehicle
						   ];
		};
		
		private _leaderData = [
								getPosATL _leader, getDir _leader, typeOf _leader, getUnitLoadout _leader, assignedVehicleRole _leader
							  ];
		
		private _otherUnitData = [];
		
		{
			if ( _x != _leader ) then {
				private _unit = _x;
				private _data = [ getPosATL _unit, getDir _unit, typeOf _unit, getUnitLoadout _unit, assignedVehicleRole _unit ];
				_otherUnitData pushback _data;
			};
		} forEach (units _group);
		
		private _setup = +(_group getVariable ["RTS_Setup", []]);
		_group setVariable ["RTS_setup",[]];
		
		private _groupData = [	
								_group,
								_setup,
								_vehicleData,
								_leaderData, 
								_otherUnitData 
							 ];
		
		_unitData pushback _groupData;
		
	} forEach _groups;
	
	
} forEach _setups;

// Re-setup hierarchy info

{
	_x params ["_setup","_logic"];
	
	_setup params ["_side","_waveNo","_type","_time"];
	
	private _wave = _reinforcementWaves select (_waveNo-1);
	_wave params ["_waveType","_waveTime","_unitData"];
	
	
	private _groupmap = [];
	
	{
		_x params ["_group","_setup"];
		_groupMap pushback [_group,_forEachIndex];
	} forEach _unitData;
	
	{
		_x params ["_group","_setup"];
		_setup params ["","","_commander"];

		if ( !(isNil "_commander") ) then {
			private _leaderindex = -1;
			{
				_x params ["_group","_index"];
				if ( _group isEqualTo _commander ) then {
					_leaderindex = _index;
				};
			} forEach _groupmap;
			_setup set [2, _leaderindex];
		};
		
		
	} forEach _unitData;

	
} forEach _setups;

{
	_x params ["_setup","_logic"];
	
	deleteVehicle _logic;
	
	_setup params ["_side","_waveNo","_type","_time"];
	
	private _wave = _reinforcementWaves select (_waveNo-1);
	_wave params ["_waveType","_waveTime","_unitData"];
	
	{
		_x params ["_group"];
		{
			private _unit = _x;
			private _veh = vehicle _x;
			
			if ( _veh != _unit ) then {
				deleteVehicle _veh;
			};
			
			deleteVehicle _unit;
		} forEach (units _group);
	} forEach _unitData;
	
} forEach _setups;


_reinforcementWaves