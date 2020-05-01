#include "RTS_Mission_Defines.hpp"

if ( side player == east || isServer ) then {
	if ( isNil "RTS_restrictionZone" ) then {
		RTS_restrictionZone = ["opfor_restriction"];
		publicVariable "RTS_restrictionZone";
	};
};

_rtsinit = [] spawn (compile preprocessFileLinenumbers "rts\init.sqf");

waitUntil { scriptDone _rtsinit };

// Setup insurgency functions
if ( !isNil "opforCommander" || isServer ) then {
	
	INS_setupFastTravel = {
		waitUntil { !isNil "INS_fastTravelFlags" };
		waitUntil { !isNil "INS_controlAreas" };
		private _flags = INS_fastTravelFlags select { (((INS_controlAreas select (_x select 3)) select 2) select 0) < -24 };
		{
			_x params ["_flag","_city","_marker"];
			
			while { count (_flag nearRoads 20) > 0 } do {
				_flag setPosATL (_flag findEmptyPosition [5,20,"MAN"]);
			};
			
			_flag hideObject false;
			removeAllActions _flag;
			_marker setMarkerAlphaLocal 1;
			_marker setMarkerPos (getPos _flag);
			
			{
				private _dest = _x;
				_flag addAction [format ["Travel to %1", _dest select 1],
								 {
								 	params ["","","","_arguments"];
								 	_arguments params ["_f","_c"];
								 	titleText [ format ["Travelling to %1...", _c], "PLAIN"];
								 	private _pos = (getPos _f) findEmptyPosition [2,25,"MAN"];
								 	player setPosATL _pos;
								 },_dest,1.5,true,true,"","true",5,false,"",""];
			} forEach (_flags select { (_x select 0) != _flag });
			
		} forEach _flags;			
	};

	INS_intelLevel = 0;
	INS_carClasses = [];
	INS_tankClasses = [];
	INS_apcClasses = [];
	INS_squadSetups = [];
	INS_mgSetups = [];
	INS_sniperSetups = [];
	INS_spySetups = [];
	INS_tankMin = 1; INS_tankMid = 2; INS_tankMax = 3.4;
	INS_apcMin = 3; INS_apcMid = 4; INS_apcMax = 6;
	INS_carMin = 4; INS_carMid = 4; INS_carMax = 5;
	INS_squadMin = 5; INS_squadMid = 6; INS_squadMax = 7;
	INS_mgMin = 2; INS_mgMid = 3; INS_mgMax = 4;
	INS_sniperMin = 4; INS_sniperMid = 4; INS_sniperMax = 5;
	INS_spyMin = 3; INS_spyMid = 5; INS_spyMax = 6;
	INS_spies = [];
	publicVariable "INS_spies";
	[] call (compile preprocessFileLineNumbers "rts\functions\shared\insurgency\setup.sqf");
	
	if ( isMultiplayer ) then {
		opforCommander addMPEventHandler ["MPRespawn", {
			if ( !isNil "INS_cacheBuildings" ) then {
				private _commandbuildings = INS_cacheBuildings select { ((position _x) distance (position INS_currentCache)) > 100 };
				opforCommander setPosATL ( ([_commandbuildings call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom );
			};
			opforCommander addAction ["Begin Commanding", 
				{
					if ( scriptDone RTS_ui ) then {
						RTS_ui = [] spawn (compile preprocessFileLineNumbers "rts\systems\ui_system.sqf");
					};
					
					if ( RTS_skipDeployment ) then {
						RTS_phase = "MAIN";
						{
							_x setMarkerAlpha 0;
						} forEach RTS_deploymentMarks;
						{
							_x setVariable ["status","WAITING"];
						} forEach RTS_commandingGroups;
					};
					
					RTS_commanderUnit = player;
					[true] call ace_spectator_fnc_cam;
					[true] call RTS_fnc_ui;
					RTS_setupComplete = true;
					
					[0,
					{
						_this call RTS_fnc_setupCommander
					},[player]] call CBA_fnc_globalExecute;
				}];
		}];
		[] spawn INS_setupFastTravel;
	};

};

if ( isServer && isNil "INS_caches" ) then {
	INS_bluforCasualties = 0;
	publicVariable "INS_bluforCasualties";
	INS_maxCasualties = 50;
	publicVariable "INS_maxCasualties";
	INS_caches = 2;
	publicVariable "INS_caches";
	// Setup everything by group
	{
		_setupfnc = (leader _x) getVariable ["opfor_setup", nil];
		if (!isNil "_setupfnc") then {
			[leader _x] call _setupfnc;
		};
	} forEach allGroups;
	{
		_setupfnc = _x getVariable ["opfor_setup", nil];
		if (!isNil "_setupfnc") then {
			[_x] call _setupfnc;
		};
	} forEach vehicles;
	// Spawn stuff
	INS_setupFinished = false;
	[] spawn INS_fnc_setupCaches;
	waitUntil { INS_setupFinished };
	// Give control to player
	[-1, 
		{
			if ( isNil "opforCommander" ) exitWith {};
			if ( player != opforCommander ) exitWith {};
			waitUntil { !(isNil "RTS_setupComplete") };
			[] call RTS_fnc_setupAllGroups;
		}] call CBA_fnc_globalExecute;
	[] spawn {
		while { true } do {
			waitUntil { INS_bluforCasualties >= INS_maxCasualties || INS_caches == 0 };
			if ( INS_caches == 0 ) then {
				[-1, { ["Coalition Victory",if (side player == west ) then { true } else { false },3] call BIS_fnc_endMission; }] call CBA_fnc_globalExecute;
			} else {
				[-1, { ["Insurgent Victory",if (side player == east ) then { true } else { false },3] call BIS_fnc_endMission; }] call CBA_fnc_globalExecute;
			};
		};
	};
	
	[] spawn {
		while {true} do {	
			{
				if ( !(_x getVariable ["intel_handling", false]) ) then {
					_x setVariable ["intel_handling", true];
					_x addMPEventHandler ["mpkilled", 
						{
							if ( !isServer ) exitWith {};
							params ["_unit"];
							private _spawn = [0,0,0,0,0,0,0,0,1,0,0,1] call BIS_fnc_selectRandom;
							if ( _spawn == 1 ) then  {
								_suitcase = "Suitcase" createVehicle ((getPosATL _unit) findEmptyPosition [0,30,"Suitcase"]);
								[_suitcase] spawn {
									params ["_case"];
									waitUntil { [_case, 5] call CBA_fnc_nearPlayer };
									INS_intelLevel = INS_intelLevel + 1;
									[-1, { 
											titleText ["HUMINT has revealed new information about weapons cache", "PLAIN"];
										}] call CBA_fnc_globalExecute;
									_pos = getPosATL ( if (INS_caches == 2) then { INS_cache1 } else { INS_cache2 } );
									_distance = 1100 - (INS_intelLevel*25);
									[format ["__cache___marker_intel_%1-%2", _distance, INS_caches], [_pos,_distance] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_dot", "TEXT:", format ["%1m",_distance], "PERSIST"] call CBA_fnc_createMarker;
									deleteVehicle _case;
								};
							};
						}];
				};
			} forEach ( allUnits select { side _x != west });
			sleep 2;
		};
	};
};

if ( isDedicated || !hasInterface ) exitWith {};

// Setup Blufor Player
if ( side player == west ) then {
	
	{
		_x setMarkerColorLocal "ColorBlue";
	} forEach RTS_restrictionZone;
	
	[] spawn {
		waitUntil { !isNil "INS_spies" };
		while { true } do {
			{
				private _nearhouses = _x nearObjects ["House", 150];
				if ( ((getPos _x) distance (getPos _player)) > 350 && (count _nearhouses) > 4 ) then {
					_x hideObject true;
				} else {
					_x hideObject false;
				};
			} forEach INS_spies;
			sleep 0.01;
		};		
	};

	player addEventHandler [ "killed",
							{ 
								[0, { INS_bluforCasualties = INS_bluforCasualties + 1; publicVariable "INS_bluforCasualties"; }] call CBA_fnc_globalExecute
							}];
	
	waitUntil { ! (isNull (findDisplay 46)) };

	INS_infoBox = (findDisplay 46) ctrlCreate ["RscText", -1];
	
	INS_infoBox ctrlSetFontHeight 0.07;
	INS_infoBox ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.15),safeZoneY+0.01,0.3,0.07]; 

	addMissionEventHandler ["Draw3d",
	{
		// Update insurgency info display
		INS_infoBox ctrlSetText 
			( format ["Blufor Casualties - %1 / %2 | Caches Remaining - %3", INS_bluforCasualties, INS_maxCasualties, INS_caches]
			);
		INS_infoBox ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-(ctrlTextWidth INS_infoBox)/2-0.015),safeZoneY+0.01,ctrlTextWidth INS_infoBox+0.03,0.07];

		INS_infoBox ctrlCommit 0;
	}];
	
};