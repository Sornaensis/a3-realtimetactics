params ["_group", "_pos"];

_commands = _group getVariable ["commands", []];

private _newcommand = [_pos,"MOVE", if ( (vehicle (leader _group)) == (leader _group) ) then {"AWARE"} else {"AWARE"},combatMode _group,formation _group,"LIMITED"];

_commands set [count _commands, _newcommand];

_group setVariable ["commands", _commands, true];