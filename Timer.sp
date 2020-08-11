#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR "MSWS"
#define PLUGIN_VERSION "1.0"


#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =  {
	name = "Countdown", 
	author = PLUGIN_AUTHOR, 
	description = "Simple countdown timer", 
	version = PLUGIN_VERSION, 
	url = ""
};

ConVar g_defaultTimer;
Handle g_hudSync;

int g_cachedTime; // Cache the ConVar
int g_timers[MAXPLAYERS];

public void OnPluginStart() {
	g_defaultTimer = CreateConVar("default_timer", "10", "The default time that a timer starts at if unspecified", .hasMin = true, .min = 1.0);
	g_cachedTime = g_defaultTimer.IntValue;
	
	g_defaultTimer.AddChangeHook(OnDefaultTimeChange);
	
	g_hudSync = CreateHudSynchronizer();
	
	RegAdminCmd("timer", Command_Timer, ADMFLAG_VOTE);
}

public void OnDefaultTimeChange(ConVar convar, char[] old, char[] current) {
	if (StringToFloat(current) == 0)
		convar.IntValue = 10;
	g_cachedTime = convar.IntValue;
}


public Action Command_Timer(int client, int args) {
	if (g_timers[client]) {
		ReplyToCommand(client, "You already have a timer active.");
		return Plugin_Handled;
	}
	
	int time = g_cachedTime;
	if (args == 1) {
		char str[32];
		GetCmdArg(1, str, sizeof(str));
		
		time = (time = StringToInt(str)) == 0 ? g_cachedTime : time;
	}
	g_timers[client] = time;
	
	CreateTimer(1.0, Countdown, client, TIMER_REPEAT);
	ReplyToCommand(client, "Successfully started timer.");
	char name[32];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("%s has started a timer for %d second%s.", name, time, time == 1 ? "" : "s");
	return Plugin_Handled;
}

public void OnClientDisconnect(int client) {
	g_timers[client] = 0;
}

public Action Countdown(Handle timer, int client) {
	if (g_timers[client] <= 0) {
		PrintToChatAll("Go!");
		return Plugin_Stop;
	}
	
	SetHudTextParams(-1.0, 0.53, 1.0, 255, 0, 0, 255);
	ShowSyncHudText(client, g_hudSync, "%d seconds left...", g_timers[client]);
	if (g_timers[client] % 5 == 0)
		PrintToChatAll("%d seconds left...", g_timers[client]);
	
	g_timers[client]--;
	
	return Plugin_Continue;
} 