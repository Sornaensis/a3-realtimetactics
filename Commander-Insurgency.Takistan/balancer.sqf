if ( !isServer ) exitWith {};

SOCOM_HC_RR = [];
SOCOM_fnc_nextHeadless = {
	private _headlessClients = (entities "HeadlessClient_F") - SOCOM_HC_RR;
	
	if ( count _headlessClients == 0 ) then {
		_headlessClients = entities "HeadlessClient_F";
		SOCOM_HC_RR = [];
	};
	
	private _hc = _headlessClients # 0;
	SOCOM_HC_RR pushback _hc;
	
	_hc
};

SOCOM_HEADLESS_BALANCER = [] spawn {
	
	while { true } do {
		{
			private _grp = _x;
			if ( _grp getVariable ["SOCOM_HEADLESS_TOGGLE", false] ) then {
				private _hc = call SOCOM_fnc_nextHeadless;
				diag_log (format ["Transferring %1 to headless client", _grp]);
				_grp setVariable ["SOCOM_HEADLESS_TOGGLE", false, true];
				_grp setGroupOwner (owner _hc);
			};
		} forEach allGroups;
	};

};