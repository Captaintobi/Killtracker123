#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
Handle hDatabase = INVALID_HANDLE;
Handle g_Reconnect = INVALID_HANDLE;
enum tracked
{
	kills,deaths,killstreak,killstreaks,
}
new scores[MAXPLAYERS+1][tracked];
public Plugin myinfo = 
{
	name = "KilltrackerV2",
	author = "CaptainTobi",
	description = "Tracks kills and puts them into data base",
	url = "Skynetgaming.net"
}
public OnPluginStart()
{
	Database.Connect(GotDatabase,"KillLog");
	HookEvent("player_death",Event_PlayerDeath);
}
public GotDatabase(Handle hndl, const char [] Sql_error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", Sql_error);
	}else
		{
			LogMessage("Connected To Database");
			hDatabase = hndl;
		}
}
public Action reconnectDB(Handle timer, any:nothing) {
	if (SQL_CheckConfig("KillLog")) {
		Database.Connect(GotDatabase, "KillLog");
	}
}
public OnClientConnected(int client)
{
	if(IsClientAuthorized(client))
	{
		char steamid[32];
		char Sql_error[300];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		char query[1024];
		Format(query,sizeof(query),"INSERT INTO `killlog`(`SteamId`, `kills`, `deaths`) VALUES ('%s','%i','%i') ON DUPLICATE KEY UPDATE `kills` = `kills`, `deaths` = `deaths`"
		, steamid, scores[client][kills], scores[client][deaths]);
		Handle Connected = SQL_Query(hDatabase, query);
		if (Connected != INVALID_HANDLE)
			PrintToServer("INSERTED COMPLETED FOR %s", steamid);
			else{
				SQL_GetError(hDatabase, Sql_error, sizeof(Sql_error));
				PrintToServer("DID NOT INSERT %s",Sql_error);
			}
		}
}

public OnClientDisconnect(int client)
{
	if(IsValidClient(client))
	{
		char name [MAX_NAME_LENGTH];
		char Sql_error[300];
		GetClientName(client, name, sizeof(name));
		char steamid[32];
		GetClientAuthId(client,AuthId_Steam2,steamid,sizeof(steamid));
		char query[1024];
		Format(query,sizeof(query),"UPDATE `killlog` SET `SteamId`= '%s',`kills`= `kills` + '%i',`deaths`= `deaths`+ '%i' WHERE `killlog`.`SteamId` = '%s' ",
		steamid,scores[client][kills],scores[client][deaths],steamid);
		Handle Connected = SQL_Query(hDatabase,query);
			if (Connected != INVALID_HANDLE){
				PrintToServer("INSERTED COMPLETED FOR %s", steamid);
				PurgeClient(client);
			}else{
					SQL_GetError(hDatabase, Sql_error, sizeof(Sql_error));
					PrintToServer("DID NOT INSERT %s",Sql_error);
			}	
	}
}
public OnEndMap(int client)
{
	if(IsValidClient(client))
	{
		char name [MAX_NAME_LENGTH];
		char Sql_error[300];
		GetClientName(client, name, sizeof(name));
		char steamid[32];
		GetClientAuthId(client,AuthId_Steam2,steamid,sizeof(steamid));
		char query[1024];
		Format(query,sizeof(query),"UPDATE `killlog` SET `SteamId`= '%s',`kills`= `kills` + '%i',`deaths`= `deaths`+ '%i' WHERE `killlog`.`SteamId` = '%s' ",
		steamid,scores[client][kills],scores[client][deaths],steamid);
		Handle Connected = SQL_Query(hDatabase,query);
			if (Connected != INVALID_HANDLE){
				PrintToServer("INSERTED COMPLETED FOR %s", steamid);
				PurgeClient(client);
			}else{
				SQL_GetError(hDatabase, Sql_error, sizeof(Sql_error));
				PrintToServer("DID NOT INSERT %s",Sql_error);
			}
	}
}
public Action Event_PlayerDeath(Handle event, char [] name, bool dontBroadcast)
{
	if (hDatabase == INVALID_HANDLE && g_Reconnect == INVALID_HANDLE)
	{
		g_Reconnect = CreateTimer(900.0, reconnectDB);
		PrintToServer("Reconnected to DB");
		return;
	}
	char vName[MAX_NAME_LENGTH] , aName[MAX_NAME_LENGTH];
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	GetClientName(victim,vName,sizeof(vName));
	GetClientName(attacker,aName,sizeof(aName));
	RegisterKill(victim,attacker);
}
RegisterKill(victim,attacker)
{
	if(attacker == victim)
	{	
		scores[attacker][deaths]++;
		return;
	}
	scores[attacker][kills]++;
	scores[victim][deaths]++;		
}
public bool IsValidClient(int client)
{
	if(client <=0)
		return false;
	if(client >MaxClients)
		return false;
	if(!IsClientConnected(client))
		return false;
	return IsClientInGame(client);
}
PurgeClient(int client)
{
	scores[client][kills] = 0;
	scores[client][deaths] = 0;
}