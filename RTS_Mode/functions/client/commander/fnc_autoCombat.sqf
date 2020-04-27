params ["_group","_off"];

{
	if ( !isNil "_off" ) then {
		//_x disableAI "AUTOCOMBAT";
	} else {
		//_x enableAI "AUTOCOMBAT";
	};
} forEach (units _group);

if ( !isNil "_off" ) then {
	if ( combatMode _group == "RED" ) then {
		_group setCombatMode "YELLOW";
	};
} else {
	_group setCombatMode "RED";
};

{
	if ( _x != leader _group ) then {
		_x doWatch objnull;
		_x doFollow (leader _group);
	};
} forEach (units _group);