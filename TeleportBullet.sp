#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =  {
	name = "TPBullet", 
	author = "MSWS", 
	description = "Teleport where you shoot", 
	version = "1.0", 
	url = ""
};

int g_Bullets[MAXPLAYERS];

public void OnPluginStart() {
	RegAdminCmd("sm_setbullets", Command_SetBullets, ADMFLAG_CHEATS);
	HookEvent("bullet_impact", OnBulletImpact);
	LoadTranslations("common.phrases.txt");
}

public void OnBulletImpact(Event event, const char[] name, bool dontBroadcast) {
	int id = event.GetInt("userid");
	int client = GetClientOfUserId(id);
	if (!decBullet(client))
		return;
	float pos[3], off[3];
	pos[0] = event.GetFloat("x");
	pos[1] = event.GetFloat("y");
	pos[2] = event.GetFloat("z");
	
	GetClientAbsOrigin(client, off);
	pos[0] += pos[0] > off[0] ? -25 : 25;
	pos[1] += pos[1] > off[1] ? -25 : 25;
	pos[2] += pos[2] > off[2] ? -25 : 10;
	
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	PrintToChat(client, hasBullets(client) ? "You have %d bullet%s remaining":"You've used up all your bullets.", getBullets(client), getBullets(client) == 1 ? "":"s");
}

public void OnClientDisconnect(int client){
	setBullets(client, 0);
}

public Action Command_SetBullets(int client, int args) {
	int targets[MAXPLAYERS];
	int bullets;
	
	targets[0] = client;
	
	bool ml;
	char name[32];
	GetClientName(client, name, sizeof(name));
	
	if (args == 2) {
		char target[32];
		GetCmdArg(1, target, sizeof(target));
		int size = ProcessTargetString(target, client, targets, MAXPLAYERS, COMMAND_FILTER_ALIVE, name, sizeof(name), ml);
		if (size <= 0) {
			ReplyToTargetError(client, size);
			return Plugin_Handled;
		}
	}
	
	if (args == 0) {
		ReplyToCommand(client, "[SM] Usage: sm_setbullets <#userid|name> [amount]");
		return Plugin_Handled;
	}
	
	char amountString[32];
	GetCmdArg(args, amountString, sizeof(amountString));
	bullets = StringToInt(amountString);
	if (bullets == 0) {
		ReplyToCommand(client, "Unknown bullet amount!");
		return Plugin_Handled;
	}
	
	for (int i = 0; i < MAXPLAYERS; i++) {
		if (targets[i] == 0)
			continue;
		setBullets(targets[i], bullets);
		LogAction(client, targets[i], "%L Set teleport bullets of %L to %d", client, targets[i], bullets);
	}
	
	PrintToServer("Name: ", name);
	
	ReplyToCommand(client, "Successfully set %s's bullets to %d", name, bullets);
	ShowActivity2(client, "[SM] ", "Set %s's bullets to %d", name, bullets);
	
	return Plugin_Handled;
}

void setBullets(int client, int bullets) {
	g_Bullets[client] = bullets;
}

int getBullets(int client) {
	return g_Bullets[client];
}

bool hasBullets(int client) {
	return getBullets(client) > 0;
}

bool decBullet(int client) {
	if (!hasBullets(client))
		return false;
	addBullets(client, -1);
	return true;
}

void addBullets(int client, int bullets) {
	setBullets(client, getBullets(client) + bullets);
} 