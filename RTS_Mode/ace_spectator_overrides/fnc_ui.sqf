/*
 * Author: SilentSpike
 * Handles UI initialisation and destruction
 *
 * Arguments:
 * 0: Init/Terminate <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [false] call ace_spectator_fnc_ui
 *
 * Public: No
 */
 
#include "\z\ace\addons\spectator\script_component.hpp"

params ["_init"];
TRACE_1("ui",_init);

RTS_commanding = _init;

// No change
if (_init isEqualTo !isNull SPEC_DISPLAY) exitWith {};

// Close map
openMap [false,false];

// Close any open dialogs
while {dialog} do {
    closeDialog 0;
};

// Controls some PP effects, but a little unclear which
BIS_fnc_feedback_allowPP = !_init;

// Removes death blur if present
if !(isNil "BIS_DeathBlur") then {
    BIS_DeathBlur ppEffectAdjust [0];
    BIS_DeathBlur ppEffectCommit 0;
};

// Note that init and destroy intentionally happen in reverse order
// Init: Vars > Display > UI Stuff
// Destroy: UI Stuff > Display > Vars
if (_init) then {
    // UI visibility tracking
    GVAR(uiVisible)         = false;
    GVAR(uiHelpVisible)     = false;
    GVAR(uiMapVisible)      = true;
    GVAR(uiWidgetVisible)   = false;

    // Drawing related
    GVAR(drawProjectiles)   = false;
    GVAR(drawUnits)         = false;
    GVAR(entitiesToDraw)    = [];
    GVAR(grenadesToDraw)    = [];
    GVAR(iconsToDraw)       = [];
    GVAR(projectilesToDraw) = [];

    // RMB tracking is used for follow camera mode
    GVAR(holdingRMB) = false;

    // Highlighted map object is used for click and drawing events
    GVAR(uiMapHighlighted) = objNull;

    // Holds the current list data
    GVAR(curList) = [];

    // Cache view distance and set spectator default
    GVAR(oldViewDistance) = viewDistance;
    setViewDistance DEFAULT_VIEW_DISTANCE;

    // If counter already exists handle it, otherwise display XEH will handle it
    [GETUVAR(RscRespawnCounter,displayNull)] call FUNC(compat_counter);

    // Create the display
    MAIN_DISPLAY createDisplay QGVAR(displayMission);

	// Initially hide map
    [] call FUNC(ui_toggleMap);

    // Initalise the help, widget and list information
    [] call FUNC(ui_updateCamButtons);
    [] call FUNC(ui_updateWidget);
	
    // Start updating things to draw
    GVAR(collectPFH) = [LINKFUNC(ui_updateIconsToDraw), 0.2] call CBA_fnc_addPerFrameHandler;

    // Draw icons and update the cursor object
    GVAR(uiDraw3D) = addMissionEventHandler ["Draw3D", {call FUNC(ui_draw3D)}];
	
	GVAR(uiDraw3DUnits) = addMissionEventHandler ["Draw3D", {call RTS_fnc_draw3dUnitIcons}];
	GVAR(uiDraw3DOrders) = addMissionEventHandler ["Draw3D", {call RTS_fnc_draw3dOrders}];
	setViewDistance 4500;
	
	setGroupIconsVisible [true, true];
	onGroupIconClick
	{
	    // Passed values for _this are:
	    _is3D = _this select 0;
	    _group = _this select 1;
	    _wpID = _this select 2;
	    _RMB = _this select 3;
	    _posx = _this select 4;
	    _posy = _this select 5;
	    _shift = _this select 6;
	    _ctrl = _this select 7;
	    _alt = _this select 8;
	
	    if( !_alt && !_shift && !_ctrl && _RMB == 0 ) then {
	    	RTS_selectedGroup = _group;
	    };
	};
	
    // Periodically update list and focus widget
    GVAR(uiPFH) = [{
        [] call FUNC(ui_updateListEntities);
        [] call FUNC(ui_updateWidget);
    }, 5] call CBA_fnc_addPerFrameHandler;
	ace_spectator_camMode = 0;
} else {
	
	setGroupIconsVisible [false, false];

    // Stop updating the list and focus widget
    [GVAR(uiPFH)] call CBA_fnc_removePerFrameHandler;
    GVAR(uiPFH) = nil;

    // Stop drawing icons and tracking cursor object
    removeMissionEventHandler ["Draw3D", GVAR(uiDraw3D)];
    GVAR(uiDraw3D) = nil;

    // Stop updating things to draw
    [GVAR(collectPFH)] call CBA_fnc_removePerFrameHandler;
    GVAR(collectPFH) = nil;

    // Destroy the display
    SPEC_DISPLAY closeDisplay 1;

    // Stop tracking everything
    GVAR(uiVisible)         = nil;
    GVAR(uiHelpVisible)     = nil;
    GVAR(uiMapVisible)      = nil;
    GVAR(uiWidgetVisible)   = nil;
    GVAR(holdingRMB)        = nil;
    GVAR(uiMapHighlighted)  = nil;
    GVAR(curList)           = nil;
    GVAR(uiHelpH)           = nil;

    // Stop drawing
    GVAR(drawProjectiles)   = nil;
    GVAR(drawUnits)         = nil;
    GVAR(entitiesToDraw)    = nil;
    GVAR(grenadesToDraw)    = nil;
    GVAR(iconsToDraw)       = nil;
    GVAR(projectilesToDraw) = nil;

    // Reset view distance
    setViewDistance GVAR(oldViewDistance);
    GVAR(oldViewDistance) = nil;

    // Ensure chat is shown again
    showChat true;
};
