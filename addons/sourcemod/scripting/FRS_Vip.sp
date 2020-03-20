#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <vip_core>
#include <FakeRank_Sync>
#include <clientprefs>
#include <IFR>

public Plugin myinfo = 
{
	name		= "[FRS][VIP] Vip",
	version		= "1.2",
	description	= "Fake Ranks for vip",
	author		= "ღ λŌK0ЌЭŦ ღ ™",
	url			= "https://github.com/IL0co"
}

#define VIP_FAKERANK	 "FakeRanks"
#define IND "vip"

KeyValues kv;
Handle hCookie;
char iSelectCategory[MAXPLAYERS+1][32];
bool HideBlocked, preview_enable;

public void OnPluginEnd()
{
	VIP_UnregisterMe();
	FRS_UnRegisterMe();
}

public void OnPluginStart()
{
	hCookie = RegClientCookie("VIP_MyFakeRank", "VIP_MyFakeRank", CookieAccess_Public);

	FRS_OnCoreLoaded();
	VIP_OnVIPLoaded();
	LoadCfg();
	
	LoadTranslations("vip_core.phrases");
	LoadTranslations("vip_modules.phrases");
	LoadTranslations("vip_fakerank.phrases");
}

public void FRS_OnCoreLoaded()
{
	FRS_RegisterKey(IND);

	for(int i = 1; i <= MaxClients; i++)	if(IsClientAuthorized(i) && IsClientInGame(i))
		OnClientCookiesCached(i);
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_FAKERANK, STRING, SELECTABLE, OnSelectItem);
}

public void OnMapStart()
{
	char szBuffer[256], buff[10];

	if(kv.GotoFirstSubKey())
	{	
		do
		{	
			kv.SavePosition();

			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(buff, sizeof(buff));
					FormatEx(szBuffer, sizeof(szBuffer), "materials/panorama/images/icons/skillgroups/skillgroup%s.svg", buff);

					if(FileExists(szBuffer))	
						AddFileToDownloadsTable(szBuffer);
				}
				while(kv.GotoNextKey(false));
			}

			kv.GoBack();	
		}
		while(kv.GotoNextKey());
	}
	kv.Rewind();
}

public void VIP_OnVIPClientAdded(int client, int iAdmin)
{
	char buff[10];
	kv.GetString("DefEnabled", buff, sizeof(buff));
	SetClientCookie(client, hCookie, buff);
	FRS_SetClientRankId(client, StringToInt(buff), IND);

}

public void VIP_OnVIPClientRemoved(int client, const char[] szReason, int iAdmin)
{
	SelectDisable(client);
}

public void OnClientCookiesCached(int client)
{
	CreateTimer(5.0, Timer_Delay, GetClientUserId(client));
}

public Action Timer_Delay(Handle timer, any client)
{
	client = GetClientOfUserId(client);

	char buff[64];
	GetClientCookie(client, hCookie, buff, sizeof(buff));
	if(!buff[0])
	{ 
		VIP_GetClientFeatureString(client, VIP_FAKERANK, buff, sizeof(buff));

		if(buff[0])
		{
			kv.GetString("DefEnabled", buff, sizeof(buff));
			FRS_SetClientRankId(client, StringToInt(buff), IND);
		}
	}
}

public bool OnSelectItem(int client, const char[] sFeatureName)
{
	ShowMainMenu(client);
	return false;
}

public void ShowMainMenu(int client)
{
	char buff[32], feature[128], exp_buff[16][32];
	bool allow, good = true;
	int loop;
	Menu hMenu = new Menu(OnMainMenuDisplay);

	VIP_GetClientFeatureString(client, VIP_FAKERANK, feature, sizeof(feature));
	if(strcmp(feature, "all", false) == 0)
		allow = true;
	else loop = ExplodeString(feature, ";", exp_buff, sizeof(exp_buff), sizeof(exp_buff[]));
	
	Format(buff, sizeof(buff), "%T", "Category Display", client);
	hMenu.SetTitle(buff);

	Format(buff, sizeof(buff), "%T\n ", "DISABLE_RANK", client);
	hMenu.AddItem("", buff);

	if(kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetSectionName(buff, sizeof(buff));
			
			if(!allow)
			{
				good = false;
				for(int poss = 0; poss < loop; poss++)	if(strcmp(exp_buff[poss], buff, false) == 0)
				{
					good = true;
					break;
				}
			}

			if(good)
				hMenu.AddItem(buff, buff, ITEMDRAW_DEFAULT);
			else if(HideBlocked)
				hMenu.AddItem(buff, buff, ITEMDRAW_DISABLED);
		}
		while(kv.GotoNextKey());
	} 
	kv.Rewind();

	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int OnMainMenuDisplay(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: hMenu.Close();
		case MenuAction_Cancel: if(item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(client);
		case MenuAction_Select:
		{
			if(item == 0)
			{
				SelectDisable(client);		
				ShowMainMenu(client);		
				VIP_PrintToChatClient(client, "%T", "Disabled Rank", client);	
			}
			else
			{
				char buff[32];
				hMenu.GetItem(item, buff, sizeof(buff));
				iSelectCategory[client] = buff;
				ShowItemsMenu(client);
			}
			
		}
	}
}

public void ShowItemsMenu(int client)
{
	char buff[32], id[10];
	Menu hMenu = new Menu(OnShowItemsMenu);
	
	Format(buff, sizeof(buff), "%T", "Item Display", client);
	hMenu.SetTitle(buff);

	Format(buff, sizeof(buff), "%T\n ", "DISABLE_RANK", client);
	hMenu.AddItem("", buff);

	if(kv.JumpToKey(iSelectCategory[client]) && kv.GotoFirstSubKey(false))
	{
		do
		{
			kv.GetSectionName(id, sizeof(id));
			kv.GetString(NULL_STRING, buff, sizeof(buff));
			hMenu.AddItem(id, buff);
		}
		while(kv.GotoNextKey(false));
	} 
	kv.Rewind();

	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int OnShowItemsMenu(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: hMenu.Close();
		case MenuAction_Cancel: ShowMainMenu(client);
		case MenuAction_Select:
		{
			if(item == 0)
			{
				SelectDisable(client);		
				VIP_PrintToChatClient(client, "%T", "Disabled Rank", client);		
			}
			else
			{
				char buff[32];
				hMenu.GetItem(item, buff, sizeof(buff));
				int id = StringToInt(buff);

				if(kv.JumpToKey(iSelectCategory[client]))
				{

					SetClientCookie(client, hCookie, buff);
					FRS_SetClientRankId(client, id, IND);
					
					if(preview_enable)
						IFR_ShowHintFakeRank(client, id);

					kv.GetString(buff, buff, sizeof(buff));
					VIP_PrintToChatClient(client, "%T", "YOU_SET_RANK", client, buff);
				}

				kv.Rewind();
			}
			
			ShowItemsMenu(client);
		}
	}
}

stock void SelectDisable(int client)
{
	SetClientCookie(client, hCookie, "0");
	FRS_SetClientRankId(client, 0, IND);
}

stock void LoadCfg()
{
	kv = CreateKeyValues("FakeRank");
	
	char sBuffer[256];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "data/vip/modules/fakerank.txt");

	if (!FileToKeyValues(kv, sBuffer)) 
		SetFailState("Couldn't parse file %s", sBuffer);

	HideBlocked = view_as<bool>(kv.GetNum("HideBlocked", 0));
	preview_enable = view_as<bool>(kv.GetNum("PreviewEnable", 0));
}
