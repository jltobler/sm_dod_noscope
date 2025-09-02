#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define ALLIES 2
#define AXIS 3

char weapon_sniper[4][] = {"", "", "weapon_spring", "weapon_k98_scoped"};

bool noscope_enabled = false;

public Plugin myinfo =
{
	name = "No-scope",
	author = "Justin Tobler",
	description = "Forces players to use unscoped sniper rifles in DoD:S",
	version = "1.0.0",
	url = "https://github.com/jltobler/sm_dod_noscope"
};

public Action trace_attack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	int weapon_id = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon_id))
		return Plugin_Continue;

	int zoomed = GetEntProp(weapon_id, Prop_Send, "m_bZoomed");
	if (zoomed) {
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if (noscope_enabled) {
		PrintToChat(client, "\x04[NoScope]\x01 No-scope only!")
		SDKHook(client, SDKHook_TraceAttack, trace_attack);
	}
}

public void setup_weapons(int client)
{
	int team = GetClientTeam(client);
	if (team != ALLIES && team != AXIS)
		return;

	for (int i = 0; i < 4; i++) {
		int weapon_id = GetPlayerWeaponSlot(client, i);
		if (weapon_id != -1) {
			RemovePlayerItem(client, weapon_id);
			RemoveEdict(weapon_id);
		}
	}

	int weapon_id = GivePlayerItem(client, weapon_sniper[team]);
	if (weapon_id != -1) {
		int ammo_type = GetEntProp(weapon_id, Prop_Send, "m_iPrimaryAmmoType");
		GivePlayerAmmo(client, 100, ammo_type, false);
	}
}

public void weapon_attack(Event event, const char[] name, bool dontBroadcast)
{
	int weapon_id = GetEventInt(event, "weapon");
	int user_id = GetEventInt(event, "attacker");
	int client = GetClientOfUserId(user_id);

	if (client > 0 && (weapon_id == 33 || weapon_id == 34)) {
		PrintHintText(client, "No-Scope Only");
		FakeClientCommandEx(client, "drop");
	}
}

public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int user_id = GetEventInt(event, "userid");
	int client = GetClientOfUserId(user_id);

	setup_weapons(client)
}

public Action toggle_noscope(int client, int args)
{
	noscope_enabled = !noscope_enabled;

	if (noscope_enabled) {
		HookEvent("dod_stats_weapon_attack", weapon_attack);
		HookEvent("player_spawn", player_spawn);

		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				setup_weapons(client);
				SDKHook(i, SDKHook_TraceAttack, trace_attack);
			}
		}

		PrintToChatAll("\x04[NoScope]\x01 No-scope only mode enabled!");
	} else {
		UnhookEvent("dod_stats_weapon_attack", weapon_attack);
		UnhookEvent("player_spawn", player_spawn);

		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i))
				SDKUnhook(i, SDKHook_TraceAttack, trace_attack);
		}

		PrintToChatAll("\x04[NoScope]\x01 No-scope only mode disabled!");
	}

	return Plugin_Handled;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_noscope", toggle_noscope, ADMFLAG_GENERIC);
	PrintToServer("---- sm_dod_noscope loaded ----");
}
