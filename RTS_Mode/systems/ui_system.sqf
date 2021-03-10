#include "\z\ace\addons\spectator\script_component.hpp"
#include "../RTS_Defines.hpp"

waitUntil { ! (isNull SPEC_DISPLAY) };

RTS_phaseBox = SPEC_DISPLAY ctrlCreate ["RscText", -1];

RTS_phaseBox ctrlSetFontHeight 0.07;
RTS_phaseBox ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.15),safeZoneY+0.01,0.3,0.07]; 

RTS_phaseButton = SPEC_DISPLAY ctrlCreate ["RscButton", -1];
RTS_phaseButton ctrlSetText "DONE";
RTS_phaseButton ctrlSetFontHeight 0.07;
RTS_phaseButton ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.175),safeZoneY+0.08,0.35,0.07];
RTS_phaseButtonAction = "RTS_targetPhase = if ( RTS_phase == 'DEPLOY' ) then { 'INITIALORDERS' } else { 'MAIN' }; [0, { _this call RTS_fnc_advancePhase }, [player, if ( RTS_phase == 'DEPLOY' ) then { 'INITIALORDERS' } else { 'MAIN' }] ] call CBA_fnc_globalExecute;";
RTS_phaseButton buttonSetAction RTS_phaseButtonAction;
RTS_phaseButton ctrlCommit 0;
RTS_phaseButton ctrlShow false;

if ( isNil "RTS_missionTimeElapsedSoFar" ) then {
	RTS_missionTimeElapsedSoFar = 0;
};

// Wait for mission to start
[] spawn { 
	if ( isNil "RTS_missionTimeStarted" && RTS_missionTimeElapsedSoFar == 0 ) then {
		waitUntil { RTS_phase == "MAIN" };
		RTS_missionTimeStarted = time;
	};
};

RTS_targetPhase = RTS_phase;
[] spawn {
	while { RTS_commanding && !RTS_skipDeployment } do {
		if ( RTS_phase == "MAIN" && RTS_paused && !(isNil "RTS_missionTimeStarted") ) then {
			RTS_missionTimeElapsedSoFar = RTS_missionTimeElapsedSoFar + time - RTS_missionTimeStarted;
			RTS_missionTimeStarted = nil;
		};
		
		if ( RTS_phase == "MAIN" && !RTS_paused && (isNil "RTS_missionTimeStarted") ) then {
			RTS_missionTimeStarted = time;
		};
			
		// Update phase display
		RTS_phaseBox ctrlSetText 
			( if ( RTS_paused ) then { 
				"Paused!" 
				} else { 
					switch RTS_phase do {
					case "DEPLOY": {"Deployment Phase"};
					case "MAIN": { if ( !(isNil "RTS_missionTimeStarted") ) then {
									format ["Combat Phase  -  %1", [RTS_missionTimeElapsedSoFar + time - RTS_missionTimeStarted] call BIS_fnc_secondsToString ]
								   } else {
								   	"Combat Phase"
								   }
								 };
					case "INITIALORDERS": {"Initial Orders Phase"};
					}
				}
			);
		RTS_phaseBox ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-(ctrlTextWidth RTS_phaseBox)/2-0.015),safeZoneY+0.01,ctrlTextWidth RTS_phaseBox+0.03,0.07];
		
		if ( RTS_phase == "MAIN" ) then {
			RTS_phaseButton ctrlShow false;
		};
		if ( RTS_paused ) then {
			RTS_phaseButton ctrlSetText "Paused!";
			RTS_phaseButton ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.175),safeZoneY+0.08,0.35,0.07];
			RTS_phaseButton ctrlEnable false;
		} else {
			if ( RTS_targetPhase != RTS_phase ) then {
				RTS_phaseButton ctrlSetText "Waiting...";
				RTS_phaseButton ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.175),safeZoneY+0.08,0.35,0.07];
				RTS_phaseButton ctrlEnable false;
			} else {
				RTS_phaseButton ctrlSetText "DONE";
				RTS_phaseButton ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.175),safeZoneY+0.08,0.35,0.07];
				RTS_phaseButton ctrlEnable true;
			};
		};
		RTS_phaseButton ctrlCommit 0;
		RTS_phaseBox ctrlCommit 0;
		sleep 0.5;
	};
	
	ctrlDelete RTS_phaseButton;
	ctrlDelete RTS_phaseBox;

};

waitUntil { RTS_groupSetupComplete };

// Setup Unit Info Screen

RTS_showingUnitData = true;
RTS_showingArtilleryMenu = false;
RTS_showingEquipment = false;
RTS_showingOptions = false;
RTS_showingOOB = false;

RTS_unitDataControls = [];
RTS_unitInfoControls = [];

RTS_artilleryMenuControls = [];

RTS_overViewPanel = SPEC_DISPLAY ctrlCreate ["UnitOverViewPanel", -1];

{
	RTS_unitDataControls pushback (SPEC_DISPLAY ctrlCreate [ _x, -1]);
} forEach
 [	"StatusLabel",
 	"CombatModeLabel",
	"MoraleLabel",
	"StanceLabel",
	"CommandEffectLabel",
	"CombatVictoriesLabel",
	"CasualtyLabel",
	"FormationLabel",
	"HasRadioLabel",
	"AmmoLevelLabel",
	"PassengerInfoLabel"
];

RTS_statusText = SPEC_DISPLAY ctrlCreate ["StatusText", -1];
RTS_moraleText = SPEC_DISPLAY ctrlCreate ["MoraleText", -1];
RTS_commandEffectText = SPEC_DISPLAY ctrlCreate ["CommandEffectText", -1];
RTS_combatVictoryText = SPEC_DISPLAY ctrlCreate ["CombatVictoryText", -1];
RTS_combatModeText = SPEC_DISPLAY ctrlCreate ["CombatModeText", -1];
RTS_casualtyText = SPEC_DISPLAY ctrlCreate ["CasualtyText", -1];
RTS_formationText = SPEC_DISPLAY ctrlCreate ["FormationText", -1];
RTS_stanceText = SPEC_DISPLAY ctrlCreate ["StanceText", -1];
RTS_hasRadioText = SPEC_DISPLAY ctrlCreate ["HasRadioText", -1];
RTS_ammoLevelText = SPEC_DISPLAY ctrlCreate ["AmmoLevelText", -1];
RTS_passengerInfoText = SPEC_DISPLAY ctrlCreate ["PassengerInfoText", -1];

RTS_deployUndeployBtn = SPEC_DISPLAY ctrlCreate ["DeployUndeployBtn", -1];
RTS_deployUndeployBtn buttonSetAction "[RTS_selectedGroup] call RTS_fnc_deployUndeploy;";

RTS_selectCommanderBtn = SPEC_DISPLAY ctrlCreate ["SelectCommanderBtn", -1];
RTS_selectCommanderBtn buttonSetAction "RTS_selectedGroup = RTS_selectedGroup getVariable [""command_element"", grpnull];";

RTS_controlUnitBtn = SPEC_DISPLAY ctrlCreate ["ControlBtn", -1];
RTS_controlUnitBtn buttonSetAction "if ( RTS_phase == ""MAIN"" ) then { call RTS_fnc_takeControlOfUnit; };";

RTS_unitNameText = SPEC_DISPLAY ctrlCreate ["UnitNameText", -1];
RTS_unitCallsignText = SPEC_DISPLAY ctrlCreate ["UnitCallsignText", -1];


// Artillery Menu
RTS_artMagazineLabel = SPEC_DISPLAY ctrlCreate ["ArtMagazineLabel", -1];
RTS_artMagazineLabel ctrlShow false;

RTS_artGunCountLabel = SPEC_DISPLAY ctrlCreate ["ArtGunCountLabel", -1];
RTS_artGunCountLabel ctrlShow false;

RTS_artDurationLabel = SPEC_DISPLAY ctrlCreate ["ArtDurationLabel", -1];
RTS_artDurationLabel ctrlShow false;

RTS_artDelayLabel = SPEC_DISPLAY ctrlCreate ["ArtDelayLabel", -1];
RTS_artDelayLabel ctrlShow false;

RTS_artSizeLabel = SPEC_DISPLAY ctrlCreate ["ArtSizeLabel", -1];
RTS_artSizeLabel ctrlShow false;

RTS_artStatusLabel = SPEC_DISPLAY ctrlCreate ["ArtStatusLabel", -1];
RTS_artStatusLabel ctrlShow false;

RTS_artMagazineBox = SPEC_DISPLAY ctrlCreate ["ArtMagazineBox", -1];
RTS_artMagazineBox ctrlShow false;

RTS_artGunCountBox = SPEC_DISPLAY ctrlCreate ["ArtGunCountBox", -1];
RTS_artGunCountBox ctrlShow false;

RTS_artDurationBox = SPEC_DISPLAY ctrlCreate ["ArtDurationBox", -1];
RTS_artDurationBox ctrlShow false;

RTS_artDelayBox = SPEC_DISPLAY ctrlCreate ["ArtDelayBox", -1];
RTS_artDelayBox ctrlShow false;

RTS_artSizeBox = SPEC_DISPLAY ctrlCreate ["ArtSizeBox", -1];
RTS_artSizeBox ctrlShow false;

RTS_artBackBtn = SPEC_DISPLAY ctrlCreate ["ArtBackBtn", -1];
RTS_artBackBtn buttonSetAction " RTS_showingUnitData = true; RTS_showingArtilleryMenu = false;";
////////////

{ 
	RTS_artilleryMenuControls pushback _x;
} forEach [ RTS_artSizeBox, RTS_artStatusLabel, RTS_artSizeLabel, RTS_artMagazineLabel, RTS_artGunCountLabel, RTS_artDurationLabel, RTS_artDelayLabel, RTS_artMagazineBox, RTS_artGunCountBox, RTS_artDurationBox, RTS_artDelayBox, RTS_artBackBtn ];

{
	RTS_unitDataControls pushback _x;
} forEach [ RTS_passengerInfoText,RTS_statusText,RTS_moraleText,RTS_commandEffectText,RTS_combatVictoryText,RTS_combatModeText,RTS_casualtyText,RTS_formationText,RTS_stanceText,RTS_hasRadioText,RTS_ammoLevelText];

{
	RTS_unitInfoControls pushback _x;
} forEach [ RTS_unitCallsignText, RTS_controlUnitBtn, RTS_selectCommanderBtn, RTS_deployUndeployBtn ];


// General ui controls

RTS_showOOBBtn = SPEC_DISPLAY ctrlCreate ["OOBBtn", -1];
RTS_showOOBBtn buttonSetAction " RTS_showingUnitData = !RTS_showingUnitData; RTS_showingOOB = !RTS_showingOOB; ";

RTS_oobTree = SPEC_DISPLAY ctrlCreate ["RscTree", -1];
RTS_oobTree ctrlSetFont "EtelkaMonospacePro"; 
RTS_oobTree ctrlSetFontHeight 0.04; 
RTS_oobTree ctrlSetPosition [0.0104056 * safezoneW + safezoneX,
					 0.148035 * safezoneH + safezoneY,
					 0.155062 * safezoneW,
					 0.381985 * safezoneH];

findCommander = {
	params ["_group","_target","_subgroups"];
		
	private _ret = false;
	
	for "_j" from 0 to ((count _subgroups) - 1) do {
		(_subgroups select _j) params ["_cmd","_subsubgroups"];
		if ( _cmd == _target ) then {
			_subsubgroups pushback [_group,[]];
			_ret = true;
		} else {
			_ret = _ret || [_group,_target,_subsubgroups] call findCommander;
		};
	};
	
	_ret
};

RTS_getOOBData = {

	private _oobData = [];
	private _activegroups = (RTS_commandingGroups select { (count (units _x)) > 0 });
	private _commanders = _activegroups select { isNull (_x getVariable "command_element") };
	private _subordinates = _activegroups select { !(isNull (_x getVariable "command_element")) };
	// get commanding units
	{	
		_oobData pushback [_x,[]];
	} forEach _commanders;
	
	private _leftovers = _subordinates;
	
	while { count _leftovers > 0 } do {
		private _array = [];

		{
			private _group = _x;
			private _cmdfound = false;
			private _commander = _x getVariable "command_element";
	
			if ( count (units _commander) > 0 ) then {
				
				_cmdfound = _cmdfound || [_group,_commander, _oobData] call findCommander;				
								
				if ( !_cmdfound ) then {
					_array pushback _group;
				};
				
			} else {
				_group setVariable ["command_element", grpnull];
				_oobData pushback [_group,[]];
			};
			
		} forEach _leftovers;	
		_leftovers = +_array;
	};
	
	_oobData
};

RTS_oobData = call RTS_getOOBData;
RTS_groupsSize = count (RTS_commandingGroups select { count (units _x) > 0 });
RTS_newOOB = true;

RTS_oobSelection = [];
RTS_oobSelectedGroup = grpnull;

RTS_oobTree ctrlSetBackgroundColor [0,0,0,0];
RTS_oobTree ctrlCommit 0;
RTS_oobTree ctrlShow false;

RTS_oobTree ctrlAddEventHandler ["MouseButtonDblClick", 
	{
		call RTS_OOBselector; 	
		[leader RTS_selectedGroup] call ace_spectator_fnc_setFocus;
	}];

RTS_populateOOBTree = {
	params ["_ctIndex","_data","_control"];
	
	for "_i" from 0 to ((count _data) - 1) do {
		(_data select _i) params ["_grp","_subgroups"];
		private _tv = _control tvAdd [_ctIndex, _grp getVariable ["desc","Unknown"]];
		private _index = +_ctIndex;
		_index pushback _i;
		_control tvSetPicture [ _index, _grp getVariable ["texture", ""] ];
		_control tvSetPictureColor [ _index, RTS_sideColor ];
		
		if ( _grp == RTS_selectedGroup ) then {
			_control tvSetCurSel _index;
		};
	};
	
	for "_i" from 0 to ((count _data) - 1) do {
		(_data select _i) params ["_grp","_subgroups"];
		private _index = +_ctIndex;
		_index pushback _i;
		[_index,_subgroups,_control] call RTS_populateOOBTree;
	};

};

RTS_findSelectedGroup = {
	params ["_ctIndex","_data"];
	
	private _found = false;
	
	for "_i" from 0 to ((count _data) - 1) do {
		(_data select _i) params ["_grp","_subgroups"];
		if ( RTS_selectedGroup == _grp ) then {
			_found = true;
			_ctIndex pushback _i;
		};
	};
	
	if ( _found ) exitWith { _ctIndex };
	
	for "_i" from 0 to ((count _data) - 1) do {
		(_data select _i) params ["_grp","_subgroups"];
		private _index = +_ctIndex;
		_index pushback _i;
		private _search = [_index,_subgroups] call RTS_findSelectedGroup;
		if ( !isNil "_search" ) then {
			_found = true;
			_ctIndex = _search;
		};
	};
	
	if ( _found ) exitWith { _ctIndex };
};

RTS_OOBSelector = {
	if ( RTS_oobSelectedGroup != RTS_selectedGroup && !(isNull RTS_selectedGroup) ) then {
		RTS_oobSelectedGroup = RTS_selectedGroup;
		private _index = [[],RTS_oobData] call RTS_findSelectedGroup;
		if ( !isNil "_index" ) then {
			RTS_oobTree tvSetCurSel _index;
			RTS_oobSelection = _index;
		};
	};

	private _selection = tvCurSel RTS_oobTree;
	
	if ( !(_selection isEqualTo RTS_oobSelection) ) then {
		RTS_oobSelection = _selection;
		if ( count _selection > 0 ) then {
			if ( _selection select 0 != -1 ) then { 
				private _selected = [];
				{
					if ( count _selected > 0 ) then {
						_selected = _selected select 1;
						_selected = _selected select _x;	
					} else {
						_selected = RTS_oobData select _x;
					};
				} forEach _selection;
		
				private _selected = _selected select 0;
				RTS_oobSelectedGroup = _selected;
				RTS_selectedGroup = _selected;
			};
		};
		ctrlSetFocus RTS_showOOBBtn;
	};
};

RTS_ui_cleanup = {
	ctrlDelete RTS_deployUndeployBtn;
	ctrlDelete RTS_showOOBBtn;
	ctrlDelete RTS_OOBTree;

	ctrlDelete RTS_phaseBox;
	ctrlDelete RTS_phaseButton;
	ctrlDelete RTS_statusText;
	ctrlDelete RTS_moraleText;
	ctrlDelete RTS_commandEffectText;
	ctrlDelete RTS_combatVictoryText;
	ctrlDelete RTS_combatModeText;
	ctrlDelete RTS_casualtyText;
	ctrlDelete RTS_formationText;
	ctrlDelete RTS_stanceText;
	ctrlDelete RTS_hasRadioText;
	ctrlDelete RTS_ammoLevelText;
	ctrlDelete RTS_passengerInfoText;
	
	ctrlDelete RTS_selectCommanderBtn;
	
	ctrlDelete RTS_controlUnitBtn;
	
	ctrlDelete RTS_unitNameText;
	ctrlDelete RTS_unitCallsignText;
	
	{
		ctrlDelete _x;
	} foreach RTS_artilleryControls;
	
	{
		ctrlDelete _x;
	} foreach RTS_unitDataControls;
};

RTS_ui_loop = [] spawn {
	while { true } do {
		
		if ( RTS_groupsSize != (count (RTS_commandingGroups select { count (units _x) > 0 })) ) then {
			RTS_groupsSize = count (RTS_commandingGroups select { count (units _x) > 0 });
			RTS_newOOB = true;
			RTS_oobData = call RTS_getOOBData;
		};
	
		// hide and show stuff
		{
			_x ctrlShow (!RTS_showingEquipment && RTS_showingUnitData && !RTS_showingArtilleryMenu);
		} forEach RTS_unitDataControls;
		{
			_x ctrlShow (RTS_showingUnitData || RTS_showingArtilleryMenu);
		} forEach RTS_unitInfoControls;
		{
			_x ctrlShow RTS_showingArtilleryMenu;
		} forEach RTS_artilleryMenuControls;
		
		RTS_showOOBBtn ctrlShow (!RTS_showingArtilleryMenu);
		
		if ( RTS_showingOOB ) then {
			RTS_showOOBBtn ctrlSetText "Close OOB";
			RTS_unitNameText ctrlSetText "OOB";
		} else {
			RTS_showOOBBtn ctrlSetText "Show OOB";
		};
	
		// display stuff
		if ( !(isNull RTS_selectedGroup) && RTS_showingUnitData ) then {
			if ( !(isNull (RTS_selectedGroup getVariable ["command_element", grpnull])) ) then {
				RTS_selectCommanderBtn ctrlEnable true;
			} else {
				RTS_selectCommanderBtn ctrlEnable false;
			};
			
			private _veh = RTS_selectedGroup getVariable ["owned_vehicle", grpnull];
			if ( !(isNull _veh) ) then {
				if ( _veh isKindOf "StaticWeapon" ) then {
					RTS_deployUndeployBtn ctrlEnable true;
					if ( simulationEnabled _veh ) then {
						RTS_deployUndeployBtn ctrlSetText "Undeploy";
						RTS_deployUndeployBtn buttonSetAction "[RTS_selectedGroup] call RTS_fnc_deployUndeploy;";
					} else {
						RTS_deployUndeployBtn ctrlSetText "Deploy";
						RTS_deployUndeployBtn buttonSetAction "[RTS_selectedGroup] call RTS_fnc_deployUndeploy;";
					};
				} else {
					private _subordinates = RTS_selectedGroup getVariable ["subordinates", []];
			
					if ( count _subordinates > 0 ) then {
						if ( count (getArtilleryAmmo ( _subordinates apply { vehicle (leader _x) } )) > 0 ) then {
							RTS_deployUndeployBtn ctrlSetText "Artillery";
							RTS_deployUndeployBtn buttonSetAction "RTS_showingUnitData = false; RTS_showingArtilleryMenu = true; RTS_artSetup = false;";
							RTS_deployUndeployBtn ctrlEnable true;
						};
					} else {
						RTS_deployUndeployBtn ctrlSetText "-";
						RTS_deployUndeployBtn ctrlEnable false;
					};
				};				
			} else {
				private _subordinates = RTS_selectedGroup getVariable ["subordinates", []];
			
				if ( count _subordinates > 0 ) then {
					if ( count (getArtilleryAmmo ( _subordinates apply { vehicle (leader _x) } )) > 0 ) then {
						RTS_deployUndeployBtn ctrlSetText "Artillery";
						RTS_deployUndeployBtn buttonSetAction "RTS_showingUnitData = false; RTS_showingArtilleryMenu = true; RTS_artSetup = false;";
						RTS_deployUndeployBtn ctrlEnable true;
					};
				} else {
					RTS_deployUndeployBtn ctrlSetText "-";
					RTS_deployUndeployBtn ctrlEnable false;
				};
			};
			
			if ( RTS_phase == "MAIN" || (RTS_selectedGroup getVariable ["morale", 0]) > 1 ) then {
				RTS_controlUnitBtn ctrlEnable true;
			} else {
				RTS_controlUnitBtn ctrlEnable false;
			};
			
			private _combatMode = ( switch ( combatMode RTS_selectedGroup ) do {
								case "YELLOW": { "Fire at Will" };
								case "RED": { "CQC" };
								case "GREEN": { "Return Fire" };
								default { str (combatMode RTS_selectedGroup) };
							});
			
			RTS_unitNameText ctrlSetText (RTS_selectedGroup getVariable ["desc", "Unknown"]);
			RTS_stanceText ctrlSetText (unitPos (leader RTS_selectedGroup));
			RTS_statusText ctrlSetText (RTS_selectedGroup getVariable ["status", "HOLDING"]);
			RTS_combatModeText ctrlSetText _combatMode;
			RTS_formationText ctrlSetText (formation RTS_selectedGroup);
			RTS_combatVictoryText ctrlSetText (str (RTS_selectedGroup getVariable ["combat_victories", 0]));
			private _kia = (RTS_selectedGroup getVariable ["initial_strength", 0]) - (count ((units RTS_selectedGroup) select { alive _x } ));
			RTS_casualtyText ctrlSetText (format ["%1 / %2", (if ( _kia == 0 ) then { "-" } else { _kia }) ,(RTS_selectedGroup getVariable ["initial_strength", 0])]);
			RTS_hasRadioText ctrlSetText (if ( RTS_selectedGroup getVariable ["HasRadio", false] ) then { "Yes" } else { "No" } );
			RTS_commandEffectText ctrlSetText ( if ( (RTS_selectedGroup getVariable ["command_bonus",1]) - 1 > 0 ) then { str (RTS_selectedGroup getVariable ["command_bonus",1]) } else { "None" });
			
			private _morale = RTS_selectedGroup getVariable ["morale", 0];
			RTS_moraleText ctrlSetText (format ["%1%2", round _morale, "%"]);
			if ( _morale > 70 ) then {
				RTS_moraleText ctrlSetTextColor [0,1,0,1];
			} else {
				if ( _morale > 35 ) then {
					RTS_moraleText ctrlSetTextColor [1,1,0,1];
				} else {
					RTS_moraleText ctrlSetTextColor [1,0,0,1];
				};
			};
			
			private _ammo = [RTS_selectedGroup] call RTS_fnc_getAmmoLevel;
			private _initialAmmo = RTS_selectedGroup getVariable ["initial_ammo", 1];
			
			private _ammolevel = round ((_ammo / (_initialammo max 1.0)) * 100);
			
			RTS_ammoLevelText ctrlSetText (format ["%1%2", _ammolevel, "%"]);
			
			if ( _ammolevel > 70 ) then {
				RTS_ammoLevelText ctrlSetTextColor [0,1,0,1];
			} else {
				if ( _ammolevel > 35 ) then {
					RTS_ammoLevelText ctrlSetTextColor [1,1,0,1];
				} else {
					RTS_ammoLevelText ctrlSetTextColor [1,0,0,1];
				};
			};
			
			private _vehicleinfo = "-";
			if ( !(isNull RTS_selectedGroup) && ((vehicle (leader RTS_selectedGroup)) != (leader RTS_selectedGroup)) ) then {
				private _veh = vehicle (leader RTS_selectedGroup);
				private _passengers = ((crew _veh) select { alive _x && (group _x != RTS_selectedGroup) });
				private _groups = [];
				{
					_groups pushBackUnique (group _x);
				} forEach _passengers;
				private _space = _veh emptyPositions "CARGO";
				_vehicleinfo = format 
					["%1/%2 - %3 Groups",
						(count _passengers),
						_space + (count _passengers),
						count _groups];
			};
			
			RTS_passengerInfoText ctrlSetText _vehicleinfo;
			
		} else {
			if ( RTS_showingUnitData ) then {
				RTS_deployUndeployBtn ctrlSetText "-";
				RTS_deployUndeployBtn ctrlEnable false;
				RTS_selectCommanderBtn ctrlEnable false;
				RTS_controlUnitBtn ctrlEnable false;
				RTS_unitNameText ctrlSetText "Select Unit";
				RTS_unitCallsignText ctrlSetText "-";
				RTS_stanceText ctrlSetText "-";
				RTS_statusText ctrlSetText "-";
				RTS_combatModeText ctrlSetText "-";
				RTS_formationText ctrlSetText "-";
				RTS_combatVictoryText ctrlSetText "-";
				RTS_casualtyText ctrlSetText "-";
				RTS_hasRadioText ctrlSetText "-";
				RTS_commandEffectText ctrlSetText "-";
				
				RTS_moraleText ctrlSetText "-";
				RTS_moraleText ctrlSetTextColor [1,1,1,1];			
				RTS_ammoLevelText ctrlSetText "-";
				RTS_passengerInfoText ctrlSetText "-";
			};
		};
		
		if ( !(isNull RTS_selectedGroup) && RTS_showingArtilleryMenu ) then {
			
			RTS_unitNameText ctrlSetText "Call Artillery";
			
			private _mortars = ( (RTS_selectedGroup getVariable ["subordinates", []]) select { count (getArtilleryAmmo [(vehicle (leader _x))]) > 0 } ) apply { vehicle (leader _x) };
			private _mags = getArtilleryAmmo _mortars;
			
			if ( count _mags > 0 ) then {
				private _selectedMag = ( if ( RTS_artSetup ) then { _mags select (lbCurSel RTS_artMagazineBox) } else { _mags select 0 } );
				
				private _guns = _mortars select { _selectedMag in getArtilleryAmmo [_x] };
				
				if ( !RTS_artSetup ) then {
					RTS_artSelectedMagazine = 0;
					RTS_artSetup = true;
					
					RTS_artStatusLabel ctrlSetText "WAITING";
					
					{
						lbClear _x;
					} forEach [ RTS_artSizeBox, RTS_artMagazineBox, RTS_artDurationBox, RTS_artDelayBox, RTS_artGunCountBox  ];
					
					{
						RTS_artMagazineBox lbAdd (getText (configFile >> "CfgMagazines" >> _x >> "displayName"))
					} forEach _mags;
					
					{
						RTS_artDurationBox lbAdd _x
					} forEach [ "Light", "Medium", "Heavy" ];
					
					{
						RTS_artDelayBox lbAdd _x;
					} forEach [ "Immediate", "1 Minute", "5 Minutes", "10 Minutes", "15 Minutes" ];
					
					{
						RTS_artSizeBox lbAdd _x;
					} forEach [ "None", "50m", "100m", "200m", "400m" ];
					
					{
						RTS_artGunCountBox lbAdd (str (_forEachIndex + 1));
					} forEach _guns;
					
					{
						_x lbSetCurSel 0;
					} forEach [ RTS_artSizeBox, RTS_artMagazineBox, RTS_artDurationBox, RTS_artDelayBox, RTS_artGunCountBox  ];
					
				};
				
				if ( ! ( (RTS_selectedGroup getVariable ["ArtilleryMission", "WAITING"]) isEqualTo "WAITING" ) ) then {
					RTS_artStatusLabel ctrlSetText (RTS_selectedGroup getVariable "ArtilleryMission");
					RTS_deployUndeployBtn ctrlEnable false;
				} else {
					RTS_artStatusLabel ctrlSetText "WAITING";
					RTS_deployUndeployBtn ctrlEnable (count _mags > 0);
				};
				
				if ( lbCurSel RTS_artMagazineBox != RTS_artSelectedMagazine ) then {
					RTS_artSelectedMagazine = lbCurSel RTS_artMagazineBox;
					lbClear RTS_artGunCountBox;
					{
						RTS_artGunCountBox lbAdd (str (_forEachIndex + 1));
					} forEach _guns;
				};
			};
		
			RTS_deployUndeployBtn ctrlSetText "Call Fire";
			RTS_deployUndeployBtn buttonSetAction "call RTS_fnc_callArtilleryMission;";
			RTS_deployUndeployBtn ctrlShow true;
		
		} else {
			if ( RTS_showingArtilleryMenu ) then {
				RTS_showingArtilleryMenu = false;
				RTS_showingUnitData = true;
			};
			removeAllMissionEventHandlers "MapSingleClick";
			RTS_artillery_group = grpnull;
			RTS_artillery_spotters = [];
			RTS_artillery_mortars = [];
			RTS_artillery_magazine = "";
			RTS_artillery_duration = 0;
			RTS_artillery_delay = 0;
			RTS_artillery_count = 0;
		};
		
		// OOB controls
		RTS_oobTree ctrlShow RTS_showingOOB;
		if ( RTS_showingOOB && RTS_newOOB ) then {
			RTS_newOOB = false;
			
			RTS_oobTree tvSetCurSel [-1];
			tvClear RTS_oobTree;
			
			[[],RTS_oobData,RTS_oobTree] call RTS_populateOOBTree;
			
			tvExpandAll RTS_oobTree;
			
		};
		
		if ( RTS_showingOOB ) then {
			call RTS_OOBSelector;
		};
	};
};
