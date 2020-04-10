params ["_pos", "_cmndgrp", "_owngrp"];


private _soldier = (if (!isNil "_owngrp") then { _owngrp } else { (createGroup east) }) createUnit [INS_soldierClasses call BIS_fnc_selectRandom, _pos, [], 0, "NONE"];
_soldier setUnitLoadout (INS_soldierLoadouts call BIS_fnc_selectRandom);

private _grp = group _soldier;

private _qualifier = if ( (secondaryWeapon _soldier) != "" ) then {
						getText (configFile >> "CfgWeapons" >> secondaryWeapon _soldier >> "displayName")
					 } else {
					 	getText (configFile >> "CfgWeapons" >> primaryWeapon _soldier >> "displayName")
					 };

_grp setVariable ["RTS_setup", [_grp, (if (!isNil "_owngrp") then {
									   		"Team"
									   } else {
									   		format ["Fighter (%1)", _qualifier]
									   }), _cmndgrp, "\A3\ui_f\data\map\markers\nato\o_inf.paa", "o_inf"],true];