_ret = false;
if !(isNil "bluforCommander") then {
	if ( player == bluforCommander ) then {
		_ret = true
	};
};

if !(isNil "opforCommander") then {
	if ( player == opforCommander ) then {
		_ret = true
	};
};

_ret
