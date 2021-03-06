// Situation report
player createDiaryRecord ["Diary", ["Mission Overview", "There is a meeting scheduled west of Zelenogorsk between representatives of your employers and another mob organization based out of Elektrozavodsk. You were informed last minute due to a courier missing a dead drop delivery. Because of heightened alert from the CDF stationed throughout the area, you are laying low and are underprepared. Your immediate goal is to arm yourselves with whatever is available at the safe house, and check in with your handler who is stationed there."]];
player createDiaryRecord ["Diary", ["Your Background","You are members of a mafia outfit based in Berezino, a Chernarussian outfit. You are mid level enforcers being paid to protect their flow of contraband throughout eastern Chernarus and deal with rival gangs."]];
player createDiaryRecord ["Diary", ["Historical Background", "During the fall of communism and the break up of the USSR, Chernarus was one of the first countries to secede and ratify their own constitution, forming the Republic of Chernarus. Despite the forward looking optimisim it enshrined, ethnic and internal regional conflicts quickly boiled over in the mid 1990s with a Russian nationalist movement in the northeast of the country declaring itself a separate state and attempting to remove all non ethnic russians from their claimed borders. International intervention assisting the Chernarussian defense forces managed to squash the movement and halt the genocide, with the territory being retaken within a year and the leaders imprisoned or killed in the fighting. The conflict brought large instability to the surrounding countryside in eastern Chernarus, leaving many working class Chernarussians displaced or unemployed. In the immediate years following the war local crime skyrocketed, with organized crime elements focused on lucrative weapons and drug trafficking carving out fiefdoms in the area. The Chernarus Defense Forces maintain a heavy presence in the region, often inflaming tensions with the local population who see them as western backed invaders and disruptors."]];

JTF_ratingLoop = []  spawn {
	while { true } do {
		if ( rating player < 0 ) then {
			player addRating ( -1 * ( rating player ) );
		};
		sleep 5;
	};
};

if ( leader (group player) == player ) then {
	
	player addAction
			[
				"Start Mission",
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					JTF_mission_started = true;
					publicVariable "JTF_mission_started";
					player removeAction _actionId;
				},
				nil,
				1.5,
				true,
				true,
				"",
				"true", // _target, _this, _originalTarget
				1,
				false,
				"",
				""
			];

};