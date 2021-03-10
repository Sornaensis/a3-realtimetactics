#include "../RTS_Mission_Defines.hpp"

#define RTS_Greenfor_Enemy east
#define RTS_Greenfor_Green west
#define RTS_Greenfor_EnemyColor [1,0.25,0.25,1]
#define RTS_Greenfor_GreenColor [0.25,0.25,1,1]

#ifndef RTS_SingleCommander
	#define RTS_SingleCommander false
#endif

#ifndef RTS_Spectator
	#define RTS_Spectator false
#endif

#ifndef RTS_skipBriefing
	#define RTS_skipBriefing false
#endif

#ifndef RTS_timeLimit
	#define RTS_timeLimit 0
#endif

#ifndef RTS_debug
	#define RTS_debug false
#endif

#ifndef RTS_godseye
	#define RTS_godseye false
#endif

#ifndef RTS_friendlySkillModifier
	#define RTS_friendlySkillModifier 0
#endif

#ifndef RTS_enemySkillModifier
	#define RTS_enemySkillModifier 0
#endif

#ifndef RTS_skipDeployment
	#define RTS_skipDeployment false
#endif