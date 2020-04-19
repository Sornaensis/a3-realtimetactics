#include "..\..\..\RTS_defines.hpp"
params ["_group", "_description", "_commandelement", "_grouptexture", "_icon", "_exp", "_leaderfactor" ];

clearGroupIcons _group;

RTS_commandingGroups pushbackunique _group;

[_group] call CBA_fnc_clearWaypoints;

if ( !isNil "_exp" ) then {
	_group setVariable [ "Experience", _exp ];
};

if ( !isNil "_leaderfactor" ) then {
	_group setVariable [ "LeaderFactor", _leaderfactor ];
};

[-1, 
	{
		params ["_group", "_icon"];
		if ( (side (leader _group)) == (side player) ) then {
			_group addGroupIcon [ _icon, [0,0] ];
		};
	}, [_group, _icon] ] call CBA_fnc_globalExecute;


// VCOM Stuff
_group setVariable ["VCM_NOFLANK",true];
_group setVariable ["VCM_DisableForm",true];
_group setVariable ["VCM_NORESCUE",true];
_group setVariable ["VCM_TOUGHSQUAD",true];
//_group setVariable ["VCM_DISABLE",true];

if ( (vehicle (leader _group)) == (leader _group) ) then {
	[_group, true] call RTS_fnc_autoCombat;
};

_group setCombatMode "YELLOW";
{
	_x allowFleeing 0;
	_x disableAi "FSM";
	addSwitchableUnit _x;
	_x setUnitPos "AUTO";
	_x setSpeedMOde "AUTO";
	[_x] call RTS_setupUnit;
	private _unit = _x;
	{
		_x disableCollisionWith _unit;
		_unit disableCollisionWith _x;
	} forEach (units _group);
} forEach (units _group);

// Groups maintain orders in group namespace
// Groups can have morale break if they are separated from command elements and have low morale from taking casualties

_group setVariable ["moralefactor", 200];
_group setVariable ["icon", _icon];
_group setVariable ["status", if (RTS_phase == "MAIN") then { "WAITING" } else { "HOLDING" }, false];
_group setVariable ["texture", _grouptexture, false];
_group setVariable ["desc", _description, false];
_group setVariable ["initial_strength", count (units _group), false];
_group setVariable ["commands", [], true];       // Array of commands
_group setVariable ["command_element", _commandelement, false]; // Unit responsible for commanding this unit

if ( !(isNull _commandelement) ) then {
	_subunits  = _commandelement getVariable ["subordinates",[]];
	_commandelement setVariable ["iscommander", true, false];
	_subunits set [count _subunits, _group];
	_commandelement setVariable ["subordinates", _subunits, false];
};

_group setVariable ["initial_ammo", [_group] call RTS_fnc_getAmmoLevel ];

_group setVariable ["commandable", true, true];  // Determines whether the commander can issue orders
_group setVariable ["command_bonus", 0, false];   // 0-70 : Command bonus determined by the unit's distance to its _commandelement
												  //  Command bonus has a 0-25% reduction on morale loss from casualties
												  //  				and a ((0-25)/2)% increase in all skills 

// Morale is measured from -20 to 100
//  Morale hits are calculated as 
// 		Killed : (100/3) / (total_strength in units)
//      

_group setVariable ["morale", 100, false];  

_group setVariable ["owned_vehicle",
						if ( vehicle (leader _group) != (leader _group) )
							then { 
								private _driver = (driver (vehicle (leader _group)));
								if ( _driver != objnull ) then {
									_driver spawn {
										private _vehicle = vehicle _this;
										_this disableAi "MOVE";
										waitUntil { ! (alive _this) || !(canMove _vehicle) };
										if ( alive _this ) then {
											doStop _this;
											_this enableAi "MOVE";
											[group _this] call RTS_fnc_removeCommand;
										};
									};
								};
								vehicle (leader _group) 
							} else { 
								(units _group) allowGetIn false;
								nil 
							}, false];  // Group may own one vehicle if the leader is in said vehicle

[0, { params ["_obj", "_owner"]; _obj setGroupOwner _owner; }, [_group, clientOwner]] call CBA_fnc_globalExecute;

RTS_initialMen = RTS_initialMen + (count (units _group));
private _veh = _group getVariable ["owned_vehicle", nil]; 
if !(isNil "_veh") then {
	if ( _veh isKindOf "StaticWeapon" ) then {
		RTS_initialWeapons = RTS_initialWeapons + 1;
	} else {
		RTS_initialVehicles = RTS_initialVehicles + 1;
	};
};

{
	_x addEventHandler ["killed", 
	{ 
		private _unit = _this select 0;
		private _group = group _unit;
		
		if ( leader _group == _unit ) then {
			private _living = (units _group) select { alive _x };
			if ( count _living > 0 ) then {
				_group selectLeader ( _living select 0 );
			};
		};
		
		private _commandbonus = _group getVariable ["command_bonus", 0];
		_commandbonus = (if ( _commandbonus > 2 ) then { _commandbonus / 2 } else { 1 });
		private _living = count ((units _group) select { alive _x });
		private _casualties = (_group getVariable ["initial_strength",1]) - _living;
		private _moralefactor = _group getVariable ["moralefactor", 100];
		RTS_casualties = RTS_casualties + 1; 
		
		// Morale impact
		_group setVariable ["morale", -20 max ((_group getVariable ["morale", 0]) - ( 0 max ( (_moralefactor/6) / ( 1 max _living ) )*1.2*_casualties - _commandbonus ) )];
		
		private _newmorale = _group getVariable ["morale", 0];
		
		if ( _newmorale < 0 ) then {
			// If a unit breaks, the commander should not be able to control them personally
			if ( count ((units _group) select { _x == player && alive _x }) > 0 ) then {
				call RTS_fnc_releaseControlOfUnit;
			};
			_group setVariable ["commandable", false];
			while { count (_group getVariable ["commands",[]]) > 0 } do {
				[_group] call RTS_fnc_removeCommand;
			};
			[_group, true] call RTS_fnc_autoCombat;
			[_group, [[(getMarkerPos RTS_camStart),300,300,0,false]] call CBA_fnc_randPosArea] call RTS_fnc_addFastMoveCommand;
			{
				_x setUnitPos "AUTO";
			} forEach (units _group);
			{
				doStop _x;
				_x doFollow (leader _group);
			} forEach (units _group);
		} else {
			while { count (_group getVariable ["commands",[]]) > 0 } do {
				[_group] call RTS_fnc_removeCommand;
			};
			_group setCombatMode "YELLOW";
		};
	}];
	
	_x addEventHandler ["Hit", {
			params ["_unit","_source","_damage","_instigator"];
			private _group = group _unit;
			
			private _side = _unit getVariable ["HandleDamageSide", side _unit];
			
			if ( side _instigator != _side && !(_source isEqualTo "") && (_group getVariable ["status","WAITING"]) != "OTM" ) then {	
				while { count (_group getVariable ["commands",[]]) > 0 } do {
					[_group] call RTS_fnc_removeCommand;
				};
				_group setCombatMode "YELLOW";
			};
	}];
} forEach (units _group);


// Formation & morale manager + command bonuses
[_group] spawn {
	params ["_group"];
	while { (count ((units _group) select { [_x] call CBA_fnc_isAlive })) > 0 } do {
		private _leader = leader _group;
		
		if ( (vehicle _leader) != _leader && !(canMove (vehicle _leader)) ) then {
			{
				_x enableAI "MOVE";
			} forEach (units _group);
			private _veh = vehicle _leader;
			if ( group (driver _veh) == _group ) then {
				[_group, getPos _leader] call RTS_fnc_addUnloadOrLoadCommand;				
				[_group, getPos _leader] call RTS_fnc_addMountOrDismountCommand;
			};
		};
	
		_units = (units _group) select { [_x] call CBA_fnc_isAlive };
		private _maxmorale = (count _units) / (_group getVariable ["initial_strength", 1]) * 100;
		private _commandbonus = _group getVariable ["command_bonus", 0];
		_commandbonus = (if ( _commandbonus > 1 ) then { _commandbonus } else { 1 });
		
		private _commander = _group getVariable ["command_element", grpnull];
		private _gotCommandBoost = false;
		
		if ( !isNull _commander ) then {
			private _dist = (getPosATL (leader _group)) distance (getPosATL (leader _commander));
			private _commandboost = 150 / (if ( _dist > 1 ) then { _dist } else { 1 });
			_group setVariable ["command_bonus", floor _commandboost];
			_gotCommandBoost = true;
		};	
				
		if ( !_gotCommandBoost ) then {
			_group setVariable ["command_bonus", 1];
		};
		
		private _commands = _group getVariable ["commands", []];
		private _type = "WAIT";
		
		if ( count _commands > 0 ) then {
			private _current = _commands select 0;
			_type = _current select 1;
		};
		
		_group setVariable ["morale", _maxmorale min ( (_group getVariable ["morale",0]) + ( if ( (_group getVariable ["morale",0]) > 0 ) then { 0.1 } else { 0.03 } ) * _commandbonus )];
		
		if ( (_group getVariable ["morale",0]) > 0 ) then {
			_group setVariable ["commandable", true];
			{
				_x allowFleeing 0;
			} forEach (units _group);
		};
		
		
		sleep 2;
	};
};

if RTS_SingleCommander then {
	_group setVariable ["RTS_setup", [], false];
};