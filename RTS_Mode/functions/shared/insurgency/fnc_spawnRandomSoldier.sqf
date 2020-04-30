params ["_pos","_group"];

if ( isNil "_group" ) then {
	_group = createGroup east;
};

private _setup = selectRandom (selectRandom INS_squadSetups);
_setup params ["_type","_loadout"];

private _soldier = _group createUnit [_type, _pos, [], 0, "NONE"];
_soldier setUnitLoadout _loadout;

_soldier
