#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"

// Draw Deployment zones
if ( RTS_phase == "DEPLOY" && RTS_commanding ) then {
	{
		_mark = _x;
		if ( ((getMarkerPos _mark) distance ace_spectator_camera) < 2500 ) then {
			(getMarkerPos _mark) params ["_cx", "_cy"];
			_center = [_cx,_cy];
			(getMarkerSize _mark) params ["_mx","_my"];
			_a1 = [_cx + _mx, _cy + _my];
			_b1 = [_cx + _mx, _cy - _my];
			_c1 = [_cx - _mx, _cy + _my];
			_d1 = [_cx - _mx, _cy - _my];
			
			_a = [_center, _a1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;
			_b = [_center, _b1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;
			_c = [_center, _c1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;
			_d = [_center, _d1, -1*markerDir _mark] call CBA_fnc_vectRotate2D;
			
			{
				_x set [2,0];
			} forEach [_a,_b,_c,_d];
			
			_a2 = +_a;
			_b2 = +_b;
			_c2 = +_c;
			_d2 = +_d;
			
			{
				_x set [2, 35];
			} forEach [_a,_b,_c,_d];
			
			_abVect = vectorNormalized [(_b select 0) - (_a select 0), (_b select 1) - (_a select 1), 0];
			_acVect = vectorNormalized [(_c select 0) - (_a select 0), (_c select 1) - (_a select 1), 0];
			_cdVect = vectorNormalized [(_d select 0) - (_c select 0), (_d select 1) - (_c select 1), 0];
			_bdVect = vectorNormalized [(_d select 0) - (_b select 0), (_d select 1) - (_b select 1), 0];
			
			_abVect set [2, 35];
			_acVect set [2, 35];
			_cdVect set [2, 35];
			_bdVect set [2, 35];			
			
			{
				_i = _x select 0;
				_j = _x select 1;
				_x set [0, _i*10];
				_x set [1, _j*10];
			} forEach [_abVect, _acVect, _cdVect, _bdVect];
			
			{
				_x params ["_unitvec","_start","_end"];
				_unitvec params ["_ux", "_uy"]; // Magnitude 10
				_startingpoint = [(_unitvec select 0) + (_start select 0), (_unitvec select 1) + (_start select 1), 0];
				_steps = floor ( (_start distance _end) / 10 );
				_i = 0;
				_prev = _start;
				while { _i < _steps } do {
					private _startbottom = +_startingpoint;
					private _starttop = +_startingpoint;
					_starttop set [2,35];
					drawLine3D [_startbottom,_starttop,[0,0,1,1]];
					drawLine3D [_starttop, _prev, [0,0,1,1]];
					_prev = _starttop;
					_startingpoint set [0, (_startingpoint select 0) + _ux];
					_startingpoint set [1, (_startingpoint select 1) + _uy];
					_i = _i + 1;
				};
				drawLine3D [_prev, _end, [0,0,1,1]];
				
			} forEach [[_abVect,_a,_b], [_acVect,_a,_c], [_cdVect,_c,_d], [_bdVect,_b,_d]];		
			
			
			/*drawLine3D [_a,_b,[0,0,1,1]];
			drawLine3D [_a,_c,[0,0,1,1]];
			drawLine3D [_c,_d,[0,0,1,1]];
			drawLine3D [_b,_d,[0,0,1,1]];*/
			
			drawLine3D [_a,_a2,[0,0,1,1]];
			drawLine3D [_b,_b2,[0,0,1,1]];
			drawLine3D [_c,_c2,[0,0,1,1]];
			drawLine3D [_d,_d2,[0,0,1,1]];
		};
		
	} forEach RTS_deploymentMarks;
};

// Draw Vision information
if ( RTS_selecting ) then {
	getMousePosition params ["_mx", "_my"];
	RTS_selectStart params ["_sx", "_sy"];
	
	private _mxmy = screenToWorld [_mx,_my];
	private _sxsy = screenToWorld [_sx,_sy];
	private _sizeX = ( (_mxmy select 0) max (_sxsy select 0)) - ((_mxmy select 0) min (_sxsy select 0));
	private _sizeY = ( (_mxmy select 1) max (_sxsy select 1)) - ((_mxmy select 1) min (_sxsy select 1));
	if ( _sizeX > 0.2 && _sizeY > 0.2 ) then {
	
		_a = _mxmy;
		_b = screenToWorld [_sx,_my];
		_c = screenToWorld [_mx,_sy];
		_d = _sxsy;
		
		_a2 = +_a;
		_b2 = +_b;
		_c2 = +_c;
		_d2 = +_d;
		
		{
			_x set [2, 3];
		} forEach [_a,_b,_c,_d];
		
		drawLine3D [_a,_b,[1,1,1,1]];
		drawLine3D [_a,_c,[1,1,1,1]];
		drawLine3D [_c,_d,[1,1,1,1]];
		drawLine3D [_b,_d,[1,1,1,1]];
		
		drawLine3D [_a,_a2,[1,1,1,1]];
		drawLine3D [_b,_b2,[1,1,1,1]];
		drawLine3D [_c,_c2,[1,1,1,1]];
		drawLine3D [_d,_d2,[1,1,1,1]];
	};
};

if ( RTS_commanding ) then {
	// Draw orders
	{
		private ["_grpPos", "_waypoints", "_commands", "_leader"];
		if ( count ( (units _x) select { alive _x } ) > 0 ) then {
			_leader = leader _x;
			_grpPos = getPosATLVisual _leader;
			_grpPos set [2, (_grpPos select 2) + 3];
			
			if ( _x == RTS_selectedGroup ) then  {
				_commander = _x getVariable ["command_element", objnull];
				
				if (!(isNull _commander)) then {
					if ( alive (leader _commander) ) then {
						_compos = visiblePosition (leader _commander);
						_compos set [2, (_compos select 2) + 3];
						drawLine3d [_grpPos, _comPos,[0,0,1,1]];
					};
				};
				
				_subunits = _x getVariable ["subordinates", []];
				
				if ( (count _subunits) > 0 ) then {
					{
						if ( alive _leader ) then {
							_compos = getPosATLVisual (leader _x);
							_compos set [2, (_compos select 2) + 3];
							drawLine3d [_grpPos, _compos,[0,1,0,1]];
						};
					} forEach _subunits;
				};
			};
			
			_commands = _x getVariable ["commands", []];
			for "_i" from 0 to ((count _commands) - 1) do {	
				if ( _i == 0 ) then {
					drawLine3D [_grpPos, (_commands select _i) select 0, RTS_sideColor];
				} else {
					drawLine3D [(_commands select (_i - 1)) select 0, (_commands select _i) select 0, RTS_sideColor];
				};
				
				if ( _x == RTS_selectedGroup ) then {
					
					// Waypoint number
					private _group = _x;
					private _command = _commands select _i;
					private _waypointDesc = format ["%1", _i + 1];
					
					if ( _i == 0 && ( (_x getVariable ["pause_remaining",0]) > 0 ) ) then {
						private _pausetime = _x getVariable ["pause_remaining",0];
						_waypointDesc = format ["%1 / Wait %2", _i + 1, [_pausetime,"MM:SS"] call BIS_fnc_secondsToString];
					} else {
						if ( count _command > 6 ) then {
							private _pausetime = _command select 6;
							_waypointDesc = format ["%1 / Wait %2", _i + 1, [_pausetime,"MM:SS"] call BIS_fnc_secondsToString];
						};
					};
					
					_command params ["_pos", "_type", "_behaviour", "_combat", "_form", "_speed"];
					
					// Speed mode info
					if ( vehicle (leader _group) == (leader _group) ) then { 
						if ( _type == "MOVE" ) then {
							if ( _speed == "NORMAL" ) then {
								_waypointDesc = format ["%1 / %2", _waypointDesc, "Quick"];
							};
							if ( _speed == "FULL" ) then {
								_waypointDesc = format ["%1 / %2", _waypointDesc, "Fast"];
							};						
						};
						if ( _type == "SEARCH" ) then {
							_waypointDesc = format ["%1 / %2", _waypointDesc, "Search"];					
						};
					};
					if ( _form != "" ) then {
						_waypointDesc = format ["%1 / %2", _waypointDesc, _form];
					};
					
					if ( _combat != "" ) then {
						_waypointDesc = format ["%1 / %2", _waypointDesc, 
							( switch ( _combat ) do {
								case "YELLOW": { "Fire at Will" };
								case "RED": { "CQC" };
								case "GREEN": { "Return Fire" };
								default { _combat };
							})];
					};
					
					// Draw all the waypoints
					drawIcon3D ["\A3\ui_f\data\map\groupicons\waypoint.paa", [0,0,0,1], (_commands select _i) select 0, 1.1, 1.1,0];
					drawIcon3D ["\A3\ui_f\data\map\groupicons\waypoint.paa", RTS_sideColor, (_commands select _i) select 0, 1, 1,0];
					drawIcon3D ["", [1,1,1,1], (_commands select _i) select 0, 1, 1, 0, _waypointDesc,2,0.04];
				};
			};
		};
	} forEach RTS_commandingGroups;
};