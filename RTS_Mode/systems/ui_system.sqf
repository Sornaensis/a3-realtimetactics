#include "\z\ace\addons\spectator\script_component.hpp"

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
	while { RTS_commanding } do {
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

// Setup Unit Info Screen

SPEC_DISPLAY ctrlCreate ["UnitOverViewPanel", -1];
SPEC_DISPLAY ctrlCreate ["StatusLabel", -1];
SPEC_DISPLAY ctrlCreate ["CombatModeLabel", -1];
SPEC_DISPLAY ctrlCreate ["MoraleLabel", -1];
SPEC_DISPLAY ctrlCreate ["StanceLabel", -1];
SPEC_DISPLAY ctrlCreate ["CommandEffectLabel", -1];
SPEC_DISPLAY ctrlCreate ["CombatVictoriesLabel", -1];
SPEC_DISPLAY ctrlCreate ["CasualtyLabel", -1];
SPEC_DISPLAY ctrlCreate ["FormationLabel", -1];
SPEC_DISPLAY ctrlCreate ["HasRadioLabel", -1];
SPEC_DISPLAY ctrlCreate ["AmmoLevelLabel", -1];
SPEC_DISPLAY ctrlCreate ["PassengerInfoLabel", -1];

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

RTS_selectCommanderBtn = SPEC_DISPLAY ctrlCreate ["SelectCommanderBtn", -1];
RTS_selectCommanderBtn buttonSetAction "RTS_selectedGroup = RTS_selectedGroup getVariable [""command_element"", grpnull];";

RTS_controlUnitBtn = SPEC_DISPLAY ctrlCreate ["ControlBtn", -1];
RTS_controlUnitBtn buttonSetAction "if ( RTS_phase == ""MAIN"" ) then { call RTS_fnc_takeControlOfUnit; };";

RTS_unitNameText = SPEC_DISPLAY ctrlCreate ["UnitNameText", -1];
RTS_unitCallsignText = SPEC_DISPLAY ctrlCreate ["UnitCallsignText", -1];

[] spawn {
	while { RTS_commanding } do {
		if ( !(isNull RTS_selectedGroup) ) then {
			if ( !(isNull (RTS_selectedGroup getVariable ["command_element", grpnull])) ) then {
				RTS_selectCommanderBtn ctrlEnable true;
			} else {
				RTS_selectCommanderBtn ctrlEnable false;
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
			
			private _ammolevel = round (((_ammo / _initialammo) min 1.0) * 100);
			
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
		sleep 0.5;
	};
};