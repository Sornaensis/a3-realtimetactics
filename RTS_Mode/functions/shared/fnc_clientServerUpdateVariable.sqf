// Used for coordinating variable updates between client and server.
// Should be used in place of publicVariable when changes can occur on either client or server

params ["_variableName","_variable"];

private _routingOutgoing = ( if ( isServer ) then { -1 } else { 0 } ); // send message to and fro
private _routingIncoming = ( if ( isServer ) then { 0 } else { -1 } );

private _magicNumber_1 = floor (random (8192*2*2));
private _magicNumber_2 = floor (random (8192*2*2));
private _magicNum = format ["%1__%2", _magicNumber_1, _magicNumber_2];

private _magicNumVar = format [ "__CSU_coordinated_%1__%2_MAGIC_VARIABLE_%3", time, _variableName, floor (random 2048) ];
private _lockVar = format [ "__CSU_coordinated__%1_LOCK", _variableName ];

// set magic variable
missionNamespace setVariable [_magicNumVar, _magicNum, false];
missionNamespace setVariable [_lockVar, false, false];


// Request lock
[ _routingOutGoing,
	{
	}, [ _lockVar, _magicNum ] ] call CBA_fnc_globalExecute;