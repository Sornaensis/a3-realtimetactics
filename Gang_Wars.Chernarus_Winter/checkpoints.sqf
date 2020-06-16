 [
 	
 	[ { count (allPlayers select { (getPos _x) inArea entered_pavlovo }) >= (1 max (ceil ((count (allPlayers select { alive _x })) / 2))) }
	, getMarkerPos "contact_location_marker"
	, 60
	, { if ( the_contact getVariable ["equipment_convo", false] ) then { player addWeapon "tf_anprc148jem_1"; }; }
	]
,	[ { mob_boss getVariable ["boss_convo", false] }
	, getMarkerPos "safehouse_2"
	, 20
	, { if ( the_contact getVariable ["equipment_convo", false] ) then { player addWeapon "tf_anprc148jem_1"; }; }
	]

 ]