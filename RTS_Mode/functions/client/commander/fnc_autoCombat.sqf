params ["_group","_off"];

{
	if ( !isNil "_off" ) then {
		_x disableAI "AUTOCOMBAT";
		_x disableAI "AUTOTARGET";
	} else {
		_x enableAI "AUTOCOMBAT";
		_x enableAI "AUTOTARGET";
	};
} forEach (units _group);

if ( !isNil "_off" ) then {
	_group enableAttack false;
	if ( combatMode _group == "RED" ) then {
		_group setCombatMode "YELLOW";
	};
} else {
	_group enableAttack true;
	_group setCombatMode "RED";
};

{
	if ( _x != leader _group ) then {
		_x doWatch objnull;
		_x doFollow (leader _group);
	};
} forEach (units _group);