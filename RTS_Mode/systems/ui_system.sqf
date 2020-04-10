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
RTS_missionTimeStarted = nil;


// Wait for mission to start
[] spawn { 
	if ( isNil "RTS_missionTimeStarted" ) then {
		waitUntil { RTS_phase == "MAIN" };
		RTS_missionTimeStarted = time;
	};
};

RTS_targetPhase = RTS_phase;
[] spawn {
	while { true && RTS_commanding } do {
		// Update phase display
		RTS_phaseBox ctrlSetText 
			( if ( RTS_paused ) then { 
				"Paused!" 
				} else { 
					switch RTS_phase do {
					case "DEPLOY": {"Deployment Phase"};
					case "MAIN": { if ( !(isNil "RTS_missionTimeStarted") ) then {
									format ["Combat Phase  -  %1", [time - RTS_missionTimeStarted] call BIS_fnc_secondsToString ]
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