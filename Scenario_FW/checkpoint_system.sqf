// No initial checkpoint

JTF_checkPoint = "NONE";

JTF_checkPointLogic = call compile preprocessFileLineNumbers "checkpoints.sqf";

JTF_checkpoint_respawn = {
	params ["_checkpoint_location","_code"];
	
	if ( hasInterface && player getVariable ["JTF_playerIsDead", false] ) then {
		player setVariable ["JTF_playerIsDead", false, true];
		private _spawnpos = _checkpoint_location findEmptyPosition [1.5,20,"Man"];
		player setPosATL _spawnpos;
		[false] call ace_spectator_fnc_setSpectator;
		call _code;
	};
	
};


JTF_checkpointLoop = [] spawn {
	"checkpoint_marker" setMarkerAlpha 0;
	
	private _chIdx = 0;
	while { _chIdx < count JTF_checkPointLogic } do {
		(JTF_checkPointLogic select _chIdx) params ["_condition","_location","_waveDuration","_code"];
		
		if ( !(_location isEqualTo [0,0,0]) ) then {
			
			_chIdx = _chIdx + 1;
			waitUntil { call _condition };
			
			"checkpoint_marker" setMarkerPos _location;
			"checkpoint_marker" setMarkerAlpha 1;
						
			if ( _chIdx < count JTF_checkPointLogic ) then {
				_condition = (JTF_checkPointLogic select _chIdx) select 0;
			} else {
				_condition = { false };
			};
			
			while { !(call _condition) } do {
				[[_location,_code],JTF_checkpoint_respawn] remoteExec [ "call", 0 ];
				sleep _waveDuration;
			};
		} else {
			_chIdx = _chIdx + 1;
			"checkpoint_marker" setMarkerAlpha 0;
		};
		sleep 4;
	};
	
	
	
};