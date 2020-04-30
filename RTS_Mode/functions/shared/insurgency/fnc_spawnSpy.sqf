params ["_pos"];


private _setup = selectRandom INS_spySetups;
_setup params ["_type","_loadout"];

_soldier = (createGroup east) createUnit [_type, _pos, [], 0, "NONE"];
_soldier setUnitLoadout _loadout;

_grp = group _soldier;
_grp setVariable ["RTS_setup", [_grp, "Spy", grpnull, "\A3\ui_f\data\map\markers\nato\o_support.paa", "o_support"],true];

INS_spies pushback _soldier;