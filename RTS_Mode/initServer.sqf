#include "\z\ace\addons\spectator\script_component.hpp"
#include "RTS_defines.hpp"

if ( !isServer ) exitWith {};

[] call (compile preprocessFileLineNumbers "rts\functions\server\setup.sqf");

RTS_bluforHCModules = [west] call RTS_fnc_getAllHighCommandCommanders;
RTS_opforHCModules = [east] call RTS_fnc_getAllHighCommandCommanders;
RTS_greenforHCModules = [resistance] call RTS_fnc_getAllHighcommandCommanders;

publicVariable "RTS_bluforHCModules";
publicVariable "RTS_opforHCModules";
publicVariable "RTS_greenforHCModules";

// Setup command hierarchy
RTS_highCommandSetup = compile preprocessFileLineNumbers "rts\systems\high_command_setup.sqf";
{
	[_x] call RTS_highCommandSetup;
} forEach [west, east, resistance];

RTS_bluforStaticReinforcements = [west] call RTS_fnc_getAllReinforcements;
RTS_opforStaticReinforcements = [east] call RTS_fnc_getAllReinforcements;
RTS_greenforStaticReinforcements = [resistance] call RTS_fnc_getAllReinforcements;

publicVariable "RTS_bluforStaticReinforcements";
publicVariable "RTS_opforStaticReinforcements";
publicVariable "RTS_greenforStaticReinforcements";

			//    Blufor    GreenFor   Opfor
RTS_phase = "";
RTS_commanders = [objnull,  objnull ,  objnull];
RTS_commanderPhases = ["", "", ""];
RTS_commandingGroups = [];
RTS_phaseButton = "";

[] spawn {
	_ncommanders = if RTS_SingleCommander then { 0 } else { 1 };
	
	waitUntil { ( count (RTS_commanderPhases select { _x != "" } ) ) > _ncommanders };
	
	[-1, 
	{ 
		if ( isNil "RTS_setupComplete" ) exitWith {}; 
		waitUntil { !isNil "RTS_phaseButton" };
		RTS_phaseButton ctrlShow true; 
		RTS_phaseButton ctrlCommit 0;
	}] call CBA_fnc_globalExecute;
	
	// Keep track of phase
	RTS_phaseTracker = [] spawn {
	
		// Initial Orders
		waitUntil {
			(count (RTS_commanders select { !(isNull _x) })) == (count (RTS_commanderPhases select { _x == "INITIALORDERS"}))
		};
		
		[-1,
		{
			if ( isNil "RTS_setupComplete" ) exitWith {};
			RTS_phase = "INITIALORDERS";
		}] call CBA_fnc_globalExecute;
		
		// Main Phase
		waitUntil {
			(count (RTS_commanders select { !(isNull _x) })) == (count (RTS_commanderPhases select { _x == "MAIN"}))
		};
		
		[-1,
		{
			if ( isNil "RTS_setupComplete" ) exitWith {};
			RTS_phase = "MAIN";
			{
				_x setVariable ["status", "WAITING"];
			} forEach RTS_commandingGroups;
		}] call CBA_fnc_globalExecute;
	
	};
};

call compile preprocessFileLineNumbers "scen_fw\tasks_system.sqf";
call compile preprocessFileLineNumbers "scen_fw\checkpoint_system.sqf";


// Setup map placed AI

RTS_mapAI = [["aimingAccuracy",0.09],["aimingShake",0.05],["aimingSpeed",0.25],["commanding",1],["courage",0.8],["endurance",0.7],["general",0.5],["reloadSpeed",1],["spotDistance",0.55],["spotTime",0.2]];

{
	_x setUnitLoadout (getUnitLoadout _x);
	if ( !(_x getVariable ["noskill", false]) ) then {
		private _unit = _x;
		{
			_x params ["_name","_val"];
			_unit setSkill [_name, _val];
		} forEach RTS_mapAI;
	};
	(group _x) setVariable ["Vcom_skilldisable", true, true];
	if ( !( ((group _x) getVariable ["RTS_setup",[]]) isEqualTo [] ) ) then {
		(group _x) setVariable ["Vcm_disable", true, true];
	};
} forEach allUnits;