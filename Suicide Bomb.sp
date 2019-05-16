#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Cysex"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define SOUND_BOOM "ambient/explosions/explode_8.wav"

public Plugin myinfo = 
{
	name = "[TF2] Suicide Bomb", 
	author = PLUGIN_AUTHOR, 
	description = "Let's the users' sacrifice themselves and bring others down with them to face judgement by The Almighty Allah",
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/cyt3xx/"
};

int g_fire;
int g_HaloSprite;
int g_ExplosionSprite;
int g_iTimer[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegAdminCmd("sm_jihad", Command_Bomb, 0, "[SM] Usage: sm_jihad <seconds>");
}

public OnMapStart() 
{
	g_fire = PrecacheModel("materials/sprites/fire2.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound(SOUND_BOOM, true);
}

public Action Command_Bomb(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_jihad <seconds>");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] Usage: Player must be alive.");
		return Plugin_Handled;		
	}
	
	char time[3];
	GetCmdArg(1, time, sizeof(time));
	int itime = StringToInt(time);
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, float(itime));
	
	g_iTimer[client] = itime;
	CreateTimer(0.0, Timer_SuicideBomb, client);
	
	return Plugin_Handled;
}

public Action Timer_SuicideBomb(Handle timer, int client)
{
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if(g_iTimer[client] > 0)
	{
		PrintCenterText(client, "%i", g_iTimer[client]);
		g_iTimer[client]--;
		CreateTimer(1.0, Timer_SuicideBomb, client);
		return Plugin_Continue;
	}
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);

	float distance = 400.0;
	float damage = 400.0;
	
	SuicideBomb(vecOrigin, distance, damage, client, 0, 0, DMG_BLAST, -1);	
	char username[64];
	GetClientName(client, username, sizeof(username));
	PrintToChatAll("[SM] %s has sacrificed himself in the name of Allah!", username);
	
	return Plugin_Continue;
}

void SuicideBomb(float origin[3], float distance = 500.0, float damage = 500.0, int attacker = 0, int inflictor = 0, int team = 0, int damagetype = DMG_BLAST, int weapon = -1)
{
    if (distance <= 0.0 || damage <= 0.0)
        return;

    float vecOrigin[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i) || (team > 0 && team != GetClientTeam(i)) || (attacker > 0 && i == attacker))
            continue;

        GetClientAbsOrigin(i, vecOrigin);

        if (GetVectorDistance(origin, vecOrigin) > distance)
            continue;

        SDKHooks_TakeDamage(i, inflictor, attacker, damage, damagetype, weapon, origin);
    }

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "*")) != -1)
    {
        if (!HasEntProp(entity, Prop_Send, "m_vecOrigin") || attacker > 0 && attacker == entity)
            continue;

        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);

        if (GetVectorDistance(origin, vecOrigin) > distance)
            continue;

        SDKHooks_TakeDamage(entity, inflictor, attacker, damage, damagetype, weapon, origin);
	}

	float 	location[3];
	GetClientAbsOrigin(attacker, location);
	
	int color[4]={188,220,255,200};
	EmitAmbientSound(SOUND_BOOM, location, attacker, SNDLEVEL_RAIDSIREN);
	TE_SetupExplosion(location, g_ExplosionSprite, 50.0, 1, 0, 400, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(location, 10.0, float(400), g_fire, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
	TE_SendToAll();
	
	location[2] += 10;
	EmitAmbientSound(SOUND_BOOM, location, attacker, SNDLEVEL_RAIDSIREN);
	TE_SetupExplosion(location, g_ExplosionSprite, 10.0, 1, 0, 400, 5000);
	TE_SendToAll();

	ForcePlayerSuicide(attacker);

}