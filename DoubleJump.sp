#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =  {
	name = "DoubleJump", 
	author = "MSWS", 
	description = "Double Jump!", 
	version = "1.0", 
	url = ""
};

int g_Jumps[MAXPLAYERS];
int g_MaxJumps[MAXPLAYERS];

Handle sync = CreateHudSynchronizer();

// ConVars

ConVar g_defaultJumps, g_jumpPower;

// Cache

int g_c_defaultJumps;
float g_c_jumpPower;

public void OnPluginStart() {
	LoadTranslations("common.phrases.txt");
	
	RegAdminCmd("sm_setjumps", Command_SetJumps, ADMFLAG_CHEATS);
	RegAdminCmd("sm_sj", Command_SetJumps, ADMFLAG_CHEATS);
	HookEvent("weapon_fire", JumpEvent);
	HookEvent("player_jump", ResetJumpEvent);
	
	g_defaultJumps = CreateConVar("default_jumps", "0", "The default amount of double jumps a player has");
	g_jumpPower = CreateConVar("jump_power", "350.0", "The power of a jump");
	g_c_defaultJumps = g_defaultJumps.IntValue;
	g_c_jumpPower = g_jumpPower.FloatValue;
	
	g_jumpPower.AddChangeHook();
	
	for (int i = 0; i < MAXPLAYERS; i++) {
		g_MaxJumps[i] = g_c_defaultJumps;
		g_Jumps[i] = g_c_defaultJumps;
	}
}

public void OnJumpPowerChange(ConVar con, char[] old, char[] n) {
	g_c_jumpPower = g_jumpPower.IntValue;
}

public Action Command_SetJumps(int client, int args) {
	int clients[MAXPLAYERS];
	char name[32];
	GetClientName(client, name, sizeof(name));
	clients[0] = client;
	
	int amo;
	
	if (args == 0) {
		ReplyToCommand(client, "[SM] Usage: sm_setjumps <#userid|name> [jumps]");
		return Plugin_Handled;
	}
	
	if (args == 1 && client == 0) {
		ReplyToCommand(client, "You must specify a player and amount of jumps");
		return Plugin_Handled;
	}
	
	if (args == 2) {
		char selection[32];
		GetCmdArg(1, selection, sizeof(selection));
		bool unused;
		int size = ProcessTargetString(selection, client, clients, MAXPLAYERS, COMMAND_FILTER_ALIVE, name, sizeof(name), unused);
		if (size <= 0) {
			ReplyToTargetError(client, size);
			return Plugin_Handled;
		}
	}
	
	char astr[32];
	GetCmdArg(args, astr, sizeof(astr));
	amo = StringToInt(astr);
	
	for (int i = 0; i < MAXPLAYERS; i++) {
		if (clients[i] == 0)
			continue;
		g_Jumps[clients[i]] = amo;
		g_MaxJumps[clients[i]] = amo;
		LogAction(client, clients[i], "%L set double jumps of %L to %d", client, clients[i], amo);
	}
	
	ShowActivity2(client, "[SM] ", "%N set double jumps of %s to %d", client, name, amo);
	return Plugin_Handled;
}

public void OnClientConnected(int client) {
	g_MaxJumps[client] = g_c_defaultJumps;
	g_Jumps[client] = g_MaxJumps[client];
}

public void OnClientDisconnect(int client) {
	g_Jumps[client] = 0;
	g_MaxJumps[client] = 0;
}

public Action JumpEvent(Event event, const char[] name, bool dontHandle) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_Jumps[client] <= 0)
		return Plugin_Handled;
	if (GetEntityFlags(client) & FL_ONGROUND)
		return Plugin_Handled;
	g_Jumps[client]--;
	
	char name[32];
	GetClientName(client, name, sizeof(name));
	
	float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	vel[2] = g_c_jumpPower;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	
	if (g_Jumps[client] == 0) {
		PrintHintText(client, "You've used up all your jumps\n  Land to replenish them");
		return Plugin_Continue;
	}
	
	PrintHintText(client, g_Jumps[client] == g_MaxJumps[client] - 1 ? "You have %d/%d jump%s remaining." : "%d/%d", g_Jumps[client], g_MaxJumps[client], g_Jumps[client] == 1 ? "":"s");
	return Plugin_Continue;
}

public Action ResetJumpEvent(Event event, const char[] name, bool dontHandle) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_Jumps[client] = g_MaxJumps[client];
} 