Scriptname vBBS_MetaQuestScript extends Quest  
{Check for compatible mods and take steps accordingly}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Actor Property PlayerRef Auto

Int Property ModVersion Auto

Message Property vBBS_ModLoadedMSG Auto
Message Property vBBS_ModUpdatedMSG Auto
Message Property vBBS_RNDPluginLoadedMSG Auto
Message Property vBBS_RNDPluginMissingMSGBox Auto

MiscObject Property vBBS_JarOBeans Auto
Potion Property vBBS_FoodBakedBeans Auto
Potion Property vBBS_FoodBeanChili Auto

Spell Property vBBS_BellyFullaBeansSpell Auto

Formlist Property vBBS_GassyFood Auto
Formlist Property vBBS_STUPIDGassyFood Auto
Formlist Property vBBS_DairyFood Auto
Formlist Property vBBS_RawMeatFood Auto

LeveledItem Property LItemFoodInnCommon Auto
LeveledItem Property LItemFoodInnCommon10 Auto
LeveledItem Property LItemIngredientFoodPrepared Auto
LeveledItem Property LItemBarrelFoodSame70 Auto

LeveledItem Property vBBS_FoodBakedBeansLL Auto
LeveledItem Property vBBS_FoodBakedBeansJarOnly30LL Auto
LeveledItem Property vBBS_FoodBakedBeansNoJar30LL Auto

FormList Property vBBS_BeanContainers Auto
FormList Property vBBS_BeanLists Auto
FormList Property vBBS_BeanNoJarLists Auto
FormList Property vBBS_BeanJarOnlyLists Auto

Quest Property vBBS_GasTrackingQuest Auto

;Legacy, do not remove
vBBS_BellyFullaBeansMEScript Property GasScript Auto Hidden

vBBS_PlayerGasTracker Property GasTracker Auto Hidden

Bool Property GasEnabled Hidden
	Bool Function Get()
		Return vBBS_GasTrackingQuest.IsRunning()
	EndFunction
	Function Set(Bool abEnable)
		Debug.Trace("BBS: GasEnabled was set to " + abEnable)
		If vBBS_GasTrackingQuest.IsRunning()
			vBBS_GasTrackingQuest.Stop()
		EndIf
		If abEnable
			vBBS_GasTrackingQuest.Start()
		EndIf
	EndFunction
EndProperty

;--=== Configuration ===--

GlobalVariable Property vBBS_Enabled Auto
{Master enable. Disabling this halts all gas.}

;--=== Variables ===--

Int _CurrentVersion

Bool _Running

Bool _hasFrostFall = False
Bool _hasRND = False

Bool _RNDPatchMsgShown = False

Float _StartTime
Float _EndTime

;--=== Events ===--

Event OnInit()
	If ModVersion == 0
		DoUpkeep(True)
	EndIf
EndEvent

Event OnReset()
	Debug.Trace("BBS: Metaquest event: OnReset")
EndEvent

Event OnUpdateGameTime()
	;Do Nothing
	UnregisterForUpdateGameTime()
EndEvent

;--=== Functions ===--

Function Register(vBBS_PlayerGasTracker akNewScript)
	GasTracker = akNewScript
	Debug.Trace("BBS: GasTracker is now " + akNewScript)
EndFunction

Function DoUpkeep(Bool DelayedStart = True)
	;FIXME: CHANGE THIS WHEN UPDATING!
	_CurrentVersion = 108
	String sErrorMessage
	If DelayedStart
		Wait(RandomFloat(2,4))
	EndIf
	Debug.Trace("BBS: Performing upkeep...")
	Debug.Trace("BBS: Loaded version is " + ModVersion + ", Current version is " + _CurrentVersion)
	If ModVersion == 0
		Debug.Trace("BBS: Newly installed, doing initialization...")
		DoInit()
		If ModVersion == _CurrentVersion
			Debug.Trace("BBS: Initialization succeeded.")
		Else
			Debug.Trace("BBS: WARNING! Initialization had a problem!")
		EndIf
	ElseIf ModVersion < _CurrentVersion
		Debug.Trace("BBS: Installed version is older. Starting the upgrade...")
		DoUpgrade()
		If ModVersion != _CurrentVersion
			Debug.Trace("BBS: WARNING! Upgrade failed!")
			;Debug.MessageBox("WARNING! The Baked Beans of Skyrim upgrade failed for some reason. You should report this to the mod author.")
		EndIf
		Debug.Trace("BBS: Upgraded to " + _CurrentVersion)
		vBBS_ModUpdatedMSG.Show((_CurrentVersion as Float) / 100.0)
	Else
		Debug.Trace("BBS: Loaded, no updates.")
		;CheckForOrphans()
	EndIf
	CheckForExtras()
	;FillContainers()
	Debug.Trace("BBS: Upkeep complete!")
EndFunction

Function DoInit()
	Debug.Trace("BBS: Initializing...")
	PopulateLists()
	;FillContainers()
	GasEnabled = True
	_Running = True
	ModVersion = _CurrentVersion
	vBBS_ModLoadedMSG.Show((_CurrentVersion as Float) / 100.0)
EndFunction

Function DoShutdown()
	_Running = False
	GasEnabled = False
	ModVersion = 0
	_CurrentVersion = 0
EndFunction

Function PopulateLists()
	
	Int i = vBBS_BeanLists.GetSize()
	While i > 0
		i -= 1
		Debug.Trace("BBS: Adding beans and jars to " + vBBS_BeanLists.GetAt(i))
		(vBBS_BeanLists.GetAt(i) as LeveledItem).AddForm(vBBS_FoodBakedBeansLL,1,2)
	EndWhile
	
	i = vBBS_BeanNoJarLists.GetSize()
	While i > 0
		i -= 1
		Debug.Trace("BBS: Adding beans to " + vBBS_BeanNoJarLists.GetAt(i))
		(vBBS_BeanNoJarLists.GetAt(i) as LeveledItem).AddForm(vBBS_FoodBakedBeansNoJar30LL,1,1)
	EndWhile
	
	i = vBBS_BeanJarOnlyLists.GetSize()
	While i > 0
		i -= 1
		Debug.Trace("BBS: Adding jar of beans to " + vBBS_BeanJarOnlyLists.GetAt(i))
		(vBBS_BeanJarOnlyLists.GetAt(i) as LeveledItem).AddForm(vBBS_FoodBakedBeansJarOnly30LL,1,1)
	EndWhile
	
EndFunction

Function FillContainers()
	Int i = vBBS_BeanContainers.GetSize()
	While i > 0
		i -= 1
		ObjectReference kBeanContainer = vBBS_BeanContainers.GetAt(i) as ObjectReference
		If kBeanContainer.GetItemCount(vBBS_JarOBeans) == 0
			Debug.Trace("BBS: Adding vBBS_FoodBakedBeansLL to " + kBeanContainer)
			kBeanContainer.AddItem(vBBS_FoodBakedBeansLL,RandomInt(1,3),True)
		EndIf
	EndWhile
EndFunction

Function DoUpgrade()
	_Running = False
	If ModVersion < 108
		Debug.Trace("BBS: Upgrading to version 1.08")
		PlayerREF.RemoveSpell(vBBS_BellyFullaBeansSpell)
		If vBBS_Enabled.GetValue() > 0
			vBBS_GasTrackingQuest.Start()
		EndIf
		ModVersion = 108
	EndIf
	_Running = True
	Debug.Trace("BBS: Upgrade complete!")
EndFunction

Function CheckForExtras()
	Debug.Trace("BBS: Checking for compatible mods, ignore any errors that follow!")

	vBBS_GassyFood.Revert()
	vBBS_STUPIDGassyFood.Revert()
	vBBS_DairyFood.Revert()
	vBBS_RawMeatFood.Revert()
	
	CheckHearthfire()
	CheckDragonborn()
	CheckFrostfall()
	CheckOsareFood()
	CheckCookingExpanded()
	CheckBabettesFeast()
	CheckRND()
	CheckINeed()
	CheckIMCN()
	CheckZFPM()
	CheckEatAndSleep()
	CheckRealWildlifeSkyrim	()
	CheckRealisticWildlifeLoot()
	
	Debug.Trace("BBS: Gassy foods: " + vBBS_GassyFood.GetSize())
	Debug.Trace("BBS: STUPID Gassy foods: " + vBBS_STUPIDGassyFood.GetSize())
	Debug.Trace("BBS: Dairy foods: " + vBBS_STUPIDGassyFood.GetSize())
	Debug.Trace("BBS: Raw meat foods: " + vBBS_STUPIDGassyFood.GetSize())
	
	;Debug.Trace("BBS: Gassy foods follow------")
	;Int i = vBBS_GassyFood.GetSize()
	;While i > 0
		;i -= 1
		;Debug.trace("BBS:     " + vBBS_GassyFood.GetAt(i).GetName())
	;EndWhile
	;Debug.Trace("BBS: STUPID Gassy foods follow------")
	;i = vBBS_STUPIDGassyFood.GetSize()
	;While i > 0
		;i -= 1
		;Debug.trace("BBS:     " + vBBS_STUPIDGassyFood.GetAt(i).GetName())
	;EndWhile
	Debug.Trace("BBS: Finished checking for compatible mods!")
EndFunction

Function CheckHearthfire()
	String sModName = "Hearthfire"
	String sModFilename = "Hearthfires.esm"
	Debug.Trace("BBS: Checking for " + sModName + "...")
	
	Form kHFItem = GetFormFromFile(0x010009DC,sModFilename)
	If kHFItem
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding foods to list!")	
		;.AddForm(GetFormFromFile(0x010009DB,sModFilename)) ; Braided Bread
		vBBS_DairyFood.AddForm(GetFormFromFile(0x01003534,sModFilename)) ; Jug of Milk
		;.AddForm(GetFormFromFile(0x01003535,sModFilename)) ; Argonian Bloodwine
		;.AddForm(GetFormFromFile(0x01003536,sModFilename)) ; Surilie Brothers Wine
		;.AddForm(GetFormFromFile(0x01003539,sModFilename)) ; Juniper Berry Crostata
		;.AddForm(GetFormFromFile(0x0100353A,sModFilename)) ; Jazbay Crostata
		;.AddForm(GetFormFromFile(0x0100353B,sModFilename)) ; Snowberry Crostata
		vBBS_DairyFood.AddForm(GetFormFromFile(0x0100353C,sModFilename)) ; Butter
		;.AddForm(GetFormFromFile(0x0100353F,sModFilename)) ; Steamed Mudcrab Legs
		;.AddForm(GetFormFromFile(0x01003541,sModFilename)) ; Salmon Steak
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010009DC,sModFilename)) ; Garlic Bread
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01003533,sModFilename)) ; Apple Dumpling
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01003537,sModFilename)) ; Potato Bread
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01003538,sModFilename)) ; Sack of Flour
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01003540,sModFilename)) ; Mudcrab Legs
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01011801,sModFilename)) ; Lavender Dumpling
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0100353D,sModFilename)) ; Potato Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0100353E,sModFilename)) ; Clam Chowder
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x010117FF,sModFilename)) ; Chicken Dumpling
	EndIf
EndFunction

Function CheckDragonBorn()
	Debug.Trace("BBS: Checking for Dragonborn...")
	Form kDragonBornItem = GetFormFromFile(0x0203CF72,"Dragonborn.esm")
	If kDragonBornItem
		Debug.Trace("BBS: Dragonborn (Dragonborn.esm) detected, adding foods to list!")	
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0203CF72,"Dragonborn.esm")) ; Cooked Boar Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0203CD5B,"Dragonborn.esm")) ; Horker and Ash Yam Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0203BD15,"Dragonborn.esm")) ; Ash Hopper Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0203BD14,"Dragonborn.esm")) ; Boar Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x020206E7,"Dragonborn.esm")) ; Ash Yam
	EndIf
EndFunction

Function CheckFrostfall()
	Debug.Trace("BBS: Checking for Frostfall...")
	FormList _DE_Foods10 
	FormList _DE_Foods15
	_DE_Foods10 = GetFormFromFile(0x02041b3e,"Chesko_Frostfall.esp") as FormList
	If _DE_Foods10 && !_hasFrostFall; Frostfall is loaded!
		Debug.Trace("BBS: FrostFall detected, adding Beans to _DE_Foods10")
		_DE_Foods10.AddForm(vBBS_FoodBakedBeans)
		_DE_Foods10 = GetFormFromFile(0x02041b3e,"Chesko_Frostfall.esp") as FormList
		Debug.Trace("BBS: FrostFall detected, adding Bean Chili to _DE_Foods15")
		_DE_Foods15 = GetFormFromFile(0x02041b3c,"Chesko_Frostfall.esp") as FormList
		Debug.Trace("BBS: _DE_Foods10 has baked beans: " + _DE_Foods10.HasForm(vBBS_FoodBakedBeans))
		Debug.Trace("BBS: _DE_Foods15 has bean chili : " + _DE_Foods15.HasForm(vBBS_FoodBeanChili))
		_hasFrostFall = True
	ElseIf _hasFrostFall
		Debug.Trace("BBS: _DE_Foods10 has baked beans: " + _DE_Foods10.HasForm(vBBS_FoodBakedBeans))
		Debug.Trace("BBS: _DE_Foods15 has bean chili : " + _DE_Foods15.HasForm(vBBS_FoodBeanChili))
	ElseIf !_DE_Foods10
		_hasFrostFall = False
	EndIf
EndFunction

Function CheckOsareFood()
	Debug.Trace("BBS: Checking for Osare Food...")
	Form kOsareItem = GetFormFromFile(0x01000d62,"Osare Food.esp")
	If kOsareItem
		Debug.Trace("BBS: Osare Food (Osare Food.esp) detected, adding foods to list!")
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x01000d63,"Osare Food.esp")) ; Beef Curry
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010012cc,"Osare Food.esp")) ; Riceball of Salmon
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100332b,"Osare Food.esp")) ; Rice
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x01003893,"Osare Food.esp")) ; Fried egg
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0100435d,"Osare Food.esp")) ; Laputa toast
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010048c2,"Osare Food.esp")) ; French fries
		vBBS_DairyFood.AddForm(GetFormFromFile(0x01004e27,"Osare Food.esp")) ; Flan
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100538c,"Osare Food.esp")) ; Meat spaghetti
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01005e56,"Osare Food.esp")) ; Onion
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01006920,"Osare Food.esp")) ; Hamburger
	EndIf
EndFunction

Function CheckCookingExpanded()
	Debug.Trace("BBS: Checking for Cooking Expanded...")
	Form kCEItem = GetFormFromFile(0x02000801,"CookingExpanded.esp")
	If kCEItem
		Debug.Trace("BBS: Cooking Expanded (CookingExpanded.esp) detected, adding foods to list!")
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02000801,"CookingExpanded.esp")) ; Hunter's Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02001002,"CookingExpanded.esp")) ; Mammoth Fondue
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02001deb,"CookingExpanded.esp")) ; Dogmeat Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02002e1d,"CookingExpanded.esp")) ; Equine Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02cd0002,"CookingExpanded.esp")) ; Boiled Egg
		vBBS_DairyFood.AddForm(GetFormFromFile(0x02cd0004,"CookingExpanded.esp")) ; Stuffed Gourd
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02cd0005,"CookingExpanded.esp")) ; Goat Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02cd0006,"CookingExpanded.esp")) ; Steamed Clams
	EndIf
EndFunction

Function CheckBabettesFeast()
	Debug.Trace("BBS: Checking for Babette's Feast...")
	String sBFVersion
	If GetFormFromFile(0x01001000,"Babettes Feast v1_2.esp")
		sBFVersion = "Babettes Feast v1_2.esp"
	ElseIf GetFormFromFile(0x01001000,"BabettesFeastBalanced.esp")
		sBFVersion = "BabettesFeastBalanced.esp"
	ElseIf GetFormFromFile(0x01001000,"BabettesFeastOverpowered.esp")
		sBFVersion = "BabettesFeastOverpowered.esp"
	ElseIf GetFormFromFile(0x01001000,"BabettesFeastWeakerEffects.esp")
		sBFVersion = "BabettesFeastWeakerEffects.esp"
	EndIf
	If sBFVersion
		Debug.Trace("BBS: Babette's Feast (" + sBFVersion + ") detected, adding foods to list!")
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x01001001,sBFVersion)) ; Beer Battered Spade
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x01001003,sBFVersion)) ; Clam Chowder
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001004,sBFVersion)) ; Snowberry Pie
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001008,sBFVersion)) ; Beef Stroganius
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001009,sBFVersion)) ; Savory Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x01001010,sBFVersion)) ; Mushroom and cheese quiche
		vBBS_DairyFood.AddForm(GetFormFromFile(0x01001010,sBFVersion)) ; Mushroom and cheese quiche - for lactose intolerance
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x01001011,sBFVersion)) ; Gravlaks
	EndIf
EndFunction

Function CheckRND()
	Debug.Trace("BBS: Checking for Realistic Needs and Diseases...")
	Form kRNDItem = GetFormFromFile(0x02007F5A,"RealisticNeedsandDiseases.esp")
	If kRNDItem
		Debug.Trace("BBS: Realistic Needs and Diseases (RealisticNeedsandDiseases.esp) detected, adding foods to list!")
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02007F5A,"RealisticNeedsandDiseases.esp")) ; Stale Leg of Goat Roast
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02007F5B,"RealisticNeedsandDiseases.esp")) ; Stale Seared Slaughterfish
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02007F5F,"RealisticNeedsandDiseases.esp")) ; Stale Pheasant Roast
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02012C49,"RealisticNeedsandDiseases.esp")) ; +Sugar Ball
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02015CC9,"RealisticNeedsandDiseases.esp")) ; Salmon Chowder
		vBBS_DairyFood.AddForm(GetFormFromFile(0x02015CC9,"RealisticNeedsandDiseases.esp")) ; Salmon Chowder - lactose intolerance
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02016CF5,"RealisticNeedsandDiseases.esp")) ; Dog Meat Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0201EE56,"RealisticNeedsandDiseases.esp")) ; Stale Grilled Leeks
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0203D88E,"RealisticNeedsandDiseases.esp")) ; Rabbit Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0203D890,"RealisticNeedsandDiseases.esp")) ; Pheasant Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0203DDF4,"RealisticNeedsandDiseases.esp")) ; Chicken Soup
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0205FE2B,"RealisticNeedsandDiseases.esp")) ; Charred Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x020936B9,"RealisticNeedsandDiseases.esp")) ; Wolf Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x020936BA,"RealisticNeedsandDiseases.esp")) ; Mammoth Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x020936BB,"RealisticNeedsandDiseases.esp")) ; SabreCat Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x020936BC,"RealisticNeedsandDiseases.esp")) ; Bear Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x020987BE,"RealisticNeedsandDiseases.esp")) ; Bear Roast
		vBBS_GassyFood.AddForm(GetFormFromFile(0x020987C6,"RealisticNeedsandDiseases.esp")) ; Mammoth Steak
		vBBS_GassyFood.AddForm(GetFormFromFile(0x020987C8,"RealisticNeedsandDiseases.esp")) ; Hunter's Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02007F4E,"RealisticNeedsandDiseases.esp")) ; Stale Cabbage
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02007F53,"RealisticNeedsandDiseases.esp")) ; Rotten Tomato
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02007F58,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02007F5D,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02007F61,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02016CF2,"RealisticNeedsandDiseases.esp")) ; Leek Potato Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0202140E,"RealisticNeedsandDiseases.esp")) ; Stale Baked Potatoes
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02022EFB,"RealisticNeedsandDiseases.esp")) ; Old Potato
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0206F622,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0206F628,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0206F62A,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0206F62C,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0206F630,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0206F639,"RealisticNeedsandDiseases.esp")) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x020803AB,"RealisticNeedsandDiseases.esp")) ; Spoiled Junk
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0207471D,"RealisticNeedsandDiseases.esp")) ; Spoiled Junk
		
		_HasRND = True
		
		Keyword RND_SpoilageCategory7 = GetFormFromFile(0x0206A52F,"RealisticNeedsandDiseases.esp") as Keyword

		If !_RNDPatchMsgShown
			If !vBBS_FoodBakedBeans.HasKeyword(RND_SpoilageCategory7)
				Debug.Trace("BBS: Realistic Needs and Diseases patch DOES NOT appear to be loaded!")
				vBBS_RNDPluginMissingMSGBox.Show()
				_RNDPatchMsgShown = True
			Else
				Debug.Trace("BBS: Realistic Needs and Diseases patch appears to be loaded!")
				;vBBS_RNDPluginLoadedMSG.Show()
				;_RNDPatchMsgShown = True
			EndIf
		EndIf
	Else ; RND is not installed
		_HasRND = False
		_RNDPatchMsgShown = False ; Reset message status in case player reinstalls RND later
	EndIf
EndFunction

Function CheckINeed()
	String sModName = "iNeed"
	String sModFilename = "iNeed.esp"
	Debug.Trace("BBS: Checking for " + sModName + "...")
	
	Form kTestItem = GetFormFromFile(0x02000D6C,sModFilename)
	If kTestItem
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding beans to the Medium Meals formlist!")
		FormList _SNFood_MedList = GetFormFromFile(0x02000D6C,sModFilename) as Formlist
		FormList _SNFood_HeavyList = GetFormFromFile(0x02000D69,sModFilename) as Formlist
		If !_SNFood_MedList.HasForm(vBBS_FoodBakedBeans)
			_SNFood_MedList.AddForm(vBBS_FoodBakedBeans)
		EndIf
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding bean chili to the Heavy Meals formlist!")
		If !_SNFood_HeavyList.HasForm(vBBS_FoodBeanChili)
			_SNFood_HeavyList.AddForm(vBBS_FoodBeanChili)
		EndIf
	EndIf
EndFunction

Function CheckIMCN()
	String sModName = "Imp's More Complex Needs"
	String sModFilename = "Imp's More Complex Needs.esp"
	Debug.Trace("BBS: Checking for " + sModName + "...")
	
	Form kTestItem = GetFormFromFile(0x052462CE,sModFilename)
	If kTestItem
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding foods to list!")	
		;.AddForm(GetFormFromFile(0x02004E2B,sModFilename)) ; +IMCN Vitality+
		;.AddForm(GetFormFromFile(0x02004E2E,sModFilename)) ; +IMCN Configuration+
		;.AddForm(GetFormFromFile(0x020176A1,sModFilename)) ; +IMCN Conditions+
		;.AddForm(GetFormFromFile(0x020238C5,sModFilename)) ; Water
		;.AddForm(GetFormFromFile(0x02023E39,sModFilename)) ; Tea
		;.AddForm(GetFormFromFile(0x020386DF,sModFilename)) ; Warm Food
		;.AddForm(GetFormFromFile(0x0204DB8B,sModFilename)) ; Dried Salmon
		;.AddForm(GetFormFromFile(0x0204DB91,sModFilename)) ; Dried Goat Meat
		;.AddForm(GetFormFromFile(0x0204DB93,sModFilename)) ; Dried Mammoth Snout
		;.AddForm(GetFormFromFile(0x0205CF47,sModFilename)) ; Hide Waterskin - Full
		;.AddForm(GetFormFromFile(0x0205CF49,sModFilename)) ; Hide Waterskin - Three Quarters Full
		;.AddForm(GetFormFromFile(0x0205CF4B,sModFilename)) ; Hide Waterskin - Half Full
		;.AddForm(GetFormFromFile(0x0205CF4D,sModFilename)) ; Hide Waterskin - One Quarter Full
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02023E37,sModFilename)) ; Coffee
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0204DB8D,sModFilename)) ; Dried Beef
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0204DB8F,sModFilename)) ; Dried Venison
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0204246C,sModFilename)) ; Grilled Clam
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02042F3E,sModFilename)) ; Spoiled Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02042F40,sModFilename)) ; Spoiled Produce
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02042F42,sModFilename)) ; Spoiled Food
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0204F695,sModFilename)) ; Spoiled Food
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x02064B2D,sModFilename)) ; Raw Human Flesh
	EndIf

EndFunction

Function CheckZFPM()
	String sModName = "ZF Primary Needs"
	String sModFilename = "ZF Primary Needs.esp"
	Debug.Trace("BBS: Checking for " + sModName + "...")
	
	Form kTestItem = GetFormFromFile(0x052462CE,sModFilename)
	If kTestItem
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding foods to list!")	
		;.AddForm(GetFormFromFile(0x05005E7B,sModFilename)) ; Water
		;.AddForm(GetFormFromFile(0x0512E877,sModFilename)) ; Sabrecat Eye Soup
		;.AddForm(GetFormFromFile(0x0512E879,sModFilename)) ; Slaughterfish Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05144D03,sModFilename)) ; Dirty Water - Gas from disease?
		;.AddForm(GetFormFromFile(0x052462C4,sModFilename)) ; Honey Biscuit
		;.AddForm(GetFormFromFile(0x052462C6,sModFilename)) ; Black Bread
		;.AddForm(GetFormFromFile(0x052462CC,sModFilename)) ; White Bread
		;.AddForm(GetFormFromFile(0x052462D2,sModFilename)) ; Spice Cake
		;.AddForm(GetFormFromFile(0x0524B3EB,sModFilename)) ; Fish Stew
		;.AddForm(GetFormFromFile(0x0524B3ED,sModFilename)) ; Licorice Sweet
		;.AddForm(GetFormFromFile(0x0524B3F3,sModFilename)) ; Sugar
		;.AddForm(GetFormFromFile(0x052504F6,sModFilename)) ; Apple Cider
		;.AddForm(GetFormFromFile(0x052504F7,sModFilename)) ; Barley Tea
		;.AddForm(GetFormFromFile(0x052504F9,sModFilename)) ; Blackwine
		;.AddForm(GetFormFromFile(0x0529225F,sModFilename)) ; Waterskin (Full of Water)
		;.AddForm(GetFormFromFile(0x05292260,sModFilename)) ; Waterskin (Almost Half of Water)
		;.AddForm(GetFormFromFile(0x05292262,sModFilename)) ; Waterskin (Almost Empty of Water)
		;.AddForm(GetFormFromFile(0x05292264,sModFilename)) ; Waterskin (Almost Empty of Black-Briar Mead)
		;.AddForm(GetFormFromFile(0x05292268,sModFilename)) ; Waterskin (Full of Black-Briar Mead)
		;.AddForm(GetFormFromFile(0x0529226A,sModFilename)) ; Waterskin (Almost Half of Black-Briar Mead)
		;.AddForm(GetFormFromFile(0x0529C47B,sModFilename)) ; Waterskin (Full of Honningbrew Mead)
		;.AddForm(GetFormFromFile(0x0529C47D,sModFilename)) ; Waterskin (Almost Half of Honningbrew Mead)
		;.AddForm(GetFormFromFile(0x0529C47F,sModFilename)) ; Waterskin (Almost Empty of Honningbrew Mead)
		;.AddForm(GetFormFromFile(0x0529C483,sModFilename)) ; Waterskin (Full of Nord Mead)
		;.AddForm(GetFormFromFile(0x0529C485,sModFilename)) ; Waterskin (Almost Half of Nord Mead)
		;.AddForm(GetFormFromFile(0x0529C488,sModFilename)) ; Waterskin (Almost Empty of Nord Mead)
		;.AddForm(GetFormFromFile(0x052BFBA2,sModFilename)) ; Waterskin (Full of Black-Briar Reserve)
		;.AddForm(GetFormFromFile(0x052BFBA3,sModFilename)) ; Waterskin (Almost Half of Black-Briar Reserve)
		;.AddForm(GetFormFromFile(0x052BFBA5,sModFilename)) ; Waterskin (Almost Empty of Black-Briar Reserve)
		;.AddForm(GetFormFromFile(0x052BFBA7,sModFilename)) ; Waterskin (Full of Spiced Wine)
		;.AddForm(GetFormFromFile(0x052BFBA9,sModFilename)) ; Waterskin (Almost Half of Spiced Wine)
		;.AddForm(GetFormFromFile(0x052BFBAB,sModFilename)) ; Waterskin (Almost Empty of Spiced Wine)
		;.AddForm(GetFormFromFile(0x052E8455,sModFilename)) ; Waterskin (Full of Dragon's Breath Mead)
		;.AddForm(GetFormFromFile(0x052E8456,sModFilename)) ; Waterskin (Almost Half ofDragon's Breath Mead)
		;.AddForm(GetFormFromFile(0x052E8458,sModFilename)) ; Waterskin (Almost Empty of Dragon's Breath Mead)
		;.AddForm(GetFormFromFile(0x05500FE7,sModFilename)) ; Waterskin (Full of Shein)
		;.AddForm(GetFormFromFile(0x05500FE8,sModFilename)) ; Waterskin (Almost Half of Shein)
		;.AddForm(GetFormFromFile(0x05500FEA,sModFilename)) ; Waterskin (Almost Empty of Shein)
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x05598FB7,sModFilename)) ; Cliffracer Tail
		;.AddForm(GetFormFromFile(0x05598FB9,sModFilename)) ; Baguette
		;.AddForm(GetFormFromFile(0x05598FBB,sModFilename)) ; Cookies
		;.AddForm(GetFormFromFile(0x05598FBD,sModFilename)) ; Cinnamon Bun
		;.AddForm(GetFormFromFile(0x05598FC1,sModFilename)) ; Corn Muffin
		;.AddForm(GetFormFromFile(0x05598FC7,sModFilename)) ; Blueberry Muffin
		;.AddForm(GetFormFromFile(0x05598FCD,sModFilename)) ; Cranberry Muffin
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x058635C9,sModFilename)) ; MudCrab Meat
		vBBS_DairyFood.AddForm(GetFormFromFile(0x058635CD,sModFilename)) ; Milk
		;.AddForm(GetFormFromFile(0x058635D1,sModFilename)) ; Water
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0512E869,sModFilename)) ; Dog Steak
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0512E86F,sModFilename)) ; Mushroom Soup
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0512E871,sModFilename)) ; Mushroom Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0512E873,sModFilename)) ; Grilled Human flesh
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0512E87B,sModFilename)) ; Human Flesh Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x052462C3,sModFilename)) ; Currant Biscuit
		vBBS_GassyFood.AddForm(GetFormFromFile(0x052462C8,sModFilename)) ; Barley Bread
		vBBS_GassyFood.AddForm(GetFormFromFile(0x052462CA,sModFilename)) ; Nut Bread
		vBBS_GassyFood.AddForm(GetFormFromFile(0x052462CE,sModFilename)) ; Game Pie
		vBBS_GassyFood.AddForm(GetFormFromFile(0x052462D0,sModFilename)) ; Beef Pie
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3D6,sModFilename)) ; Apple Almond Tart
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3D7,sModFilename)) ; Haafingar Cheese
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3D9,sModFilename)) ; Ivarstead Cheese
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3DB,sModFilename)) ; Rorikstead Cheese
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3DD,sModFilename)) ; Haafingar Cheese Wheel
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3DF,sModFilename)) ; Sliced Haafingar Cheese
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3E1,sModFilename)) ; Ivarstead Cheese Wheel
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3E3,sModFilename)) ; Rorikstead Cheese Wheel
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3E5,sModFilename)) ; Sliced Rorikstead Cheese
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3E7,sModFilename)) ; Sliced Ivarstead Cheese
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3E9,sModFilename)) ; Gourd and Carrot Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0524B3F1,sModFilename)) ; Spiced Porridge
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802B8,sModFilename)) ; Soap Frost
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802BB,sModFilename)) ; Soap Lava
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802BD,sModFilename)) ; Soap Aura
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802BF,sModFilename)) ; Soap Ever Spring
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802C1,sModFilename)) ; Soap Spa Fresh
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802C3,sModFilename)) ; Soap Energy
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802C5,sModFilename)) ; Soap Hawk
		vBBS_GassyFood.AddForm(GetFormFromFile(0x053802C7,sModFilename)) ; Soap Dragonborn
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05593EB4,sModFilename)) ; Meat Pie
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FB6,sModFilename)) ; Cliffracer Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FBF,sModFilename)) ; Blueberry Pie
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FC3,sModFilename)) ; Strawberry Rhubarb Pie
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FC5,sModFilename)) ; Pumpkin Pie
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FC9,sModFilename)) ; Rack of Ribs
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FCF,sModFilename)) ; Fig & Walnut Muffin
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FD1,sModFilename)) ; Audmund's Seasoned Beef
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FD3,sModFilename)) ; Seasoned Beef Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FD5,sModFilename)) ; Spirit Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FD7,sModFilename)) ; Varrina's Special Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FD9,sModFilename)) ; Vegetable Medley
		vBBS_GassyFood.AddForm(GetFormFromFile(0x05598FDB,sModFilename)) ; Wine Basted Venison
		vBBS_GassyFood.AddForm(GetFormFromFile(0x058635C1,sModFilename)) ; Cooked Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x058635C5,sModFilename)) ; Skeever Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x058635C5,sModFilename)) ; Skeever Meat ; It's rat meat AND it's raw!
		vBBS_GassyFood.AddForm(GetFormFromFile(0x058635D5,sModFilename)) ; Strange Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x058635D9,sModFilename)) ; Bestial Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0512E86C,sModFilename)) ; Gourd Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0512E875,sModFilename)) ; Human Heart Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x055297FF,sModFilename)) ; Spoiled Apple Dumpling
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529800,sModFilename)) ; Spoiled Braided Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529802,sModFilename)) ; Spoiled Butter
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529804,sModFilename)) ; Spoiled Chicken Dumpling
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529806,sModFilename)) ; Spoiled Clam Chowder
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529808,sModFilename)) ; Spoiled Garlic Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552980A,sModFilename)) ; Spoiled Jazbay Crostata
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552980C,sModFilename)) ; Spoiled Juniper Berry Crostata
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552980E,sModFilename)) ; Spoiled Lavender Dumpling
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529810,sModFilename)) ; Spoiled Jug of Milk
		vBBS_DairyFood.AddForm(GetFormFromFile(0x05529810,sModFilename)) ; Spoiled Jug of Milk - dairy
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529812,sModFilename)) ; Spoiled Mudcrab Legs
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529814,sModFilename)) ; Spoiled Steamed Mudcrab Legs
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529816,sModFilename)) ; Spoiled Potato Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529818,sModFilename)) ; Spoiled Salmon Steak
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552981A,sModFilename)) ; Spoiled Snowberry Crostata
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552981C,sModFilename)) ; Spoiled Mammoth Snout
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552981E,sModFilename)) ; Spoiled Soul Husk
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529820,sModFilename)) ; Spoiled Ash Hopper Leg
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529822,sModFilename)) ; Spoiled Ash Hopper Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529824,sModFilename)) ; Spoiled Ash Yam
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529826,sModFilename)) ; Spoiled Boar Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529828,sModFilename)) ; Spoiled Cooked Boar Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552982A,sModFilename)) ; Spoiled Horker and Ash Yam Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552982C,sModFilename)) ; Spoiled Spiced Beef
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552982E,sModFilename)) ; Spoiled Red Apple
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529830,sModFilename)) ; Spoiled Green Apple
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529832,sModFilename)) ; Spoiled Raw Beef
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529834,sModFilename)) ; Spoiled Cooked Beef
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529836,sModFilename)) ; Spoiled Beef Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529838,sModFilename)) ; Spoiled Boiled Creme Treat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552983A,sModFilename)) ; Spoiled Full Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552983C,sModFilename)) ; Spoiled Half Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552983E,sModFilename)) ; Spoiled Cabbage
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529840,sModFilename)) ; Spoiled Cabbage Potato Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529842,sModFilename)) ; Spoiled Cabbage Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529844,sModFilename)) ; Spoiled Carrot
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529846,sModFilename)) ; Spoiled Charred Skeever Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529848,sModFilename)) ; Spoiled Goat Cheese Wedge
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552984A,sModFilename)) ; Spoiled Eidar Cheese Wedge
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552984C,sModFilename)) ; Spoiled Goat Cheese Wheel
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552984E,sModFilename)) ; Spoiled Sliced Goat Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529850,sModFilename)) ; Spoiled Eidar Cheese Wheel
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529852,sModFilename)) ; Spoiled Sliced Eidar Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529854,sModFilename)) ; Spoiled Chicken Breast
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529856,sModFilename)) ; Spoiled Grilled Chicken Breast
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529858,sModFilename)) ; Spoiled Clam Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552985A,sModFilename)) ; Spoiled Dog Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552985C,sModFilename)) ; Spoiled Elsweyr Fondue
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552985E,sModFilename)) ; Spoiled Leg of Goat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529860,sModFilename)) ; Spoiled Leg of Goat Roast
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529862,sModFilename)) ; Spoiled Gourd
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529864,sModFilename)) ; Spoiled Honey
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529866,sModFilename)) ; Spoiled Honey Nut Treat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529868,sModFilename)) ; Spoiled Horker Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552986A,sModFilename)) ; Spoiled Horker Loaf
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552986C,sModFilename)) ; Spoiled Horker Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552986E,sModFilename)) ; Spoiled Horse Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529870,sModFilename)) ; Spoiled Horse Haunch
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529872,sModFilename)) ; Spoiled Leek
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529874,sModFilename)) ; Spoiled Grilled Leeks
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529876,sModFilename)) ; Spoiled Long Taffy Treat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05529878,sModFilename)) ; Spoiled Mammoth Cheese Bowl
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552987A,sModFilename)) ; Spoiled Mammoth Snout
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E97D,sModFilename)) ; Spoiled Homecooked Meal
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E97E,sModFilename)) ; Spoiled Pheasant Breast
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E980,sModFilename)) ; Spoiled Pheasant Roast
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E982,sModFilename)) ; Spoiled Apple Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E984,sModFilename)) ; Spoiled Potato
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E986,sModFilename)) ; Spoiled Baked Potatoes
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E988,sModFilename)) ; Spoiled Potato Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E98A,sModFilename)) ; Spoiled Raw Rabbit Leg
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E98C,sModFilename)) ; Spoiled Rabbit Haunch
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E98E,sModFilename)) ; Spoiled Salmon Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E990,sModFilename)) ; Spoiled Salmon Steak
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E992,sModFilename)) ; Spoiled Seared Slaughterfish
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E994,sModFilename)) ; Spoiled Sweet Roll
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E996,sModFilename)) ; Spoiled Tomato
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E998,sModFilename)) ; Spoiled Tomato Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E99A,sModFilename)) ; Spoiled Vegetable Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E99C,sModFilename)) ; Spoiled Venison
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E99E,sModFilename)) ; Spoiled Venison Chop
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9A0,sModFilename)) ; Spoiled Venison Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9A2,sModFilename)) ; Spoiled Currant Biscuit
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9A4,sModFilename)) ; Spoiled Honey Biscuit
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9A6,sModFilename)) ; Spoiled Black Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9A8,sModFilename)) ; Spoiled Barley Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9AA,sModFilename)) ; Spoiled Nut Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9AC,sModFilename)) ; Spoiled Haafingar Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9AE,sModFilename)) ; Spoiled Ivarstead Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9B0,sModFilename)) ; Spoiled Rorikstead Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9B2,sModFilename)) ; Spoiled Haafingar Cheese Wheel
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9B4,sModFilename)) ; Spoiled Sliced Haafingar Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9B6,sModFilename)) ; Spoiled Ivarstead Cheese Wheel
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9B8,sModFilename)) ; Spoiled Sliced Ivarstead Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9BA,sModFilename)) ; Spoiled Rorikstead Cheese Wheel
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9BC,sModFilename)) ; Spoiled Sliced Rorikstead Cheese
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9BE,sModFilename)) ; Spoiled Gourd and Carrot Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9C0,sModFilename)) ; Spoiled Fish Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9C2,sModFilename)) ; Spoiled Licorice Sweet
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9C4,sModFilename)) ; Spoiled Game Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9C6,sModFilename)) ; Spoiled Beef Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9C8,sModFilename)) ; Spoiled Spiced Porridge
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9CA,sModFilename)) ; Spoiled Spice Cake
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9CC,sModFilename)) ; Spoiled Apple Almond Tart
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9CE,sModFilename)) ; Spoiled Dog Steak
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9D0,sModFilename)) ; Spoiled Gourd Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9D2,sModFilename)) ; Spoiled Grilled Human flesh
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9D4,sModFilename)) ; Spoiled Human Flesh Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9D6,sModFilename)) ; Spoiled Human Heart Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9D8,sModFilename)) ; Spoiled Mushroom Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9DA,sModFilename)) ; Spoiled Mushroom Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9DC,sModFilename)) ; Spoiled Sabrecat Eye Soup
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0552E9DE,sModFilename)) ; Spoiled Slaughterfish Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD53,sModFilename)) ; Spoiled Baguette
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD54,sModFilename)) ; Spoiled Cookies
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD56,sModFilename)) ; Spoiled Cinnamon Bun
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD58,sModFilename)) ; Spoiled Blueberry Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD5A,sModFilename)) ; Spoiled Corn Muffin
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD5C,sModFilename)) ; Spoiled Strawberry Rhubarb Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD5E,sModFilename)) ; Spoiled Pumpkin Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD60,sModFilename)) ; Spoiled Blueberry Muffin
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD62,sModFilename)) ; Spoiled Cranberry Muffin
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD64,sModFilename)) ; Spoiled Fig & Walnut Muffin
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD66,sModFilename)) ; Spoiled Rack of Ribs
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD68,sModFilename)) ; Spoiled Grilled Pork Kabob
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD6A,sModFilename)) ; Spoiled Meat Pie
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD6C,sModFilename)) ; Spoiled Audmund's Seasoned Beef
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD6E,sModFilename)) ; Spoiled Varrina's Special Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD70,sModFilename)) ; Spoiled Spirit Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD72,sModFilename)) ; Spoiled Vegetable Medley
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD74,sModFilename)) ; Spoiled Seasoned Beef Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD76,sModFilename)) ; Spoiled Wine Basted Venison
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD78,sModFilename)) ; Spoiled Cliffracer Tail
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0553DD7A,sModFilename)) ; Spoiled Cliffracer Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0554D081,sModFilename)) ; Spoiled White Bread
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0554D082,sModFilename)) ; Spoiled Apple Cabbage Stew
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0554D084,sModFilename)) ; Spoiled Mammoth Steak
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0557A99E,sModFilename)) ; Spoiled Holy Water
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0557FAA0,sModFilename)) ; Spoiled Barley Tea
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0557FAA1,sModFilename)) ; Spoiled Water
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x05598FCB,sModFilename)) ; Grilled Pork Kabob
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x058635C5,sModFilename)) 	   ; Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x058635BF,sModFilename)) ; Spoiled Raw Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x058635C3,sModFilename)) ; Spoiled Cooked Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x058635C7,sModFilename)) ; Spoiled Skeever Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x058635CB,sModFilename)) ; Spoiled MudCrab Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x058635CF,sModFilename)) ; Spoiled Milk
		vBBS_DairyFood.AddForm(GetFormFromFile(0x058635CF,sModFilename)) ; Spoiled Milk - Lactose
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x058635D3,sModFilename)) ; Spoiled Water
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x058635D7,sModFilename)) ; Spoiled Strange Meat
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x058635DB,sModFilename)) ; Spoiled Bestial Stew
	
		FormList ZF_FoodList = GetFormFromFile(0x05626C9A,sModFilename) as Formlist
		If !ZF_Foodlist.HasForm(vBBS_FoodBakedBeans)
			Debug.Trace("BBS: Adding Baked Beans to ZF_FoodList...")
			ZF_Foodlist.AddForm(vBBS_FoodBakedBeans)
		EndIf
		If !ZF_Foodlist.HasForm(vBBS_FoodBeanChili)
			Debug.Trace("BBS: Adding Bean Chili to ZF_FoodList...")
			ZF_Foodlist.AddForm(vBBS_FoodBeanChili)
		EndIf

		
		FormList ZF_FoodCookedList = GetFormFromFile(0x05626CA5,sModFilename) as Formlist
		If !ZF_FoodCookedList.HasForm(vBBS_FoodBakedBeans)
			Debug.Trace("BBS: Adding Baked Beans to ZF_FoodCookedList...")
			ZF_FoodCookedList.AddForm(vBBS_FoodBakedBeans)
		EndIf
		If !ZF_FoodCookedList.HasForm(vBBS_FoodBeanChili)
			Debug.Trace("BBS: Adding Bean Chili to ZF_FoodCookedList...")
			ZF_FoodCookedList.AddForm(vBBS_FoodBeanChili)
		EndIf
		
	EndIf
EndFunction

Function CheckEatAndSleep()
	String sModName = "Eat and Sleep"
	String sModFilename = "kuerteeEatAndSleep.esp"
	Debug.Trace("BBS: Checking for " + sModName + "...")
	
	Form kTestItem = GetFormFromFile(0x0100EBD4,sModFilename)
	If kTestItem
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding foods to list!")	
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0100F14B,sModFilename)) ; Leg of Goat Slice
		;.AddForm(GetFormFromFile(0x010198E2,sModFilename)) ; kuEASSmallerPortion000
		;.AddForm(GetFormFromFile(0x010198E3,sModFilename)) ; kuEASSmallerPortion002
		;.AddForm(GetFormFromFile(0x010198E6,sModFilename)) ; kuEASSmallerPortion001
		;.AddForm(GetFormFromFile(0x010198E7,sModFilename)) ; kuEASSmallerPortion003
		;.AddForm(GetFormFromFile(0x010198E9,sModFilename)) ; kuEASSmallerPortion004
		;.AddForm(GetFormFromFile(0x010198EB,sModFilename)) ; kuEASSmallerPortion005
		;.AddForm(GetFormFromFile(0x010198ED,sModFilename)) ; kuEASSmallerPortion006
		;.AddForm(GetFormFromFile(0x010198EF,sModFilename)) ; kuEASSmallerPortion007
		;.AddForm(GetFormFromFile(0x010198F1,sModFilename)) ; kuEASSmallerPortion008
		;.AddForm(GetFormFromFile(0x010198F3,sModFilename)) ; kuEASSmallerPortion009
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0101B955,sModFilename)) ; Chicken Breast Slice
		;.AddForm(GetFormFromFile(0x0101B957,sModFilename)) ; Grilled Chicken Breast Slice
		;.AddForm(GetFormFromFile(0x0101B95D,sModFilename)) ; Homecooked Meal Serving
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0101B95F,sModFilename)) ; Pheasant Breast Slice
		;.AddForm(GetFormFromFile(0x0101B961,sModFilename)) ; Pheasant Roast Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0101B965,sModFilename)) ; Rabbit Haunch Slice
		;.AddForm(GetFormFromFile(0x0102096B,sModFilename)) ; kuEASMeal1
		;.AddForm(GetFormFromFile(0x0102096C,sModFilename)) ; kuEASMeal2
		;.AddForm(GetFormFromFile(0x0102096E,sModFilename)) ; kuEASMeal3
		;.AddForm(GetFormFromFile(0x01020973,sModFilename)) ; kuEASMeal4
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100EBD4,sModFilename)) ; Horse Steak Slice
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100EBD5,sModFilename)) ; Mammoth Steak Slice
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100EBD7,sModFilename)) ; Venison Chop Slice
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100EBDB,sModFilename)) ; Leg of Goat Roast Slice
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100EBDD,sModFilename)) ; Eidar Cheese Wedge
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0100EBDF,sModFilename)) ; Goat Cheese Wedge
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0100F147,sModFilename)) ; Venison Slice
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0101B94E,sModFilename)) ; Mammoth Snout Slice
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0101B94F,sModFilename)) ; Spiced Beef Slice
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0101B953,sModFilename)) ; Cooked Beef Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0101B959,sModFilename)) ; Dog Meat Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0101B95B,sModFilename)) ; Horse Meat Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0100EBD9,sModFilename)) ; Horker Loaf Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0100F146,sModFilename)) ; Mammoth Snout Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0100F149,sModFilename)) ; Horker Meat Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0101B951,sModFilename)) ; Raw Beef Slice
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0101B963,sModFilename)) ; Raw Rabbit Leg Slice
		
		FormList kuEASFoodCookedList = GetFormFromFile(0x0100239A,sModFilename) as Formlist
		If !kuEASFoodCookedList.HasForm(vBBS_FoodBakedBeans)
			Debug.Trace("BBS: Adding Baked Beans to kuEASFoodCookedList...")
			kuEASFoodCookedList.AddForm(vBBS_FoodBakedBeans)
			Debug.Trace("BBS: Adding Bean Chili to kuEASFoodCookedList...")
			kuEASFoodCookedList.AddForm(vBBS_FoodBeanChili)
		EndIf
		
		FormList kuEASFoodSpoilsIn3Days = GetFormFromFile(0x0100845D,sModFilename) as Formlist
		If !kuEASFoodSpoilsIn3Days.HasForm(vBBS_FoodBakedBeans)
			Debug.Trace("BBS: Adding Baked Beans to kuEASFoodSpoilsIn3Days...")
			kuEASFoodSpoilsIn3Days.AddForm(vBBS_FoodBakedBeans)
			Debug.Trace("BBS: Adding Bean Chili to kuEASFoodSpoilsIn3Days...")
			kuEASFoodSpoilsIn3Days.AddForm(vBBS_FoodBeanChili)
		EndIf
	EndIf
EndFunction

Function CheckRealWildlifeSkyrim()
	String sModName = "Real Wildlife Skyrim"
	String sModFilename = "Real Wildlife Skyrim 0.1.esp"
	Debug.Trace("BBS: Checking for " + sModName + "...")
	
	Form kTestItem = GetFormFromFile(0x02001011,sModFilename)
	If kTestItem
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding foods to list!")	
		;.AddForm(GetFormFromFile(0x02001010,sModFilename)) ; Hawk Breast Meat
		;.AddForm(GetFormFromFile(0x02001030,sModFilename)) ; Roasted Wolf Meat
		;.AddForm(GetFormFromFile(0x02001033,sModFilename)) ; Grilled Hawk's Breast
		;.AddForm(GetFormFromFile(0x020170FE,sModFilename)) ; Grouse Breast
		;.AddForm(GetFormFromFile(0x02017100,sModFilename)) ; Grilled Grouse Breast
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x02001011,sModFilename)) ; Wolf Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x02001012,sModFilename)) ; Mammoth Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0200101F,sModFilename)) ; Fox Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0200102C,sModFilename)) ; Cooked Bear Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0200102D,sModFilename)) ; Cooked Saber Cat Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0200102E,sModFilename)) ; Roasted Dog Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0200102F,sModFilename)) ; Mammoth Meatloaf
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02001032,sModFilename)) ; Roasted FoxMeat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02001034,sModFilename)) ; Roasted Giant's Flesh
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02001035,sModFilename)) ; Mammoth Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02001036,sModFilename)) ; Elsweyr Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x02001037,sModFilename)) ; Hunter's Hotpot
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x02001003,sModFilename)) ; Raw Diseased Bear Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x02001003,sModFilename)) ; Raw Diseased Bear Meat - Raw
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x0200100D,sModFilename)) ; Diseased Wolf Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0200100D,sModFilename)) ; Diseased Wolf Meat - Raw
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0200100E,sModFilename)) ; Raw Saber Cat Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x0200100F,sModFilename)) ; Raw Bear Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x02001014,sModFilename)) ; Raw Saber Cat Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x02001018,sModFilename)) ; Giant Flesh
		vBBS_GassyFood.AddForm(GetFormFromFile(0x0201CED7,sModFilename)) ; Tripe Stew
	EndIf
EndFunction

Function CheckRealisticWildlifeLoot()
	String sModName = "Realistic Wildlife Loot"
	String[] sModFilenames = New String[4]
	sModFilenames[0] = "Realistic Wildlife Loot - Realistic.esp"
	sModFilenames[1] = "Realistic Wildlife Loot - IMCN Realistic.esp"
	sModFilenames[2] = "Realistic Wildlife Loot - Reduced.esp"
	sModFilenames[3] = "Realistic Wildlife Loot - IMCN Reduced.esp"

	Debug.Trace("BBS: Checking for " + sModName + "...")
	
	String sModFilename
	Form kTestItem 
	Int i = 0
	While i < sModFilenames.Length
		kTestItem = GetFormFromFile(0x010018A8,sModFilenames[i])
		If kTestItem
			sModFilename = sModFilenames[i]
			i = sModFilenames.Length
		EndIf
		i += 1
	EndWhile

	If kTestItem
		Debug.Trace("BBS: " + sModName + " (" + sModFilename + ") detected, adding foods to list!")	
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D89,sModFilename)) ; Raw Mudcrab Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D93,sModFilename)) ; Raw Slaughterfish Meat
		;.AddForm(GetFormFromFile(0x010018AA,sModFilename)) ; Goat Steak
		;.AddForm(GetFormFromFile(0x010023D2,sModFilename)) ; Rabbit Sandwich
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010018A8,sModFilename)) ; Grilled Fox Meat
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010018AC,sModFilename)) ; Garlic Dog Ribs
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010018B4,sModFilename)) ; Marinated Mammoth Steak
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010018B9,sModFilename)) ; Spicy Sabre Cat Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001E0D,sModFilename)) ; Bear Roast
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001E20,sModFilename)) ; Skeever Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001E25,sModFilename)) ; Sabre Cat Roast
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001E28,sModFilename)) ; Bear Roast, Marinated
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001E2C,sModFilename)) ; Elk Venison Chop
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001E2F,sModFilename)) ; Elk Venison Stew
		vBBS_GassyFood.AddForm(GetFormFromFile(0x01001E31,sModFilename)) ; Wolf Roast
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D6D,sModFilename)) ; Raw Bear Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D73,sModFilename)) ; Raw Skeever Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D79,sModFilename)) ; Raw Mammoth Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D7B,sModFilename)) ; Raw Sabre Cat Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D83,sModFilename)) ; Raw Wolf Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01000D97,sModFilename)) ; Raw Fox Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x010012FD,sModFilename)) ; Raw Goat Meat
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x01001309,sModFilename)) ; Raw Venison (Elk)
		vBBS_STUPIDGassyFood.AddForm(GetFormFromFile(0x010018A6,sModFilename)) ; Bear Sausage
		vBBS_GassyFood.AddForm(GetFormFromFile(0x010018B6,sModFilename)) ; Mudcrab and Clam Chowder
		vBBS_DairyFood.AddForm(GetFormFromFile(0x010018B6,sModFilename)) ; Mudcrab and Clam Chowder - Chowder = cream sauce
		vBBS_RawMeatFood.AddForm(GetFormFromFile(0x010023D0,sModFilename)) ; Raw Rabbit Meat
	EndIf
EndFunction