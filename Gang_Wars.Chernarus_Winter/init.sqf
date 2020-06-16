// Scenario init
call compile preprocessFileLineNumbers "scen_fw\init.sqf";

// Hide Markers
{
	_x setMarkerAlpha 0;
} foreach [ 
			"tent_marker",
			"observe_meeting_marker",
			"ambush_north",
			"ambush_east",
			"cdf_basemarker",
			"safehouse_2"
		   ];