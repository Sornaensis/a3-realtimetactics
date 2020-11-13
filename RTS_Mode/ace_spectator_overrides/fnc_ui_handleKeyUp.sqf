/*
 * Author: Nelson Duarte, SilentSpike
 * Function used to handle key up event
 *
 * Arguments:
 * 0: Spectator display <DISPLAY>
 * 1: Key DIK code <NUMBER>
 * 2: State of shift <BOOL>
 * 3: State of ctrl <BOOL>
 * 4: State of alt <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _this call ace_spectator_fnc_ui_handleKeyUp
 *
 * Public: No
 */
 
#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"

params ["","_key","_shift","_ctrl","_alt"];

if (_key == DIK_LALT) exitWith {
    [false] call FUNC(cam_toggleSlow);
    true
};

if ( _key == DIK_BACKSLASH ) exitWith {
	RTS_focusingOnUnit = false;
	true
};

if (_key == DIK_TAB) exitWith {
	RTS_pausing = false;
};


if ( _key == DIK_H ) exitWith {
	RTS_helpKey = false;
	true
};

if ( _key == DIK_BACKSPACE ) exitWith {
	RTS_backspace = false;
	true
};

if ( _key == DIK_DELETE ) exitWith {
	RTS_delete = false;
	true
};

if ( _key == DIK_P ) exitWith {
	RTS_issuingPause = false;
	true
};


if ( _key == DIK_X ) exitWith {
	RTS_buildingposChoose = false;
	RTS_command = nil;
	true
};

if ( _key == DIK_T && RTS_checkVisibility ) exitWith {
	RTS_checkVisibility = false;
	RTS_command = nil;
};

false
