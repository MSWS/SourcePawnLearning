#include <sourcemod>
#include <sdktools>
#include <smlib>

public Plugin myinfo = {
	name = "Chicken Plugin",
	author = "MSWS",
	description = "Easily manage chickens!",
	version = "1.0",
	url = "http://msws.xyz"
};

public OnPluginStart(){
	RegAdminCmd("sm_chicken", Command_Chicken, ADMFLAG_SLAY);
	LoadTranslations("common.phrases.txt");
}

public Action Command_Chicken(int client, int args) {
	int amo = 1;
	PrintToChat(client, "\x011\x022\x033\x044\x055\x066\x077\x088\x099\x0AA\x0BB\x0CC\x0DD\x0EE\x0FF");

	if(args > 0) {
		char amoStr[32];
		GetCmdArg(args, amoStr, sizeof(amoStr));
		
		amo = (amo=StringToInt(amoStr)) == 0 ? 1 : amo;
		
		if(args == 1 && amo == 1) {
			int[] clients = new int[MaxClients];
			char arg[32], name[32];
			GetCmdArg(1, arg, sizeof(arg));
			bool ml;
			int size;
			
			if((size = ProcessTargetString(arg, client, clients, MaxClients, COMMAND_FILTER_ALIVE, name, sizeof(name), ml)) <= 0) {
				ReplyToTargetError(client, size);
				return Action:Plugin_Handled;
			}
			
			for(int i=0; i < size; i++){
				int c = clients[i];
				if(c==-1)
				break;
				SpawnChicken(c, amo);
				LogAction(client, c, "%L spawned %d chicken at %L", client, amo, c);
			}
			
			ShowActivity2(client, "[SM] ", "Spawned %d chicken", amo);
			return Action:Plugin_Handled;
		}
		
	}
	
	if(!IsValidEntity(client)){
		ReplyToCommand(client, "You must be ingame to run this command, or target a client.");
		return Action:Plugin_Handled;
	}
	
	float origin[3];
	GetClientEyePosition(client, origin);
	float loc[3];
	RaytraceClientEye(client, loc);
	bool result = SpawnChickenPositional(loc, amo);
	ReplyToCommand(client, result ? "\x04Successfully spawned \x05%d \x04chicken where you're looking." : "\x02Could not spawn chicken.", amo);
	return Plugin_Handled;
}

bool SpawnChicken(int client, int amo=1) {
	for(int i=0;i<amo;i++){
		int chicken = CreateEntityByName("chicken");
		bool result = DispatchSpawn(chicken);
		if(!result)
		return false;
		float origin[3];
		GetClientAbsOrigin(client, origin);
		TeleportEntity(chicken, origin, NULL_VECTOR, NULL_VECTOR);
	}
	return true;
}

bool SpawnChickenPositional(float[3] pos, int amo=1){
	for(int i=0;i<amo;i++){
		int chicken = CreateEntityByName("chicken");
		bool result = DispatchSpawn(chicken);
		TeleportEntity(chicken, pos, NULL_VECTOR, NULL_VECTOR);
		if(!result)
		return false;
	}
	return true;
}

void RaytraceClientEye(int client, float[3] store) {
	float origin[3];
	float angles[3];
	float result[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	
	
	TR_TraceRayFilter(origin, angles, MASK_SOLID, RayType:RayType_Infinite, NoFilter);
	if(TR_DidHit())
	TR_GetEndPosition(result);
	store = result;
}

public bool NoFilter (int target, mask, int client) {
	return (target == client);
}