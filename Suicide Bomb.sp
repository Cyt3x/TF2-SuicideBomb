#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Cysex"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

public void OnPluginStart()
{
	RegAdminCmd("sm_jihad", Command_Bomb, 0, "[SM] Usage: sm_jihad <#userid|name>");
}

public Action Command_Bomb(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_jihad <#userid|name>");
		return Plugin_Handled;
	}
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);

	float distance = 400.0;
	float damage = 400.0;
	PrintToChat(client, "%.2f", distance);
	PrintToChat(client, "%.2f", damage);

	DamageArea(vecOrigin, distance, damage, client, 0, 0, DMG_GENERIC, -1);
	ForcePlayerSuicide(client);
	
	return Plugin_Handled; 
}

stock void DamageArea(float origin[3], float distance = 500.0, float damage = 500.0, int attacker = 0, int inflictor = 0, int team = 0, int damagetype = DMG_GENERIC, int weapon = -1)
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
}