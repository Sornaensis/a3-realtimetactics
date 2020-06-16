
JTF_conversation_map = call compile preprocessFileLineNumbers "conversation_map.sqf";

if ( isServer ) then {
	
	JTF_characters = [];

	{
		_x params ["_character"];
		JTF_characters pushback _character;
	} forEach JTF_conversation_map;
	
	[] spawn {
		while { true } do {	
			{
				private _target = _x;
				if ( !(_target getVariable ["conversing", false]) && (_target getVariable [ "starting_conversing", false ]) ) then {
					_target setVariable [ "conversing", true ];	
					[_target] spawn {
						params ["_target"];
						private _index_1 = _target getVariable "conversation_index_1";
						private _index_2 = _target getVariable "conversation_index_2";
						private _conversation = ((_target getVariable "conversation_table") select _index_1) select _index_2;
			
						_conversation params [ "_title", "_variable", "_condition", "_sentences" ]; 
						[[_target,((name _target) splitString " ") select 0,_title,_variable,_sentences],JTF_fnc_renderSpeech] remoteExec [ "spawn", 0 ];
						waitUntil { !(_target getVariable ["starting_conversing", false]) };
						_target doWatch objNull;
						if ( _variable != "" ) then {
							_target setVariable [_variable, true, true ];
						};
						_target setVariable ["conversing", false];
						[_target] call JTF_fnc_advanceConv;
					};
				};
			} forEach JTF_characters;
			sleep 1;
		};
	};
};

JTF_fnc_renderSpeech = {
	if ( hasInterface ) then {
		params ["_target","_name","_title","_variable","_sentences"];
		for "_i" from 0 to ((count _sentences)-1) do {
			private _text = _sentences select _i;
			private _time = ((count (_text splitString " ")) * 0.5) / 10;
			
			private _speech = format [ "%1: %2", _name, _text ];
			if ( (player distance2d _target) < 10.2 ) then {
				titleText [ _speech, "PLAIN", _time, true, true ];
			};
			if ( isNil "JTF_skipConvo" ) then {
				sleep (_time*10);
			};
		};
		_target setVariable ["starting_conversing", false, true];
	};
};

JTF_fnc_advanceConv = {
	params ["_character"];
	
	{
		_x params ["_char","_convs"];
		
		if ( _char == _character ) then {
			
			private _index_1 = _char getVariable "conversation_index_1";
			private _index_2 = _char getVariable "conversation_index_2";
			private _convos  = _char getVariable "conversation_table";		
			
			private _index_2_max = (count (_convos select _index_1)) - 1;
			private _index_1_max = (count _convos);
			
			if ( _index_2 == _index_2_max ) then {
				_index_2 = 0;
				_index_1 = _index_1 + 1;
			} else {
				_index_2 = _index_2 + 1;
			};
			
			if ( _index_1 == _index_1_max ) exitWith {};
			
			_char setVariable [ "conversation_index_1", _index_1 ];
			_char setVariable [ "conversation_index_2", _index_2 ];

			private _convo = (_convos select _index_1) select _index_2;
			
			_convo params [ "_title", "_variable", "_condition", "_sentences" ];
					
			[_char,	[
				format [_title, name _char ],
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					_target lookAt player;
					_target setVariable ["starting_conversing", true, true];
					[_target,_actionId] remoteExecCall ["removeAction", 0];
				},
				nil,
				1.5,
				true,
				true,
				"",
				"!(_target getVariable ['starting_conversing', false]) && " + "(" + _condition + ")", // _target, _this, _originalTarget
				3.1,
				false,
				"",
				""
			]] remoteExecCall ["addAction", 0];
			
		};
		
	} forEach JTF_conversation_map;
};

JTF_fnc_initConv = {
	params ["_character"];
	
	{
		_x params ["_char","_convs"];
		
		if ( _char == _character ) then {
		
			_char setVariable [ "conversation_index_1", 0 ];
			_char setVariable [ "conversation_index_2", 0 ];
			_char setVariable [ "conversation_table", _convs ];
			
			private _convo = (_convs select 0) select 0;
			
			_convo params [ "_title", "_variable", "_condition", "_sentences" ];
			
			[_char,	[
				format [_title, name _char ],
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					_target lookAt player;
					_target setVariable ["starting_conversing", true, true];
					[_target,_actionId] remoteExecCall ["removeAction", 0];
				},
				nil,
				1.5,
				true,
				true,
				"",
				"!(_target getVariable ['starting_conversing', false]) && " + "(" + _condition + ")", // _target, _this, _originalTarget
				3.1,
				false,
				"",
				""
			]] remoteExecCall ["addAction", 0];
			
		};
		
	} forEach JTF_conversation_map;
	
};