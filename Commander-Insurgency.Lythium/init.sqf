_rtsinit = [] spawn (compile preprocessFileLinenumbers "rts\init.sqf");

waitUntil { scriptDone _rtsinit };

// Setup insurgency functions
if ( side player == east || isServer ) then {
	INS_intelLevel = 0;
	INS_carClasses = [];
	INS_tankClasses = [];
	INS_apcClasses = [];
	INS_soldierClasses = [];
	INS_leaderClasses = [];
	INS_spyClasses = [];
	INS_soldierLoadouts = [];
	INS_leaderLoadouts = [];
	INS_spyLoadouts = [];
	INS_tankMin = 0.5; INS_tankMid = 0.95; INS_tankMax = 2.4;
	INS_apcMin = 2; INS_apcMid = 4; INS_apcMax = 5;
	INS_carMin = 4; INS_carMid = 5; INS_carMax = 6;
	INS_squadMin = 7; INS_squadMid = 8; INS_squadMax = 10;
	INS_groupMin = 3; INS_groupMid = 4; INS_groupMax = 5;
	INS_soleFighterMin = 5; INS_soleFighterMid = 6; INS_soleFighterMax = 7;
	INS_spyMin = 0; INS_spyMid = 0; INS_spyMax = 0;
	// Threshold = 0.5
	INS_groupChanceMin = 0.3; INS_groupChanceMid = 0.5; INS_groupChanceMax = 1;
	INS_apcChanceMin = 0.25; INS_apcChanceMid = 0.3; INS_apcChanceMax = 1;
	INS_tankChanceMin = 0.1; INS_tankChanceMid = 0.1; INS_tankChanceMax = 1;
	[] call (compile preprocessFileLineNumbers "rts\functions\shared\insurgency\setup.sqf");
	if ( !isServer ) then {
		[] spawn {
			waitUntil { RTS_phase == "MAIN" };
			[-1, { 
					if (!(isNil "INS_zoneRestrictHandler")) then {
						removeMissionEventHandler ["Draw3D", INS_zoneRestrictHandler];
					};
				}] call CBA_fnc_globalExecute;
			sleep 5;
			"blufor_restrict" setMarkerSize [0,0];
		};
	};
};

if ( isServer ) then {
	INS_bluforCasualties = 0;
	publicVariable "INS_bluforCasualties";
	INS_maxCasualties = 25;
	publicVariable "INS_maxCasualties";
	INS_caches = 2;
	publicVariable "INS_caches";
	// Setup everything
	{
		_setupfnc = _x getVariable ["opfor_setup", nil];
		if (!isNil "_setupfnc") then {
			[_x] call _setupfnc;
		};
	} forEach allUnits;
	{
		_setupfnc = _x getVariable ["opfor_setup", nil];
		if (!isNil "_setupfnc") then {
			[_x] call _setupfnc;
		};
	} forEach vehicles;
	// Spawn stuff
	[] call INS_fnc_setupCaches;
	// Give control to player
	waitUntil { !(isNil "opforCommander") };
	[-1, 
		{
			params ["_cache1","_cache2"];
			if ( player != opforCommander ) exitWith {};
			waitUntil { !(isNil "RTS_setupComplete") };
			[] call RTS_fnc_setupAllGroups;
			"opfor_deploy_0" setMarkerPos (getPos _cache1);
			"opfor_deploy_1" setMarkerPos (getPos _cache2);
			"opfor_deploy_0" setMarkerBrush "SOLID";
			"opfor_deploy_1" setMarkerBrush "SOLID";
			"opfor_deploy_0" setMarkerAlphaLocal 1;
			"opfor_deploy_1" setMarkerAlphaLocal 1;
			INS_cacheActual1 = [format ["__cache___marker1_%1", time], getPos _cache1, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", "Cache #1 Location"] call CBA_fnc_createMarker;
			INS_cacheActual2 = [format ["__cache___marker2_%1", time], getPos _cache2, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", "Cache #2 Location"] call CBA_fnc_createMarker;
			[] spawn {
				while { true } do {
					waitUntil { (count (allunits select { (alive _x) && (side _x == RTS_sidePlayer) })) < 125 }; 
					sleep 125;
					[] call INS_fnc_spawnReinforcements;
				};
			};
		},[INS_cache1,INS_cache2]] call CBA_fnc_globalExecute;
	[] spawn {
		while { true } do {
			waitUntil { INS_bluforCasualties == INS_maxCasualties || INS_caches == 0 };
			if ( INS_caches == 0 ) then {
				[-1, { ["Coalition Victory",if (side player == west ) then { true } else { false },3] call BIS_fnc_endMission; }] call CBA_fnc_globalExecute;
			} else {
				[-1, { ["Insurgent Victory",if (side player == east ) then { true } else { false },3] call BIS_fnc_endMission; }] call CBA_fnc_globalExecute;
			};
		};
	};
	{
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
						_distance = 925 - (INS_intelLevel*25);
						[format ["__cache___marker_intel_%1-%2", _distance, INS_caches], [_pos,_distance] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_dot", "TEXT:", format ["%1m",_distance], "PERSIST"] call CBA_fnc_createMarker;
						deleteVehicle _case;
					};
				};
			}];
	} forEach ( allUnits select { side _x == east });
};

if ( isDedicated || !hasInterface ) exitWith {};

// Setup Blufor Player
if ( side player == west ) then {
	player addEventHandler [ "killed",
							{ 
								[0, { INS_bluforCasualties = INS_bluforCasualties + 1; publicVariable "INS_bluforCasualties"; }] call CBA_fnc_globalExecute
							}];
	_action = ["fob_redeploy", "Re-deploy", "\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa", {[] spawn btc_fnc_fob_redeploy}, {btc_p_redeploy}, {}, [], [0.4,0,0.4], 5] call ace_interact_menu_fnc_createAction;
	[btc_gear_object, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
	btc_gear_object addAction ["<t color='#ff1111'>Arsenal</t>", "['Open',true] spawn BIS_fnc_arsenal;"];
	
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
	
	if ( ((getMarkerSize "blufor_restrict") select 0) > 0 ) then {
	
		INS_zoneboundaries = ["blufor_restrict"] call RTS_fnc_markerBoundaries;
		INS_zoneboundaries pushBack "blufor_restrict";
		INS_zoneRestrictHandler = addMissionEventHandler ["Draw3d",
				{
					hintSilent "Waiting for mission to start";
					 INS_zoneboundaries call RTS_fnc_zoneRestrict;
				}];
	};
};