// Commander Specific constantly running functionality

ace_hearing_disableVolumeUpdate = true;
waitUntil { !(isNil "ace_spectator_camdummy") };
waitUntil { !(isNil "ace_spectator_camera") };
waitUntil { !(isNil "RTS_setupComplete") };
waitUntil { RTS_setupComplete };
		
private _camstart = getMarkerPos RTS_camStart;
_camstart set [2,120];
private _camtarget = getMarkerPos RTS_camTarget;
ace_spectator_camera setPos _camstart;
private _target = "camera" createVehicle _camtarget;
hideObject _target;
[_target] call ace_spectator_fnc_setFocus;

RTS_sound = 1;
RTS_aoRestriction =
	addMissionEventHandler ["Draw3D", 
	{
		if ( RTS_commanding ) then {
		
			if ( !((getMarkerSize RTS_aoMarker) isEqualTo [0,0]) ) then {
				(getMarkerPos RTS_aoMarker) params ["_aoX","_aoY"];
				(getMarkerSize RTS_aoMarker) params ["_width","_height"];
				private _aoMaxX = _aoX + _width;
				private _aoMinX = _aoX - _width;
				private _aoMaxY = _aoY + _height;
				private _aoMinY = _aoY - _height;
			
				/// AREA OF OPERATIONS RESTRICTION
				(getPosATL ace_spectator_camera) params ["_camX","_camY","_camZ"];
				_setpos = false;
				if ( _camX > _aoMaxX ) then {
					_camX = _aoMaxX;
					_setpos = true;
				};
				if ( _camX < _aoMinX ) then {
					_camX = _aoMinX;
					_setpos = true;
				};
				if ( _camY > _aoMaxY ) then {
					_camY = _aoMaxY;
					_setpos = true;
				};
				if ( _camY < _aoMinY ) then {
					_camY = _aoMinY;
					_setpos = true;
				};
				if _setpos then {
					ace_spectator_camera setPosATL [_camX,_camY,_camZ];
				};
				///////////////////
			};
			
			/// SOUND CONTROL
			_allunits = [RTS_commandingGroups, { units _x }] call CBA_fnc_filter;
			_allunits2 = [];
			{
				_allunits2 = _allunits2 + _x;
			} forEach _allunits;
			
			_nearest = [ace_spectator_camera, _allunits2] call CBA_fnc_getNearest;
			_pos1 = getPos _nearest;
			_camPos = getPos ace_spectator_camera;
			_pos1 set [2,0];
			_camPos set [2,0];
			_dist = [_camPos, _pos1] call CBA_fnc_getDistance;
			private _newsound = ( ( (120 - _dist) max 0 )/120 );
			if ( _newsound > RTS_sound || _newsound < RTS_sound ) then {
				1 fadeSound _newsound;
				RTS_sound = _newsound;
			};
			///////////////////////////
		} else {
			1 fadeSound 1;
		};
	}];
