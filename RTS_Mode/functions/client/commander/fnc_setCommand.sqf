#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"

params ["_key", "_alt", "_shift", "_ctrl"];
if ( RTS_phase == "MAIN" || RTS_phase == "INITIALORDERS" ) then {
	switch ( _key ) do {
		// Move
		case DIK_E: {
			if ( _shift ) then {
				RTS_command = ["Quick Move", { _this call RTS_fnc_addMoveCommand } ];
			} else {
				if ( _ctrl ) then {
					RTS_command = ["Sprint", { _this call RTS_fnc_addFastMoveCommand  } ];
				} else {
					RTS_command = ["Move", { _this call RTS_fnc_addSlowMoveCommand } ];
				};
			};
		};
		// Mount/Dismount
		case DIK_R: {
			RTS_command = ["Mount/Dismount", { _this call RTS_fnc_addMountOrDismountCommand } ];
		};
		// Turn/ Suppress
		case DIK_T: {
			if ( !_shift ) then {
				RTS_command = ["Watch Position", 
								{
									params ["_group", "_pos"];
									_group setFormDir ((leader _group) getDir _pos);
									{
										_x doWatch _pos
									} forEach (units _group);
								}];
			};
		};
		// Load/Unload
		case DIK_SPACE: {
			RTS_command = ["Load/Unload", { _this call RTS_fnc_addUnloadOrLoadCommand }];
		};
	};
} else {
	switch ( _key ) do {
		// Move
		case DIK_E: {
			RTS_command = ["Move", { _this call RTS_fnc_placeUnit } ];
		};
		// Mount/Dismount
		case DIK_R: {
			RTS_command = ["Mount/Dismount", { /*_this call RTS_fnc_mountOrDismountUnit*/ } ];
		};
		// Turn/ Suppress
		case DIK_T: {
			if ( !_shift ) then {
				RTS_command = ["Set Direction",{ _this call RTS_fnc_setDirection }];
			};
		};
		// Load/Unload
		case DIK_SPACE: {
			RTS_command = ["Load/Unload", { _this call RTS_fnc_loadOrUnload }];
		};
	};
};