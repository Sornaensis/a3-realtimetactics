// Despite the name, this sets up all of opfor's stuff
private _cities = (nearestLocations [ getMarkerPos "map_center", ["NameCityCapital","NameCity","NameVillage"], 13000]) select { !((position _x) inArea "opfor_restriction") };

// locations we may use for opfor areas
INS_areas = (nearestLocations [ getMarkerPos "map_center", ["NameCityCapital","NameCity","NameVillage","NameLocal"], 13000]) select { !((position _x) inArea "opfor_restriction") }; // these are the different mission areas
INS_areaMarkers = [];
INS_bluforPacification = false;
publicVariable "INS_bluforPacification";

for "_i" from 0 to 100 do {
	private _mark = format ["ins_area_%1", _i];
	
	if ( !((markerSize _mark) isEqualTo [0,0]) ) then {
		INS_areaMarkers pushback _mark;
	};
};

INS_controlAreas = []; // format:
						/*
						 * [ name, marker name,
						 *   [ side allegiance value, manpower value, material value, blufor aggression, blufor intel ]
						 * ]
						 *
						 * Side Allegiance:
						 *  -100 - 0 - +100
						 *  [-100,-51] = east forces control and can move with impunity | text: "Insurgent forces have decisive control of the area"
						 *  [-50,-25]  = east forces may move freely but do not get manpower or material benefits | text: "Insurgent forces present amongst friendly (and unfriendly) militia."
						 *  [-24,0]    = east forces may not move freely, militia are more likely to be hostile to east forces | text: "Local militias strongly contesting the area."
						 *  [1,24]     = east forces may not move freely, militia are twice as likely to be hostile to east forces | text: "Local militias control the area."
						 *  [25,50]    = Milita are almost always friendly to blufor | text: "Friendly militia control the area."
						 *  [51,100]   = Area pacified, nearby opfor areas take manpower and materiel penalties | text: "Area is friendly controlled, local militias are exerting control into nearby territories".
						 */

private _areas = count INS_areaMarkers;
private _greenforLight = floor (_areas * 0.4);
private _greenforHeavy = floor (_areas * 0.4);
private _opforHeavy = ceil (_areas * 0.2);

private _leftover = _areas - (_greenforLight + _greenforHeavy + _opforHeavy);

if ( _leftover > 0 ) then {
	_greenforLight = _greenforLight + _leftover;
};

private _zoneSetups = ["GLIGHT","GHEAVY","OHEAVY"];

// Create control areas
{
	private _marker = _x;
	private _location = (INS_areas select { (position _x) inArea _marker }) select 0;
	
	private _zoneType = selectRandom _zoneSetups;
	private _allegiance = 0;
	
	switch ( _zoneType ) do {
		case "OHEAVY": {
			_opforHeavy = _opforHeavy - 1;
			if ( _opforHeavy == 0 ) then {
				_zoneSetups deleteAt (_zoneSetups find "OHEAVY");
			};
			_allegiance = random [-100,-80,-75];
		};
		case "GLIGHT": {
			_greenforLight = _greenforLight - 1;
			if ( _greenforLight == 0 ) then {
				_zoneSetups deleteAt (_zoneSetups find "GLIGHT");
			};
			_allegiance = random [-24,-10,-0];
		};
		case "GHEAVY": {
			_greenforHeavy = _greenforHeavy - 1;
			if ( _greenforHeavy == 0 ) then {
				_zoneSetups deleteAt (_zoneSetups find "GHEAVY");
			};
			_allegiance = random [1,10,24];
		};
	};
	
	(getMarkerSize _marker) params ["_mx","_my"];
	
	_marker setMarkerShape "ELLIPSE";
	_marker setMarkerBrush "CROSS";
	
	if ( _allegiance < -24 ) then {
		_marker setMarkerColor "ColorRed";
	} else {
		_marker setMarkerColor "ColorGreen";
	};
	
	private _buildings = ((getMarkerPos _marker) nearObjects ["HOUSE", _mx max _my ]) select { _x inArea _marker };
	_buildings = _buildings select { count (_x buildingPos -1) > 2 };
	
	private _roads = ((getMarkerPos _marker) nearRoads (_mx max _my)) select { _x inArea _marker };
	
	INS_controlAreas pushback [text _location, _marker, [_allegiance,floor ((count _buildings)/3),floor ((count _roads)/2),0, random 15]];
	
} forEach INS_areaMarkers;

INS_fastTravelFlags = [];

// Setup fast travel network for insurgents
{
	private _marker = _x select 1;
	private _area = getMarkerPos _marker;
	(getMarkerSize _marker) params ["_mx","_my"];
	private _buildings = (_area nearObjects [ "HOUSE", _mx max _my ]) select { (position _x) inArea _marker };
	private _pos = (getPos (selectRandom _buildings)) findEmptyPosition [ 5, 40, "lop_Flag_isis_F"];
	
	while { isOnRoad _pos || (_pos isEqualTo []) || (_pos isEqualTo [0,0,0]) } do {
		_pos = (getPos (selectRandom _buildings)) findEmptyPosition [ 5, 40, "lop_Flag_isis_F"]
	};
	
	private _flag = "lop_Flag_isis_F" createVehicle _pos;
	_flag allowDamage false;
	
	private _flagmark = createMarker [ format ["opfor_fast_travel_marker__%1", _x select 0], _pos];
	_flagMark setMarkerShape "ICON";
	_flagMark setMarkerType "hd_dot";
	_flagMark setMarkerText "Travel & Recruitment";
	_flagMark setMarkerAlpha 0;
	
	INS_fastTravelFlags pushback [ _flag, _x select 0, _flagmark, _forEachIndex];
} forEach INS_controlAreas;

// Set two of the three nearest the base to blue zones
private _nearestZones = [ INS_controlAreas, [], { (getMarkerPos (_x select 1)) distance (getMarkerPos "opfor_restriction")}, "ASCEND"] call BIS_fnc_sortBy;
private _nearestThree = [];
for "_i" from 0 to 2 do {
	_nearestThree pushback (_nearestZones # _i);
};

private _excl = (selectRandom _nearestThree) select 0;

{
	private _zone = _x;
	private _disp = random [52, 60, 90];
	(_zone select 2) set [0, _disp];
} forEach _nearestThree;

// Setup zones however the mission designer wants them
[] call (compile preprocessFileLineNumbers "mission_specific_zone_setups.sqf");

// Static verification
INS_areaCount = count INS_controlAreas;
publicVariable "INS_areaCount";

publicVariable "INS_fastTravelFlags";
publicVariable "INS_controlAreas";

INS_bluforZoneAmount = floor ( (count (INS_controlAreas)) * 0.75 );
publicVariable "INS_bluforZoneAmount";

INS_setupFinished = true;

waitUntil { count (INS_controlAreas select { ( (_x select 2) select 0 ) >= 51 }) >= INS_bluforZoneAmount };
INS_bluforPacification = true;
publicVariable "INS_bluforPacification";

[-1,
{
	if ( !hasInterface ) exitWith {};
	titleText ["<t size='1.5'>Coalition forces have successfully pacified a sufficient amount of the AO.</t>", "PLAIN", 1, true, true];
}] call CBA_fnc_globalExecute;

private _targetcities = INS_controlAreas select { ( (_x select 2) select 0 ) < -24 };

if ( count _targetcities == 0 ) then {
	_targetcities = INS_controlAreas select { ( (_x select 2) select 0 ) < 51 };
};

// CACHE 1
private _cachecity = selectRandom _targetcities;
private _cachecityname = _cachecity select 0;
private _cachecitymark = _cachecity select 1;
(getMarkerSize _cachecitymark) params ["_mx1","_my1"];

INS_cacheMarker1 = [format ["__cache___%1-%2", _cachecityname, time], [getMarkerPos _cachecitymark, 125] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", format ["Destroy Cache Near %1", _cachecityname], "PERSIST"] call CBA_fnc_createMarker;

// Spawn Cache
private _buildings1 = (nearestObjects [ getMarkerPos _cachecitymark, ["House"], _mx1 max _my1] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 }) select { !((position _x) inArea "opfor_restriction") };
private _buildingPos = ([_buildings1 call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom;
INS_cache1 = "CUP_GuerillaCacheBox" createVehicle [0,0,0];
INS_cache1 setPos _buildingPos;
INS_cacheBuildings = _buildings1;
INS_currentCache = INS_cache1;


// CACHE 2
private _cities = _targetcities select { (_x select 0) != _cachecityname };

if ( count _targetcities == 0 ) then {
	_targetcities = INS_controlAreas select { ( (_x select 2) select 0 ) < 51 };
};

private _cachecity1 = selectRandom _cities;
private _cachecityname1 = _cachecity1 select 0;
private _cachecitymark1 = _cachecity1 select 1;
(getMarkerSize _cachecitymark1) params ["_mx2","_my2"];

INS_cacheMarker2 = [format ["__cache___%1-%2", _cachecityname1,time], [getMarkerPos _cachecitymark1, 125] call CBA_fnc_randPos, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", format ["Destroy Cache Near %1", _cachecityname1], "PERSIST"] call CBA_fnc_createMarker;
INS_cacheMarker2 setMarkerAlpha 0;

// Spawn Cache
private _buildings = (nearestObjects [ getMarkerPos _cachecitymark1, ["House"], _mx2 max _my2 ] select { ( count ([_x] call BIS_fnc_buildingPositions)) > 0 }) select { !((position _x) inArea "opfor_restriction") };
private _buildingPos = ([_buildings call BIS_fnc_selectRandom] call BIS_fnc_buildingPositions) call BIS_fnc_selectRandom;
INS_cache2 = "CUP_GuerillaCacheBox" createVehicle [0,0,0];
INS_cache2 setPos _buildingPos;

INS_cacheBuildings2 = _buildings;

INS_cache1 addEventHandler [ "killed", 
{ 
	INS_caches = INS_caches - 1; 
	publicVariable "INS_caches";
	INS_cacheMarker1 setMarkerAlpha 0;
	INS_cacheMarker2 setMarkerAlpha 1;
	private _distance = 925 - (INS_intelLevel*25);
	private _markername = format ["__cache___marker_intel_%1-%2", _distance, INS_caches + 1];
	while { ! ( (((getMarkerPos _markername) select 0) == 0 )
				&& (((getMarkerPos _markername) select 1) == 0 )
				&& (((getMarkerPos _markername) select 2) == 0 ) ) } do {
		deleteMarker _markername;
		INS_intelLevel = INS_intelLevel - 1;
		_distance = 925 - (INS_intelLevel*25);
		_markername = format ["__cache___marker_intel_%1-%2", _distance, INS_caches + 1];
	};
	[-1, 
		{
			if ( isNil "opforCommander" ) exitWith {};
			if ( player == opforCommander ) then {
				[] call RTS_fnc_setupAllGroups;
			};
		}] call CBA_fnc_globalExecute;
}];
INS_cache2 addEventHandler [ "killed", 
{ 
	INS_caches = INS_caches - 1; 
	publicVariable "INS_caches";
	INS_cacheBuildings = INS_cacheBuildings2;
	INS_currentCache = INS_cache2;
}];

private _camPos = [getPos INS_cache1,200] call CBA_fnc_randPos;

while { (_camPos distance (getPos INS_cache1)) < 100 } do {
	_camPos = [getPos INS_cache1,300] call CBA_fnc_randPos;
};

"opfor_start" setMarkerPos (getPos INS_cache1);
"opfor_target" setMarkerPos _camPos;

private _commandbuildings = INS_cacheBuildings select { ((position _x) distance (position INS_cache1)) > 100 };

[-1, {
	params ["_cache1","_cache2"];
	if ( isNil "opforCommander" ) exitWith {};
	if ( player != opforCommander ) exitWith {};
	"opfor_deploy_0" setMarkerPos (getPos _cache1);
	"opfor_deploy_1" setMarkerPos (getPos _cache2);
	"opfor_deploy_0" setMarkerBrush "SOLID";
	"opfor_deploy_1" setMarkerBrush "SOLID";
	"opfor_deploy_0" setMarkerAlphaLocal 1;
	"opfor_deploy_1" setMarkerAlphaLocal 1;
	INS_cacheActual1 = [format ["__cache___marker1_%1", time], getPos _cache1, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", "Cache #1 Location"] call CBA_fnc_createMarker;
	INS_cacheActual2 = [format ["__cache___marker2_%1", time], getPos _cache2, "ICON", [1, 1], "COLOR:", "ColorRED", "TYPE:", "hd_objective", "TEXT:", "Cache #2 Location"] call CBA_fnc_createMarker;
   },[INS_cache1,INS_cache2]] call CBA_fnc_globalExecute;