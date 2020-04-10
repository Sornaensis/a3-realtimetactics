params ["_group"];
{
	_x enableAI "AUTOCOMBAT";
} forEach (units _group);