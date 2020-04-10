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