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
								 		"opfor_target" setMarkerPos (getPos player);
										private _mrkStart = (getPos player) vectorAdd ((vectorDir player) vectorMultiply -50);
										"opfor_start" setMarkerPos _mrkStart;
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
						private _rtsSetup = (group _soldier) getVariable "RTS_Setup";
						(group _soldier) setVariable [ "RTS_Setup", [ _rtsSetup # 0,
																	  _rtsSetup # 1,
																	  _rtsSetup # 2,
																	  _rtsSetup # 3,
																	  _rtsSetup # 4,
																	  selectRandomWeighted ["GREEN", 0.2, "VETERAN", 0.8, "ELITE", 0.3 ],
																	  selectRandomWeighted [ 2,0.5,
																						     3,0.2,
																							 1,0.8,
																							 -1,0.3,
																							 -2,0.1,
																							 0,0.9 ] ], true ];
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
					
					private _marker = format ["__resource_mark__%1", _name];
					_marker setMarkerTypeLocal _marktype;
					
				} forEach INS_controlAreas;
				
				call INS_setupFastTravel;
				
				sleep 30;
			};
		};
		
		INS_maxMen = 45;
		
		// Costs in [manpower, materials]
		INS_spyCost = [3, 10];
		INS_squadCost = [6,8];
		INS_mgCost = [5, 12];
		INS_sniperCost = [4, 8];
		INS_carCost = [5, 25];
		INS_apcCost = [10, 65];
		INS_tankCost = [30, 150];		
		
		INS_mpMax = 85;
		INS_matMax = 400;
		INS_lastMen = 0;
		INS_menPulse = 220;
		INS_lastMat = 0;
		INS_matPulse = 300;
		
		// Starting materials and manpower
		if ( isNil "INS_playerMaterials" ) then {
			INS_playerMaterials = 250;
			publicVariable "INS_playterMaterials";
			INS_playerManpower = 75;
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
				
				INS_refundButton = SPEC_DISPLAY ctrlCreate ["RscButton", -1];
				INS_refundButton ctrlSetText "Refund Unit";
				INS_refundButton buttonSetAction "[RTS_selectedGroup] call INS_fnc_refundUnit";
				INS_refundButton ctrlEnable false;
				INS_refundButton ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.05) - 0.152,safeZoneY+0.073,0.15,0.07]; 
				
				INS_moveButton = SPEC_DISPLAY ctrlCreate ["RscButton", -1];
				INS_moveButton ctrlSetText "Deploy On Commander";
				INS_moveButton buttonSetAction "[RTS_selectedGroup] call INS_fnc_moveUnitToCommander";
				INS_moveButton ctrlEnable false;
				INS_moveButton ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.05),safeZoneY+0.073,0.20,0.07];
				
				INS_repairRearm = SPEC_DISPLAY ctrlCreate ["RscButton", -1];
				INS_repairRearm ctrlSetText "Repair & Rearm";
				INS_repairRearm buttonSetAction "[RTS_selectedGroup] call INS_fnc_repairRearmUnit";
				INS_repairRearm ctrlEnable false;
				INS_repairRearm ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.05) + 0.2,safeZoneY+0.073,0.15,0.07];
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
			
			if ( INS_disp ) then { 
				if ( !(isNull RTS_selectedGroup) ) then {
					([RTS_selectedGroup] call INS_fnc_calculateRefundRearmCost) params [ "_mat", "_man" ];
					private _leaderPos = getPosATL (leader RTS_selectedGroup);
					private _nearEnemies = count (allUnits select { side _x != civilian && side _x != east && ((getPos _x) distance2d _leaderPos) < 650 }) > 0;
					INS_refundButton ctrlEnable ( !_nearEnemies );
					INS_refundButton ctrlSetTooltip ( format ["Manpower: %1 / Materials: %2", _man, _mat] );
					INS_moveButton ctrlEnable ( !_nearEnemies );
					INS_repairRearm ctrlEnable ( !_nearEnemies && _mat <= INS_playerMaterials && _man <= INS_playerManpower );
				} else {
					INS_refunButton ctrlSetTooltip "";
					INS_refundButton ctrlEnable false;
					INS_moveButton ctrlEnable false;
					INS_repairRearm ctrlEnable false;
				};
				INS_refundButton ctrlCommit 0;
				INS_moveButton ctrlCommit 0;
				INS_repairRearm ctrlCommit 0;
			};
			
			// Process income

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
			
		}];
		if ( isNil "RTS_postCmmand_Finished" ) then {
			[] spawn (compile preprocessFileLineNumbers "commander_post_setup.sqf");
			
			RTS_postCommand_Finished = true;
			publicVariable "RTS_postCommand_Finished";
		};
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
									private _pos = getPosATL ( if (INS_caches == 2) then { INS_cache1 } else { INS_cache2 } );
									private _distance = 1100 - (INS_intelLevel*25);
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
	
	{
		_x params ["_name","_marker"];
		private _localMarker = createMarkerLocal [ _marker + "__local_blufor", getMarkerPos _marker ];
		_localMarker setMarkerShapeLocal ( markerShape _marker );
		_localMarker setMarkerColorLocal ( getMarkerColor _marker );
		_localMarker setMarkerBrushLocal ( markerBrush _marker );
		_localMarker setMarkerSizeLocal ( getMarkerSize _marker );
		_localMarker setMarkerDirLocal ( markerDir _marker );
		_marker setMarkerAlphaLocal 0;
	} forEach INS_controlAreas;
	
	FOB_arsenal_Class = "CargoNet_01_box_F";
	FOB_layout = [
	    ["Land_CamoNetVar_NATO_EP1",[0.866211,-2.41064,0],0,1,0,[],"","",true,false], 
	    ["Land_Laptop_02_unfolded_F",[2.6416,-0.231445,0.0104232],75.4494,1,0,[],"","",true,false], 
	    ["FoldTable",[2.88916,-0.17334,0],74.7982,1,0,[],"","",true,false], 
	    ["Land_Sacks_goods_F",[-3.1001,0.0649414,0],30,1,0,[],"","",true,false], 
	    ["Land_CratesPlastic_F",[3.89453,0.455566,0],270,1,0,[],"","",true,false], 
	    ["Land_Sacks_heap_F",[-3.90234,1.43213,0],330,1,0,[],"","",true,false], 
	    ["Land_CratesShabby_F",[-4.25977,0.0966797,0],0,1,0,[],"","",true,false], 
	    ["Land_Sacks_heap_F",[4.64258,-0.797363,0],195,1,0,[],"","",true,false], 
	    ["Land_CampingChair_V2_F",[3.81641,-3.71289,-1.90735e-006],227.615,1,0,[],"","",true,false], 
	    ["PowerGenerator_EP1",[-3.73242,-3.79736,0],165,1,0,[],"","",true,false], 
	    ["Land_HBarrier5",[-5.55811,-2.05371,0],270,1,0,[],"","",true,false], 
	    ["Land_CampingChair_V2_F",[5.15039,-2.06982,-1.43051e-006],15.7636,1,0,[],"","",true,false], 
	    ["Land_CratesWooden_F",[5.51758,0.452637,0],0,1,0,[],"","",true,false], 
	    ["Land_HBarrier5",[3.26123,2.15381,0],0,1,0,[],"","",true,false], 
	    ["Land_Sacks_heap_F",[5.89258,-0.797363,0],0,1,0,[],"","",true,false], 
	    ["CargoNet_01_box_F",[3.51367,-5.57471,0],218.481,1,0,[],"","",true,false], 
	    ["Land_CampingChair_V2_F",[5.03613,-4.56201,2.38419e-006],200.587,1,0,[],"","",true,false], 
	    ["Land_CampingChair_V2_F",[6.24902,-2.7417,-1.90735e-006],52.2189,1,0,[],"","",true,false], 
	    ["Land_HBarrier5",[-4.22119,-7.24707,0],255,1,0,[],"","",true,false], 
	    ["AmmoCrateNoInteractive",[-6.75,-3.20068,0],90,1,0,[],"","",true,false], 
	    ["Land_HBarrier5",[7.59326,0.833984,0],90,1,0,[],"","",true,false], 
	    ["Land_PaperBox_closed_F",[-6.7417,-4.68018,0],240,1,0,[],"","",true,false], 
	    ["AmmoCrates_NoInteractive_Medium",[-6.08301,-6.0332,0],345,1,0,[],"","",true,false], 
	    ["Land_HBarrier5",[4.24365,-7.33984,0],315,1,0,[],"","",true,false], 
	    ["M1130_HQ_unfolded_Base_EP1",[-0.982422,8.57764,0],0,1,0,[],"","",true,false], 
	    ["Land_HBarrier_large",[4.55713,9.59033,0],90,1,0,[],"","",true,false], 
	    ["MetalBarrel_burning_F",[-8.35742,6.70264,0],315,1,0,[],"","",true,false], 
	    ["Land_PaperBox_open_empty_F",[2.39258,12.9521,0],180,1,0,[],"","",true,false], 
	    ["Land_HBarrier5",[1.95459,17.8188,0],60,1,0,[],"","",true,false], 
	    ["Land_PaperBox_closed_F",[0.900879,16.3179,0],150,1,0,[],"","",true,false], 
	    ["NDS_6x6_ATV_MIL2_LR",[-3.98486,15.8545,-0.0351567],337.386,0.984764,0,[],"","",true,false], 
	    ["NDS_6x6_ATV_MIL2_LR",[-1.97168,16.561,-0.0342455],336.495,1,0,[],"","",true,false], 
	    ["Land_HBarrier1",[-6.3584,16.3184,0],75,1,0,[],"","",true,false], 
	    ["Land_BagFence_End_F",[1.8042,17.9248,-0.000999928],60,1,0,[],"","",true,false], 
	    ["Land_BagFence_Round_F",[0.427734,19.605,-0.00130129],195,1,0,[],"","",true,false]
	];
	
	player addMPEventHandler [ "MPRespawn",
							{ 
								//private _condition = { !INS_fobDeployed && !((getPos player) inArea "opfor_restriction") && (leader (group player)) == player };
								//private _action = ["Create FOB","Deploy FOB at your location.","",INS_createFob,_condition] call ace_interact_menu_fnc_createAction;
								//[player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
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
	
	// CQB Settings
	//// Civilian Enable
	CQB_flag addAction [
		"Toggle Civilians: <t color='#FF0000'>DISABLED</t>",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			[[],{ 
				INS_civilians = true;
				publicVariable "INS_civilians";
			}] remoteExec ["call",2];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"!INS_civilians",
		5,
		false,
		"",
		""
	];
	//// Civilian Disable
	CQB_flag addAction [
		"Toggle Civilians: <t color='#00FF00'>ENABLED</t>",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			[[],{ 
				INS_civilians = false;
				publicVariable "INS_civilians";
			}] remoteExec ["call",2];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"INS_civilians",
		5,
		false,
		"",
		""
	];
	//// Shootback Enable
	CQB_flag addAction [
		"Toggle Live-Fire: <t color='#FF0000'>DISABLED</t>",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			[[],{ 
				INS_shootback = true;
				publicVariable "INS_shootback";
			}] remoteExec ["call",2];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"!INS_shootback",
		5,
		false,
		"",
		""
	];
	//// Shootback Disable
	CQB_flag addAction [
		"Toggle Live-Fire: <t color='#00FF00'>ENABLED</t>",
		{
			params ["_target", "_caller", "_actionId", "_arguments"];
			[[],{ 
				INS_shootback = false;
				publicVariable "INS_shootback";
			}] remoteExec ["call",2];
		},
		nil,
		1.5,
		true,
		true,
		"",
		"INS_shootback",
		5,
		false,
		"",
		""
	];
	
	// TP
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
		10,
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
			{
				if ( _x isKindOf "AIR" || _x isKindOf "CAR" || _x isKindOf "TANK" ) then {
					if ( count (crew _x) == 0 ) then {
						deleteVehicle _x;
					};
				} else {
					deleteVehicle _x;
				};
			} forEach INS_fob_Objects;
			INS_fob_Objects = [];
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
	
	INS_fobMarker = createMarkerLocal ["Insurgency_Fob_Marker", getPos fob_flag ];
	INS_fobMarker setMarkerColorLocal "ColorBlue";
	INS_fobMarker setMarkerShapeLocal "ICON";
	INS_fobMarker setMarkerTypeLocal "mil_flag";
	INS_fobMarker setMarkerTextLocal "FOB Sentinel";
	INS_fobMarker setMarkerAlphaLocal 0;
	
	INS_createFob = {
		private _pos = (getPosATL player) findEmptyPosition [2, 5, typeOf fob_flag];
		[fob_flag, false] remoteExecCall ["hideObjectGlobal", 2];
		fob_flag setPosATL _pos;
		player reveal fob_flag;
		publicVariable "INS_fobMarker";
		INS_fobDeployed = true;
		publicVariable "INS_fobDeployed";
		INS_fob_Objects = [ _pos, getDir player, FOB_layout ] call BIS_fnc_ObjectsMapper;
		{
			[_x, true] call ace_arsenal_fnc_initBox;	
		} forEach (INS_fob_Objects select { _x isKindOf FOB_arsenal_Class });
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

	INS_bluforGrpMarkers = [];

	INS_markerUpdate = 0;

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
		
		if ( INS_markerUpdate < time - 3 ) then {
			{
				_x params ["_name","_marker","_stats"];
				if ( (_stats # 4) < 50 ) then {
					if ( ( (_x select 2) select 0 ) >= 51 ) then {
						( _marker + "__local_blufor" ) setMarkerColorLocal "ColorBlue";
					} else {
						( _marker + "__local_blufor" ) setMarkerColorLocal "ColorRed";
					};
				} else {
					( _marker + "__local_blufor" ) setMarkerColorLocal (getMarkerColor _marker);
				};
			} forEach INS_controlAreas;
			INS_markerUpdate = time;
		};
		
		private _humanPlayers = call INS_allPlayers;
		private _bluformarks = [];
		{
			private _group = _x;
			
			
			if ( count ( (units _group) select { alive _x } ) == 0 ) then {
				private _marker = _group getVariable ["blufor_tracker", createMarkerLocal [ str _group, [0,0,0] ] ];
				deleteMarkerLocal _marker;
			};
			private _leader = leader _group;
		
			if ( !( _leader in _humanPlayers ) && !((getPos _leader) inArea "opfor_restriction") ) then {
				private _marker = _group getVariable ["blufor_tracker", createMarkerLocal [ str _group, getPos _leader ]];
				_marker setMarkerShapeLocal "ICON";
				_marker setMarkerPosLocal (getPos _leader);
				private _veh = vehicle _leader;
				if ( _veh isKindOf "Car" ) then {
					_marker setMarkerTypeLocal "b_motor_inf";
				};
				if ( _veh isKindOf "APC" ) then {
					_marker setMarkerTypeLocal "b_mech_inf";
				};
				if ( _veh isKindOf "Tank" ) then {
					_marker setMarkerTypeLocal "b_armor";
				};
				if ( _veh isKindOf "StaticWeapon" ) then {
					_marker setMarkerTypeLocal "b_support";
				};
				if ( _veh isKindOf "Man" ) then {
					_marker setMarkerTypeLocal "b_inf";
				};
				_marker setMarkerColorLocal "ColorBlufor";
				_bluformarks pushback _marker;
				
			};
		} forEach ( allGroups select { side _x == west && ((getPos (leader _x)) distance2d (getPos player)) < 1500  } );
		
		{
			if ( !( _x in _bluformarks ) ) then {
				deleteMarkerLocal _x;
			};
		} forEach INS_bluforGrpMarkers;
		INS_bluforGrpMarkers = _bluformarks;
		
		if ( !( isObjectHidden fob_flag ) ) then {
			INS_fobMarker setMarkerAlphaLocal 1;
			INS_fobMarker setMarkerPosLocal (getPos fob_flag);
		} else {
			INS_fobMarker setMarkerAlphaLocal 0;
		};
	}];
	
};