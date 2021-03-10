if ( isDedicated || !hasInterface ) exitWith {};

waitUntil { time > 0 };
sleep 10;
if ( isNull (getAssignedCuratorLogic player) ) exitWith {};


SOCOM_fnc_enableAdvancedAI = {
	curatorSelected params ["","_groups"];
	if ( !isNil "_groups" ) then {
		{
			private _group = _x;
			_group setVariable ["VCM_Disable", !(_group getVariable ["VCM_disable", false]) ];
		} forEach _groups;
	};
};

SOCOM_CURATOR_UI = [] spawn {
	waitUntil { !isNull (findDisplay 312) };
	while { true } do {
		if ( isNil "CURATOR_TRANSFER_BTN" && !isNull (findDisplay 312) ) then {
			CURATOR_TRANSFER_BTN = (findDisplay 312) ctrlCreate ["RscButton", -1];
			CURATOR_TRANSFER_BTN ctrlSetText "Toggle VCOM";
			CURATOR_TRANSFER_BTN ctrlSetFontHeight 0.07;
			CURATOR_TRANSFER_BTN ctrlSetPosition [safeZoneX + (safeZoneWAbs/2-0.175),safeZoneY+0.13,0.35,0.07];
			CURATOR_TRANSFER_BTN_ACTION = "call SOCOM_fnc_enableAdvancedAI;";
			CURATOR_TRANSFER_BTN buttonSetAction CURATOR_TRANSFER_BTN_ACTION;
			CURATOR_TRANSFER_BTN ctrlCommit 0;
		} else {
			if ( isNull (findDisplay 312) ) then {
				CURATOR_TRANSFER_BTN = nil;
			} else {
				curatorSelected params ["","_groups"];
				private _enable = false;
				if ( !isNil "_groups" ) then {
					private _vcomon = true;
					private _vcomoff = true;
					if ( count _groups > 0 ) then {
						_enable = true;
						_vcomon = (_group getVariable ["VCM_disable", false]) && _vcomon;
						_vcomoff = !(_group getVariable ["VCM_disable", true]) && _vcomoff;
					};
					if ( _vcomon && _enable ) then {
						CURATOR_TRANSFER_BRN ctrlSetText "Disable VCOM";
					};
					if ( _vcomoff && _enable ) then {
						CURATOR_TRANSFER_BRN ctrlSetText "Enable VCOM";
					};
				};
				CURATOR_TRANSFER_BTN ctrlEnable _enable;
			};
		};
	};
};