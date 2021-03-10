#include "RTS_defines.hpp"

waitUntil {!isNull player};
waitUntil {player == player};

setGroupIconsVisible [true,false];

// Non Commander Stuff
if ( !(call RTS_fnc_isCommander) && RTS_Spectator ) then {
	waitUntil { !(isNull player) && isPlayer player };
	waitUntil { time > 1 };
	JTF_player_loadout = getUnitLoadout player;
	
	JTF_respawn_h = {
		player removeAllEventHandlers "Killed";
		player removeAllEventHandlers "Respawn";
		player setUnitLoadout JTF_player_loadout;
		player setVariable [ "JTF_playerIsDead", true, true];
		JTF_playerDeathHandler = player addEventHandler ["Killed", { 
			[allPlayers select { !(_x getVariable ["JTF_playerIsDead", false]) }, [player]] call ace_spectator_fnc_updateUnits; 
			JTF_playerIsDead = true; [true] call ace_spectator_fnc_setSpectator; 
		}];
		JTF_player_respawnHandler = player addEventHandler ["respawn", JTF_respawn_h ];
	};
	
	JTF_player_respawnHandler = player addEventHandler ["respawn", JTF_respawn_h ];
	
	// Spectator stuff 
	JTF_playerIsDead = false;
	JTF_playerDeathHandler = player addEventHandler ["Killed", { 
		[allPlayers select { !(_x getVariable ["JTF_playerIsDead", false]) }, [player]] call ace_spectator_fnc_updateUnits; 
		[true] call ace_spectator_fnc_setSpectator; 
	}];
	[[west], [east,civilian,resistance]] call ace_spectator_fnc_updateSides;
	
	addMissionEventHandler [ "Draw3d",
	{
		if ( player in ([] call ace_spectator_fnc_players) ) then {
			[1,nil,-2] call ace_spectator_fnc_setCameraAttributes;
			[ allPlayers select { !(_x getVariable ["JTF_playerIsDead", false]) }, [player] ] call ace_spectator_fnc_updateUnits;
		};
	}];
	
};