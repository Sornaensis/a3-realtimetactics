params ["_group", "_pos"];

_commands = _group getVariable ["commands", []];

private _newcommand = [ _pos,
						"MOVE",
						"AWARE",
						"",
						"",
						if ( (vehicle (leader _group)) == (leader _group) ) then {
							"NORMAL"
						} else {
							"FULL"
						}
						];

_commands set [count _commands, _newcommand];

_group setVariable ["commands", _commands, true];