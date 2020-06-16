// Map of conversations for all NPC

[
	[safehouse_contact,
	
	[
		[
			    ["Talk to %1", "intro_conversation", "true"
			  , [ "Hey, you guys are late.", 
		          "Listen up. We sent out some guys into the forest to do a little recon, since last night.",
		          "This whole thing is a bit hush hush but expect some trouble.",
		          "We're doing a bit of bartering with some of those Elektro losers, that's all you need to know.",
		          "Meeting place is a farm out west of Zelenogorsk.",
		          "We need more security from a distance; don't need anyone getting all jumpy on us ok?",
		          "There are some weapons around back; go load up and then catch up with the scouting team.", 
		          "They'll fill you in on the rest."
		        ]]
		      , ["Talk to %1", "", "true"
		      , [ "We don't have all day here, hurry up!" ]]
		]
	]]
	
,   [the_contact,
	
	[
		[
			    ["Talk to %1", "fixer_intro", "triggerActivated SECURED_2"
			  , [ "Whoa, whoa, whoa, what's all this now??", 
		          "Ah, hm. Attacked, right?", 
		          "They started a war?", 
		          "Can't say I'm surprised, really... Hm.." 
		        ]]
		      , ["Ask about Equipment", "fixer_convo", "true"
		      , [ "Right, sure, you probably need a lot of stuff..",
				  "Okay, there is a stash of radios here in the village, down the street.",
				  "I also have some medical supplies stashed behind the church.",
				  "I don't have any bombs or fun toys laying around however-- *BUZZER BEEPS*",
				  "Wha-? Looks like someone tripped my alarms.",
				  "Probably coming after me I expect. Looks like no more than five or six troublemakers.",
				  "My alarms are set to the north and east of the village, so they'll be coming from there."]]
			  , ["Talk to %1", "equipment_convo", "!(isNil 'JTF_pavlovo_defended')"
		      , [ "These men were very well equipped. Interesting..",
		      	  "Stuff you might very well have seen during the insurgency.",
		      	  "Anyhow then, I just got off the radio: it looks like I have information for you, but not much else.",
		      	  "There will be a sizeable shipment of contraband-- explosives, and soldier's equipment-- delivered to Bor, just over the hills.",
		      	  "To some Elektro grunts, that is.",
		      	  "It looks like preparation for something even bigger.",
		      	  "I suggest you go and take it from them. You all look well armed enough. A small group of their mercenaries are in the town.",
		      	  "There are two cars in this village you can borrow.",
		      	  "After that, make your way to Anatoli Zykov's place, up north of Zelenogorsk. He has some plan cooked up already.",
				  "Oh, and avoid large towns, such as Zelenogorsk; the military are on high alert."		      	  
				  ]]
		]
	]]

,   [mob_boss,
	
	[
		[
			    ["Talk to %1", "boss_convo", "true"
			  , [ "This is a fucking disaster!",
				  "We lost a shitload of product because some messenger got himself killed!",
				  "They've already made a move on our turf in Cherno. Had all of our depots there raided by the military.",
				  "But we're gonna fuck them right back.",
				  "The heir of the Elektro family is going to have a very public meeting with a Russian arms dealer.",
				  "They'll be at the international hotel in the center of Cherno.",
				  "They have the local garrison on their payroll, but we have more cunning.",
				  "So here's how this is going to go down:",
				  "There is a big garrison sitting around Cherno, and they think that's going to protect them.",
				  "Down the street is a large base, at Balota.",
				  "You're gonna take these explosives you intercepted and destroy the old ammo depot at the east end of the base.",
				  "That should give a good distraction for the troops at Cherno, and when they move out...",
				  "You're gonna go and kill every one of those motherfuckers.",
				  "There are some suppressed guns in the big truck outside. Now get going."
		        ]]
		]
	]]

]