params ["_pos"];

private _setups = selectRandom INS_mgSetups;

private _group = grpnull;

{
	_x params ["_type","_loadout"];
	if ( isNull _group ) then {
		private _soldier = (createGroup east) createUnit [_type, _pos, [], 0, "NONE"];
		_soldier setUnitLoadout _loadout;
		_group = group _soldier;
	} else {
		private _soldier = _group createUnit [_type, _pos, [], 0, "NONE"];
		_soldier setUnitLoadout _loadout;
	};
} forEach _setups;

_group setVariable ["RTS_setup", [_group, "MG Team", grpnull, "\A3\ui_f\data\map\markers\nato\o_inf.paa", "o_inf"],true];