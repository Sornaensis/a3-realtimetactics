params ["_pos","_side"];

private _nosetup = false;

if ( isNil "_side" ) then {
	_side = east;
} else {
	_nosetup = true;
};

private _setups = selectRandom (
	switch ( _side ) do {
		case east: { INS_squadSetups };
		case resistance: { INS_greenforSquadSetups };
		case west: { INS_bluforSquadSetups };
	});

private _group = grpnull;

{
	_x params ["_type","_loadout"];
	if ( isNull _group ) then {
		private _soldier = (createGroup _side) createUnit [_type, _pos, [], 0, "NONE"];
		_soldier setUnitLoadout _loadout;
		_group = group _soldier;
	} else {
		private _soldier = _group createUnit [_type, _pos, [], 0, "NONE"];
		_soldier setUnitLoadout _loadout;
	};
} forEach _setups;

if ( !_nosetup ) then {
	_group setVariable ["RTS_setup", [_group, "Squad", grpnull, "\A3\ui_f\data\map\markers\nato\o_inf.paa", "o_inf"],true];
};	

(leader _group)