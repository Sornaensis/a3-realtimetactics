params ["_pos"];


_soldier = (createGroup east) createUnit [INS_spyClasses call BIS_fnc_selectRandom, _pos, [], 0, "NONE"];
_soldier setUnitLoadout (INS_spyLoadouts call BIS_fnc_selectRandom);

_grp = group _soldier;

_grp setVariable ["RTS_setup", [_grp, "Spy", grpnull, "\A3\ui_f\data\map\markers\nato\o_support.paa", "o_support"],true];