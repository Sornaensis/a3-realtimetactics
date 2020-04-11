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

setGroupIconsVisible [false, false];

makeVehicleSafe = {
	private _veh = _this select 0;
	private _side = side _veh;
	{
		if ( side _x == _side && !(isPlayer _x) ) then {
			_veh disableCollisionWith _x;
		};
	} forEach allUnits;
};
disableFriendlyCollision = {
	{
		if ( !( _x isKindOf "StaticWeapon" ) && !( _x isKindOf "EmptyDetector" ) ) then {
			[_x] call makeVehicleSafe;
		};
	} forEach vehicles;
};

call disableFriendlyCollision;

RTS_safeVehicleThread = [] spawn {
	while { true } do {
		call disableFriendlyCollision;
		sleep 30;
	};
};


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
RTS_issuingPause = false;
RTS_command = nil;
RTS_commanding = false;
RTS_commandingGroups = [];
RTS_opfor_vehicles = [];
RTS_greenfor_vehicles = [];
RTS_selectedGroup = grpnull;
RTS_fakeCameraTarget = "Land_HandyCam_F" createVehicleLocal [0,0,0];
RTS_fakeCameraTarget hideObject true;
RTS_groupIconMaxDistance = 1500;
RTS_briefingComplete = false;
RTS_helpKey = false;
RTS_showHelp = false;

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

[] execVm "rts\briefing\presentMissionToCommander.sqf";

waitUntil { RTS_briefingComplete };

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
					
		// Controls information
		_name = "";
		_additional = "";
		if ( ! isNil "RTS_command" ) then { 
			RTS_command params ["_one","","","_three"];
			if !(isNil "_one") then { _name = "\n\n" + _one };
			if !(isNil "_three") then { _additional = "\n\n" + _three };
		};
		
		private _helptext =
		"Click and Drag, or Double Click on a soldier/vehicle to select a unit\n\n" +
		"Hold Buttons and double click to assign an order to a unit\n\n" +
		"E: Move" + "\n" +
		"Shift+E: Fast Move" + "\n" +
		"Ctrl+E: Careful Move" + "\n" +
		"R: Mount/Dismount Crew" + "\n" +
		"T: Watch Position" + "\n" +
		"Shift+T: Check Position Visibility" + "\n" +
		"X: Enter Building" + "\n" +
		"Space: Load/Unload Passengers" + "\n" +
		"F: Select Formation" + "\n" +
		"V: Select Stance" + "\n" +
		"C: Select Combat Mode" + "\n" +
		"`: Control Unit" + "\n" +
		"Backspace: Delete Last Order" + "\n" +
		"P: Add Wait time to Last Order" + "\n" +
		"Tab: Pause";
		
		_controlinfo = format ["Press H For Command List\n\nNEXT COMMAND%1%2", _name, _additional];
		hintSilent format ["%1\n\n%2\n\n%3",_commanderinfo, _controlinfo, ( if ( RTS_showHelp ) then { _helptext } else { "" } ) ];
};

RTS_ai_system = compile preprocessFileLineNumbers "rts\systems\ai_command_processing.sqf";
RTS_processingThread = addMissionEventHandler ["Draw3D", { call RTS_ai_system }];
// Update status info on every frame (for now, will use proper UI eventually)
RTS_monitorHandler = addMissionEventHandler ["Draw3D", { if ( RTS_commanding ) then { call RTS_groupMon }; }];

};