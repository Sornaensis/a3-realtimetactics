private _unit = _this;

RTS_militiaAI  = [["aimingAccuracy",0.1],["aimingShake",0.1],["aimingSpeed",0.15],["commanding",1],["courage",0.5],["endurance",0.5],["general",0.5],["reloadSpeed",1],["spotDistance",0.7],["spotTime",0.7]];
RTS_greenAI    = [["aimingAccuracy",0.15],["aimingShake",0.1],["aimingSpeed",0.25],["commanding",1],["courage",0.8],["endurance",0.7],["general",0.5],["reloadSpeed",1],["spotDistance",0.75],["spotTime",0.75]];
RTS_veteranAI  = [["aimingAccuracy",0.3],["aimingShake",0.3],["aimingSpeed",0.35],["commanding",1],["courage",1],["endurance",1],["general",1],["reloadSpeed",1],["spotDistance",0.85],["spotTime",0.85]];
RTS_eliteAI    = [["aimingAccuracy",0.4],["aimingShake",0.4],["aimingSpeed",0.45],["commanding",1],["courage",1],["endurance",1.2],["general",1],["reloadSpeed",1],["spotDistance",0.85],["spotTime",0.85]];


private _group = group _unit;
private _side = side _group;
private _sideModifier = (switch (_side) do {
						case west: { RTS_bluforAIModifier };
						case east: { RTS_opforAIModifier }; 
						case resistance: { RTS_greenforAIModifier };
						case civilian: { RTS_bluforAIModifier };
						});

_group setVariable ["LeaderFactor", _group getVariable ["LeaderFactor", 3 - (floor (random 5.5)) ] ];

private _leaderFactor = _group getVariable "LeaderFactor";


private _groupExp = ( switch ( _group getVariable ["Experience", "GREEN"] ) do {
					  	case "GREEN": { RTS_greenAI };
					  	case "VETERAN": { RTS_veteranAI };
					  	case "ELITE": { RTS_eliteAI };
					  	case "MILITIA": { RTS_militiaAI };
					  });


private _isLeader = leader _group == _unit;

private _softFactor = (0.05 * (_leaderFactor + 1) * ( if ( _isLeader ) then { 1.045 } else { 1 } )) + (0.1 - random 0.2);

_unit setVariable ["SoftFactor", _unit getVariable ["SoftFactor", _softFactor]];

_softFactor = _unit getVariable "SoftFactor";

private _unitSoftFactors = _softFactor * ( _sideModifier / 100 + 1 );

{
	_x params ["_name","_val"];
	_unit setSkill [_name, _val*(1+_unitSoftFactors)];
} forEach _groupExp;	

if ( (_unit skill "spotDistance") > 0.85 ) then {
	_unit setSkill ["spotDistance", 0.85];
};
if ( (_unit skill "spotTime") > 0.85 ) then {
	_unit setSkill ["spotTime", 0.85];
};

if ( side _unit != RTS_sidePlayer ) then {
	(group _unit) setVariable ["VCM_SkillDisable",true];
};