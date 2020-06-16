#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"
#include "../../../RTS_defines.hpp"

if ( RTS_commanding ) then {
	if ( RTS_buildingposChoose && !isNil "RTS_selectedBuilding" ) then {
		_positions = [RTS_selectedBuilding] call BIS_fnc_buildingPositions;
		_nearest = [_positions, { (worldToScreen _x) distance getMousePosition }] call CBA_fnc_filter;
		_i = -1;
		_least = 100;
		{
			if ( _x < _least ) then {
				_least = _x;
				_i = _forEachIndex;
			};
		} forEach _nearest;
		{
			_least = _forEachIndex == _i;
			drawIcon3D ["\A3\ui_f\data\map\groupicons\selector_selectedFriendly_ca.paa", if _least then { RTS_sideColor } else { [1,1,1,1] }, _x, 1, 1, 0, "", 2, 0.04, "TahomaB", "CENTER", true];
			drawIcon3D ["", if _least then { RTS_sideColor } else { [1,1,1,1] }, _x, 1, 1, 0, str _forEachIndex, 2,0.04];
		} forEach _positions;
	};
	
	if ( !isNil "RTS_command" ) then {
		RTS_command params ["_name","","_pos"];
		if ( ! (isNil "_name") ) then {
			drawIcon3D ["", [1,1,1,1], screentoWorld getMousePosition, 1, 1, 0,_name,2,0.04];
		};
		if ( ! (isNil "_pos") ) then {
			_group = RTS_selectedGroup;
			if !(isNull _group) then {
				_fpos = eyePos (leader _group);
				drawLine3D [_pos,ASLtoATL _fpos,[1,1,1,1]];
			};
			drawIcon3D ["\A3\ui_f\data\map\groupicons\selector_selectedMission_ca.paa", [1,1,1,1], _pos, 1, 1, 0,"",2,0.04];
		};
	};
};		

private _nearestGrp = [];
private _campos = (if (RTS_commanding) then { (getPos GVAR(camera)) } else { getPos player } );

if ( RTS_commanding ) then {
	// Get nearest group icon to cursor
	{
		private ["_group","_pos","_drawpos"];
		_group = _x;
		if ( count ( (units _x) select { alive _x } ) > 0 ) then {
			_pos = getPosATLVisual (leader _group);
			_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 3];
			private _iconpos = worldToScreen _drawpos;
			
			// if onscreen
			if ( count _iconpos > 0 ) then {
				if ( (_iconpos distance2d getMousePosition) < 0.05 ) then {
					if ( count _nearestGrp == 0 ) then {
						_nearestGrp = [ _group, _drawpos ];
					} else {
						private _otherPos = _nearestGrp select 1;
						
						if ( (_otherPos distance _campos) > (_drawpos distance _campos) ) then {
							_nearestGrp = [ _group, _drawpos ];
						};
					};
				};
			};
		};
	} forEach RTS_commandingGroups;
};

if ( count _nearestGrp > 0 ) then {
	RTS_mouseHoverGrp = _nearestGrp select 0;
} else {
	RTS_mouseHoverGrp = grpnull;
};

// Draw Unit Icons all the time
{
	private ["_group","_pos","_drawpos", "_distScale", "_scale"];
	_group = _x;
	if ( count ( (units _x) select { alive _x } ) > 0 ) then {
		_pos = getPosATLVisual (leader _group);
		_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 3];
		_distance =  _campos distance2D (getPos (leader _group));
		_distScale = RTS_groupIconMaxDistance - _distance;
		_scale = 0.3 + (if ( _distScale > 0 ) then { (_distScale/RTS_groupIconMaxDistance) * 0.7 } else { 0 });
		
		if ( !(_scale isEqualType 0) ) exitWith {};
		
		// Description string with casualty indication
		private _desc = _group getVariable ["desc", str _group];
		private _unitcolor = RTS_sideColor;
		
		private _living = count ((units _group) select { alive _x });
		private _maxmorale = (count _units) / ((_group getVariable ["initial_strength", 1]) max 1) * 100;
		private _morale = _group getVariable ["morale", 0];
		if ( _living < (_group getVariable ["initial_strength",-1]) ) then {
			_unitcolor = RTS_casualtyColor;
			if ( _morale < 0 ) then {
				_desc = _desc + "(!!!)";
				_unitcolor = RTS_brokenColor;
			} else {
				if ( _morale < _maxmorale / 3 ) then {
					_desc = _desc + "(!!)";
				} else {
					if ( _morale < _maxmorale ) then {
						_desc = _desc + "(!)";
					};
				}
			};
		};
		
		if ( combatMode _group == "RED" ) then {
			_desc = "[CQC]" + _desc;
		};
		
		if (_group == RTS_selectedGroup) then {	
			{
				private ["_pos", "_drawpos"];
				_pos = getPosATLVisual _x;
				_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.7]; 
				if ( ( _x != leader _group ) && (vehicle _x == _x) ) then {
					drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", [0,0,0,1], _drawpos, 0.8, 0.8,0];
					drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", RTS_sideColor, _drawpos, 0.6, 0.6,0];
				};
				// Show us where the unit intends to go
				if ( RTS_debug ) then {
					drawIcon3D ["\A3\ui_f\data\map\groupicons\waypoint.paa", RTS_sideColor, (expectedDestination _x) select 0, 0.6, 0.6,0, str (_forEachIndex + 1), 2, 0.04];
				};
			} forEach (units _group);
			if ( (group (driver (vehicle (leader _group)))) == _group || isNull (driver (vehicle (leader _group))) ) then {
				drawIcon3D [_group getVariable ["texture", ""], _unitcolor, _drawpos, _scale, _scale, 0, "", 2, 0.04, "TahomaB", "CENTER", true];
				drawIcon3D ["\A3\ui_f\data\map\groupicons\selector_selectedFriendly_ca.paa", [1,1,1,1], _drawpos, _scale, _scale, 0, "", 2, 0.04, "TahomaB", "CENTER", true];
				drawIcon3D ["", [1,1,1,1], _drawpos, _scale, _scale, 0, _desc,2,0.04];
			} else {
				RTS_selectedGroup = grpnull;
			};
		} else {
			if ( (group (driver (vehicle (leader _group)))) == _group || isNull (driver (vehicle (leader _group))) ) then {
				if ( _group == RTS_mouseHoverGrp ) then {
					_unitcolor = +_unitcolor;
					_unitcolor set [3,0.65];
				};
				drawIcon3D [ _group getVariable ["texture", ""], _unitcolor, _drawpos, _scale, _scale, 0];
				if ( _distance < 500 ) then {
					drawIcon3D ["", [1,1,1,1], _drawpos, _scale, _scale, 0, _desc,2,0.04];
				};
			};
		};
	};
} forEach RTS_commandingGroups;

if ( RTS_commanding ) then {
	
	{
		private ["_pos", "_drawpos"];
		_pos = getPosATLVisual _x;
		_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.7]; 
		if ( !( isObjectHidden _x ) && ((vehicle _x) == _x) ) then {
			_selectedgroup = RTS_selectedGroup;
			_draw = if ( !(isNull _selectedgroup) && !RTS_godseye ) then {
						_x in (_selectedgroup getVariable ["spotted", []])
					} else {
						true
					};
			if _draw then {
				drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", [0,0,0,1], _drawpos, 0.8, 0.8,0];
				drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", RTS_sideColor, _drawpos, 0.6, 0.6,0];
			};
		};
	} forEach ( allUnits select {side _x == RTS_sidePlayer && !((group _x) in RTS_commandingGroups) } );


	{
		private ["_pos", "_drawpos"];
		_pos = getPosATLVisual _x;
		_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.7]; 
		if ( !( isObjectHidden _x ) && ((vehicle _x) == _x) ) then {
			_selectedgroup = RTS_selectedGroup;
			_draw = if ( !(isNull _selectedgroup) && !RTS_godseye ) then {
						_x in (_selectedgroup getVariable ["spotted", []])
					} else {
						true
					};
			if _draw then {
				drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", [0,0,0,1], _drawpos, 0.8, 0.8,0];
				drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", RTS_enemyColor, _drawpos, 0.6, 0.6,0];
			};
		};
	} forEach ( allUnits select {side _x == RTS_sideEnemy} );
	
	{
		private ["_pos", "_drawpos"];
		_pos = getPosATLVisual _x;
		
		private _leaders = [RTS_commandingGroups, { (getPos (leader _x)) distance _pos }] call CBA_fnc_filter;
		private _nearest = [_leaders, [], {_x}, "ASCEND"] call BIS_fnc_sortBy;
		private _near = false;
		
		if ( (count _nearest) > 0 ) then {
			if ( (isEngineOn _x) && (_nearest select 0) < 150 ) then {
				_near = true;
				_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
			} else {
				if ( (isEngineOn _x) && (_nearest select 0) < 300 && (speed _x) > 6 ) then {
					_near = true;
					_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
				} else {
					if ( (isEngineOn _x) && (_nearest select 0) < 500 && (speed _x) > 9 ) then {
						_near = true;
						_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
					};
				};	
			};
		};
		
		if ( !( isObjectHidden _x ) ) then {
			_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
		};
		if ( _near || !( isObjectHidden _x ) ) then {
			_selectedgroup = RTS_selectedGroup;
			_draw = if ( !(isNull _selectedgroup) && !RTS_godseye && !( isObjectHidden _x ) ) then {
						_tmp = false;
						{
							_tmp = _x in (_selectedgroup getVariable ["spotted", []])
						} forEach (crew _x);
						_tmp
					} else {
						true
					};
			if _draw then {
				drawIcon3D ["\A3\ui_f\data\map\markers\military\triangle_CA.paa", [0,0,0,1], _drawpos, 0.8, 0.8,0];
				drawIcon3D ["\A3\ui_f\data\map\markers\military\triangle_CA.paa", RTS_enemyColor, _drawpos, 0.6, 0.6,0];
			};
		};
	} forEach ( if ( RTS_godseye ) then { 
					[((allUnits select { side _x == RTS_sideEnemy }) select { (vehicle _x) != _x } ), { vehicle _x }] call CBA_fnc_filter
				 } else { 
				 	RTS_opfor_vehicles 
				 });
		
	{
		private ["_pos", "_drawpos"];
		_pos = getPosATLVisual _x;
		_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.7]; 
		if ( !( isObjectHidden _x ) && ((vehicle _x) == _x) ) then {
			_selectedgroup = RTS_selectedGroup;
			_draw = if ( !(isNull _selectedgroup) && !RTS_godseye ) then {
						_x in (_selectedgroup getVariable ["spotted", []])
					} else {
						true
					};
			if _draw then {
				drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", [0,0,0,1], _drawpos, 0.8, 0.8,0];
				drawIcon3D ["\A3\ui_f\data\map\markers\handdrawn\dot_CA.paa", RTS_greenColor, _drawpos, 0.6, 0.6,0];
			};
		};
	} forEach ( allUnits select {side _x == RTS_sideGreen} );
	
	{
		private ["_pos", "_drawpos"];
		_pos = getPosATLVisual _x;
		
		private _leaders = [RTS_commandingGroups, { (getPos (leader _x)) distance _pos }] call CBA_fnc_filter;
		private _nearest = [_leaders, [], {_x}, "ASCEND"] call BIS_fnc_sortBy;
		private _near = false;
		
		if ( (count _nearest) > 0 ) then {
			if ( (isEngineOn _x) && (_nearest select 0) < 150 ) then {
				_near = true;
				_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
			} else {
				if ( (isEngineOn _x) && (_nearest select 0) < 300 && (speed _x) > 6 ) then {
					_near = true;
					_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
				} else {
					if ( (isEngineOn _x) && (_nearest select 0) < 500 && (speed _x) > 9 ) then {
						_near = true;
						_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
					};
				};	
			};
		};
		
		if ( !( isObjectHidden _x ) ) then {
			_drawpos = [_pos select 0, _pos select 1, (_pos select 2) + 0.2]; 
		};
		if ( _near || !( isObjectHidden _x ) ) then {
			_selectedgroup = RTS_selectedGroup;
			_draw = if ( !(isNull _selectedgroup) && !RTS_godseye && !( isObjectHidden _x ) ) then {
						_tmp = false;
						{
							_tmp = _x in (_selectedgroup getVariable ["spotted", []])
						} forEach (crew _x);
						_tmp
					} else {
						true
					};
			if _draw then {
				drawIcon3D ["\A3\ui_f\data\map\markers\military\triangle_CA.paa", [0,0,0,1], _drawpos, 0.8, 0.8,0];
				drawIcon3D ["\A3\ui_f\data\map\markers\military\triangle_CA.paa", ( if ( side (driver _x) != RTS_sidePlayer ) then { RTS_Greenfor_GreenColor } else { RTS_sideColor }), _drawpos, 0.6, 0.6,0];
			};
		};
	} forEach ( RTS_greenfor_vehicles );
};