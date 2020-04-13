// Need to draw 2d orders as well

[] spawn {
	while { true } do {
		{
			private _group = _x;
			private _icon = _group getVariable ["icon",""];
			private _color = RTS_sideColor;
			
			if ( _group in RTS_commandingGroups ) then {	
				private _units = units _group;
				private _living = count ((units _group) select { alive _x });
				private _maxmorale = (count _units) / (_group getVariable ["initial_strength", 1]) * 100;
				private _morale = _group getVariable ["morale", 0];
				if ( _living < (_group getVariable ["initial_strength",-1]) ) then {
					_unitcolor = RTS_casualtyColor;
					if ( _morale < 0 ) then {
							_unitcolor = RTS_brokenColor;
					};
				};
			};
			
			[-1, 
			{
				params ["_group", "_icon", "_color"	];
				clearGroupIcons _group;
				if ( _icon != "" && (side (leader _group)) == (side player) ) then {
					_group addGroupIcon [ _icon, [0,0] ];
					_group setGroupIconParams [ _color, "", 1, true ];
				};
			}, [_group, _icon, _color] ] call CBA_fnc_globalExecute;
		} forEach allGroups;
		
		sleep 2;
	};
};