params ["_pos","_group"];

if ( isNil "_group" ) then {
	_group = createGroup east;
};

private _setups = ( 
	switch ( side _group ) do {
		case east: {
			 INS_squadSetups
		};
		case resistance:
		case west: {
			INS_greenforSquadSetups
		};
	});

private _setup = selectRandom (selectRandom _setups);
_setup params ["_type","_loadout"];

private _soldier = _group createUnit [_type, _pos, [], 0, "NONE"];
_soldier setUnitLoadout _loadout;

_soldier
