//=============================================================================
// Healing Extend Mutator Main Part
//
// Code And Concept By ArHShRn
// http://steamcommunity.com/id/ArHShRn/
//
// Version Release 1.1.3
// - Add config bools to control HE/HE_HUD Usage
// - HealingExtend main func adds HealthNArmor Regeneration
// - New ChatController forked from RPW, easier usage.
// - Removed Dynamic Settings, will develop later.
//
// Last Update Date Jan.29th 2018
//=============================================================================
class HE_Main extends KFMutator
	config(HE_Main);

//**************************
//*  System Configs
//**************************
//Mutator Version Info
var config HEVersionInfo	HEVI;
var HEVersionInfo			Editable_HEVI;

//System Variable Configs
var config bool				bEnableHE;
var config bool				bEnableHE_HUD; //Disable HE_HUD will disable OC as well,thx to health bar bugs by twi
var config bool				bEnableCustomizedWeapons;
var config bool				bEnableHealthRegen; //Like Zerk
var config bool				bEnableArmourRegen; //Like Zerk
var config bool				bEnableInfiniteSpareAmmo;
var config bool				bFillAllWeapAmmoAfterQuickPurchase; //Set true to fill all ammo
var config bool				bEnableHealthAndArmorOverclocking;	
var config bool				bGsAltOneIsSPX; //True to set Gunslinger's Alt+1 purchasing SPX, False to purchase 1911
var config bool				bInitedConfig;
var config bool				bEnableAmmoRecovering;	
var config bool				bEnableDoshBonus;

//System Variables		
var	bool					bInNormalTime;				
var float					fLastHeadshotCounts; // a players last headshot count
var HE_ChatController		HECC;
var() RGBColor				RGB;
var bool					bCreatedBH;

//**************************
//*  Gameplay Configs
//**************************
var array<HEPlayer>			Players; //Cached Players
var STraderItem				TI; //Trader Items
	 
//**************************
//*  Common Settings
//**************************
var config float			fCurrentRegenRate;
var config float			DecreModifier; //For health n armor decreament
var config float			RegenModifier; //For health n armor regeneration
var config float			HealthRegenPerSecond;
var config float			ArmourRegenPerSecond;
var config float			HealthHealingAmount;
var config float			ArmourHealingAmount;
var config int				BonusDosh;
var config int				OverclockHealthLimit;
var config int				OverclockArmorLimit;

//*************************************************
//*  Initialization
//*************************************************
//1.PreBeginPlay, before game starts
//	Init mutator config values
//	Create empty HEPlayer instance
function PreBeginPlay()
{
	//Force Init
	if(!bEnableHE_HUD)
		bEnableHealthAndArmorOverclocking=bEnableHE_HUD;
	
	if(!bInitedConfig)
	{
		//`log("[HEMain]Init Basic Mutator Values...");
		InitBasicMutatorValues();
	}
	
	SaveConfig();
	//Debug RGBColor
	//`log("[HEMain]Check RGBColor::Firebrick="$RGB.Firebrick);
	//`log("[HEMain]Check RGBColor::DeepCyan="$RGB.DeepCyan);
	
	super.PreBeginPlay();
}
//2.NotifyLogin, when player enters game
//	Add him into HEPlayer array to manage him
function NotifyLogin(Controller NewPlayer)
{
	local HE_HUDManager tmp;
	
	tmp=Spawn(class'HE_HUDManager', NewPlayer);
	tmp.ClientGetKFPlayerOwner(); 
	tmp.ClientPrint("-[HUD Manager Initialization Complete]-", False);
	tmp.ClientOpenURL();
	
	//Set spectator's HUD as well
	if(NewPlayer.IsSpectating())
	{
		tmp.ClientPrint("-[HUD Entered Spectating State]-", False);
		tmp.ClientSetHUD();
	}
	
	super.NotifyLogin(NewPlayer);
}
//3.PostBeginPlay, after game starts
function PostBeginPlay()
{	
	SetTimer(1.1f, true, nameof(SetBH));
	super.PostBeginPlay();
}
//4.ModifyPlayer, when player's pawn is created
//	Modify HealthRegenRate
//	ReInitPlayersArry, because he may have died last wave
function ModifyPlayer(Pawn Other)
{	
	//Instant Healing Stuffs
	local KFPawn_Human KFPH;
	local KFPlayerController KFPC;
	local HEPlayer tmp;
	
	KFPH=KFPawn_Human(Other);
	KFPC=KFPlayerController(Other.Controller);
	
	if(bEnableHE)
		KFPH.HealthRegenRate=(1/fCurrentRegenRate);
	`log("[HE::ModifyPlayer]HealthRegenRate Set to "$KFPH.HealthRegenRate);

	//Re-initialize Players Array, Check if he exists in the game
	//Attention: When there's a player exited the game, dead HEP will be removed
	//			Turn to AddHimIntoPlayers(Other) directly
	if(!ReInitPlayersArry(Other))
	//Add this player in to Players array if he's new in this game
	//	Or he's been deleted after a player exited while he's dead
		AddHimIntoPlayers(Other);
	
	//Testing Rep, should be commented in release ver
	//Spawn(class'HE_RepTest', Other.Controller);
	
	tmp=GetHEP(KFPC);
	tmp.HUDManager.ClientAddChatLine("[HE Quick-Purchase System Enabled]", "B22222");
	tmp.HUDManager.ClientAddChatLine("--Press 'Alt+0' For Usage Help--", "B22222");
	BroadcastBuyHelp(KFPC, "!HEBuyPerk");
		
	super.ModifyPlayer(Other);
}
//5.NotifyLogout, when player exits
//	Delete him out of HEPlayer array
function NotifyLogout(Controller Exiting)
{	
	NotifyPlayerExits(KFPlayerController(Exiting));
	
	super.NotifyLogout(Exiting);
}

//*************************************************
//*  Mutator Basic Values Init
//*************************************************
//Initialize basic config default values used in the mutator
//Author recommended values, plz do not edit
function InitBasicMutatorValues()
{
	//Muatator Version Info
	Editable_HEVI.ThisMutatorName="Healing Extend Main Part";
	Editable_HEVI.AuthorNickname="ArHShRn";
	Editable_HEVI.AuthorSteamcommunityURL="http://steamcommunity.com/id/ArHShRn/";
	Editable_HEVI.Version="Release 1.1.3";
	Editable_HEVI.LastUpdate="Jan.26th 2018 09:22 PM";
	HEVI=Editable_HEVI;
	
	//Mutator Config Variable
	bInitedConfig=True;
	
	//Mutator Mechanism
	bEnableHE=True;
	bEnableHE_HUD=True;
	bEnableCustomizedWeapons=False;
	bEnableHealthRegen=False;
	bEnableArmourRegen=False;
	bEnableInfiniteSpareAmmo=False;
	bGsAltOneIsSPX=True;
	bFillAllWeapAmmoAfterQuickPurchase=True;
	
	bEnableDoshBonus=True;
	bEnableAmmoRecovering=True;
	bEnableHealthAndArmorOverclocking=bEnableHE_HUD;
	//bEnableAAR_Headshots=True;

	//Gameplay Settings
	HealthRegenPerSecond=1;
	ArmourRegenPerSecond=1;
	BonusDosh=85; 
	fCurrentRegenRate=10.0;
	HealthHealingAmount=1; 
	ArmourHealingAmount=1;
	OverclockHealthLimit=150; 
	OverclockArmorLimit=175;
	DecreModifier=0.2f;
	RegenModifier=1.0f;
}

//*************************************************
//*  Players::Array<HEPlayer> Related Functions
//*  Essential For HealingExtend
//*  Report Bug In Time To Prevent Disability
//*  Last Edit: Jan.29th 2018
//*************************************************
//1.
//To add a new player into Players Array
//if player is died last wave, update his info to the array
function AddHimIntoPlayers(Pawn P)
{
	local HEPlayer				instance;
	local KFPlayerController	PlayerKFPC;
	local KFPawn_Human			PlayerKFPH;
	
	PlayerKFPC=KFPlayerController(P.Controller);
	PlayerKFPH=KFPawn_Human(P);
	
	if(PlayerKFPC==None || PlayerKFPH==None) //if he's not Human, return
	{
		`log("[HEMain::AddHimIntoPlayers]WARNING: PlayerKFPC or PlayerKFPH is None!");
		return;
	}

	instance.UniqueID=PlayerKFPC.GetOnlineSubsystem().UniqueNetIdToString(PlayerKFPC.PlayerReplicationInfo.UniqueId);
	instance.KFPC=PlayerKFPC;
	
	//Should be re-inited every time the ModifyPlayer is called(e.g, he died last wave)
	instance.KFPH=PlayerKFPH;//Will be invalid when he died last wave
	
	instance.LastPerk=PlayerKFPC.GetPerk().GetPerkClass();
	
	//Spawn Player's HUDManager and set his HUD
	//First spawn a manager and set owner to this Pawn's player
	instance.HUDManager = GetHUDManager(instance.KFPC);
	//If player doesn't want to use HE_HUD then HUDManager only gets LocalPlayer to handle chat message
	//	but not spawn and set HE_HUD to the new one.
	if(bEnableHE_HUD)
		instance.HUDManager.ClientSetHUD();
		
	instance.HUDManager.bStartGame=True;
	
	//Spawn Trader Manager
	instance.TraderManager = Spawn(class'HE_TraderManager', instance.KFPC);
	`log("[HEMain]Spawned a new HE_TraderManager="$instance.TraderManager.Name);
	if(bEnableCustomizedWeapons)
		instance.TraderManager.StartSyncItem();
	
	instance.bIsEpt=False;
	
	Players.AddItem(instance);
	`log("[HEMain]"$PlayerKFPC.PlayerReplicationInfo.PlayerName$" UID="$instance.UniqueID$" has been added into Players Array");
} 
//2. Returns Bool
//Re-initialize Players Array
//Check if there's player died last wave
//Return true if find and re-init him
function bool ReInitPlayersArry(Pawn P)
{
	local string					UID;
	local int						PlayerIndex;
	local bool						bIsDiedLastWave;
	local KFPawn_Human				PlayerKFPH;
	local KFPlayerController    	PlayerKFPC;
	local HEPlayer					TargetHEP;

	bIsDiedLastWave=False;
		
	PlayerKFPH=KFPawn_Human(P);
	PlayerKFPC=KFPlayerController(P.Controller);
	
	//Get UID
	UID=PlayerKFPC.GetOnlineSubsystem().UniqueNetIdToString(PlayerKFPC.PlayerReplicationInfo.UniqueId);
	`log("[HEMain::ReInitPlayersArry]Get UID of "$PlayerKFPC.PlayerReplicationInfo.PlayerName$" UID="$UID);
	//Check Players array to find him
	PlayerIndex = 0;
	ForEach Players(TargetHEP)
	{
		`log("[HEMain::ReInitPlayersArry]Current Players Name="$TargetHEP.KFPC.PlayerReplicationInfo.PlayerName$" UID="$TargetHEP.UniqueID);
		if(UID == TargetHEP.UniqueID)
		{
			bIsDiedLastWave = True;
			`log("[HEMain::ReInitPlayersArry]TargetHEP UID Matched. Player Index = "$PlayerIndex$". Starting Re-Initializing.");
			break;
		}
		
		++PlayerIndex;
	}
		
	//If player died last wave, update Player Info
	//HUD, HUDManager, TraderManager, doesn't need respawning again
	if(bIsDiedLastWave)
	{		
		//Update his new KFPH into the array
		Players[PlayerIndex].KFPC=PlayerKFPC;
		`log("[HEMain::ReInitPlayersArry]TargetHEP.KFPC sets to "$PlayerKFPC.Name$" with current value "$Players[PlayerIndex].KFPC.Name);
		Players[PlayerIndex].KFPH=PlayerKFPH;
		`log("[HEMain::ReInitPlayersArry]TargetHEP.KFPH sets to "$PlayerKFPH.Name$" with current value "$Players[PlayerIndex].KFPH.Name);
		
		//Set its perk class
		Players[PlayerIndex].LastPerk=PlayerKFPC.GetPerk().GetPerkClass();
		`log("[HEMain::ReInitPlayersArry]TargetHEP.LastPerk with current value "$Players[PlayerIndex].LastPerk.Name);
			
		Players[PlayerIndex].HUDManager.ClientAddChatLine("YOU DIED LAST WAVE", "B22222"); //Firebrick
		Players[PlayerIndex].HUDManager.ClientAddChatLine("KILLER: "$class'HE_Assistance'.static.ConvertMonsterClassName(PlayerKFPC.PWRI.ClassKilledByLastWave), "B22222"); //Firebrick
			
		return true;
	}
	else `log("[HEMain::ReInitPlayersArry]Player="$PlayerKFPC.PlayerReplicationInfo.PlayerName$" Is New To Game.");
	
	return false;
}
//3.
//Delete him from HEPlayer array and re-assign each instance's location
function NotifyPlayerExits(KFPlayerController KFPC)
{
	local HEPlayer TargetHEP;
	local string UID;
	
	if(KFPC == None)
	{
		`log("[HEMain]WARNING: Ghost Detected!");
		return;
	}
	
	//Find and remove him
	UID=KFPC.GetOnlineSubsystem().UniqueNetIdToString(KFPC.PlayerReplicationInfo.UniqueId);
	`log("[HEMain::NotifyPlayerExits]Exited Player Name="$KFPC.PlayerReplicationInfo.PlayerName$" UID="$UID);
	
	ForEach Players(TargetHEP)
	{
		`log("[HEMain::NotifyPlayerExits]Iterator TargetHEP Name="$TargetHEP.KFPC.PlayerReplicationInfo.PlayerName$" UID="$TargetHEP.UniqueID);
		if(TargetHEP.UniqueID == UID)
		{
			`log("[HEMain::NotifyPlayerExits]Exited Player UID Matched");
			
			Players.RemoveItem(TargetHEP);
			
			`log("[HEMain]ACTION: Exited player removed from Players Array.");
			
			ForEach Players(TargetHEP)
				`log("[HEMain]CHECK: Current Players Array Info:"$TargetHEP.KFPC.PlayerReplicationInfo.PlayerName$"-"$TargetHEP.UniqueID);
				
			break;
		}
	}
}

//*************************************************
//*  Broadcast Related
//*************************************************
//Initialization
//Set new BroadcastHandler
function SetBH() 
{
	if (HE_ChatController(MyKFGI.BroadcastHandler)==None) 
	{
		HECC=spawn(class'HE_ChatController');
		HECC.InitHEClass(Self);
		`log("[HEMain]Spawn HE_ChatController to "$MyKFGI.MyKFGRI);
	 	ClearTimer(nameof(SetBH));
	}
}

//1.
//Player Message
function PlayerMsg(KFPlayerController KFPC, coerce string msg, optional string MsgColor=RGB.HE_HUDDefaultCyan, optional name Type = 'ChatBox', optional bool bAutoPrefix = false)
{
	local HEPlayer HEP;
	foreach Players(HEP)
	{
		if(HEP.KFPC == KFPC)
		{
			if(Type == 'ChatBox')
				HEP.HUDManager.ClientAddChatLine(msg, MsgColor);
				//HEP.KFPC.MyGFxManager.PartyWidget.ReceiveMessage(msg, MsgColor);
			else if(Type == 'Console')
				HEP.HUDManager.ClientPrint(msg, bAutoPrefix);
			else if(Type == 'Center')
				HEP.HUDManager.ClientHUDMessage(msg);
			return;
		}
	}
}
//2.
//Global Player Message
function GlobalMsg(coerce string msg, optional string MsgColor=RGB.HE_HUDDefaultCyan, optional name Type = 'ChatBox', optional bool bAutoPrefix = false)
{
	local HEPlayer HEP;
	foreach Players(HEP)
	{
		if(Type == 'ChatBox')
			HEP.HUDManager.ClientAddChatLine(msg, MsgColor);
			//HEP.KFPC.MyGFxManager.PartyWidget.ReceiveMessage(msg, MsgColor);
		else if(Type == 'Console')
			HEP.HUDManager.ClientPrint(msg, bAutoPrefix);
		else if(Type == 'Center')
			HEP.HUDManager.ClientHUDMessage(msg);
	}
}
//Main Function
//Broadcast function
function Broadcast(PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string Msg) 
{
	local string MsgHead, Param;
	local array<String> splitbuf;
	
	ParseStringIntoArray(Msg,splitbuf," ",true);
	MsgHead = splitbuf[0];
	Param = splitbuf[splitbuf.Length-1];
	switch(MsgHead) 
	{
		case "!HESys":
			GlobalBroadcastHESysInfo();
			break;
		case "!HEBuyPerk":
			if(Param == "Help")
			{
				BroadcastBuyHelp(KFPlayerController(Receiver), MsgHead);
				break;
			}
			BuyPlayerWeapon(KFPlayerController(Receiver), Param, ,MsgHead);
			break;
		case "!HEInfo":
			GlobalBroadcastHEInfo();
			break;
		case "!HEDebug":
			BroadcastDebug(KFPlayerController(Receiver));
			break;
		case "!TK18039":
			GlobalMsg("TK18039 Meow Meow Meow ~ �ţ�3����",,'Center');
			break;
		case "!Fuck":
		case "!Fvck":
		case "!Fk":
			GlobalMsg("WHAT ARE YOU TALKING ABOUT ?","B22222");
			GlobalMsg("DOSH -25,000","B22222");
			KFPlayerReplicationInfo(KFPlayerController(Receiver).PlayerReplicationInfo).AddDosh(-25000);
			break;
	}
}

//Global broadcast HE System Info
function GlobalBroadcastHESysInfo()
{
	if(!bEnableHE)
	{
		GlobalMsg("[HealingExtend System Disabled]");
		return;
	}
	GlobalMsg("[HealingExtend System]");
	GlobalMsg("Best For CD Usage :D");
	GlobalMsg("MutVer:"$HEVI.Version);
	GlobalMsg("LastUpdate:"$HEVI.LastUpdate);
	GlobalMsg("--[HealingExtend System]--",,'Console');
	GlobalMsg("Best For CD Usage :D",,'Console');
	GlobalMsg("MutVer:"$HEVI.Version,,'Console');
	GlobalMsg("LastUpdate:"$HEVI.LastUpdate,,'Console');
}
//Global broadcast HE Info
function GlobalBroadcastHEInfo()
{
	if(!bEnableHE)
	{
		GlobalMsg("[HealingExtend System Disabled]");
		return;
	}
	GlobalMsg("[HealingExtend Config]");
	GlobalMsg("(Details See Console)");
	GlobalMsg("-----[HealingExtend Config]-----",,'Console');
	GlobalMsg("Current Health Regeneration Rate:"$fCurrentRegenRate$" Per second",,'Console');
	GlobalMsg("Health and Armor Decrement Modifier / Health and Armor Regeneration Modifier:"$DecreModifier$" / "$RegenModifier,,'Console');
	GlobalMsg("Is Enabled Health Regen(Ammount) / Is Enabled Armor Regen(Ammount):"$bEnableHealthRegen$"("$HealthRegenPerSecond$") / "$bEnableArmourRegen$"("$ArmourRegenPerSecond$")",,'Console');
	GlobalMsg("Health / Armor gain Ammount:"$HealthHealingAmount$" / "$ArmourHealingAmount,,'Console');
	GlobalMsg("Dosh Bonus Ammount:"$BonusDosh,,'Console');
	GlobalMsg("Maximum Overclocked Health / Maximum Overclocked Armor:"$OverclockHealthLimit$" / "$OverclockArmorLimit,,'Console');
	GlobalMsg("Is Recovering Ammo:"$bEnableAmmoRecovering,,'Console');
}

//Broadcast Buy Help
function BroadcastBuyHelp(KFPlayerController KFPC, string MsgHead)
{
	if(MsgHead == "!HEBuy")
	{
		PlayerMsg(KFPC, "--HE Quick Purchase Help--");
		PlayerMsg(KFPC, "=Current Supported Weapons=");
		PlayerMsg(KFPC, "M14EBR");
		PlayerMsg(KFPC, "AK12 / SCAR");
		PlayerMsg(KFPC, "HMT-401");
		PlayerMsg(KFPC, "M4 / AA12");
		PlayerMsg(KFPC, "P90 / HK-UMP / Kriss");
		PlayerMsg(KFPC, "Gunslinger QuickBuying Under Construction");
	}
	if(MsgHead == "!HEBuyPerk")
	{
		PlayerMsg(KFPC, "[HE Quick-Purchase]", "F8F8FF");
		PlayerMsg(KFPC, "[Press ALT+1 ALT+2 ALT+3]", "F8F8FF");
		switch(KFPC.GetPerk().Class)
		{
			case class'KFPerk_SharpShooter': PlayerMsg(KFPC, "(1)SPX 464 (2)M14EBR (3)Railgun", "FF69B4"); break;
			case class'KFPerk_Commando': PlayerMsg(KFPC, "(1)AK12 (2)SCAR (3)Stoner63A", "FF69B4"); break;
			case class'KFPerk_FieldMedic': PlayerMsg(KFPC, "(1)HMT-201 (2)HMT-301 (3)HMT-401", "FF69B4"); break;
			case class'KFPerk_Support': PlayerMsg(KFPC, "(1)DualB (2)M4 (3)AA12", "FF69B4"); break;
			case class'KFPerk_Swat': PlayerMsg(KFPC, "(1)P90 (2)HK-UMP (3)Kriss", "FF69B4"); break;
			case class'KFPerk_Gunslinger':
				if(bGsAltOneIsSPX)
					PlayerMsg(KFPC, "(1)SPX 464 (2)Deagle (3)SW500", "FF69B4");
				else
					PlayerMsg(KFPC, "(1)1911 (2)Deagle (3)SW500", "FF69B4");
					break;
		}
	}
}
//Broadcast Debug Info
function BroadcastDebug(KFPlayerController KFPC)
{
	local HEPlayer HEP;
	PlayerMsg(KFPC,"[Healing Extend Debug Info Full]",,'Console');
	//1.Players Array Details In Console
	PlayerMsg(KFPC,"----Players Array Details",,'Console');
	ForEach Players(HEP)
	{
		PlayerMsg(KFPC,"  --Player",,'Console');
		PlayerMsg(KFPC,"    PlayerName="$HEP.KFPC.PlayerReplicationInfo.PlayerName,,'Console');
		PlayerMsg(KFPC,"    PlayerUID="$HEP.UniqueID,,'Console');
		PlayerMsg(KFPC,"    PlayerKFPC="$HEP.KFPC.Name,,'Console');
		PlayerMsg(KFPC,"    PlayerKFPH="$HEP.KFPH.Name,,'Console');
	}
	//2.Network status
}

//Stop broadcasting
function bool StopBroadcast(string Msg) {
	local string MsgHead;
	local array<String> splitbuf;
	ParseStringIntoArray(Msg,splitbuf," ",true);
	MsgHead = splitbuf[0];
	switch(MsgHead) {
		case "!HEDebug":
		case "!HEBuy":
		case "!HEBuyPerk":
		case "!HETestStopBroadcast":
			return True;
	}
	return false;
}

//*************************************************
//*  KFPlayer's Weapons Related
//*************************************************
//Buy plyaer a weapon
function BuyPlayerWeapon(KFPlayerController KFPC, string ChatMsg, optional bool bFillAmmo = True, optional string MsgHead="!HEBuyPerk")
{
	local int				WeapPrice;
	local byte				TraderIndex;
	local int				FillDosh;
	local int				AmountPurchased;
	local bool				bFindWeap;
	//local STraderItem		WeaponItem;
	local class<KFWeapon>	KFW;
	local class<KFPerk>		PlayerPerk;
	local KFWeapon			KFWObj;
	local Inventory			Inv;
	
	WeapPrice=0;
	TraderIndex=-1;
	bFindWeap=false;
	
	//0.Check wave state
	if(MyKFGI.IsWaveActive())
	{
		//PlayerMsg(KFPC, "You Can't Buy It Now!","B22222",);
		return;
	}
	
	//1.Convert ChatMsg
	if(MsgHead == "!HEBuyPerk")
	{
		PlayerPerk = KFPC.GetPerk().Class;
		if(PlayerPerk == class'KFPerk_Commando')
		{
			if(ChatMsg=="One")
			{
				KFW=class'KFWeap_AssaultRifle_AK12';
				WeapPrice=1100;
				TraderIndex=9;
			}
			if(ChatMsg=="Two")
			{
				KFW=class'KFWeap_AssaultRifle_Scar';
				WeapPrice=1500;
				TraderIndex=10;
			}
			if(ChatMsg=="Three")
			{
				KFW=class'KFWeap_LMG_Stoner63A';
				WeapPrice=1500;
				TraderIndex=11;
			}
		}
		if(PlayerPerk == class'KFPerk_FieldMedic')
		{
			if(ChatMsg=="One")
			{
				KFW=class'KFWeap_SMG_Medic';
				WeapPrice=650;
				TraderIndex=18;
			}
			if(ChatMsg=="Two")
			{
				KFW=class'KFWeap_Shotgun_Medic';
				WeapPrice=1100;
				TraderIndex=19;
			}
			if(ChatMsg=="Three")
			{
				KFW=class'KFWeap_AssaultRifle_Medic';
				WeapPrice=1500;
				TraderIndex=20;
			}
		}
		if(PlayerPerk == class'KFPerk_Gunslinger')
		{
			if(ChatMsg=="One" && bGsAltOneIsSPX)
			{
				KFW=class'KFWeap_Pistol_DualColt1911';
				WeapPrice=650;
				TraderIndex=24;
			}
			else if(ChatMsg=="One" && !bGsAltOneIsSPX)
			{
				KFW=class'KFWeap_Rifle_CenterfireMB464';
				WeapPrice=650;
				TraderIndex=41;
			}
			
			if(ChatMsg=="Two")
			{
				KFW=class'KFWeap_Pistol_DualDeagle';
				WeapPrice=1100;
				TraderIndex=26;
			}
			if(ChatMsg=="Three")
			{
				KFW=class'KFWeap_Revolver_DualSW500';
				WeapPrice=1500;
				TraderIndex=28;
			}
		}
		if(PlayerPerk == class'KFPerk_Sharpshooter')
		{
			if(ChatMsg=="One")
			{
				KFW=class'KFWeap_Rifle_CenterfireMB464';
				WeapPrice=650;
				TraderIndex=41;
			}
			if(ChatMsg=="Two")
			{
				KFW=class'KFWeap_Rifle_M14EBR';
				WeapPrice=1100;
				TraderIndex=43;
			}
			if(ChatMsg=="Three")
			{
				KFW=class'KFWeap_Rifle_Railgun';
				WeapPrice=1500;
				TraderIndex=44;
			}
		}
		if(PlayerPerk == class'KFPerk_Support')
		{
			if(ChatMsg=="One")
			{
				KFW=class'KFWeap_Shotgun_DoubleBarrel';
				WeapPrice=650;
				TraderIndex=30;
			}
			if(ChatMsg=="Two")
			{
				KFW=class'KFWeap_Shotgun_M4';
				WeapPrice=1100;
				TraderIndex=32;
			}
			if(ChatMsg=="Three")
			{
				KFW=class'KFWeap_Shotgun_AA12';
				WeapPrice=1500;
				TraderIndex=33;
			}
		}
		if(PlayerPerk == class'KFPerk_SWAT')
		{
			if(ChatMsg=="One")
			{
				KFW=class'KFWeap_SMG_P90';
				WeapPrice=1100;
				TraderIndex=50;
			}
			if(ChatMsg=="Two")
			{
				KFW=class'KFWeap_SMG_HK_UMP';
				WeapPrice=1200;
				TraderIndex=54;
			}
			if(ChatMsg=="Three")
			{
				KFW=class'KFWeap_SMG_Kriss';
				WeapPrice=1500;
				TraderIndex=51;
			}
		}
	}
	if(TraderIndex == -1)
	{
		PlayerMsg(KFPC, "Wrong Parameter", "B22222",,);
		return;
	}
	
	//2.Already have?
	for (Inv = KFPC.GetPurchaseHelper().MyKFIM.InventoryChain; Inv != None; Inv = Inv.Inventory)
	{
		if(Inv.Class == KFW)
		{
			//PlayerMsg(KFPC, "You Owned This Weapon",,);
			bFindWeap=true;
			break;
		}
    }
    if(bFindWeap) return;
	
	//3.No money?
	if(KFPC.PlayerReplicationInfo.Score < WeapPrice)
	{
		//PlayerMsg(KFPC, "Out Of Dosh "$KFPC.PlayerReplicationInfo.Score$"/"$WeapPrice);
		return;
	}
	//`log("[HEMain]"$KFPC.PlayerReplicationInfo.PlayerName$" Affords Current Buy Price="$ WeapPrice );
	
	//4.Simulating trader buying process
		//4.1 Initialize
	KFPC.GetPurchaseHelper().Initialize();
		//4.2 Simulating trader-open state
	KFPC.GetPurchaseHelper().MyKFIM.bServerTraderMenuOpen=true;
			//4.3.1 Standalone game sound playing
	if(WorldInfo.NetMode == NM_Standalone)
		KFPC.MyGFxManager.PlaySoundFromTheme('TRADER_OPEN_MENU', 'UI');
			//4.3.2 Online session sound playing
	if(WorldInfo.NetMode == NM_DedicatedServer && Role == Role_Authority)
		GetHEP(KFPC).HUDManager.ClientPlaySoundFromTheme('TRADER_OPEN_MENU', 'UI');
		//4.4 Buy Weapon
	KFPC.GetPurchaseHelper().MyKFIM.ServerBuyWeapon(TraderIndex);
		//4.5 Simulating trader-closed state
	KFPC.GetPurchaseHelper().MyKFIM.ServerCloseTraderMenu();
		//4.6 Check and give ammo
		//AmmoNeed is SpareAmmoCapacity[0]-SpareAmmoOwned
	if(bFillAmmo)
	{
		//Give him enough dosh to fill ammo
		AmountPurchased=KFWeapon(KFPC.Pawn.Weapon).GetMaxAmmoAmount(0)-KFWeapon(KFPC.Pawn.Weapon).SpareAmmoCount[0];
		FillDosh= AmountPurchased 
			/ KFWeapon(KFPC.Pawn.Weapon).MagazineCapacity[0] 
			* KFGameReplicationInfo( WorldInfo.GRI ).TraderItems.SaleItems[TraderIndex].WeaponDef.default.AmmoPricePerMag;
		if(KFPC.PlayerReplicationInfo.Score <= FillDosh)
		{
			PlayerMsg(KFPC, "Horzine Tech LTD. Helps With Your Money", "DB7093");
			KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo).AddDosh( -KFPC.PlayerReplicationInfo.Score );
		}
		else
			KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo).AddDosh( -FillDosh );
			
		////Then buy ammo full
		//KFPC.GetPurchaseHelper().MyKFIM.BuyAmmo
		//(
			//AmountPurchased,
			//0,
			//TraderIndex,
			//false
		//);
		ForEach KFPC.Pawn.InvManager.InventoryActors(class'KFWeapon', KFWObj)
		{	
			if(!bFillAllWeapAmmoAfterQuickPurchase && KFWObj.Class == KFW)
			{
				KFWObj.AmmoCount[0] = KFWObj.MagazineCapacity[0];
				KFWObj.AddAmmo(KFWObj.GetMaxAmmoAmount(0));
			}
			else if(bFillAllWeapAmmoAfterQuickPurchase)
			{
				KFWObj.AmmoCount[0] = KFWObj.MagazineCapacity[0];
				KFWObj.AddAmmo(KFWObj.GetMaxAmmoAmount(0));
			}
			//KFWObj.AddSecondaryAmmo(KFWObj.MagazineCapacity[1]);
		}
	}
	KFPC.GetPurchaseHelper().MyKFIM.UpdateHUD();
}

//*************************************************
//*  Query Functions
//*************************************************
//Get HEP
//Returns null and -1 out-index if not find
function HEPlayer GetHEP(KFPlayerController KFPC, optional bool bMatchUID = False, optional out int PlayerIndex)
{
	local HEPlayer HEP;
	local string UID;

	for(PlayerIndex = 0; PlayerIndex < Players.Length; ++PlayerIndex)
	{
		HEP=Players[PlayerIndex];
		
		if(!bMatchUID && HEP.KFPC == KFPC)
			return HEP;
			
		if(bMatchUID)
		{
			UID=KFPC.GetOnlineSubsystem().UniqueNetIdToString(KFPC.PlayerReplicationInfo.UniqueId);
			if(UID == HEP.UniqueID)
				return HEP;
		}
	}
	
	PlayerIndex = -1;
	return HEP;
}

//Get HUD Manager
//Returns null if not find
function HE_HUDManager GetHUDManager(KFPlayerController KFPC)
{
	local HE_HUDManager tmp;
	
	ForEach WorldInfo.AllActors(class'HE_HUDManager', tmp)
	{
		`log("[HEMain::GetHUDManager]Querying Current HE_HUDManager Class="$tmp.Name$" Owner="$tmp.Owner);
		if(tmp.Owner == KFPC)
		{
			`log("[HEMain::GetHUDManager]Matched HE_HUDManager Class="$tmp.Name);
			if(tmp.KFPlayerOwner!=None)
				`log("[HEMain::GetHUDManager]Matched HE_HUDManager KFPlayerOwner ServerSide="$tmp.KFPlayerOwner.Name);
				
			return tmp;
		}
	}
	
	return tmp;
}
//*************************************************
//*  Healing Extend Main Funcion
//*************************************************
//Headshot Recover Function Version 1.1.3
//config-bool-control of the function
//let players who only want to use weapon related stuffs use HE as usual
function HeadshotRecover(int IteratorIndex)
{
	if(IteratorIndex >= Players.Length) return;
	
	if(bEnableHealthAndArmorOverclocking)
	{
		//Health
		if(Players[IteratorIndex].KFPH.Health > Players[IteratorIndex].KFPH.HealthMax)
			Players[IteratorIndex].KFPH.Health=Min
			(
				Players[IteratorIndex].KFPH.Health + 2 * HealthHealingAmount, 
				OverclockHealthLimit
			);
		else
			Players[IteratorIndex].KFPH.Health=Min
			(
				Players[IteratorIndex].KFPH.Health + HealthHealingAmount, 
				OverclockHealthLimit
			);
			
		//Armor
		if(Players[IteratorIndex].KFPH.Armor > Players[IteratorIndex].KFPH.MaxArmor)
			Players[IteratorIndex].KFPH.Armor=Min
			(
				Players[IteratorIndex].KFPH.Armor + 2 * ArmourHealingAmount, 
				OverclockArmorLimit
			);
		else
			Players[IteratorIndex].KFPH.Armor=Min
			(
				Players[IteratorIndex].KFPH.Armor + ArmourHealingAmount, 
				OverclockArmorLimit
			);
	}
	else
	{
		//Health default state
		Players[IteratorIndex].KFPH.Health=Min
		(
			Players[IteratorIndex].KFPH.Health + HealthHealingAmount, 
			Players[IteratorIndex].KFPH.HealthMax
		);
		
		//Armor default state
		Players[IteratorIndex].KFPH.Armor=Min
		(
			Players[IteratorIndex].KFPH.Armor+ ArmourHealingAmount,
			Players[IteratorIndex].KFPH.MaxArmor
		);
	}
}
//Tick Mutator
//i is from 1
function TickMutRecover(float DeltaTime, int IteratorIndex)
{	
	if(Players[IteratorIndex].KFPC == None 
		|| Players[IteratorIndex].KFPH == None
		|| IteratorIndex >= Players.Length
		)
		return;

	Players[IteratorIndex].KFWeap=KFWeapon(Players[IteratorIndex].KFPH.Weapon);
	
	//Infinite spare ammo
	if(bEnableInfiniteSpareAmmo && Players[IteratorIndex].KFWeap!=None)
	{
		Players[IteratorIndex].KFWeap.SpareAmmoCount[0]=Players[IteratorIndex].KFWeap.SpareAmmoCapacity[0];
		
		Players[IteratorIndex].KFWeap.ClientForceAmmoUpdate
		(
			Players[IteratorIndex].KFWeap.AmmoCount[0],
			Players[IteratorIndex].KFWeap.SpareAmmoCount[0]
		);
		
		Players[IteratorIndex].KFWeap.bNetDirty=True;
	}
	
	if(Players[IteratorIndex].fLastHeadshotCounts!=Players[IteratorIndex].KFPC.PWRI.VectData1.X)
	{
		//AAR_Dection Ammo Recovery
		if(bEnableAmmoRecovering && Players[IteratorIndex].KFWeap!=None)
		{

			Players[IteratorIndex].KFWeap.AmmoCount[0]+=Players[IteratorIndex].KFPC.PWRI.VectData1.X-Players[IteratorIndex].fLastHeadshotCounts;
			Players[IteratorIndex].KFWeap.AmmoCount[0]=Min
			(
				Players[IteratorIndex].KFWeap.AmmoCount[0], 
				Players[IteratorIndex].KFWeap.MagazineCapacity[0]
			);
			
			Players[IteratorIndex].KFWeap.ClientForceAmmoUpdate
			(
				Players[IteratorIndex].KFWeap.AmmoCount[0], 
				Players[IteratorIndex].KFWeap.SpareAmmoCount[0]
			);
			
			Players[IteratorIndex].KFWeap.bNetDirty=True;
		}
		//Add Dosh
		if(bEnableDoshBonus)
			KFPlayerReplicationInfo(Players[IteratorIndex].KFPC.PlayerReplicationInfo).AddDosh(BonusDosh);
		
		//AAR_Dection Health N Armor Recovering
		HeadshotRecover(IteratorIndex);
			
		//Set Last Headshot Counts
		Players[IteratorIndex].fLastHeadshotCounts=Players[IteratorIndex].KFPC.PWRI.VectData1.X;
	}
	
	//Record in ZedTime
	bInNormalTime=True;
	
	if(`IsInZedTime(self))
	{
		//If it's in zedtime then we call zedtime-actions
		//	and let the boolean value know that we're in zedtime
		bInNormalTime=False;
		
		//TO-DO: Functions called in ZedTime
	}
	
	//If the boolean tells that we're in zedtime(not in normal time)
	//	then this normal-time-action shouldn't be acted
	if(bInNormalTime)
	{
		//TO-DO: Functions called in NormalTime
	}
	//HEP.KFPC.ShotTarget = None;
}

//*************************************************
//*  Tick Time Update
//*************************************************
//Tick event
//version 1.1.3
//-Add health n' armor regeneration like Zerk
Event Tick(float DeltaTime)
{
	local int IteratorIndex;
	
	IteratorIndex = 0;
	for(IteratorIndex = 0; IteratorIndex < Players.Length; ++IteratorIndex)
	{
		//Prevent processing empty HEPlayer object
		if(Players[IteratorIndex].bIsEpt || Players[IteratorIndex].KFPH == None)
			continue;
		
		if(!Players[IteratorIndex].bIsEpt && bEnableHE)
			TickMutRecover(DeltaTime, IteratorIndex);
		
		//Tick overclock armor and health Decrement
		//Check health and armor state
		//Only decrease when overclocks
		if(Players[IteratorIndex].KFPH.Health > Players[IteratorIndex].KFPH.HealthMax)
		{
			Players[IteratorIndex].HealthDecrement += DecreModifier * HealthHealingAmount * DeltaTime;
			if(Players[IteratorIndex].HealthDecrement >= 1.f)
			{
				--Players[IteratorIndex].KFPH.Health;
				Players[IteratorIndex].HealthDecrement -= 1.f;
			}
		}
		if(Players[IteratorIndex].KFPH.Armor > Players[IteratorIndex].KFPH.MaxArmor)
		{
			Players[IteratorIndex].ArmorDecrement += DecreModifier * ArmourHealingAmount * DeltaTime;
			if(Players[IteratorIndex].ArmorDecrement >= 1.f)
			{
				--Players[IteratorIndex].KFPH.Armor;
				Players[IteratorIndex].ArmorDecrement -= 1.f;
			}
		}
		
		//Tick armor and health regen
		//Check health and armor state
		//Only regen when not in overclocking state
		if(bEnableHealthRegen && !Players[IteratorIndex].bIsEpt && bEnableHE)
		{
			if(Players[IteratorIndex].KFPH.Health < Players[IteratorIndex].KFPH.HealthMax)
			{
				Players[IteratorIndex].HealthRegenDelta += RegenModifier * HealthRegenPerSecond * DeltaTime;
				if(Players[IteratorIndex].HealthRegenDelta >= 1.f)
				{
					++Players[IteratorIndex].KFPH.Health;
					Players[IteratorIndex].HealthRegenDelta -= 1.f;
				}
			}
		}
		if(bEnableArmourRegen && !Players[IteratorIndex].bIsEpt && bEnableHE)
		{
			if(Players[IteratorIndex].KFPH.Armor < Players[IteratorIndex].KFPH.MaxArmor)
			{	
				Players[IteratorIndex].ArmorRegenDelta += RegenModifier * ArmourRegenPerSecond * DeltaTime;		
				if(Players[IteratorIndex].ArmorRegenDelta >= 1.f)
				{
					++Players[IteratorIndex].KFPH.Armor;
					Players[IteratorIndex].ArmorRegenDelta -= 1.f;
				}
			}
		}
	}
	
	super.Tick(DeltaTime);
}

defaultproperties
{
	//PlayerNumber=0
	bInNormalTime=True
	bCreatedBH=False
}