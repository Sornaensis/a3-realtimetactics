// Full Scenario Logic

/**
 *
		private _taskScript = 
		[	owner object/side, "Task Title", "Description", "marker", 
			position, "task_id", 
			{ <condition for success> }, [],
			{ <condition for failure> }, [],
			{ <condition for cancellation }, []		] call JTF_newTask;
		waitUntil { scriptDone _taskScript };
 *
*/

waitUntil { !(isNil "JTF_mission_started") };

{
	_x hideObjectGlobal true;
	_x enableSimulationGlobal false;
} forEach ( allUnits select { (getPos _x) inArea OBSERVING_1 });

sleep 10;

[safehouse_contact] call JTF_fnc_initConv;

// Speak with safehouse guy
private _safehouseTask = 
[	west, "Talk to Safehouse Contact", "Speak with the contact at the safehouse.", "", 
	getPos safehouse_contact, "talk_to_safehouse", 
	{ safehouse_contact getVariable ["intro_conversation", false] }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
waitUntil { scriptDone _safehouseTask };

// Arm Self Task 
private _armTask =
[	west, "Arm Yourselves", "There is a small weapons cache near the safehouse. Distribute the equipment amongst yourselves.", "", 
	getPos weapon_cache, "arm_self_task", 
	{ count (allPlayers select { currentWeapon _x != "" }) == count allPlayers}, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
waitUntil { scriptDone _armTask };

"meeting_marker" setMarkerAlpha 0;

// Search for Scout Camp
private _findScoutTask =
[	west, "Search for Scout Camp", "Some scouts have been sent ahead to do recon. Meet up with them and assist with security.", "tent_marker", 
	getMarkerPos "tent_marker", "search_for_scouts", 
	{ triggerActivated found_dead_scouts }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
waitUntil { (triggerActivated found_dead_scouts) && (count (["scout_executioners"] call JTF_fnc_getWaveGroups) > 0) };

sleep 2;

private _scoutAmbush = ((["scout_executioners"] call JTF_fnc_getWaveGroups) apply { units _x }) call JTF_fnc_flatten;

private _shooter = selectRandom _scoutAmbush;
_shooter forceWeaponFire [currentWeapon _shooter, currentWeaponMode _shooter];
sleep ((random 1.5) + 1);
_shooter = selectRandom _scoutAmbush;
_shooter forceWeaponFire [currentWeapon _shooter, currentWeaponMode _shooter];
sleep ((random 1.5) + 1);
_shooter = selectRandom _scoutAmbush;
_shooter forceWeaponFire [currentWeapon _shooter, currentWeaponMode _shooter];

// Attack camp location
{
	_x setSkill ["aimingAccuracy",0.01];
	_x setSkill ["aimingShake",0.01];
	[group _x, getPos tent_1, 50] call CBA_fnc_taskAttack;
} forEach _scoutAmbush;

waitUntil { count (_scoutAmbush select { alive _x }) == 0 };

// Enable meeting area stuff
{
	_x hideObjectGlobal false;
	_x enableSimulationGlobal true;
} forEach ( allUnits select { (getPos _x) inArea OBSERVING_1 });

// Observation area task
private _observeMeetingTask =
[	west, "Observe Meetingplace", "Looks like there's trouble ahead. Keep concealed in the treeline and find a spot to observe the meetingplace until it's time.", "observe_meeting_marker", 
	getMarkerPos "observe_meeting_marker", "observe_meetingplace", 
	{ triggerActivated observed_meeting }, [],
	{ false }, [],
	{ triggerActivated OBSERVING_1 }, []		] call JTF_newTask;
waitUntil { scriptDone _observeMeetingTask };

// If the player has not activated the attack trigger yet
if ( ("observe_meetingplace" call BIS_fnc_taskState) == "SUCCEEDED" ) then {		
	// Approach meeting area task
	private _supportMeetingTask =
	[	west, "Approach Carefully", "The meeting started early! Approach without being detected and support.", "", 
		getPos dead_leader, "support_meeting", 
		{ false }, [],
		{ false }, [],
		{ !(alive dead_leader) || !(alive dead_guard) || !(alive dead_guard2) }, []		] call JTF_newTask;
};

waitUntil { !(isNull (driver contraband_vehicle)) };

// Arm the boss being met with
warlord_1 setUnitLoadout [[],[],["rhs_weap_makarov_pm","","","",["rhs_mag_9x18_8_57N181S",8],[],""],["U_O_R_Gorka_01_black_F",[["FirstAidKit",1],["CUP_8Rnd_9x18_Makarov_M",3,8]]],[],[],"","milgp_f_tactical_khk",[],["ItemMap","","","ItemCompass","",""]];
sleep (random 0.8);
dead_leader setUnitLoadout [["rhs_weap_akm","rhs_acc_dtkakm","","",["rhs_30Rnd_762x39mm_bakelite",30],[],""],[],[],["CUP_U_C_Citizen_02",[["FirstAidKit",1],["rhs_30Rnd_762x39mm_polymer",2,30]]],[],[],"rhs_fieldcap_khk","",[],["ItemMap","","ItemRadio","ItemCompass","ItemWatch",""]];
sleep (random 0.8);
dead_guard setUnitLoadout [["rhs_weap_akm","rhs_acc_dtkakm","","",["rhs_30Rnd_762x39mm_bakelite",30],[],""],[],[],["CUP_U_O_CHDKZ_Lopotev",[["FirstAidKit",1],["rhs_mag_nspn_red",1,1],["rhs_30Rnd_762x39mm_polymer",2,30]]],[],[],"H_StrawHat_dark","",[],["ItemMap","","ItemRadio","ItemCompass","ItemWatch",""]];
sleep (random 0.8);
dead_guard2 setUnitLoadout [["CUP_arifle_AKS74U","","","",["CUP_30Rnd_545x39_AK74_plum_M",30],[],""],[],[],["CUP_U_O_CHDKZ_Lopotev",[["FirstAidKit",1],["rhs_mag_nspn_red",1,1],["rhs_30Rnd_545x39_7N6_green_AK",3,30]]],[],[],"H_Bandanna_gry","",[],["ItemMap","","ItemRadio","ItemCompass","ItemWatch",""]];
sleep (random 0.8);

sleep 1;

{
	_x setCaptive false;
} forEach [ gun_1, gun_2, warlord_1, dead_leader, dead_guard, dead_guard2 ];

warlord_1 allowDamage true;

dead_leader doTarget warlord_1;

{
	_x setDamage ((random 0.4) + 0.45);
} forEach ( vehicles select { _x inArea OBSERVING_1 && _x != contraband_vehicle } );

sleep 2;

dead_leader allowDamage true;
dead_guard allowDamage true;
dead_guard2 allowDamage true;

waitUntil { !(alive dead_leader) && !(alive dead_guard) && !(alive dead_guard2) };

gun_1 allowDamage true;
gun_2 allowDamage true;

{ 
	(group _x) setVariable ["Vcm_Disable",false];
} forEach [ dead_leader, dead_guard, dead_guard2, warlord_1, gun_1, gun_2 ];

// Secure meeting area task
private _secureAreaTask =
[	west, "Secure Area", "Kill the gunmen and secure the area.", "", 
	getPos dead_leader, "kill_rivals", 
	{ triggerActivated SECURED_1 }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
waitUntil { scriptDone _secureAreaTask };

waitUntil { count (["meeting_attack_team"] call JTF_fnc_getWaveGroups) > 0 };

private _meetingAttackUnits = ((["meeting_attack_team"] call JTF_fnc_getWaveGroups) apply { units _x }) call JTF_fnc_flatten;
[_meetingAttackUnits,0.2] call JTF_fnc_revealPlayers;
private _meetingAttackVehicles = ["meeting_attack_team"] call JTF_fnc_getWaveVehicles;

// Survive against counterattack task
private _holdPositionTask =
[	west, "Hold off Attackers", "A radio call from one of the enemy trucks indicated reinforcements are on their way from the east! Hold them off.", "", 
	getPos dead_leader, "hold_position", 
	{ count (_this select { alive _x }) == 0 }, _meetingAttackUnits,
	{ false }, [],
	{ false }, []		] call JTF_newTask;
waitUntil { scriptDone _holdPositionTask };

sleep 65;

// Retreat toward pavlovo
private _escapeToPavlovoTask =
[	west, "Escape Military Forces!", "CDF forces are on their way from Zelenogorsk! Escape south to Pavlovo.", "", 
	getMarkerPos "contact_location_marker", "go_to_pavlovo", 
	{ count (allPlayers select { (getPos _x) inArea entered_pavlovo }) >= (1 max (ceil ((count (allPlayers select { alive _x })) / 2))) }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;

sleep 60;

JTF_wave1_military_go = true;

waitUntil { scriptDone _escapeToPavlovoTask && count (["cdf_force_1"] call JTF_fnc_getWaveGroups) > 0 };

[the_contact] call JTF_fnc_initConv;

// Cleanup
{ 
	deleteVehicle _x;
} forEach ( _meetingAttackUnits + _meetingAttackVehicles );

private _cdfAttackUnits = ((["cdf_force_1"] call JTF_fnc_getWaveGroups) apply { units _x }) call JTF_fnc_flatten;
private _cdfAttackVehicles = ["cdf_force_1"] call JTF_fnc_getWaveVehicles;
{ 
	deleteVehicle _x;
} forEach ( _cdfAttackUnits + _cdfAttackVehicles );
////////////////////////////////

// Heal Everyone
[[],{[player] call ace_medical_treatment_fnc_fullHealLocal;}] remoteExecCall [ "call", 0 ];

// Search For Contact in Pavlovo	
private _findSaboteurTask =
[	west, "Find The Fixer", "This is war. And you are short on firepower. There is a company fixer located in Pavlovo. Find him and he will point you toward what you need.", "", 
	getMarkerPos "contact_location_marker", "find_saboteur", 
	{ the_contact getVariable ["fixer_convo", false] }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
waitUntil { scriptDone _findSaboteurTask };

// Radio boxes, and medical supplies
private _getRadiosTask =
[	west, "Acquire Radios", "Get everyone on a good radio.", "", 
	 getPos radio_crate, "radio_box", 
	{ count (allPlayers select { "tf_anprc148jem" in (assignedItems _x) }) == (count allPlayers) }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
private _getMedicalTask =
[	west, "Acquire Medic Gear", "Stock up on medical supplies.", "", 
	 getPos medic_crate, "medical_box", 
	{ triggerActivated found_crates }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;

// Setup attackers once they spawn in
waitUntil { count (["gang_attack_2"] call JTF_fnc_getWaveGroups) > 0 };

private _gangAttackUnits = ((["gang_attack_2"] call JTF_fnc_getWaveGroups) apply { units _x }) call JTF_fnc_flatten;
[_gangAttackUnits,0.2] call JTF_fnc_revealPlayers;

// Defend Pavlovo
private _defendPavlovoTask =
[	west, "Defend Pavlovo", "There are intruders from the North and East.", "", 
	getMarkerPos "contact_location_marker", "defend_pavlovo", 
	{ count (_this select { alive _x }) == 0 }, _gangAttackUnits,
	{ false }, [],
	{ false }, []		] call JTF_newTask;

{ _x setMarkerAlpha 1; } forEach [ "ambush_north", "ambush_east" ];

["Your map has been updated."] remoteExec ["hint",0];

waitUntil { scriptDone _defendPavlovoTask && scriptDone _getMedicalTask && scriptDone _getRadiosTask };

{ _x setMarkerAlpha 0; } forEach [ "ambush_north", "ambush_east" ];


JTF_pavlovo_defended = true;
publicVariable "JTF_pavlovo_defended";

// Talk to fixer again
private _talkWithFixerAgainTask =
[	west, "Speak with Fixer", "The Fixer has more information about equipment and the movements of the Elektro mafia.", "", 
	getPos the_contact, "talk_to_fixer_again", 
	{ the_contact getVariable ["equipment_convo", false] }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
waitUntil { scriptDone _talkWithFixerAgainTask };

car_1 setVehicleLock "UNLOCKED";
car_2 setVehicleLock "UNLOCKED";

private _zeleno_roadBlocks = [];
private _zeleno_units = [];

{
	_zeleno_roadBlocks pushback _x;
	_x enableSimulationGlobal true;
	_x hideObjectGlobal false;
} forEach ( (entities [[], ["Man"]])  select { _x inArea south_zeleno || _x inArea north_zeleno } );
{
	_zeleno_units pushback _x;
	_x enableSimulationGlobal true;
	_x hideObjectGlobal false;
} forEach ( allUnits select { _x inArea south_zeleno || _x inArea north_zeleno } );

waitUntil { count (["bor_defenders"] call JTF_fnc_getWaveGroups) > 0 &&
			 count (["bor_defenders_2"] call JTF_fnc_getWaveGroups) > 0 };

private _borDefenders = ((["bor_defenders"] call JTF_fnc_getWaveGroups) apply { units _x }) call JTF_fnc_flatten;
private _borDefenders_2 =  ((["bor_defenders_2"] call JTF_fnc_getWaveGroups) apply { units _x }) call JTF_fnc_flatten;

{
	_x hideObjectGlobal true;
	_x enableSimulationGlobal false;
} forEach _borDefenders_2;

// Ambush in Bor
private _ambushInBor =
[	west, "Ambush Delivery", "There will be a lot of equipment and explosives delivered to some Elektro mafia grunts in Bor. High quality military stuff. Stake out the town and ambush them when the delivery arrives.", "", 
	getMarkerPos "weapon_delivery_marker", "ambush_bor", 
	{ !(alive contraband_driver) && count (_this select { alive _x }) == 0 }, _borDefenders + _borDefenders_2,
	{ false }, [],
	{ false }, []		] call JTF_newTask;

_ambushInBor spawn { waitUntil { scriptDone _this }; explosives_truck setVehicleLock "UNLOCKED"; };

// Meet in pogorevka
private _pogorevkaMeeting =
[	west, "Meet with Anatoli", "Anatoli Zykov is a mob boss in the Berezino mafia. He has a compound north of Zelenogorsk. Meet with him to receive further instructions for the war against the Elektro.", "", 
	getPos mob_boss, "pogorevka_meeting", 
	{ mob_boss getVariable ["boss_convo", false] }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;

[mob_boss] call JTF_fnc_initConv;

waitUntil { scriptDone  _pogorevkaMeeting };

"cdf_basemarker" setMarkerAlpha 1;
"safehouse_2" setMarkerAlpha 1;

{
	_x enableSimulationGlobal true;
	_x hideObjectGlobal false;
} forEach ( allUnits select { _x inArea base_infiltrated } );

private _cherno_units = [];

{
	_x enableSimulationGlobal true;
	_x hideObjectGlobal false;
} forEach ( (entities [[], ["Man"]]) select { _x inArea west_cherno || _x inArea north_cherno } );
{
	_cherno_units pushBackUnique _x;	
	_x enableSimulationGlobal true;
	_x hideObjectGlobal false;
} forEach ( allUnits select { _x inArea west_cherno || _x inArea north_cherno } );

private _JTF_chernoProtect = [] spawn {
	while { true } do {
		waitUntil { triggerActivated cherno_trespassing };
		sleep 5;
		if ( alive ammo_1 || alive ammo_2 || alive ammo_3 ) then {
			{
				private _group = _x;
				{
					_group reveal [ _x, 4.0 ];
				} forEach allPlayers;
				[_group] call CBA_fnc_clearWaypoints;
				[_group, getPos russian_dealer, 75,6,0.9,0] call CBA_fnc_taskDefend;
			} forEach _cherno_groups;	
		};
	};
};

sleep 3;

{
	_x enableSimulationGlobal true;
} forEach ( allUnits select { _x inArea cherno_trespassing } );

// Kill elektro mob guys and russian dealer
private _killMob =
[	west, "Kill Mob Heir", "The heir to the Elektro mob is meeting with a Russian arms dealer at the international hotel in Chernogorsk. The city is under heavy watch from CDF troops. Once the ammo depot is destroyed and they are distracted and move towards Balota, enter the city and kill everyone at the meeting in the hotel. There is a good security detail expected, with possible reinforcements so beware.", "", 
	getPos russian_dealer, "kill_mob_boss", 
	{ !(alive russian_dealer) && !(alive elektro_boss) }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;

// Destroy ammo depot
private _ammoDump =
[	west, "Destroy Ammo Depot", "There is an old ammo dump at the east end of the Balota airbase. It is lightly guarded. Sneak up and destroy it with satchel charges to distract CDF forces located in Chernogorsk.", "", 
	getPos ammo_1, "destroy_ammo", 
	{ !(alive ammo_1) && !(alive ammo_2) && !(alive ammo_3) }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;
	
waitUntil { scriptDone _ammoDump };

terminate _JTF_chernoProtect;

// Cleanup Zeleno
{
	deleteVehicle _x;
} forEach ( _zeleno_units + _zeleno_roadBlocks );

private _chern_grps_act = [];

{
	if ( !( (typeOf (vehicle _x)) isKindOf "StaticWeapon" ) ) then {
		if ( !((group _x) in _chern_grps_act) ) then {
			_chern_grps_act pushback (group _x);
			[group _x] call CBA_fnc_clearWaypoints;
			[group _x, getMarkerPos "ammo_warehouse", 150] call CBA_fnc_taskAttack;
		};
	};
} forEach _cherno_units;

private _gangsters = allUnits select { side _x == east && _x inArea cherno_trespassing && _x != russian_dealer && _x != elektro_boss };

waitUntil { triggerActivated cherno_trespassing };

{
	(group _x) setVariable ["Vcm_disabled", false];
} forEach _gangsters;

waitUntil { scriptDone _killMob };

// Destroy ammo depot
private _exfil =
[	west, "Exfiltrate to Pusta", "Mission accomplished! Now exfiltrate everyone to Pusta.", "", 
	getMarkerPos "exfil_marker", "exfiltrate", 
	{ count (allplayers select { _x inArea exfiltration }) == count allPlayers }, [],
	{ false }, [],
	{ false }, []		] call JTF_newTask;

waitUntil { scriptDone _exfil };

JTF_missionEndedSuccess = true;