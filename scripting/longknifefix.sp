#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>
#include <multicolors>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
    name = "Anti Long Knife Fix",
    author = "SyntX34",
    description = "Fixes long knife issues in Zombie Reloaded with configurable distance limits",
    version = PLUGIN_VERSION,
    url = "https://github.com/SyntX34 && https://steamcommunity.com/id/SyntX34"
};

#define METHOD_PLAYERHURT 0
#define METHOD_TAKEDAMAGE 1
#define METHOD_BOTH 2

ConVar 
    g_cvPluginEnabled,
    g_cvMaxDistance,
    g_cvDetectionMethod,
    g_cvFixLongKnife,
    g_cvDebug,
    g_cvUseZRDistance;

bool 
    g_bPluginEnabled,
    g_bFixLongKnife,
    g_bDebug,
    g_bUseZRDistance,
    g_bHookedPlayerHurt = false,
    g_bHookedTakeDamage = false;

int 
    g_iMaxDistance,
    g_iDetectionMethod;

ConVar 
    g_cvZRInfectMaxDistance;

public void OnPluginStart()
{
    g_cvPluginEnabled = CreateConVar("sm_antilongknife_enable", "1", "Enable/disable the Anti Long Knife plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvMaxDistance = CreateConVar("sm_antilongknife_maxdistance", "150", "Maximum allowed distance for knife infection (0 = disabled)", FCVAR_NOTIFY, true, 0.0);
    g_cvFixLongKnife = CreateConVar("sm_antilongknife_fix", "1", "Enable/disable long knife fix", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvDetectionMethod = CreateConVar("sm_antilongknife_method", "2", "Detection method: 0 = player_hurt event, 1 = OnTakeDamage, 2 = both", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    g_cvDebug = CreateConVar("sm_antilongknife_debug", "0", "Enable debug messages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvUseZRDistance = CreateConVar("sm_antilongknife_use_zr_distance", "1", "Use zr_infect_max_distance if available, otherwise use plugin distance", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    g_cvPluginEnabled.AddChangeHook(OnConVarChanged);
    g_cvMaxDistance.AddChangeHook(OnConVarChanged);
    g_cvFixLongKnife.AddChangeHook(OnConVarChanged);
    g_cvDetectionMethod.AddChangeHook(OnConVarChanged);
    g_cvDebug.AddChangeHook(OnConVarChanged);
    g_cvUseZRDistance.AddChangeHook(OnConVarChanged);
    
    g_bPluginEnabled = g_cvPluginEnabled.BoolValue;
    g_iMaxDistance = g_cvMaxDistance.IntValue;
    g_bFixLongKnife = g_cvFixLongKnife.BoolValue;
    g_iDetectionMethod = g_cvDetectionMethod.IntValue;
    g_bDebug = g_cvDebug.BoolValue;
    g_bUseZRDistance = g_cvUseZRDistance.BoolValue;
    
    ApplyHooks();
    g_cvZRInfectMaxDistance = FindConVar("zr_infect_max_distance");
    
    AutoExecConfig(true, "antilongknife");
    
    PrintToServer("[AntiLongKnife] Plugin loaded successfully");
    DebugPrint("Debug mode enabled");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bool oldPluginState = g_bPluginEnabled;
    bool oldFixState = g_bFixLongKnife;
    int oldMethod = g_iDetectionMethod;
    bool oldDebug = g_bDebug;
    bool oldUseZR = g_bUseZRDistance;
    
    g_bPluginEnabled = g_cvPluginEnabled.BoolValue;
    g_iMaxDistance = g_cvMaxDistance.IntValue;
    g_bFixLongKnife = g_cvFixLongKnife.BoolValue;
    g_iDetectionMethod = g_cvDetectionMethod.IntValue;
    g_bDebug = g_cvDebug.BoolValue;
    g_bUseZRDistance = g_cvUseZRDistance.BoolValue;
    
    if (oldDebug != g_bDebug)
    {
        if (g_bDebug)
        {
            DebugPrint("Debug mode enabled");
        }
        else
        {
            DebugPrint("Debug mode disabled");
        }
    }
    
    if (oldUseZR != g_bUseZRDistance)
    {
        if (g_bUseZRDistance)
        {
            DebugPrint("Using ZR distance if available");
        }
        else
        {
            DebugPrint("Using plugin distance only");
        }
    }
    
    bool hooksChanged = (oldPluginState != g_bPluginEnabled) || 
                       (oldFixState != g_bFixLongKnife) || 
                       (oldMethod != g_iDetectionMethod);
    
    if (hooksChanged)
    {
        RemoveHooks();
        ApplyHooks();
        
        if (g_bPluginEnabled && g_bFixLongKnife)
        {
            DebugPrint("Hooks updated - Method: %d", g_iDetectionMethod);
        }
        else
        {
            DebugPrint("Hooks removed - Plugin disabled or fix disabled");
        }
    }
}

void ApplyHooks()
{
    if (!g_bPluginEnabled || !g_bFixLongKnife)
        return;
    
    DebugPrint("Applying hooks with method: %d", g_iDetectionMethod);
    
    if (g_iDetectionMethod == METHOD_PLAYERHURT || g_iDetectionMethod == METHOD_BOTH)
    {
        if (!g_bHookedPlayerHurt)
        {
            HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
            g_bHookedPlayerHurt = true;
            DebugPrint("Hooked player_hurt event");
        }
    }
    
    if (g_iDetectionMethod == METHOD_TAKEDAMAGE || g_iDetectionMethod == METHOD_BOTH)
    {
        if (!g_bHookedTakeDamage)
        {
            for (int client = 1; client <= MaxClients; client++)
            {
                if (IsClientInGame(client))
                {
                    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
                }
            }
            g_bHookedTakeDamage = true;
            DebugPrint("Hooked OnTakeDamage for all clients");
        }
    }
}

void RemoveHooks()
{
    DebugPrint("Removing all hooks");
    
    if (g_bHookedPlayerHurt)
    {
        UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
        g_bHookedPlayerHurt = false;
        DebugPrint("Unhooked player_hurt event");
    }
    
    if (g_bHookedTakeDamage)
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (IsClientInGame(client))
            {
                SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
        g_bHookedTakeDamage = false;
        DebugPrint("Unhooked OnTakeDamage for all clients");
    }
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bPluginEnabled || !g_bFixLongKnife)
        return Plugin_Continue;
    
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if (!IsValidClient(victim) || !IsValidClient(attacker) || victim == attacker)
        return Plugin_Continue;
    
    char weapon[32];
    event.GetString("weapon", weapon, sizeof(weapon));
    
    if (!IsKnifeWeapon(weapon))
        return Plugin_Continue;
    
    DebugPrint("PlayerHurt Event - Victim: %N, Attacker: %N, Weapon: %s", victim, attacker, weapon);
    
    return ProcessKnifeDamage(victim, attacker, "player_hurt");
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (!g_bPluginEnabled || !g_bFixLongKnife)
        return Plugin_Continue;
    
    if (!IsValidClient(victim) || !IsValidClient(attacker) || victim == attacker)
        return Plugin_Continue;
    
    if (!(damagetype & DMG_SLASH) && damagecustom != 16)
        return Plugin_Continue;
    
    char weaponClassname[32];
    if (IsValidEntity(weapon) && GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname)))
    {
        if (!IsKnifeWeapon(weaponClassname))
            return Plugin_Continue;
    }
    else
    {
        if (!(damagetype & DMG_SLASH))
            return Plugin_Continue;
    }
    
    DebugPrint("OnTakeDamage - Victim: %N, Attacker: %N, Damage: %.1f, Type: %d", victim, attacker, damage, damagetype);
    
    return ProcessKnifeDamage(victim, attacker, "ontakedamage");
}

Action ProcessKnifeDamage(int victim, int attacker, const char[] method)
{
    bool victimZombie = ZR_IsClientZombie(victim);
    bool attackerZombie = ZR_IsClientZombie(attacker);
    
    DebugPrint("%s - Victim: %N (Zombie: %s), Attacker: %N (Zombie: %s)", 
               method, victim, victimZombie ? "Yes" : "No", attacker, attackerZombie ? "Yes" : "No");
    
    if (!victimZombie && attackerZombie)
    {
        int maxDistance = GetMaxDistance();
        
        DebugPrint("%s - Max distance: %d", method, maxDistance);
        
        if (maxDistance > 0)
        {
            float victimPos[3], attackerPos[3];
            GetClientAbsOrigin(victim, victimPos);
            GetClientAbsOrigin(attacker, attackerPos);
            
            victimPos[2] = 0.0;
            attackerPos[2] = 0.0;
            
            float distance = GetVectorDistance(victimPos, attackerPos);
            
            DebugPrint("%s - Actual distance (2D): %.2f units", method, distance);
            
            if (distance > float(maxDistance))
            {
                char attackerName[MAX_NAME_LENGTH];
                char victimName[MAX_NAME_LENGTH];
                GetClientName(attacker, attackerName, sizeof(attackerName));
                GetClientName(victim, victimName, sizeof(victimName));
                
                //CPrintToChat(attacker, "{red}[AntiLongKnife] {default}Infection blocked: Distance too far ({green}%.0f{default} units)", distance);
                //CPrintToChat(victim, "{red}[AntiLongKnife] {default}Infection blocked: Attacker was too far away ({green}%.0f{default} units)", distance);
                
                PrintToServer("[AntiLongKnife] BLOCKED: %s -> %s (%.0f units > max %d units) - Method: %s", 
                             attackerName, victimName, distance, maxDistance, method);
                
                DebugMessageAll("{red}[AntiLongKnife] {default}BLOCKED: {green}%s {default}-> {green}%s {default}({red}%.0f{default} units > max {red}%d{default} units) - Method: {yellow}%s", 
                               attackerName, victimName, distance, maxDistance, method);
                
                if (StrEqual(method, "player_hurt"))
                {
                    int health = GetClientHealth(victim);
                    SetEntityHealth(victim, health + 65);
                    DebugPrint("%s - Restored health for victim %N", method, victim);
                }
                
                return Plugin_Handled;
            }
            else
            {
                DebugPrint("%s - Distance check PASSED: %.2f <= %d", method, distance, maxDistance);
                
                if (g_bDebug)
                {
                    char attackerName[MAX_NAME_LENGTH];
                    char victimName[MAX_NAME_LENGTH];
                    GetClientName(attacker, attackerName, sizeof(attackerName));
                    GetClientName(victim, victimName, sizeof(victimName));
                    
                    PrintToServer("[AntiLongKnife] ALLOWED: %s -> %s (%.0f units <= max %d units) - Method: %s", 
                                 attackerName, victimName, distance, maxDistance, method);
                    
                    DebugMessageAll("{green}[AntiLongKnife] {default}ALLOWED: {lightgreen}%s {default}-> {lightgreen}%s {default}({green}%.0f{default} units <= max {green}%d{default} units) - Method: {yellow}%s", 
                                   attackerName, victimName, distance, maxDistance, method);
                }
            }
        }
        else
        {
            DebugPrint("%s - Distance check disabled (maxDistance = %d)", method, maxDistance);
        }
    }
    else
    {
        DebugPrint("%s - Not a human->zombie infection, skipping", method);
    }
    
    return Plugin_Continue;
}

bool IsKnifeWeapon(const char[] weapon)
{
    return (StrContains(weapon, "knife", false) != -1 || 
            StrContains(weapon, "bayonet", false) != -1 ||
            StrContains(weapon, "melee", false) != -1);
}

int GetMaxDistance()
{
    if (g_bUseZRDistance && g_cvZRInfectMaxDistance != null)
    {
        int zrDistance = g_cvZRInfectMaxDistance.IntValue;
        DebugPrint("Using ZR distance: %d", zrDistance);
        return zrDistance;
    }
    
    DebugPrint("Using plugin distance: %d", g_iMaxDistance);
    return g_iMaxDistance;
}

bool IsValidClient(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
        return false;
    return true;
}

void DebugPrint(const char[] format, any ...)
{
    if (!g_bDebug)
        return;
    
    char buffer[256];
    VFormat(buffer, sizeof(buffer), format, 2);
    PrintToServer("[AntiLongKnife-DEBUG] %s", buffer);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_BAN))
        {
            CPrintToChat(i, "{olive}[AntiLongKnife-DEBUG] {default}%s", buffer);
        }
    }
}

void DebugMessageAll(const char[] format, any ...)
{
    char buffer[256];
    VFormat(buffer, sizeof(buffer), format, 2);
    char consoleBuffer[256];
    strcopy(consoleBuffer, sizeof(consoleBuffer), buffer);
    ReplaceString(consoleBuffer, sizeof(consoleBuffer), "{red}", "", false);
    ReplaceString(consoleBuffer, sizeof(consoleBuffer), "{green}", "", false);
    ReplaceString(consoleBuffer, sizeof(consoleBuffer), "{lightgreen}", "", false);
    ReplaceString(consoleBuffer, sizeof(consoleBuffer), "{yellow}", "", false);
    ReplaceString(consoleBuffer, sizeof(consoleBuffer), "{olive}", "", false);
    ReplaceString(consoleBuffer, sizeof(consoleBuffer), "{default}", "", false);
    PrintToServer("[AntiLongKnife] %s", consoleBuffer);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_BAN))
        {
            CPrintToChat(i, "%s", buffer);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (g_bPluginEnabled && g_bFixLongKnife && 
       (g_iDetectionMethod == METHOD_TAKEDAMAGE || g_iDetectionMethod == METHOD_BOTH) && 
       g_bHookedTakeDamage)
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        DebugPrint("Hooked OnTakeDamage for new client %N", client);
    }
}

public void OnClientDisconnect(int client)
{
    if (g_bHookedTakeDamage)
    {
        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public void OnConfigsExecuted()
{
    if (g_cvZRInfectMaxDistance == null)
    {
        g_cvZRInfectMaxDistance = FindConVar("zr_infect_max_distance");
        if (g_cvZRInfectMaxDistance != null)
        {
            DebugPrint("Found ZR infect max distance cvar: %d", g_cvZRInfectMaxDistance.IntValue);
        }
        else
        {
            DebugPrint("ZR infect max distance cvar not found");
        }
    }
    
    RemoveHooks();
    ApplyHooks();
}

public void OnPluginEnd()
{
    RemoveHooks();
    PrintToServer("[AntiLongKnife] Plugin unloaded");
}