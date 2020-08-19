#include <sdktools>
#include <vip_core>
#include <FakeRank_Sync>
#include <clientprefs>
#include <sourcemod>
#undef REQUIRE_PLUGIN
#tryinclude <IFR>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name		= "[FRS][VIP] FakeRanks",
	version		= "1.2.1",
	description	= "Fake Ranks for vip",
	author		= "iLoco",
	url			= "https://github.com/IL0co"
}

#define VIP_FAKERANK	 "FakeRanks"
#define IND "vip"

KeyValues kv;
Cookie hCookie;
char iSelectCategory[MAXPLAYERS+1][32];
bool HideBlocked, preview_enable, isIFRReady;

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	MarkNativeAsOptional("IFR_ShowHintFakeRank");

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "Intermediary_FakeRank", false) == 0)
		isIFRReady = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "Intermediary_FakeRank", false) == 0)
		isIFRReady = false;
}

public void OnPluginEnd()
{
	VIP_UnregisterMe();
	FRS_UnRegisterMe();
}

public void OnPluginStart()
{
	isIFRReady = LibraryExists("Intermediary_FakeRank");
	hCookie = new Cookie("VIP_MyFakeRank", "VIP_MyFakeRank", CookieAccess_Public);

	LoadCfg();
	
	FRS_OnCoreLoaded();
	
	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
	
	LoadTranslations("vip_core.phrases");
	LoadTranslations("vip_modules.phrases");
	LoadTranslations("vip_fakerank.phrases");
}

public void FRS_OnCoreLoaded()
{
	FRS_RegisterKey(IND);

	for(int i = 1; i <= MaxClients; i++)	if(IsClientAuthorized(i) && IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i))
		VIP_OnVIPClientLoaded(i);
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

public void VIP_OnVIPClientLoaded(int client)
{
	if(CheckClient(client))
		FRS_SetClientRankId(client, GetClientId(client), IND);
}

public void VIP_OnVIPClientRemoved(int client, const char[] szReason, int iAdmin)
{
	FRS_SetClientRankId(client, 0, IND);
}

public void VIP_OnVIPClientAdded(int client, int admin)
{
	if(CheckClient(client))
		FRS_SetClientRankId(client, GetClientId(client), IND);
}

public bool OnSelectItem(int client, const char[] sFeatureName)
{
	Menu_Category(client).Display(client, 0);
	return false;
}

public Menu Menu_Category(int client)
{
	char buff[32], feature[128], exp_buff[16][32];
	bool allow, good = true;
	int loop;
	Menu menu = new Menu(MenuHendler_Category);

	VIP_GetClientFeatureString(client, VIP_FAKERANK, feature, sizeof(feature));
	if(strcmp(feature, "all", false) == 0)
		allow = true;
	else loop = ExplodeString(feature, ";", exp_buff, sizeof(exp_buff), sizeof(exp_buff[]));
	
	Format(buff, sizeof(buff), "%T", "Category Display", client);
	menu.SetTitle(buff);

	Format(buff, sizeof(buff), "%T\n ", "DISABLE_RANK", client);
	menu.AddItem("", buff);

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
				menu.AddItem(buff, buff, ITEMDRAW_DEFAULT);
			else if(HideBlocked)
				menu.AddItem(buff, buff, ITEMDRAW_DISABLED);
		}
		while(kv.GotoNextKey());
	} 
	kv.Rewind();

	menu.ExitBackButton = true;

	return menu;
}

public int MenuHendler_Category(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel: if(item == MenuCancel_ExitBack) VIP_SendClientVIPMenu(client);
		case MenuAction_Select:
		{
			if(item == 0)
			{
				SetClientCookie(client, hCookie, "0");
				FRS_SetClientRankId(client, 0, IND);
				Menu_Category(client).Display(client, 0);
				VIP_PrintToChatClient(client, "%T", "Disabled Rank", client);	
			}
			else
			{
				char buff[32];
				menu.GetItem(item, buff, sizeof(buff));
				iSelectCategory[client] = buff;
				ShowItemsMenu(client).Display(client, 0);
			}
			
		}
	}
}

public Menu ShowItemsMenu(int client)
{
	char buff[32], id[10];
	Menu menu = new Menu(MenuHendler_Items);
	
	Format(buff, sizeof(buff), "%T", "Item Display", client);
	menu.SetTitle(buff);

	Format(buff, sizeof(buff), "%T\n ", "DISABLE_RANK", client);
	menu.AddItem("", buff);

	if(kv.JumpToKey(iSelectCategory[client]) && kv.GotoFirstSubKey(false))
	{
		do
		{
			kv.GetSectionName(id, sizeof(id));
			kv.GetString(NULL_STRING, buff, sizeof(buff));
			menu.AddItem(id, buff);
		}
		while(kv.GotoNextKey(false));
	} 
	kv.Rewind();

	return menu;
}

public int MenuHendler_Items(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel: Menu_Category(client).Display(client, 0);
		case MenuAction_Select:
		{
			if(item == 0)
			{
				SetClientCookie(client, hCookie, "0");
				FRS_SetClientRankId(client, 0, IND);	
				VIP_PrintToChatClient(client, "%T", "Disabled Rank", client);		
			}
			else
			{
				char buff[32];
				menu.GetItem(item, buff, sizeof(buff));
				int id = StringToInt(buff);

				if(kv.JumpToKey(iSelectCategory[client]))
				{

					SetClientCookie(client, hCookie, buff);
					FRS_SetClientRankId(client, id, IND);
					
					if(isIFRReady && preview_enable)
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

stock bool CheckClient(int client)
{
	if(!VIP_IsClientVIP(client))
		return false;

	char buff[128];
	VIP_GetClientFeatureString(client, VIP_FAKERANK, buff, sizeof(buff));

	if(!buff[0])
		return false;

	return true;
}

stock int GetClientId(int client)
{
	char buff[128];
	VIP_GetClientFeatureString(client, VIP_FAKERANK, buff, sizeof(buff));
	bool isAll = (strcmp(buff, "all", false) == 0);
	char iId[16], buff2[3];
	hCookie.Get(client, iId, sizeof(iId));

	kv.Rewind();
	
	if(kv.GotoFirstSubKey())
	{
		char exp[16][32];
		int loop;

		if(!isAll)
			loop = ExplodeString(buff, ";", exp, sizeof(exp), sizeof(exp[]));

		do
		{
			kv.GetSectionName(buff, sizeof(buff));

			if(!isAll)
			{
				for(int poss = 0; poss < loop; poss++)	if(strcmp(exp[poss], buff, false) == 0)
				{
					kv.GetString(iId, buff2, sizeof(buff2));

					if(buff2[0])
					{
						return StringToInt(iId);
					}
				}
			}
			else
			{
				kv.SavePosition();

				if(kv.GotoFirstSubKey(false))
				{
					do
					{
						kv.GetString(iId, buff2, sizeof(buff2));

						if(buff2[0])
						{
							return StringToInt(iId);
						}
					}
					while(kv.GotoNextKey(false));

					kv.GoBack();
				}
			}
		}
		while(kv.GotoNextKey());
	}

	kv.Rewind();
	return kv.GetNum("DefEnabled");
}
