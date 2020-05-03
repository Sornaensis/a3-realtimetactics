params ["_pos","_group","_side"];

if ( isNil "_group" ) then {
	if ( isNil "_side" ) then {
		_group = createGroup east;
	} else {
		_group = createGroup _side;
	};
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
