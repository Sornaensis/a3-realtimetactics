/*
// For Insurgency Missions
INS_getZone = {
	params ["_zoneName"];
	
	(INS_controlAreas select { _x select 0 == _zoneName }) select 0;
};

((["Nur"] call INS_getZone) # 2) set [ 0, -100 ];
((["Nagara"] call INS_getZone) # 2) set [ 0, -100 ];
((["Gospandi"] call INS_getZone) # 2) set [ 0, -100 ];
((["Mulladost"] call INS_getZone) # 2) set [ 0, -100 ];
((["Khusab"] call INS_getZone) # 2) set [ 0, -100 ];
((["Shamali"] call INS_getZone) # 2) set [ 0, -100 ];

((["Rasman"] call INS_getZone) # 2) set [ 0, 100 ];
((["Bastam"] call INS_getZone) # 2) set [ 0, 100 ];
((["Imarat"] call INS_getZone) # 2) set [ 0, 100 ];
((["Garmarud"] call INS_getZone) # 2) set [ 0, 100 ];

((["Feruz Abad"] call INS_getZone) # 2) set [ 0, -20 ];
*/
