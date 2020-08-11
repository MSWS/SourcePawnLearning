#define DEBUG

#define PLUGIN_AUTHOR "MSWS"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =  {
	name = "Death", 
	author = PLUGIN_AUTHOR, 
	description = "Teleport back to where you die", 
	version = PLUGIN_VERSION, 
	url = ""
};


float g_Locations[MAXPLAYERS][32];

public void OnPluginStart() {
	RegConsoleCmd("sm_death", Command_Death);
	HookEvent("player_death", DeathEvent, EventHookMode_Post);
}

public void OnClientDisconnect(int client) {
	ResetLocation(client);
}

public Action Command_Death(int client, int args) {
	if (!HasValidLocation(client)) {
		ReplyToCommand(client, "You have not died yet!");
		return Plugin_Handled;
	}
	
	float loc[3];
	GetLocation(client, loc);
	
	TeleportEntity(client, loc, NULL_VECTOR, NULL_VECTOR);
	ReplyToCommand(client, "You have been teleported");
	ResetLocation(client);
	return Plugin_Handled;
}

public void DeathEvent(Event event, const char[] name, bool dontBroadcast) {
	int id = event.GetInt("userid");
	int client = GetClientOfUserId(id);
	float origin[3];
	GetClientAbsOrigin(client, origin);
	SetLocation(client, origin);
}

void SetLocation(int client, float loc[3]) {
	for (int i = 0; i < 3; i++) {
		g_Locations[client][i] = loc[i];
	}
}

void GetLocation(int client, float store[3]) {
	for (int i = 0; i < 3; i++) {
		store[i] = g_Locations[client][i];
	}
}

void ResetLocation(int client) {
	float loc[] =  { 0.0, 0.0, 0.0 };
	SetLocation(client, loc);
}

bool HasValidLocation(int client) {
	float loc[3];
	GetLocation(client, loc);
	for (int i = 0; i < 3; i++) {
		if (loc[i] != 0)
			return true;
	}
	return false;
} 