params ["_pos"];


private _soldier = (createGroup east) createUnit [INS_leaderClasses call BIS_fnc_selectRandom, _pos, [], 0, "NONE"];
_soldier setUnitLoadout (INS_leaderLoadouts call BIS_fnc_selectRandom);

private _grp = group _soldier;

private _qualifier = if ( (secondaryWeapon _soldier) != "" ) then {
						getText (configFile >> "CfgWeapons" >> secondaryWeapon _soldier >> "displayName")
					 } else {
					 	getText (configFile >> "CfgWeapons" >> primaryWeapon _soldier >> "displayName")
					 };

_grp setVariable ["RTS_setup", [_grp, format ["Leader (%1)", _qualifier], grpnull, "\A3\ui_f\data\map\markers\nato\o_hq.paa", "o_hq"],true];

private _subunit_count = floor (random [INS_groupMin, INS_groupMid, INS_groupMax]);

_subgroup = if (_subunit_count > 1) then { createGroup east } else { grpnull };

for "_j" from 1 to _subunit_count do {
	[_pos findEmptyPosition [5,30, "MAN"], _grp, if (_subunit_count > 1) then { _subgroup } else { nil }] call INS_fnc_spawnSoldier;
};

private _solecount = floor (random [INS_soleFighterMin, INS_soleFighterMid, INS_soleFighterMax]);

for "_j" from 1 to _solecount do {
	[_pos findEmptyPosition [5,50, "MAN"],_grp] call INS_fnc_spawnSoldier;
}