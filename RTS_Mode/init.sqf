#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"
#include "RTS_defines.hpp"

_east = createCenter east;
_west = createCenter west;
_resist = createCenter resistance;
_civ = createCenter civilian;

mapAnimAdd [0, 0.1, getMarkerPos "map_center"];
mapAnimCommit;

RTS_setupScripts = [];

// Function for creating function setups
RTS_setupFunction = {
	params ["_prefix", "_functions"];
	RTS_setupScripts pushBackUnique (_prefix + "\setup.sqf");
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

RTS_rerunAllSetups = {
	{
		[] call (compile preprocessFileLineNumbers _x);
	} forEach RTS_setupScripts;
};

[] call (compile preprocessFileLineNumbers "rts\functions\shared\setup.sqf");

_initserver = [] spawn (compile preprocessFileLineNumbers "rts\initServer.sqf");

waitUntil { scriptDone _initserver };

if ( isDedicated || !hasInterface ) exitWith {};

[] call (compile preprocessFileLineNumbers "rts\functions\client\setup.sqf");

[] call RTS_fnc_hideAllMarkers;

[] execVM "rts\initPlayer.sqf";

waitUntil { !(isNull player) && isPlayer player };
waitUntil { time > 1 };

if ( !([] call RTS_fnc_isCommander) ) exitWith {};

[] call (compile preprocessFileLineNumbers "rts\ace_spectator_overrides\setup.sqf");
[] call (compile preprocessFileLineNumbers "rts\functions\client\commander\setup.sqf");

if ( side player == west ) then {
	RTS_deploymentMarks = ["blufor"] call RTS_fnc_getAllDeploymentMarkers;
	RTS_aoMarker = "blufor_ao";
	RTS_camStart = "blufor_start";
	RTS_camTarget = "blufor_target";
	RTS_sidePlayer = west;
	RTS_sideEnemy = east;
	RTS_sideGreen = resistance;
	RTS_sideColor = [0.25,0.25,1,1];
	RTS_enemyColor = [1,0.25,0.25,1];
	RTS_greenColor = [0.25,1,0.25,1];
} else {
	if ( side player == east ) then  {
		RTS_deploymentMarks = ["opfor"] call RTS_fnc_getAllDeploymentMarkers;
		RTS_aoMarker = "opfor_ao";
		RTS_camStart = "opfor_start";
		RTS_camTarget = "opfor_target";
		RTS_sidePlayer = east;
		RTS_sideEnemy = west;
		RTS_sideGreen = resistance;
		RTS_sideColor = [1,0.25,0.25,1];
		RTS_enemyColor = [0.25,0.25,1,1];
		RTS_greenColor = [0.25,1,0.25,1];
	} else {
		RTS_deploymentMarks = ["greenfor"] call RTS_fnc_getAllDeploymentMarkers;
		RTS_aoMarker = "greenfor_ao";
		RTS_camStart = "greenfor_start";
		RTS_camTarget = "greenfor_target";
		RTS_sidePlayer = resistance;
		RTS_sideEnemy = RTS_Greenfor_Enemy;
		RTS_sideGreen = RTS_Greenfor_Green;
		RTS_sideColor = [0.25,1,0.25,1];
		RTS_enemyColor = RTS_Greenfor_EnemyColor;
		RTS_greenColor = RTS_Greenfor_GreenColor;
	};
};

RTS_canPause = if ( isServer ) then { true } else { false };
RTS_casualtyColor = [0.8,0.8,0,1];
RTS_brokenColor = [0.3,0.3,0.3,0.8];
RTS_commandAction = -1;
RTS_paused = false;
RTS_pausing = false;
RTS_initialMen = 0;
RTS_initialWeapons = 0;
RTS_initialVehicles = 0;
RTS_casualties = 0;

// Start in the deployment phase
RTS_phase = "DEPLOY";
RTS_selecting = false;
RTS_selectStart = [];
RTS_backspace = false;
RTS_formationChoose = false;
RTS_combatChoose = false;
RTS_stanceChoose = false;
RTS_buildingposChoose = false;
RTS_command = nil;
RTS_commanding = false;
RTS_commandingGroups = [];
RTS_opfor_vehicles = [];
RTS_greenfor_vehicles = [];
RTS_selectedGroup = grpnull;
RTS_fakeCameraTarget = "Land_HandyCam_F" createVehicleLocal [0,0,0];
RTS_fakeCameraTarget hideObject true;
RTS_groupIconMaxDistance = 1500;

// RTS Specific Commands
[] call (compile preprocessFileLineNumbers "rts\commands\setup.sqf");
[] spawn (compile preprocessFileLineNumbers "rts\systems\commander_sys.sqf");
[] spawn (compile preprocessFileLineNumbers "rts\systems\spotting_system.sqf");
RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");

// Reveal dead stuff
{
	(vehicle _x) hideObject true;
	_x addEventHandler [ "killed", { (_this select 0) hideObject false; (vehicle (_this select 0)) hideObject false; } ];
} forEach (allunits select { side _x != RTS_sidePlayer } );


{
	_x addEventHandler ["killed", 
						{
							params ["","_killer"];
							private _group = group _killer;
							if ( side _group == RTS_sidePlayer && _group in RTS_commandingGroups ) then {
								_group setVariable ["combat_victories", (_group getVariable ["combat_victories", 0]) + 1];
							};							
						}];
} forEach (allunits select { side _x != RTS_sidePlayer } );

RTS_setupComplete = false;

// Setup command hierarchy
[] call (compile preprocessFileLineNumbers "rts\systems\high_command_setup.sqf");

sleep 10;

[] spawn {

command_laptop addAction ["Begin Commanding", 
	{
		RTS_commanderUnit = player;
		[true] call ace_spectator_fnc_cam;
		[true] call RTS_fnc_ui;
		RTS_setupComplete = true;
		
		[0,
		{
			_this call RTS_fnc_setupCommander
		},[player]] call CBA_fnc_globalExecute;
	}];

waitUntil { RTS_setupComplete };

RTS_killedEH = player addEventHandler ["killed", {
	private _pos = getPosATL player;
	private _dir = getDir player;
	_pos set [2, 5];
	private _leader = ((units (group player)) select { alive _x }) select 0;
	(group player) selectLeader _leader;
	(units (group player)) doFollow _leader;
	RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");
	player removeAction RTS_commandAction;
	player removeEventHandler ["killed", RTS_killedEH];
	selectPlayer RTS_commanderUnit;
	[true] call ace_spectator_fnc_cam;
	[true] call RTS_fnc_ui;
	ace_spectator_camera setPosATL _pos;
	ace_spectator_camera setDir _dir;
}];

[] call RTS_fnc_setupAllGroups;

{

	_group = _x;
	
	// VCOM Stuff
	_group setVariable ["VCM_NOFLANK",true];
	_group setVariable ["VCM_DisableForm",true];
	_group setVariable ["VCM_NORESCUE",true];
	_group setVariable ["VCM_TOUGHSQUAD",true];
	
	if ( (vehicle (leader _group)) == (leader _group) ) then {
		{ 
			_x disableAi "AUTOCOMBAT";
		} forEach (units _group);
	};
	
	_group enableAttack false;
	{
		_x allowFleeing 0;
		_x disableAi "FSM";
		addSwitchableUnit _x;
	} forEach (units _group);
} forEach RTS_commandingGroups;


[] spawn (compile preprocessFileLineNumbers "rts\systems\radio_communications.sqf");

// temporary group monitor
RTS_groupMon = {
		private _group = RTS_selectedGroup;
		_commanderinfo = format
			["COMBAT OVERVIEW\n\nInitial Strength - %1\nInitial Weapons - %2\nInitial Vehicles - %3\nCasualties - %4", 
				RTS_initialMen,
				RTS_initialWeapons,
				RTS_initialVehicles,
				RTS_casualties];
		_groupinfo = 
			if ( ! (isNull _group) ) then {
				// Group information
				_unitSkills = [(units _group) select { alive _x }, { skill _x }] call CBA_fnc_filter;
				format 
				["GROUP OVERVIEW\n\nStatus - %1\nType - %2\nBehaviour - %3\nFormation - %4\nCombat Mode - %5\nCombat Victories - %6\nComm Effect - %7\nMorale - %8\nCasualties - %9\nAvg. Skill - %10\nComm State - %11",
				  _group getVariable ["status", "Unkown"],
				  _group getVariable ["desc", "Unkown"],
				  behaviour (leader _group),
				  formation _group,
				  combatMode _group,
				  _group getVariable ["combat_victories", 0],
				  _group getVariable ["command_bonus", 0],
				  _group getVariable ["morale", 0],
				  format ["%1\nInitial Strength - %2", (_group getVariable ["initial_strength", 0]) - (count ((units _group) select { alive _x } )),(_group getVariable ["initial_strength", 0])],
				  if ( count _unitSkills > 0 ) then { _unitSkills call BIS_fnc_arithmeticMean } else { 0 },
				  _group getVariable ["comms", "None"]]
			} else { 
				""
			};
		_vehicleinfo = "";
		if ( !(isNull _group) && ((vehicle (leader _group)) != (leader _group)) ) then {
			_veh = vehicle (leader _group);
			_passengers = ((crew _veh) select { alive _x && (group _x != _group) });
			_groups = [];
			{
				_groups pushBackUnique (group _x);
			} forEach _passengers;
			_space = _veh emptyPositions "CARGO";
			_vehicleinfo = format 
				["Passenger Space - %1\nAvailable - %2\nPassenger Groups - %3",
					_space + (count _passengers),
					_space,
					count _groups];
		};
					
		// Controls information
		_name = "";
		_additional = "";
		if ( ! isNil "RTS_command" ) then { 
			RTS_command params ["_one","","","_three"];
			if !(isNil "_one") then { _name = "\n\n" + _one };
			if !(isNil "_three") then { _additional = "\n\n" + _three };
		};
		_controlinfo = format ["NEXT COMMAND%1%2", _name, _additional];
		hintSilent format ["%1\n\n%2\n\n%3\n\n%4",_commanderinfo,_groupinfo,_vehicleinfo, _controlinfo];
};

RTS_ai_system = compile preprocessFileLineNumbers "rts\systems\ai_command_processing.sqf";
RTS_processingThread = addMissionEventHandler ["Draw3D", { call RTS_ai_system }];
// Update status info on every frame (for now, will use proper UI eventually)
RTS_monitorHandler = addMissionEventHandler ["Draw3D", { if ( RTS_commanding ) then { call RTS_groupMon }; }];

};