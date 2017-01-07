#pragma semicolon 1

#include <sourcemod>
#include <discord>

public Plugin myinfo = 
{
	name = "Discord - Test",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "github.com/Bara20"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_tdiscord", Command_TDiscord, ADMFLAG_ROOT);
}

public Action Command_TDiscord(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "sm_tdiscord <channel> <message...>");
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
	
	SendMessageToDiscord(sChannel, sMessage);
	
	return Plugin_Continue;
}