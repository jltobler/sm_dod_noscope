#include <sourcemod>

public Plugin myinfo =
{
	name = "No-scope",
	author = "Justin Tobler",
	description = "Forces players to use unscoped sniper rifles in DoD:S",
	version = "0.0.0",
	url = "https://github.com/jltobler/sm_dod_noscope"
};

public void OnPluginStart()
{
	PrintToServer("---- sm_dod_noscope loaded ----");
}
