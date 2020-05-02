params ["_pos","_group"];

if ( isNil "_group" ) then {
	_group = createGroup east;
};

private _setups = ( 
	switch ( side _group ) do {
		case east: {
			 INS_squadSetups
		};
		case resistance:{
			INS_greenforSquadSetups
		};
		case west: {
			INS_bluforSquadSetups
		};
		case civilian: {
			INS_civilianSetups
		};
	});
	
private _soldier = objnull;

if ( side _group != civilian ) then {
	private _setup = selectRandom (selectRandom _setups);
	_setup params ["_type","_loadout"];
	_soldier = _group createUnit [_type, _pos, [], 0, "NONE"];
	_soldier setUnitLoadout _loadout;
} else {
	_soldier = _group createUnit [selectRandom _setups, _pos, [], 0, "NONE"];
};

_soldier
