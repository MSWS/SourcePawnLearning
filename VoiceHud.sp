#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required
#pragma semicolon 1

// VoiceannounceEX https://forums.alliedmods.net/showthread.php?t=245384
// DHooks 		   https://forums.alliedmods.net/showthread.php?p=2588686#post2588686

public Plugin myinfo =  {
	name = "VoiceHud", 
	author = "MSWS", 
	description = "View who is talking", 
	version = "1.0", 
	url = ""
};

int g_Voices[MAXPLAYERS];
bool g_huds[MAXPLAYERS];

Handle g_Sync;

// ConVars

ConVar g_VoiceDefault;
ConVar g_RefreshRate;

// Cached

char g_VoiceCached[100];
float g_cRefreshRate;

// Cookies

Handle g_VoiceCookie;

public void OnPluginStart() {
	g_VoiceDefault = CreateConVar("voicehud_enable_default", "false", "If true all new players will automatically have the voicehud enabled");
	g_VoiceCookie = RegClientCookie("voicehud_enabled", "Whether or not the voicehud is anebld", CookieAccess_Protected);
	g_RefreshRate = CreateConVar("voicehud_refreshrate", "1.0", "How quickly the HUD refreshes.", .hasMin = true, .min = 1.0);
	
	g_Sync = CreateHudSynchronizer();
	g_cRefreshRate = g_RefreshRate.FloatValue;
	
	GetConVarString(g_VoiceDefault, g_VoiceCached, sizeof(g_VoiceCached));
	
	CreateTimer(g_cRefreshRate, Timer_SendVoiceHud, .flags = TIMER_REPEAT);
	RegConsoleCmd("sm_voicehud", Command_VoiceHud);
}

public void OnClientCookiesCached(int client) {
	char value[32];
	GetClientCookie(client, g_VoiceCookie, value, sizeof(value));
	
	if (StrEqual(value, NULL_STRING)) {
		for (int i = 0; i < 100; i++) {
			if (g_VoiceCached[i] == 0)
				break;
			value[i] = g_VoiceCached[i];
		}
	}
	bool v = StrEqual(value, "true", false);
	g_huds[client] = v;
}

public Action Command_VoiceHud(int client, int args) {
	bool t = !g_huds[client];
	g_huds[client] = t;
	ReplyToCommand(client, "You %s your voicehud.", t ? "enabled":"disabled");
	SetClientCookie(client, g_VoiceCookie, t ? "true":"false");
	return Plugin_Handled;
}

/**
* Formats and sends a voicehud to all clients that have voicehud enabled
*/
public Action Timer_SendVoiceHud(Handle timer) {
	int ids[MAXPLAYERS][32];
	
	for (int i = 0; i < MAXPLAYERS; i++) {
		int val = g_Voices[i];
		if (val == 0)
			continue;
		ids[i][0] = i;
		ids[i][1] = val;
	}
	
	SortCustom2D(ids, 32, SortByValue);
	
	int index = 0;
	int line = 0;
	int size = ByteCountToCells(255 * 10);
	
	char[] msg = new char[size];
	bool valid;
	
	for (int i = 0; i < MAXPLAYERS; i++) {
		int cl = ids[i][0];
		if (cl == 0)
			continue;
		if (!IsClientInGame(cl))
			continue;
		char name[32];
		GetClientName(cl, name, sizeof(name));
		int val = ids[i][1];
		if (val == 0 || GetTime() - val > 60)
			break;
		if (index + 2 >= size)
			break;
		if (i > 0 && valid)
			msg[index++] = '\n';
		valid = false;
		int nPos = 0;
		for (int ind = index; ind < size; ind++) {
			if (name[nPos] == 0)
				break;
			
			msg[index + ind] = name[nPos];
			nPos++;
		}
		index += nPos;
		
		if (index + 1 >= size)
			break;
		msg[index++] = ' ';
		index = AppendTime(msg, val, index, size);
	}
	
	
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (!IsClientInGame(i))
			continue;
		PrintHintText(i, msg);
	}
	return Plugin_Continue;
}

/**
* Appends "(started/ended) x (seconds/minutes/hours) ago"
*/
int AppendTime(char[] array, int time, int index, int size) {
	if (index >= size)
		return -1;
	char prefix[8];
	if (time < 0) {
		char bef[] = "started ";
		for (int i = 0; i < sizeof(prefix); i++) {
			prefix[i] = bef[i];
		}
	} else {
		char bef[] = "stopped ";
		for (int i = 0; i < sizeof(prefix); i++) {
			prefix[i] = bef[i];
		}
	}
	
	int sSize = ByteCountToCells(255);
	char[] suffix = new char[sSize];
	
	FormatCustomTime(suffix, GetTime() - IntAbs(time), sSize);
	
	for (int i = 0; i < sizeof(prefix); i++) {
		array[i + index] = prefix[i];
		if (i + index + 1 > size)
			break;
	}
	index += sizeof(prefix);
	
	int total;
	
	for (int i = 0; i < sSize; i++) {
		if (!suffix[i])
			return index + i;
		array[i + index] = suffix[i];
		total++;
		if (i + index + 1 > size)
			break;
	}
	
	return index + total;
}

/**
* Inserts "x (seconds/minutes/hours) ago" into the buffer
*/
void FormatCustomTime(char[] buffer, int seconds, int size) {
	if (seconds <= 60) {
		Format(buffer, size, "%d second%s ago", seconds, seconds == 1 ? "":"s");
	} else if (seconds <= 60 * 60) {
		Format(buffer, size, "%.2f minute%s ago", seconds / 60.0, seconds / 60.0 == 1 ? "":"s");
	} else if (seconds <= 60 * 60 * 60) {
		Format(buffer, size, "%.2f hour%s ago", seconds / 60.0 / 60.0, seconds / 60.0 * 60.0 ? "":"s");
	} else {
		Format(buffer, size, "a while ago");
	}
}

int SortByValue(int[] x, int[] y, int[][] array, Handle data) {
	return x[1] == y[1] ? 0 : x[1] > y[1] ? 1 : -1;
}

stock int IntAbs(int val) {
	return val < 0 ? -val : val;
}

public void OnClientDisconnect(int client) {
	g_Voices[client] = 0;
}

public void OnClientSpeakingEx(int client) {
	if (g_Voices[client] < 0)
		return;
	char message[128];
	Format(message, sizeof(message), "[VH] %d: %L started speaking", GetTime(), client);
	PrintToConsoleAll(message);
	g_Voices[client] = -GetTime();
}

public void PrintToConsoleAll(const char[] msg) {
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (!IsClientInGame(i) || !g_huds[i])
			continue;
		PrintToConsole(i, msg);
	}
}

public void OnClientSpeakingEnd(int client) {
	g_Voices[client] = GetTime();
	char message[128];
	Format(message, sizeof(message), "[VH] %d: %L stopped speaking", GetTime(), client);
	PrintToConsoleAll(message);
}