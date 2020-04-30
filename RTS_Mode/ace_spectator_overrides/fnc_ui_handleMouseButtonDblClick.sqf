/*
 * Author: Nelson Duarte, AACO, SilentSpike
 * Function used to handle mouse button double clicks
 *
 * Expected behaviour:
 * Double left click teleports free camera toward the unit, but does not focus
 *
 * Arguments:
 * 0: Control <CONTROL>
 * 1: Mouse button pressed <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * _this call ace_spectator_fnc_ui_handleMouseButtonDblClick
 *
 * Public: No
 */
 
#include "\z\ace\addons\spectator\script_component.hpp"

params ["", "_button","","","_shift","_ctrl","_alt"];

if (_button == 0 && {!isNull GVAR(cursorObject)} && !_shift && !_alt  && (isNil "RTS_command") ) then {
   if( ( GVAR(cursorObject) isKindOf "Man" ) && ((group GVAR(cursorObject)) in RTS_commandingGroups) ) then {
		RTS_selectedGroup = group GVAR(cursorObject);
   };
} else {
	if ( _button == 0 && _alt && !_shift && !_ctrl && (isNil "RTS_command") ) then {
		RTS_fakeCameraTarget setPosATL (screenToWorld getMousePosition);
		[RTS_fakeCameraTarget] call RTS_fnc_cam_prepareTarget;
	} else {
		if ( !isNil "RTS_command" && (RTS_selectedGroup getVariable ["commandable", false]) ) then {
			private _group = RTS_selectedGroup;
			private _pos = screenToWorld getMousePosition;
			
			if ( RTS_phase == "DEPLOY" ) then {
				_inarea = false;
				
				{
					if ( _pos inArea _x ) then {
						_inarea = true;
					};
				} forEach RTS_deploymentMarks;
				
				if ( _inarea ) then {
					if !(isNull _group) then {
						[_group, _pos] call (RTS_command select 1);
					};
				};
			} else {
				private _restricted = false;
				
				{
					_restricted = _restricted || (_pos inArea _x);
				} forEach RTS_restrictionZone;
				
				if ( !((getMarkerSize RTS_aoMarker) isEqualTo [0,0]) ) then {					
					if ( _pos inArea RTS_aoMarker && !_restricted ) then {
						if !(isNull _group) then {
							[_group, _pos] call (RTS_command select 1);
						};
					};
				} else {
					if ( !_restricted && !(isNull _group) ) then {
						[_group, _pos] call (RTS_command select 1);
					};
				};
			};
		} else {
			RTS_selectedGroup = grpnull;
		};
	};
};

/* 

if ( _button == 0 && _shift && !_alt && !_ctrl && RTS_selectedGroup != grpnull && (RTS_selectedGroup getVariable ["commandable", false]) ) then {
			[RTS_selectedGroup, screenToWorld getMousePosition] call RTS_fnc_addMoveCommand;
		} else {
			if ( _button == 0 && !_shift && !_alt && _ctrl && RTS_selectedGroup != grpnull && (RTS_selectedGroup getVariable ["commandable", false]) ) then {
				[RTS_selectedGroup, screenToWorld getMousePosition] call RTS_fnc_addCombatMoveCommand;
			} else {
				if ( _button == 0 && _shift && _ctrl && !_alt && RTS_selectedGroup != grpnull && (RTS_selectedGroup getVariable ["commandable", false]) ) then {
					[RTS_selectedGroup, screenToWorld getMousePosition] call RTS_fnc_addSlowMoveCommand;
				} else {
					if ( _button == 0 && _shift && !_ctrl && _alt && RTS_selectedGroup != grpnull && (RTS_selectedGroup getVariable ["commandable", false]) ) then {
						while { count (RTS_selectedGroup getVariable ["commands", []]) > 0 } do {
							[RTS_selectedGroup] call RTS_fnc_removeCommand;
						};
					} else {
						if ( _button == 0 && !_shift && _ctrl && _alt && RTS_selectedGroup != grpnull && (RTS_selectedGroup getVariable ["commandable", false]) ) then {
							RTS_selectedGroup setFormDir ((leader RTS_selectedGroup) getDir (screenToWorld getMousePosition));
							{
								_x doWatch (screenToWorld getMousePosition)
							} forEach (units RTS_selectedGroup);
						} else {
							if ( _button == 0 && _shift && _ctrl && _alt && RTS_selectedGroup != grpnull && (RTS_selectedGroup getVariable ["commandable", false]) ) then {
								[RTS_selectedGroup, (screenToWorld getMousePosition)] call RTS_fnc_addUnloadOrLoadCommand;
							} else {
								RTS_selectedGroup = grpnull;
							};
						};
					};
				};
			};
		};

*/