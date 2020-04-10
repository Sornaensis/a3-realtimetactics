params ["_side"];
private _i = 0;
private _highCommands = [];
private _commander = nil;
while { !(isNil (format ["BIS_HC_%1", _i])) } do {
	_commander = call (compile (format ["BIS_HC_%1", _i]));
	if ( (count ((synchronizedObjects _commander ) select { side _x == _side })) > 0 ) then {
		_highCommands set [count _highCommands, _commander];
	};
	_i = _i + 1;
};
_highCommands