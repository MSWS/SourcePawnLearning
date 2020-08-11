#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =  {
	name = "", 
	author = "MSWS", 
	description = "", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart() {
	RegConsoleCmd("rps", Command_RPS, "Rock, Paper, Scissors!");
}

public Action Command_RPS(int client, int args) {
	
	
	if (args != 1) {
		ReplyToCommand(client, "Please specify rock, paper, or scissors (/rps [choice]).");
		return Plugin_Handled;
	}
	
	char raw[32];
	char choice[9];
	GetCmdArg(1, raw, sizeof(raw));
	
	//char options[3][8] =  {  };
	char options[][] =  { "Rock", "Paper", "Scissors" };
	
	int index = 0;
	
	for (int i = 0; i < 3; i++) {
		if (StrContains(options[i], raw, false) != -1) {
			//choice = options[i]; Can't do this apparently
			int last = 0;
			for (int j = 0; j < 8; j++) {
				choice[j] = options[i][j];
				last = j;
			}
			index = i;
			break;
		}
	}
	
	if (StrEqual(choice, NULL_STRING)) {
		ReplyToCommand(client, "I unfortunately don't know what you chose, please specify rock, paper, or scissors.");
		return Plugin_Handled;
	}
	
	
	ReplyToCommand(client, "You chose %s", choice);
	
	char mChoice[8];
	int c = GetRandomInt(0, 2);
	for (int i = 0; i < 8; i++) {
		mChoice[i] = options[c][i];
	}
	
	ReplyToCommand(client, "I choose... %s", mChoice);
	
	int result = 0;
	
	result = (index == c) ? 0 : (index == 0) ? (c == 1 ? -1:1) : index == 1 ? (c == 2 ? -1:1) : (c == 0 ? -1:1);
	
	ReplyToCommand(client, result == 0 ? "It's a draw!" : result == 1 ? "You win!" : "I win :D");
	
	return Plugin_Handled;
} 