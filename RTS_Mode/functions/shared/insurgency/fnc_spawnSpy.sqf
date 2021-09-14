params ["_pos"];


private _setup = selectRandom INS_spySetups;
_setup params ["_type","_loadout"];

_soldier = (createGroup east) createUnit [_type, _pos, [], 0, "NONE"];
_soldier setUnitLoadout _loadout;

_soldier setCaptive true;
_soldier disableAI "TARGET";
_soldier disableAI "AUTOTARGET";
_soldier disableAI "RADIOPROTOCOL";
_soldier disableAI "WEAPONAIM";
_soldier disableAI "AUTOCOMBAT";

_grp = group _soldier;
_grp setVariable ["RTS_setup", [_grp, "Spy", grpnull, "\A3\ui_f\data\map\markers\nato\o_support.paa", "o_support"],true];

INS_spies pushback _soldier;
publicVariable "INS_spies";

_soldier