#include "\z\ace\addons\spectator\script_component.hpp"

#define Q(x) QUOTE(x)

[ "rts\ace_spectator_overrides",
	[Q(RTS_fnc_handleKeyDown),
	 Q(RTS_fnc_ui),
	 Q(RTS_fnc_cam_prepareTarget),
	 Q(RTS_fnc_ui_handleMapClick),
	 Q(RTS_fnc_ui_handleMouseButtonUp),
	 Q(RTS_fnc_ui_handleMouseButtonDown),
	 Q(RTS_fnc_ui_handleMouseButtonDblClick),
	 Q(RTS_fnc_ui_handleKeyUp)]
] call RTS_setupFunction;