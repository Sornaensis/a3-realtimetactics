#include "RTS_defines.hpp"

waitUntil {!isNull player};
waitUntil {player == player};

setGroupIconsVisible [true,false];

if !RTS_SingleCommander then {

	player addEventHandler ["Respawn", 
		{ 
			player setUnitLoadout [[],false];
			setGroupIconsSelectable true;
			hintSilent "Open the map and select a new unit to join";
			onGroupIconClick {
				private _units = (units (_this select 1)) select { (vehicle _x) == _x };
				if ( (count _units) == 0 ) exitWith { hintSilent "No valid unit in that group" };
				private _unit = _units call BIS_fnc_selectRandom;
				private _loadout = getUnitLoadout _unit;
				private _pos = getPosATL _unit;
				private _dir = getDir _unit;
				player setUnitLoadout [_loadout, false];
				deleteVehicle _unit;
				player setPosATL _pos;
				player setDir _dir;
				setGroupIconsSelectable false;
				onGroupIconClick {};
			};
		}];
};