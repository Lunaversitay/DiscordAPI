#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>
#include <morecolors>

public Plugin myinfo = 
{
	name = "Discord API",
	author = "Bara",
	description = "Thanks to ImACow and Phire for their snippet",
	version = "1.0.0",
	url = "github.com/Ragenewb"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SendMessageToDiscord", Native_SendMessageToDiscord);
	
	RegPluginLibrary("discord");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_sdiscord", Command_TestDiscord, ADMFLAG_CUSTOM1 || ADMFLAG_CUSTOM2 || ADMFLAG_CUSTOM3 || ADMFLAG_CUSTOM4 || ADMFLAG_CUSTOM5 || ADMFLAG_CUSTOM6);
        RegConsoleCmd(sm_discord", Command_ShowDiscord;
	CreateTimer(300.0, Timer_Advertise);
}

public Action Timer_Advertise(Handle timer)
{
        static advertisecount=-1;
	advertisecount++;
	CreateTimer(300.0, Timer_Advertise);
	if (Advertise > 1.0)
	{
	        switch (advertisecount)
		{
                	case 1;
                	{
                	        CPrintToChatAll("We have a discord! Type {olive}/discord{default to join!");
                	}
                	case 3;
        	{
                	        CPrintToChatAll("Introducing {unique}Discord Relay{default}! Donors are able to send messages to the Discord by typing {olive}/sdiscord relay <message>{default");}
                	}
                	case 5;
                	{
        	                CPrintToChatAll("Admin required issue? Donators can relay messages to Discord! Type {olive}/sdiscord relay <message>{default} to send one! (Abuse will get you banned, however).");
                	}
		}
	}
	return Plugin_Handled;
}


public Action Command_TestDiscord(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[OPST] Usage: sm_sdiscord relay <message...>");
		return Plugin_Handled;
	}
	
	char sChannel[64];
	GetCmdArg(1, sChannel, sizeof(sChannel));
	
	char sMessage[512], sBuffer[64];
	if (args >= 2)
	{
		GetCmdArg(2, sMessage, sizeof(sMessage));
		for (new i = 3; i <= args; i++)
		{
			GetCmdArg(i, sBuffer, sizeof(sBuffer));
			Format(sMessage, sizeof(sMessage), "%s %s", sMessage, sBuffer);
		}
	}
	else
		return Plugin_Handled;
	
	PrintToChat(client, "Channel: %s - Message: %s", sChannel, sMessage);
	
	SendToDiscord(sChannel, sMessage);
	
	return Plugin_Continue;
}

public int Native_SendMessageToDiscord(Handle plugin, int numParams)
{
	char sChannel[64], sMessage[512];
	GetNativeString(1, sChannel, sizeof(sChannel));
	GetNativeString(2, sMessage, sizeof(sMessage));
	
	SendToDiscord(sChannel, sMessage);
}

public void SendToDiscord(const char[] channel, const char[] message)
{
	char sURL[512];
	if(GetChannelWebHook(channel, sURL, sizeof(sURL)))
	{
		Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sURL);
	
		SteamWorks_SetHTTPRequestGetOrPostParameter(request, "content", message);
		SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/x-www-form-urlencoded");
		
		if(request == null || !SteamWorks_SetHTTPCallbacks(request, Callback_SendToDiscord) || !SteamWorks_SendHTTPRequest(request))
		{
			PrintToServer("[SendToDiscord] Failed to fire");
			delete request;
		}
	}
}


public Callback_SendToDiscord(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if(!bFailure && bRequestSuccessful)
	{
		if (eStatusCode != k_EHTTPStatusCode200OK && eStatusCode != k_EHTTPStatusCode204NoContent)
		{
			LogError("[Callback_SendToDiscord] Failed with code [%i]", eStatusCode);
			SteamWorks_GetHTTPResponseBodyCallback(hRequest, Callback_Response);
		}
	}
	delete hRequest;
}

public Callback_Response(const char[] sData)
{
	PrintToServer("[Callback_Response] %s", sData);
}

bool GetChannelWebHook(const char[] channel, char[] webhook, int length)
{
	KeyValues kv = new KeyValues("DiscordAPI");
	
	char sFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/discord.cfg");

	if (!FileExists(sFile))
	{
		SetFailState("[GetChannelWebHook] \"%s\" not found!", sFile);
		return false;
	}

	kv.ImportFromFile(sFile);

	if (!kv.GotoFirstSubKey())
	{
		SetFailState("[GetChannelWebHook] Can't find a channel in \"%s\"!", sFile);
		return false;
	}
	
	char sChannel[64];
	
	do
	{
		kv.GetSectionName(sChannel, sizeof(sChannel));
		
		if(StrEqual(sChannel, channel, false))
		{
			kv.GetString("url", webhook, length);
			return true;
		}
	}
	while (kv.GotoNextKey());
	
	delete kv;
	
	return false;
}
