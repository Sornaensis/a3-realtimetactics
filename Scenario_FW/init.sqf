if ( hasInterface ) then {
	disableUserInput true;
};

RTS_greenAI   = [["aimingAccuracy",0.09],["aimingShake",0.05],["aimingSpeed",0.25],["commanding",1],["courage",0.8],["endurance",0.7],["general",0.5],["reloadSpeed",1],["spotDistance",0.55],["spotTime",0.2]];

if ( isServer ) then {
	{
		_x setUnitLoadout (getUnitLoadout _x);
		if ( !(_x getVariable ["noskill", false]) ) then {
			private _unit = _x;
			{
				_x params ["_name","_val"];
				_unit setSkill [_name, _val];
			} forEach RTS_greenAi;
		};
		(group _x) setVariable ["Vcom_skilldisable", true];
	} forEach allUnits;
};

//VCOM setup
VCM_SKILLCHANGE = false;
VCM_AIMagLimit = 1; 
VCM_ACTIVATEAI = true;
VCM_SIDESPECIFICSKILL = true;
VCM_StealVeh = false;
VCM_ClassSteal = false;
VCM_CARGOCHNG = true;
VCM_TURRETUNLOAD = true;
VCM_DISEMBARKRANGE = 200;
VCM_AISNIPERS = false;
VCM_AISUPPRESS = true;
Vcm_DrivingActivated = true;
Vcm_PlayerAISkills = false;
VCM_AIDISTANCEVEHPATH = 150; 
VCM_ADVANCEDMOVEMENT = true;
VCM_FRMCHANGE = true;
VCM_SKILLCHANGE = true;

JTF_setupScripts = [];

// Used for setting up function definitions
JTF_setupFunction = {
	params ["_prefix", "_functions"];
	JTF_setupScripts pushBackUnique (_prefix + "\setup.sqf");
	{
		private _split = _x splitString "_";
		private _head = _split select 0;
		private _filename = [];
		for "_i" from 1 to ((count _split)-1) do {
			_filename set [count _filename, _split select _i];
		};
		_filename = _filename joinString "_";
		private _code = (format ["%1_%2 = compile preprocessFileLineNumbers ""%3\%2.sqf"";", _head, _filename, _prefix]);
		call (compile _code);
	} forEach _functions;
};

call compile preprocessFileLineNumbers "scen_fw\functions\server\setup.sqf";

/* Data for spawning waves */
JTF_unit_waves_blufor = [];
JTF_unit_waves_greenfor = [];
JTF_unit_waves_opfor = [];

if ( isServer ) then {
	JTF_unit_waves_blufor = [west] call JTF_fnc_setupAIWaves;
	JTF_unit_waves_greenfor = [resistance] call JTF_fnc_setupAIWaves;
	JTF_unit_waves_opfor = [east] call JTF_fnc_setupAIWaves;
};

JTF_wave_map = [];

JTF_fnc_getWaveGroups = {
	params ["_name"];
	
	private _groups = [];
	
	{
		_x params ["_wName","_wGroups"];
		if ( _name == _wName ) then {
			_groups = _wGroups;
		};
	} forEach JTF_wave_map;
	
	_groups
};

JTF_fnc_getWaveVehicles = {
	params ["_name"];
	
	private _vehicles = [];
	
	{
		_x params ["_wName","","_wVehicles"];
		if ( _name == _wName ) then {
			_vehicles = _wVehicles;
		};
	} forEach JTF_wave_map;
	
	_vehicles
};

JTF_fnc_flatten = {
	
	private _newArray = [];
	
	{
		private _arr = _x;
		{
			_newArray pushback _x;
		} forEach _arr;
	} forEach _this;
	
	_newArray
};

JTF_fnc_revealPlayers = {
	params ["_units","_accuracy"];
	{
		private _unit = _x;
		{
			private _player = _x;
			_unit reveal [ _player, _accuracy ];
		} forEach allPlayers;
	} forEach _units;
};

assignToVehicle = {
	params ["_vehicle", "_unit", "_info"];
		
	if ( count _info > 0 ) then {
	
		switch ( _info select 0 ) do {
			case "driver": {
				_unit assignAsDriver _vehicle;
				_unit moveInDriver _vehicle;	
			};
			case "Driver": {
				_unit assignAsDriver _vehicle;
				_unit moveInDriver _vehicle;	
			};
			case "Cargo": {
				if ( count _info > 1 ) then {
					_unit assignAsCargoIndex [ _vehicle, _info select 1];
					_unit moveInCargo [ _vehicle, _info select 1];
				} else {
					_unit assignAsCargo _vehicle;
					_unit moveInCargo _vehicle;
				};
			};
			case "Turret": {
				_unit assignAsTurret [ _vehicle, _info select 1 ];
				_unit moveInTurret [ _vehicle, _info select 1 ];
			};
			case "cargo": {
				if ( count _info > 1 ) then {
					_unit assignAsCargoIndex [ _vehicle, _info select 1];
					_unit moveInCargo [ _vehicle, _info select 1];
				} else {
					_unit assignAsCargo _vehicle;
					_unit moveInCargo _vehicle;
				};
			};
			case "turret": {
				_unit assignAsTurret [ _vehicle, _info select 1 ];
				_unit moveInTurret [ _vehicle, _info select 1 ];
			};
			default {
				hintSilent str _info;
			};
		};
	};
};

spawnReinforcements = {
	params ["_unitData","_side"];
	
	// Create leader and recreate group
	private _groups = [];
	private _vehicles = [];
	{
		_x params ["", "_setup", "_vehicle", "_leader", "_otherUnits"];
		
		_vehicle params ["_vehicleType","_vehiclePos","_vehicleDir","_weaponCargo","_magazineCargo"];
		
		
		private _vehicleUnit = objnull;

		if ( !isNil "_vehicleType" ) then {
			_vehicleUnit = _vehicleType createVehicle [0,0,0];
			_vehicleUnit hideObjectGlobal true;
			_vehicleUnit setPosATL _vehiclePos;
			_vehicleUnit setDir _vehicleDir;
			clearWeaponCargo _vehicleUnit;
			clearMagazineCargo _vehicleUnit;
			
			{
				_vehicleUnit addWeaponCargo [ _x, (_weaponCargo select 1) select _forEachIndex];
			} forEach (_weaponCargo select 0);
			{
				_vehicleUnit addMagazineCargo [ _x, (_magazineCargo select 1) select _forEachIndex];
			} forEach (_magazineCargo select 0);
			_vehicleUnit enableSimulationGlobal false;
			_vehicles pushback _vehicleUnit;
		};
		
		
		_leader params ["_leaderPos", "_leaderDir", "_leaderType", "_leaderLoadout", "_leaderVehicleInfo"];
		
		private _leaderUnit = (createGroup [_side, true]) createUnit [ _leaderType, [0,0,0], [], 0, "FORM" ];
		private _group = group _leaderUnit;
		_leaderUnit hideObjectGlobal true;
		_leaderUnit setPosATL ( _leaderPos findEmptyPosition [0,10,"MAN"] );
		_leaderUnit setDir _leaderDir;
		_leaderUnit setUnitLoadout _leaderLoadout;
		_group selectLeader _leaderUnit;
		
		_groups pushback _group;
		
		_x set [0, _group];
		_setup set [0, _group];
		
		if ( !isNull _vehicleUnit ) then {
			_group addVehicle _vehicleUnit;
			[_vehicleUnit,_leaderUnit,_leaderVehicleInfo] call assignToVehicle;
		};
		
		_leaderUnit enableSimulationGlobal false;
		
		{
			_x params [ "_unitPos", "_unitDir", "_unitType", "_unitLoadout", "_unitVehicleInfo"];
			private _unit = _group createUnit [ _unitType, [0,0,0], [], 0, "FORM"];
			_unit hideObjectGlobal true;
			_unit setPosATL ( _unitPos findEmptyPosition [0,10,"MAN"] );
			_unit setDir _unitDir;
			_unit setUnitLoadout _unitLoadout;
			if ( !(isNull _vehicleUnit) ) then {
				[_vehicleUnit,_unit,_unitVehicleInfo] call assignToVehicle;
			};
			_unit enableSimulationGlobal false;
			
		} forEach _otherUnits;
		
		_group setVariable ["Vcom_skilldisable", true];
		
		{ 
			private _unit = _x;
			{
				_x params ["_name","_val"];
				_unit setSkill [_name, _val];
			} forEach RTS_greenAi;
		} forEach (units _group);
		
	} forEach _unitData;
	
	
	{
		_x params ["_group","_setup"];
		
		{
			_x hideObjectGlobal false;
			(vehicle _x) hideObjectGlobal false;
			_x enableSimulationGlobal true;
			(vehicle _x) enableSimulationGlobal true;
		} forEach (units _group);
	} forEach _unitData;
	
	[_groups,_vehicles]

};

call compile preprocessFileLineNumbers "scen_fw\conversation_system.sqf";

if ( hasInterface ) then {
	hintSilent "Waiting on server init...";
	waitUntil { !isNil "JTF_server_init" };
	waitUntil { !(isNull player) && isPlayer player };
	waitUntil { time > 1 };
	JTF_player_loadout = getUnitLoadout player;
	
	JTF_respawn_h = {
		player removeAllEventHandlers "Killed";
		player removeAllEventHandlers "Respawn";
		player setUnitLoadout JTF_player_loadout;
		player removeWeapon "tf_microdagr";
		player setVariable [ "JTF_playerIsDead", true, true];
		JTF_playerDeathHandler = player addEventHandler ["Killed", { [allPlayers select { alive _x }, [player]] call ace_spectator_fnc_updateUnits; JTF_playerIsDead = true; [true] call ace_spectator_fnc_setSpectator; }];
		JTF_player_respawnHandler = player addEventHandler ["respawn", JTF_respawn_h ];
	};
	
	JTF_player_respawnHandler = player addEventHandler ["respawn", JTF_respawn_h ];
	
	// Spectator stuff and whatnot
	JTF_playerIsDead = false;
	JTF_playerDeathHandler = player addEventHandler ["Killed", { [allPlayers select { alive _x }, [player]] call ace_spectator_fnc_updateUnits; [true] call ace_spectator_fnc_setSpectator; }];
	[[west], [east,civilian,resistance]] call ace_spectator_fnc_updateSides;
	
	call compile preprocessFileLineNumbers "briefing.sqf";
	hintSilent "Server init complete...";
	disableUserInput false;
};

if ( isServer ) then {
	JTF_spawnloop = [] spawn {
		JTF_waves = JTF_unit_waves_blufor + JTF_unit_waves_greenfor + JTF_unit_waves_opfor;

		while { true } do {
			{
				_x params ["_type","_code","_unitData","_side","_destination", "_radius", "_label" ];
				
				if ( call _code ) then {
					( [_unitData,_side] call spawnReinforcements ) params ["_groups","_vehicles"];
					
					JTF_wave_map pushback [ _label, _groups, _vehicles ]; // store the groups
					
					switch (_type) do {
						case "ATTACK": {
							{ 
								// vehicle groups need to just move to the destination first
								if ( vehicle (leader _x) == (leader _x) ) then {
									[_x, _destination, _radius] call CBA_fnc_taskAttack;
								} else {
									_x setBehaviour "SAFE";
									_x setSpeedMode "FULL";
									_x setCombatMode "Yellow";
									(units _x) doMove ([_destination,_radius] call CBA_fnc_randPos);
								};
							} forEach _groups;
						};
						case "DEFEND": {
							{ 
								// vehicle groups need to just move to the destination first
								if ( vehicle (leader _x) == (leader _x) ) then {
									[_x, _destination, _radius,6,0.9,0] call CBA_fnc_taskDefend; 
								} else {
									_x setBehaviour "SAFE";
									_x setSpeedMode "FULL";
									_x setCombatMode "Yellow";
									(units _x) doMove ([_destination,_radius] call CBA_fnc_randPos);
								};
							} forEach _groups;
						};;
						default { };
					};				
					
					_x set [1, { false } ]; // disable multiple spawning
				};
				
			} forEach JTF_waves;
			
			sleep 1;
		};
	};
		
	call compile preprocessFileLineNumbers "scen_fw\tasks_system.sqf";
	call compile preprocessFileLineNumbers "scen_fw\checkpoint_system.sqf";
	
	JTF_server_init = true;
	publicVariable "JTF_server_init";
};
