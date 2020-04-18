private _unit = _this;

RTS_militiaAI  = [['aimingAccuracy',0.1],['aimingShake',0.1],['aimingSpeed',0.15],['commanding',1],['courage',0.5],['endurance',0.6],['general',0.5],['reloadSpeed',1],['spotDistance',0.7],['spotTime',0.7]];
RTS_greenAI    = [['aimingAccuracy',0.15],['aimingShake',0.1],['aimingSpeed',0.25],['commanding',1],['courage',0.8],['endurance',1],['general',0.5],['reloadSpeed',1],['spotDistance',0.8],['spotTime',0.8]];
RTS_veteranAI  = [['aimingAccuracy',0.25],['aimingShake',0.25],['aimingSpeed',0.35],['commanding',1],['courage',1],['general',1],['reloadSpeed',1],['spotDistance',0.85],['spotTime',0.85]];
RTS_eliteAI    = [['aimingAccuracy',0.4],['aimingShake',0.4],['aimingSpeed',0.45],['commanding',1],['courage',1],['endurance',1],['general',1],['reloadSpeed',1],['spotDistance',0.8],['spotTime',0.8]];


private _group = group _unit;
private _side = side _group;
private _sideModifier = (switch (_side) do {
						case west: { RTS_bluforAIModifier };
						case east: { RTS_opforAIModifier }; 
						case resistance: { RTS_greenforAIModifier }; 
						});

_group setVariable ["LeaderFactor", _group getVariable ["LeaderFactor", 3 - (floor (random 5.5)) ] ];

private _leaderFactor = _group getVariable "LeaderFactor";


private _groupExp = ( switch ( _group getVariable ["Experience", "GREEN"] ) do {
					  	case "GREEN": { RTS_greenAI };
					  	case "VETERAN": { RTS_veteranAI };
					  	case "ELITE": { RTS_eliteAI };
					  });


private _isLeader = leader _group == _unit;

private _softFactor = (0.02 * (_leaderFactor + 1) * ( if ( _isLeader ) then { 1.045 } else { 1 } )) + (0.04 - random 0.08);

_unit setVariable ["SoftFactor", _unit getVariable ["SoftFactor", _softFactor]];

_softFactor = _unit getVariable "SoftFactor";


private _unitSoftFactors = _softFactor * ( _sideModifier / 100 + 1 );

{
	_x params ["_name","_val"];
	_unit setSkill [_name,_val*(1+_unitSoftFactors)];
} forEach _groupExp;	