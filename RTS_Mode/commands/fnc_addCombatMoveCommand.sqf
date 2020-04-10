params ["_group", "_pos"];

_commands = _group getVariable ["commands", []];

private _newcommand = [_pos,"MOVE", "COMBAT","YELLOW","LINE","FULL"];

_commands set [count _commands, _newcommand];

_group setVariable ["commands", _commands, true];