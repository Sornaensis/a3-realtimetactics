private _briefingIntro = [] call (compile (preprocessFileLineNumbers "briefing\briefingIntroText.sqf"));

waitUntil { !isNull (findDisplay 46) };

sleep 2;

for "_i" from 0 to ((count _briefingIntro) - 1) do {
	(_briefingIntro select _i) params ["_text", "_time"];
	titleText [ _text, "PLAIN", _time, true, true ];
	sleep (_time*10);
};

RTS_briefingComplete = true;