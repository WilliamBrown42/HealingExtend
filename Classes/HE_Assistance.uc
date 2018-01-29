//=============================================================================
// Healing Extend Mutator : Data Structure
// This class stores the basic data structures and variables of the mut
//
// Code And Concept By ArHShRn
// http://steamcommunity.com/id/ArHShRn/
//
// Version Release 1.1.1
//
// Last Update Date Oct.11th 2017
//=============================================================================
//=================================KFPC.PWRI========================================
//struct native PostWaveReplicationInfo
//{
//	var Vector 	VectData1; //used for compressing data //X:HeadShots Y:Dosh Earned Z:Damage Dealt
//	var Vector 	VectData2;	//used for compressing data //Damage Taken, Heals Received, Heals Given
//
//	var byte	LargeZedKills;
//	//Dialog
//	var bool 	bDiedDuringWave;
//	var bool	bBestTeammate;
//	var bool	bKilledMostZeds;
//	var bool	bEarnedMostDosh;
//	var bool	bAllSurvivedLastWave;
//	var bool	bSomeSurvivedLastWave;
//	var bool	bOneSurvivedLastWave;
//	var bool	bKilledFleshpoundLastWave;
//	var bool	bKilledScrakeLastWave;
//	/** Work-around so we don't have to wait for GRI.OpenTrader() to determine dialog */
//	var bool    bOpeningTrader;
//
//	var class< KFPawn_Monster > ClassKilledByLastWave;
//
//	var byte	RepCount;
//};
//=============================================================================
class HE_Assistance extends Object
	Abstract;

/**
  *Every player in the game should have a Healing Extend structure
  *to restore the info he has
*/
struct HEPlayer
{
	//Player Identification
	var string					UniqueID;
	//Headshot Recover : Target Relative
	var Pawn					pShotTarget;			//	A shot target
	var Pawn					LastTarget;				//	His last zed target
	var KFPawn_Monster			KFPM_Victim;			//	Zed victim
	var KFWeapon				KFWeap;					//  Weapon in hand
	//Headshot Recover : Player Relative
	var KFPlayerReplicationInfo	KFPRI;
	var KFPlayerController		KFPC;
	var KFPawn_Human			KFPH;
	var int						fLastHSC;				//  Last AAR Headshots Ammout
	var class<KFPerk>			LastPerk;
	//Player Health Pool
	var float					HealthDecrement;
	var float					ArmorDecrement;
	
	//Actor Relative
	var HE_HUDManager			HUDManager;
	var HE_TraderManager		TraderManager;
	
	//Structure Relative
	var int						Index;					//  Shows his Index
	var bool					bIsEpt;
};

struct HEVersionInfo
{
	var string					ThisMutatorName;
	var string					AuthorNickname;
	var string					AuthorSteamcommunityURL;
	var string					Version;
	var string					LastUpdate;
};

struct HECommand
{
	var string					CommandHead;
	var string					UserName;
	var string					Argument;
	var string					Parameter;
	var string					Value;
};

enum HUDCrosshairStatus
{
	HE_Good,
	HE_WeapNotGuns,
	HE_Player_Closed,
	HE_Player_Dead,
	HE_Player_NoWeap,
	HE_Player_Monster,
	HE_Player_UsingIronsight,
	HE_Player_SpecialMoveDontAllow,
	HE_NoneInit
};

enum AsCMode
{
	AsC_Default,
	AsC_CenterDot,
	AsC_OnlyDot
};

struct HEConfig
{
	//Mutator Version
	var HEVersionInfo			HEVI;
	//System Variable Configs
	var float					fCurrentRegenRate;
	var bool					bAllowOverClocking;	
	var bool					bInitedConfig;
	var bool					bRecoverAmmo;	
	var bool					bEnableAAR_Headshots;
	var bool					bGetDosh;
	 
	//Common Settings
	var int						HealthHealingAmount;
	var int						ArmourHealingAmount;
	var int						AmmoRecoverAmout;
	var int						BonusDosh;
	var int						OverclockLimitHealth;
	var int						OverclockLimitArmour;

};

struct WeaponInfo
{
	var class<KFWeaponDefinition>	WeapDefClass;
	var class<KFWeapon>				WeapClass;
	
	var byte						WeapTraderIndex;
	var string						WeapName;
	var int							BuyPrice;
	var int							AmmoPricePerMag;
	var int							AmmoPricePerProjectile;
};

static function string ConvertMonsterClassName(class<KFPawn_Monster> zed)
{
	switch(zed)
	{
		case class'KFPawn_ZedBloat': return "Bloat";
		case class'KFPawn_ZedClot': return "Clot";
		case class'KFPawn_ZedCrawler': return "Crawler";
		case class'KFPawn_ZedFleshpound': return "Fleshpound";
		case class'KFPawn_ZedGorefast': return "Gorefast";
		case class'KFPawn_ZedHusk': return "Husk";
		case class'KFPawn_ZedScrake': return "Scrake";
		case class'KFPawn_ZedSiren': return "Siren";
		case class'KFPawn_ZedStalker': return "Stalker";
		default: return string(zed.Name);
	}
} 
defaultproperties
{
}