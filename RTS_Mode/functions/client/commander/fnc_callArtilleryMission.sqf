#include "\z\ace\addons\spectator\script_component.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"

removeAllMissionEventHandlers "MapSingleClick";

private _group = RTS_selectedGroup;

RTS_artillery_group = _group;

RTS_artillery_spotters = units _group; 

RTS_artillery_mortars = ( (_group getVariable ["subordinates", []]) select { count (getArtilleryAmmo [(vehicle (leader _x))]) > 0 } ) apply { vehicle (leader _x) };
private _mags = getArtilleryAmmo RTS_artillery_mortars;

RTS_artillery_magazine = _mags select (lbCurSel RTS_artMagazineBox);

RTS_artillery_duration = (switch ( lbCurSel RTS_artDurationBox ) do {
				 	case 0: {
				 		selectRandom [3,4,5,6]
					};
					case 1: {
						selectRandom [8,9,10,11]
					};
					case 2: {
						selectRandom [15,16,17,18,19,20]
					};
				 });

RTS_artillery_delay = (switch ( lbCurSel RTS_artDelayBox ) do {
				 	case 0: {
				 		0
					};
					case 1: {
						60
					};
					case 2: {
						5*60
					};
					case 3: {
						600	
					};
					case 4: {
						15*60
					};
				 });


RTS_artillery_count = (lbCurSel RTS_artGunCountBox) + 1;

RTS_artillery_radius = ( switch ( lbCurSel RTS_artSizeBox ) do {
						 	case 0: { 0 };
						 	case 1: { 50 };
						 	case 2: { 100 };
						 	case 3: { 200 };
						 	case 4: { 400 };
						 });

addMissionEventHandler [ "MapSingleClick", 
	{ 
		params ["_units", "_pos", "_alt", "_shift"];
		
		private _bestView = 0;
		
		private _checkPos = +_pos;
		_checkPos set [2,2];
		_checkPos = ATLtoASL _checkPos;
		
		{
			_x doWatch _pos;
			private _view = [vehicle _x, "VIEW"] checkVisibility [ eyePos _x, _checkPos ];
			_bestView = _view max _bestView;
		} forEach RTS_artillery_spotters;
		
		[] call FUNC(ui_toggleMap);
		
		if ( _bestView < 0.2 ) exitWith { RTS_artStatusLabel ctrlSetText "Spotters have no LOS" };
		
		if ( count RTS_artillery_mortars == 0 ) exitWith {};
		
		[ _pos, RTS_artillery_group, +RTS_artillery_mortars, RTS_artillery_radius, RTS_artillery_magazine, RTS_artillery_duration, RTS_artillery_delay, RTS_artillery_count, RTS_artillery_spotters ] spawn {
			params [ "_pos", "_group", "_mortars", "_radius", "_magazine", "_duration", "_delay", "_count", "_spotters" ];
			
			private _shooters = [];
			
			for "_i" from 1 to _count do {
				private _gun = selectRandom _mortars;
				_shooters pushBack _gun;
				_mortars = _mortars - [ _gun ];
				(effectiveCommander _gun) doWatch _pos;
			};
			
			_group setVariable [ "ArtilleryMission", "RECEIVING" ];
			
			sleep ( 30 + random 15 );
			
			_group setVariable [ "ArtilleryMission", "DELAY" ];
			
			sleep _delay;
			
			_group setVariable [ "ArtilleryMission", "FIRING" ];
			
			private _scripts = [];
			
			{
				_scripts pushBack ([ _x, _duration, _pos, _radius, _magazine, _spotters ] spawn {
					params ["_gun", "_duration", "_pos", "_radius", "_magazine", "_spotters" ];
					
					private _checkPos = +_pos;
					_checkPos set [2,2];		
					_checkPos = ATLtoASL _checkPos;
		
					for "_i" from 1 to _duration do {
						
						sleep ( (random 5) + 2.2 );
						
						// Fire mission adjusts based on visibility
						private _bestView = 0;		
						
						{
							private _view = [vehicle _x, "VIEW"] checkVisibility [ eyePos _x, _checkPos ];
							_bestView = _view max _bestView;
						} forEach _spotters;	
					
						( effectiveCommander _gun ) doWatch _pos;
						
						if ( _bestView == 0 ) then {
							_bestView = 0.01;
						};
						
						_gun doArtilleryFire [ [ _pos, _radius + ( (35 / _bestView ) min 400 ) ] call CBA_fnc_randPos, _magazine, 1 ];
					};
				});
			} forEach _shooters;
			
			
			waitUntil { count (_scripts select { ! (scriptDone _x) }) == 0 };
			
			_group setVariable [ "ArtilleryMission", "WAITING" ];
			
		};
		
		removeAllMissionEventHandlers "MapSingleClick";
	}];

[] call FUNC(ui_toggleMap);