#include "\z\ace\addons\spectator\script_component.hpp"
#include "RTS_Mission_Defines.hpp"

acex_fortify_locations pushBack [fob_flag, 200, 200, 0, false];

if ( side player == east || isServer ) then {
	if ( isNil "RTS_restrictionZone" ) then {
		RTS_restrictionZone = ["opfor_restriction"];
		publicVariable "RTS_restrictionZone";
	};
};

// base protection

INS_baseMarker = "opfor_restriction";
INS_detentionArea = "detention_area";
INS_detentionArea setMarkerAlpha 0;
(getMarkerSize INS_baseMarker) params ["_mx","_my"];
private _baseSize = (_mx max _my);

{
	_x allowDamage false;
	_x removeAllEventHandlers "Hit";
	_x removeAllEventHandlers "HandleDamage";
	_x removeAllEventHandlers "HitPart";	
} forEach ( ((getMarkerPos INS_baseMarker) nearObjects ["HOUSE", _baseSize]) select { _x inArea INS_baseMarker });

private _rtsinit = [] spawn (compile preprocessFileLinenumbers "rts\init.sqf");

waitUntil { scriptDone _rtsinit };

[] spawn (compile preprocessFileLinenumbers "balancer.sqf");
[] spawn (compile preprocessFileLinenumbers "headless_vcom.sqf");

setViewDistance 2000;

// Setup insurgency functions
waitUntil { isDedicated || ( !(isNull player) && isPlayer player ) || !hasInterface };

INS_allPlayers = {
	private _headlessClients = entities "HeadlessClient_F";
	(allPlayers - _headlessClients)
};

private _runsetup = false;

if ( !(isNil "opforCommander") ) then {
	if ( side player == east ) then {
		_runsetup = true;
	};
};

if ( !isDedicated && hasInterface ) then {
	enableEngineArtillery false;
};

if ( isServer || !hasInterface ) then {
	
	setupAsCivilianGarrison = {
		params ["_group", "_pos", "_radius","_city"];
		[_group] call CBA_fnc_clearWaypoints;
		_group setVariable ["ai_status", "GARRISON"];
		_group setVariable ["ai_city", _city, true];
		[_group, _pos, _radius, 2, 0.35, 0.9 ] call CBA_fnc_taskDefend;
	};
	
	setupAsGarrison = {
		params ["_group", "_pos", "_radius","_city"];
		[_group] call CBA_fnc_clearWaypoints;
		_group setVariable ["ai_status", "GARRISON"];
		_group setVariable ["ai_city", _city, true];
		[_group, _pos, _radius, 2, 0.5, 0.8 + ((random 2)/10) ] call CBA_fnc_taskDefend;
	};
	
	setupAsHardGarrison = {
		params ["_group", "_pos", "_radius","_city"];
		[_group] call CBA_fnc_clearWaypoints;
		_group setVariable ["ai_status", "GARRISON"];
		_group setVariable ["ai_city", _city, true];
		[_group, _pos, _radius, 2, 0, 1 ] call CBA_fnc_taskDefend;
	};
	
	setupAsFullGarrison = {
		params ["_group", "_pos", "_radius","_city"];
		[_group] call CBA_fnc_clearWaypoints;
		_group setVariable ["ai_dismiss_loc", _pos];
		_group setVariable ["ai_status", "GARRISON"];
		_group setVariable ["ai_city", _city, true];
		[_pos, nil, units _group, _radius, 0, false, false] call ace_ai_fnc_garrison;
	};
	
	setupAsPatrol = {
		params ["_group", "_pos", "_radius","_city"];
		[_group] call CBA_fnc_clearWaypoints;
		_group setVariable ["ai_status", "PATROL"];
		_group setVariable ["ai_city", _city, true];
		[_group, _pos, _radius, 7, "MOVE", "SAFE", "RED", (if ( side _group == civilian ) then { "LIMITED" } else { "NORMAL" })] call CBA_fnc_taskPatrol;
	};
	
	doCounterAttack = {
		params ["_group", "_pos", "_radius","_city"];
		[_group] call CBA_fnc_clearWaypoints;
		
		_group setVariable ["ai_tough", selectRandomWeighted [true,0.4,false,0.6] ]; // fleeing requires lots of casualties
		_group setVariable ["ai_status", "COUNTER-ATTACK"];
		_group setVariable ["ai_city", _city, true];
		if ( vehicle (leader _group) != leader _group ) then {
			[_group, _pos, _radius, 7, "MOVE", "COMBAT", "RED", "FULL"] call CBA_fnc_taskPatrol;
		} else {
			[_group, _pos, _radius] call CBA_fnc_taskAttack;
		};
	};
};


if ( isDedicated || _runsetup ) then {

	INS_setupFastTravel = {
	
		{
			_x params ["_flag","_city","_marker"];
			
			_flag hideObject true;
			removeAllActions _flag;
			_marker setMarkerAlphaLocal 0;
			
		} forEach (INS_fastTravelFlags select { (((INS_controlAreas select (_x select 3)) select 2) select 0) >= -24 });	
	
		private _flags = INS_fastTravelFlags select { (((INS_controlAreas select (_x select 3)) select 2) select 0) < -24 };
		{
			_x params ["_flag","_city","_marker"];
			
			while { isOnroad _flag } do {
				_flag setPosATL ((getPos _flag) findEmptyPosition [5,20,"MAN"]);
			};
			
			_flag hideObject false;
			removeAllActions _flag;
			_marker setMarkerAlphaLocal 1;
			_marker setMarkerPosLocal (getPos _flag);
		
			_flag addAction ["Open Purchase Menu",
							 {
							 	private _diag = createDialog "PurchaseMenuDialog";
							 	waitUntil { _diag };
							 	[] spawn INS_setupPurchaseMenu;
							 },[],1.5,true,true,"","true",5,false,"",""];
			
			{
				private _dest = _x;
				_flag addAction [format ["Travel to %1", _dest select 1],
								 {
								 	params ["","","","_arguments"];
								 	_arguments params ["_f","_c"];
								 	[_f,_c] spawn {
								 		params ["_f","_c"];
									 	titleText [ format ["Travelling to %1...", _c], "PLAIN"];
								 		sleep 3;
								 		private _pos = (getPos _f) findEmptyPosition [2,25,"MAN"];
								 		player setPosATL _pos;
								 		player setDir ((getPos player) getDir (getPos _f));
								 	};
								 },_dest,1.5,true,true,"","true",5,false,"",""];
			} forEach (_flags select { (_x select 0) != _flag });
			
		} forEach _flags;	
	};
	
	if ( isNil "INS_squadSetups" ) then {
		INS_intelLevel = 0;	
		publicVariable "INS_intelLevel";
		INS_carClasses = [];
		publicVariable "INS_carClasses";
		INS_tankClasses = [];
		publicVariable "INS_tankClasses";
		INS_apcClasses = [];
		publicVariable "INS_apcClasses";
		INS_squadSetups = [];
		publicVariable "INS_squadSetups";
		INS_civilianSetups = [];
		publicVariable "INS_civilianSetups";
		INS_bluforSquadSetups = [];
		publicVariable "INS_bluforSquadSetups";
		INS_greenforSquadSetups = [];
		publicVariable "INS_greenforSquadSetups";
		INS_mgSetups = [];
		publicVariable "INS_mgSetups";
		INS_sniperSetups = [];
		publicVariable "INS_sniperSetups";
		INS_spySetups = [];
		publicVariable "INS_spySetups";
		INS_spies = [];
		publicVariable "INS_spies";
	};
	INS_tankMin = 1; INS_tankMid = 2; INS_tankMax = 2;
	INS_apcMin = 1; INS_apcMid = 2; INS_apcMax = 6;
	INS_carMin = 3; INS_carMid = 3; INS_carMax = 5;
	INS_squadMin = 4; INS_squadMid = 4; INS_squadMax = 6;
	INS_mgMin = 2; INS_mgMid = 3; INS_mgMax = 4;
	INS_sniperMin = 3; INS_sniperMid = 4; INS_sniperMax = 5;
	INS_spyMin = 5; INS_spyMid = 6; INS_spyMax = 8;
	
	[] call (compile preprocessFileLineNumbers "rts\functions\shared\insurgency\setup.sqf");
	
	if ( !isDedicated ) then {
		
		INS_purchaseUnit = {
			params ["_unitType"];
			
			private _canPurchase = false;
			
			private _costs = [];
			private _spawner = { };
			
			switch ( _unitType ) do {
				case "SPY":{
					_costs = INS_spyCost;
					_spawner = INS_fnc_spawnSpy;
				};
				case "TANK":{
					_costs = INS_tankCost;
					_spawner = INS_fnc_spawnTank;
				};
				case "IFV":{
					_costs = INS_apcCost;
					_spawner = INS_fnc_spawnAPC;
				};
				case "SQUAD":{
					_costs = INS_squadCost;
					_spawner = INS_fnc_spawnSquad;
				};
				case "MG":{
					_costs = INS_mgCost;
					_spawner = INS_fnc_spawnMG;
				};
				case "SNIPER":{
					_costs = INS_sniperCost;
					_spawner = INS_fnc_spawnSniper;
				};
				case "CAR":{
					_costs = INS_carCost;
					_spawner = INS_fnc_spawnCar;
				};
				case "EMPTYCAR":{
					_costs = INS_carCost;
					_spawner = INS_fnc_spawnEmptyCar;
				};
			};
			
			if ( !(_costs isEqualTo []) ) then {
				_costs params ["_mp","_mat"];
				private _men = RTS_commandingGroups apply { count (units _x) };
				private _tot = 0;
				{
					_tot = _tot + _x;
				} forEach _men;
				
				if ( _tot < INS_maxMen ) then {
					if ( _mp <= INS_playerManpower && _mat <= INS_playerMaterials ) then {
						_canPurchase = true;
						INS_playerManpower = INS_playerManpower - _mp;
						publicVariable "INS_playerManpower";
						INS_playerMaterials = INS_playerMaterials - _mat;
						publicVariable "INS_playerMaterials";
						private _spawnpos = (getPos player) findEmptyPosition [5,20, "MAN"];
						private _soldier = [_spawnpos] call _spawner;
						[] call RTS_fnc_setupAllGroups;
					};
				} else {
					_canPurchase = true;
					titleText [ format ["<t size='1.4'>You may not control more than %1 men</t>", INS_maxMen], "PLAIN", 1, true, true];
				};
			};
			
			if ( ! _canPurchase ) then {
				titleText ["<t size='1.4'>Not Enough Funds...</t>", "PLAIN", 1, true, true];
			};
		};
	
		INS_setupPurchaseMenu = {
			private _spy = 1600;
			private _squad = 1601;
			private _emptyCar = 1602;
			private _car = 1603;
			private _mgTeam = 1604;
			private _sniperTeam = 1605;
			private _ifv = 1606;
			private _tank = 1607;
			
			waitUntil { !( (uiNamespace getVariable ["purchase_dialog",objnull]) isEqualTo objnull ) };
			
			private _display = uiNamespace getVariable "purchase_dialog";
			
			(_display displayCtrl _spy) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_spyCost select 0, INS_spyCost select 1] );
			(_display displayCtrl _squad) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_squadCost select 0, INS_squadCost select 1] );
			(_display displayCtrl _mgTeam) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_mgCost select 0, INS_mgCost select 1] );
			(_display displayCtrl _sniperTeam) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_sniperCost select 0, INS_sniperCost select 1] );
			(_display displayCtrl _car) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_carCost select 0, INS_carCost select 1] );
			(_display displayCtrl _emptyCar) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_carCost select 0, INS_carCost select 1] );
			(_display displayCtrl _ifv) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_apcCost select 0, INS_apcCost select 1] );
			(_display displayCtrl _tank) ctrlSetTooltip ( format ["%1 Manpower / %2 Material", INS_tankCost select 0, INS_tankCost select 1] );
			
			buttonSetAction [_tank, "['TANK'] spawn INS_purchaseUnit"];
			buttonSetAction [_squad, "['SQUAD'] spawn INS_purchaseUnit"];
			buttonSetAction [_mgTeam, "['MG'] spawn INS_purchaseUnit"];
			buttonSetAction [_sniperTeam, "['SNIPER'] spawn INS_purchaseUnit"];
			buttonSetAction [_car, "['CAR'] spawn INS_purchaseUnit"];
			buttonSetAction [_emptyCar, "['EMPTYCAR'] spawn INS_purchaseUnit"];
			buttonSetAction [_ifv, "['IFV'] spawn INS_purchaseUnit"];
			buttonSetAction [_spy, "['SPY'] spawn INS_purchaseUnit"];
			
		};
		
		waitUntil { !isNil "INS_fastTravelFlags" };
		waitUntil { !isNil "INS_controlAreas" };
		waitUntil { !isNil "INS_areaCount" };
		waitUntil { count INS_controlAreas == INS_areaCount };
		
		INS_rscMarks = [];
		
		{
			_x params ["_name","_mark","_params"];
			_params params ["_disp","_mp","_mat"];
			
			private _marktype = "mil_warning";
			
			if ( _disp < -51 ) then {
				_marktype = "mil_flag";
			};
			
			private _marker = createMarkerLocal [ format ["__resource_mark__%1", _name], getMarkerPos _mark];
			_marker setMarkerShapeLocal "ICON";
			_marker setMarkerTypeLocal _marktype;
			_marker setMarkerColorLocal "ColorBlue";
			_marker setMarkerTextLocal (format ["Manpower: %1  /  Materials: %2", _mp, _mat]);
			_marker setMarkerAlphaLocal 1;
			INS_rscMarks pushback _mark;
		} forEach INS_controlAreas;
		
		[] spawn {
			while { true } do {
			
				{
					_x params ["_name","_mark","_params"];
					_params params ["_disp","_mp","_mat"];
					
					private _marktype = "mil_warning";
					
					if ( _disp < -51 ) then {
						_marktype = "mil_flag";
					};
					
					private _marker = INS_rscMarks select _forEachIndex;
					_marker setMarkerTypeLocal _marktype;
					
				} forEach INS_controlAreas;
				
				call INS_setupFastTravel;
				
				sleep 30;
			};
		};
		
		INS_maxMen = 45;
		
		// Costs in [manpower, materials]
		INS_spyCost = [2, 5];
		INS_squadCost = [10,20];
		INS_mgCost = [5, 20];
		INS_sniperCost = [10, 15];
		INS_carCost = [5, 50];
		INS_apcCost = [10, 100];
		INS_tankCost = [30, 250];		
		
		INS_mpMax = 75;
		INS_matMax = 300;
		INS_lastMen = 0;
		INS_menPulse = 300;
		INS_lastMat = 0;
		INS_matPulse = 400;
		
		// Starting materials and manpower
		if ( isNil "INS_playerMaterials" ) then {
			INS_playerMaterials = 100;
			publicVariable "INS_playterMaterials";
			INS_playerManpower = 50;
			publicVariable "INS_playerManpower";
		};
		
		/*     Material and Manpower
		 * Material and manpower are used to purchase units and represent abstractions of the procurement and training process
	     *   of irregular/semi regular militia and insurgencies. Capturing towns gives immediate rewards, and time based rewards.
	     * Over time the rewards gained from a town diminish, leading to a cycle where the insurgency relies on its Blufor
	     *   opponents to actually recapture towns from them in order to gain manpower and materiel.
	     *
	     *	   Procurement and Training
	     * Procurement depends on type and existing quantity. The more units a commander controls the more expensive new units
	     *  of that type become.
	     * Additionally commanders should task one area as a training center to increase unit abilities.
	     * Training only applies to the units undergoing training.
		 */
		
		
		player addMPEventHandler ["MPRespawn", {
			if ( !isNil "INS_cacheBuildings" ) then {
				private _commandbuildings = INS_cacheBuildings select { ((position _x) distance (position INS_currentCache)) > 100 };
				player setPosATL ( ([_commandbuildings call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom );
			} else {
				private _flag = selectRandom (INS_fastTravelFlags select { (((INS_controlAreas select (_x select 3)) select 2) select 0) < -24 });
				player setPos ( (getPos (_flag select 0)) findEmptyPosition [2,10,"MAN"] );
				player setDir ( (getPos player) getDir (getPos (_flag select 0)) );
			};
			player addAction ["Begin Commanding", 
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
				
		waitUntil { !isNull (findDisplay 46) };
		
		call INS_setupFastTravel;
		{
			_x hideObject false;
		} forEach INS_spies;
		
		private _flag = selectRandom (INS_fastTravelFlags select { (((INS_controlAreas select (_x select 3)) select 2) select 0) < -24 });
		player setPos ( (getPos (_flag select 0)) findEmptyPosition [2,10,"MAN"] );
		player setDir ( (getPos player) getDir (getPos (_flag select 0)) );
		
		"opfor_target" setMarkerPos (getPos player);
		
		private _mrkStart = (getPos player) vectorAdd ((vectorDir player) vectorMultiply -50);
		
		"opfor_start" setMarkerPos _mrkStart;
		
		INS_disp = false;
		
		INS_setupInfoBox = {
			
			if ( isNull SPEC_DISPLAY ) exitWith { 
				false 
			};
			
			if ( !INS_disp ) then {
				INS_infoBox2 = SPEC_DISPLAY ctrlCreate ["RscText", -1];
			
				INS_infoBox2 ctrlSetFontHeight 0.07;
				INS_infoBox2 ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.15),safeZoneY+0.01,0.3,0.07]; 
			};

			true			
		};
		
		INS_infoBox = (findDisplay 46) ctrlCreate ["RscText", -1];
			
		INS_infoBox ctrlSetFontHeight 0.07;
		INS_infoBox ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.15),safeZoneY+0.01,0.3,0.07];
		
		INS_controlled = INS_controlAreas select { ((_x select 2) select 0) < -51 };
	
		addMissionEventHandler ["Draw3d",
		{
			INS_disp = call INS_setupInfoBox;
			
			private _box = ( if ( INS_disp ) then { INS_infoBox2 } else { INS_infoBox } );
			
			_box ctrlSetText 
				( format ["Manpower: %1/%4   /   Material: %2/%5   /   Income Regions: %3", INS_playerManpower, INS_playerMaterials, count INS_controlled, INS_mpMax, INS_matMax]
				);
				
			_box ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-(ctrlTextWidth _box)/2-0.015),safeZoneY+0.01,ctrlTextWidth _box+0.03,0.07];
	
			_box ctrlCommit 0;
			
			// Process income
			if ( count ((call INS_allPlayers) select { side _x == west }) > 0 ) then {
				INS_controlled = INS_controlAreas select { ((_x select 2) select 0) < -51 };
				// manpower
				if ( time > (INS_lastMen + INS_menPulse) && INS_playerManpower < INS_mpMax ) then {
					INS_lastMen = time;
					private _amount = 0;
					{
						INS_playerManpower = INS_playerManpower + _x;
						_amount = _amount + _x;
					} forEach ( INS_controlled apply { floor ( ( (_x select 2) select 1 ) / 10 ) } );
					publicVariable "INS_playerManpower";
					titleText [ format [ "<t size='1.5'>%1 MANPOWER Income received!</t>", _amount ], "PLAIN", 1, true, true];
				};
				
				// material 
				if ( time > (INS_lastMat + INS_matPulse) && INS_playerMaterials < INS_matMax ) then {
					INS_lastMat = time;
					private _amount = 0;
					{
						INS_playerMaterials = INS_playerMaterials + _x;
						_amount = _amount + _x;
					} forEach ( INS_controlled apply { floor ( ( (_x select 2) select 2 ) / 15 ) } );
					publicVariable "INS_playerMaterials";
					titleText [ format [ "<t size='1.5'>%1 MATERIALS Income received!</t>", _amount ], "PLAIN", 1, true, true];
				};
			};
			
		}];
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
	
	publicVariable "INS_carClasses";
	publicVariable "INS_tankClasses";
	publicVariable "INS_apcClasses";
	publicVariable "INS_squadSetups";
	publicVariable "INS_civilianSetups";
	publicVariable "INS_bluforSquadSetups";
	publicVariable "INS_greenforSquadSetups";
	publicVariable "INS_mgSetups";
	publicVariable "INS_sniperSetups";
	publicVariable "INS_spySetups";	
	
	// Spawn stuff
	INS_setupFinished = false;	
	[] spawn INS_fnc_setupCaches;
	
	// Headless client strategic AI and spawning
	[] call (compile preprocessFileLineNumbers "rts\functions\shared\insurgency\setup.sqf");
	[] call (compile preprocessFileLineNumbers "rts\systems\insurgency\insurgency.sqf");
	[] call (compile preprocessFileLineNumbers "rts\systems\insurgency\hc_ai.sqf");
	
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
				[-1, { ["Coalition Victory",if (side (group player) == west ) then { true } else { false },3] call BIS_fnc_endMission; }] call CBA_fnc_globalExecute;
			} else {
				[-1, { ["Insurgent Victory",if (side (group player) == east ) then { true } else { false },3] call BIS_fnc_endMission; }] call CBA_fnc_globalExecute;
			};
		};
	};
	
	[] spawn {
		waitUntil { !isNil "INS_cache1" };
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
								private _suitcase = "Suitcase" createVehicle ((getPosATL _unit) findEmptyPosition [0,30,"Suitcase"]);
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
	
	// Mission coordinator
	private _insmon = [] spawn (compile preprocessFileLineNumbers "rts\systems\insurgency\insurgency.sqf");
	waitUntil { scriptDone _insmon };
	// Serverside AI controller
	[] spawn (compile preprocessFileLineNumbers "rts\systems\insurgency\ai_controller.sqf");
	[] call (compile preprocessFileLineNumbers "rts\systems\insurgency\base_setup.sqf");
	[] call (compile preprocessFileLineNumbers "rts\systems\insurgency\cqb_training.sqf");
	diag_log "Server Init Complete";
};

if ( isDedicated || !hasInterface ) exitWith {};

{
	_x setMarkerColorLocal "ColorBlue";
} forEach RTS_restrictionZone;

// Setup Blufor Player
if ( side player == west ) then {
	[] spawn {	
		while { true } do {
			{
				_x params ["_flag","_city","_marker"];
				
				_flag hideObject true;
			} forEach INS_fastTravelFlags;
			sleep 2;
		};
	};
	
	player addMPEventHandler [ "MPRespawn",
							{ 
								private _condition = { !INS_fobDeployed && !((getPos player) inArea "opfor_restriction") && (leader (group player)) == player };
								private _action = ["Create FOB","Deploy FOB at your location.","",INS_createFob,_condition] call ace_interact_menu_fnc_createAction;
								[player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
								[0, { INS_bluforCasualties = INS_bluforCasualties + 1; publicVariable "INS_bluforCasualties"; }] call CBA_fnc_globalExecute
							}];
	
	CQB_flag addAction [
		"Start CQB Training",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			[[],{ call INS_startCqbTraining; }] remoteExec ["call",2];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"!INS_cqbStarted",
		5,
		false,
		"",
		""
	];
	
	CQB_flag addAction [
		"Reset CQB Training",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			[[],{ { deleteVehicle _x; } forEach (call INS_getCqbSoldiers); }] remoteExec ["call",2];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"INS_cqbStarted",
		5,
		false,
		"",
		""
	];
	
	base_flag addAction [
		"Deploy to FOB",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			(vehicle player) setPosATL ((getPos fob_flag) findEmptyPosition [2, 50, typeOf (vehicle player)]);
		},
		nil,
		1.5,
		true,
		true,
		"",
		"INS_fobDeployed && count ([fob_flag, allUnits select { side (group _x) != civilian && side (group _x) != west }, 500] call CBA_fnc_getNearest) == 0",
		5,
		false,
		"",
		""
	];
	
	fob_flag addAction [
		"Undeploy FOB",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			[fob_flag, true] remoteExec ["hideObjectGlobal", 2];
			fob_flag setPosATL INS_initFobFlagPos;
			deleteMarker INS_fobMarker;
			INS_fobDeployed = false;
			publicVariable "INS_fobDeployed";
		},
		nil,
		1.5,
		true,
		true,
		"",
		"INS_fobDeployed && (leader (group player)) == player",
		5,
		false,
		"",
		""
	];
	
	fob_flag addAction [
		"Deploy to Airbase",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			(vehicle player) setPosATL ((getPos base_flag) findEmptyPosition [2, 50, typeOf (vehicle player)]);
		},
		nil,
		1.5,
		true,
		true,
		"",
		"count ([player, allUnits select { side (group _x) != civilian && side (group _x) != west }, 500] call CBA_fnc_getNearest) == 0",
		5,
		false,
		"",
		""
	];
	
	arsenal_crate addAction [
		"Get Spare Ammo Crate",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			["AMMO",getPos player, group player] call RTS_fnc_spawnCrate;
			(group player) setVariable ["INS_ammoCrateSpawned", time, true];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"time > (((group player) getVariable ['INS_ammoCrateSpawned',-300]) + 300)",
		10,
		false,
		"",
		""
	];
	
	arsenal_crate addAction [
		"Get Medical Crate",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			["MEDICAL",getPos player, group player] call RTS_fnc_spawnCrate;
			(group player) setVariable ["INS_medicCrateSpawned", time, true];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"time > (((group player) getVariable ['INS_medicCrateSpawned',-300]) + 300)",
		10,
		false,
		"",
		""
	];
	
	arsenal_crate addAction [
		"Get Vehicle Ammo Crate",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			["VEHICLE_AMMO",getPos player, group player] call RTS_fnc_spawnCrate;
			INS_vehicleAmmoCrateSpawned = time;
			publicVariable "INS_vehicleAmmoCrateSpawned";
		},
		nil,
		1.5,
		true,
		true,
		"",
		"time > (INS_vehicleAmmoCrateSpawned + 1800)",
		10,
		false,
		"",
		""
	];
	
	arsenal_crate addAction [
		"Get Fuel Pallet",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			["FUEL",getPos player, group player] call RTS_fnc_spawnCrate;
			INS_fuelPalletSpawned = time;
			publicVariable "INS_fuelPalletSpawned";
		},
		nil,
		1.5,
		true,
		true,
		"",
		"time > (INS_fuelPalletSpawned + 1800)",
		10,
		false,
		"",
		""
	];
	
	INS_createFob = {
		[fob_flag, false] remoteExecCall ["hideObjectGlobal", 2];
		private _pos = (getPosATL player) findEmptyPosition [2, 15, typeOf fob_flag];
		fob_flag setPosATL _pos;
		player reveal fob_flag;
		INS_fobMarker = createMarker ["Insurgency_Fob_Marker", _pos ];
		INS_fobMarker setMarkerColor "ColorBlue";
		INS_fobMarker setMarkerShape "ICON";
		INS_fobMarker setMarkerType "mil_flag";
		INS_fobMarker setMarkerText "FOB Sentinel";
		publicVariable "INS_fobMarker";
		INS_fobDeployed = true;
		publicVariable "INS_fobDeployed";
	};
	
	private _condition = { !INS_fobDeployed && !((getPos player) inArea "opfor_restriction") && (leader (group player)) == player };
	private _action = ["Create FOB","Deploy FOB at your location.","",INS_createFob,_condition] call ace_interact_menu_fnc_createAction;
	[player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
		
	waitUntil { ! (isNull (findDisplay 46)) };

	INS_infoBox = (findDisplay 46) ctrlCreate ["RscText", -1];
	
	INS_infoBox ctrlSetFontHeight 0.07;
	INS_infoBox ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.15),safeZoneY+0.01,0.3,0.07]; 
	
	INS_localTruckMarker = createMarkerLocal ["local_ins_truck_marker",[0,0,0]];
	INS_localTruckMarker setMarkerShapeLocal "ICON";
	INS_localTruckMarker setMarkerTextLocal "AID Vehicle";
	INS_localTruckMarker setMarkerColorLocal "ColorBlue";
	INS_localTruckMarker setMarkerTypeLocal "select";
	INS_localTruckMarker setMarkerAlphaLocal 0;

	addMissionEventHandler ["Draw3d",
	{
		if ( INS_bluforMission == "AID" ) then {
			INS_localTruckMarker setMarkerAlphaLocal 1;
			INS_localTruckMarker setMarkerPosLocal (getPos INS_aidTruck);
		} else {
			INS_localTruckMarker setMarkerAlphaLocal 0;
		};
	
		// Update insurgency info display
		if ( INS_bluforPacification ) then {
			INS_infoBox ctrlSetText 
				( format ["Blufor Casualties - %1 / %2 | Caches Remaining - %3", INS_bluforCasualties, INS_maxCasualties, INS_caches]
				);
		} else {
			private _bluforZones = count (INS_controlAreas select { ( (_x select 2) select 0 ) >= 51 });
			INS_infoBox ctrlSetText 
				( format ["Blufor Casualties - %1 / %2 | Towns Remaining - %3", INS_bluforCasualties, INS_maxCasualties, INS_bluforZoneAmount - _bluforZones]
				);
		};
		INS_infoBox ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-(ctrlTextWidth INS_infoBox)/2-0.015),safeZoneY+0.01,ctrlTextWidth INS_infoBox+0.03,0.07];

		INS_infoBox ctrlCommit 0;
	}];
	
};