params ["_group","_off"];

if ( !isNil "_off" ) then {
	_group enableAttack false;
} else {
	_group enableAttack true;
};

{
	if ( !isNil "_off" ) then {
		_x disableAI "AUTOCOMBAT";
		_x disableAI "COVER";
		_x disableAI "AUTOTARGET";
		_x disableAI "FSM";
	} else {
		_x enableAI "AUTOCOMBAT";
		_x enableAI "AUTOCOMBAT";
		_x enableAI "COVER";
		_x enableAI "AUTOTARGET";
		_x enableAI "FSM";
	};
} forEach (units _group);