Scriptname vBBS_MCMScript extends SKI_ConfigBase

vBBS_MetaQuestScript Property MetaQuestScript Auto

;--=== Configuration ===--

GlobalVariable Property vBBS_Enabled Auto
{Master enable. Disabling this halts all gas.}

GlobalVariable Property vBBS_GasLevel Auto
{Player's current gas level, for use by other forms}

GlobalVariable Property vBBS_GasPressure Auto
{Player's current gas pressure, for use by other forms}

GlobalVariable Property vBBS_GasLoad Auto
{Player's current gas load, for use by other forms}

GlobalVariable Property vBBS_DigestionSpeed Auto
{How quickly the queue gets processed}

GlobalVariable Property vBBS_GasMult Auto
{How much gas food produces}

GlobalVariable Property vBBS_AftershockChanceMult Auto
{How likely an "aftershock" is}

GlobalVariable Property vBBS_GasCheckInterval Auto
{Average interval at which gas is checked}

GlobalVariable Property vBBS_ReliefDelay Auto
{Normal delay time is multiplied by this for post-expulsion relief}

GlobalVariable Property vBBS_EnableWalking Auto
{Enable walking farts}

GlobalVariable Property vBBS_EnableJumping Auto
{Enable jumping farts}

GlobalVariable Property vBBS_GasShoutEnabled Auto
{Allow player to gain "Corrupted Shout" when loaded with gas}

GlobalVariable Property vBBS_LactoseIntolerance Auto
{Lactose intolerance}

GlobalVariable Property vBBS_RawMeatIntolerance Auto
{Raw meat intolerance}

Int 		_iPresetState = 1
String[] 	_sPresetNames


Event OnConfigInit()
	ModName = "$Baked Beans of Skyrim"
EndEvent

event OnGameReload()
    parent.OnGameReload()
endEvent

Int Function GetVersion()
    return 2
EndFunction

Event OnVersionUpdate(int a_version)
	If CurrentVersion < 2
		OnConfigInit()
	EndIf
EndEvent

event OnPageReset(string a_page)
	UpdateSettings()
	Int OptionFlags = 0
	If !((vBBS_Enabled.GetValue() as Int) as Bool)
		OptionFlags = OPTION_FLAG_DISABLED
	EndIf	
	SetCursorFillMode(TOP_TO_BOTTOM)
	AddHeaderOption("$General")
	AddToggleOptionST("CFG_Enabled","$Enable gas",(vBBS_Enabled.GetValue() as Int) as Bool)
	AddTextOptionST("CFG_Preset","$Preset",_sPresetNames[_iPresetState],OptionFlags)
	AddTextOptionST("CFG_Help","$Configuration help","$Click")
	AddEmptyOption()
	AddHeaderOption("$Gas options")
	AddSliderOptionST("CFG_GasCheckInterval","$Gas check interval",vBBS_GasCheckInterval.GetValue(),"{2} s",OptionFlags)
	AddSliderOptionST("CFG_AftershockChance","$Aftershock chance",vBBS_AftershockChanceMult.GetValue() * 100,"{0}%",OptionFlags)
	AddSliderOptionST("CFG_ReliefDelay","$Relief delay",vBBS_ReliefDelay.GetValue(),"{2}",OptionFlags)
	AddToggleOptionST("CFG_Walking","$Enable walking farts",(vBBS_EnableWalking.GetValue() as Int) as Bool,OptionFlags)
	AddToggleOptionST("CFG_Jumping","$Enable jumping farts",(vBBS_EnableJumping.GetValue() as Int) as Bool,OptionFlags)
	AddToggleOptionST("CFG_FartShout","$Enable corrupted shout",(vBBS_GasShoutEnabled.GetValue() as Int) as Bool,OptionFlags)
	
	SetCursorPosition(1)
	AddHeaderOption("$Digestion options")
	AddSliderOptionST("CFG_DigestionSpeed","$Digestion speed",vBBS_DigestionSpeed.GetValue(),"{0} s",OptionFlags)
	AddSliderOptionST("CFG_DairyIntolerance","$Dairy intolerance",vBBS_LactoseIntolerance.GetValue(),"{1}",OptionFlags)
	AddSliderOptionST("CFG_RawMeatIntolerance","$Raw meat intolerance",vBBS_RawMeatIntolerance.GetValue(),"{1}",OptionFlags)
	AddSliderOptionST("CFG_GasMult","$Gas multiplier",vBBS_GasMult.GetValue(),"{2}",OptionFlags)
	AddEmptyOption()
	AddHeaderOption("$Stats")
	AddTextOption("$Current gas level",StringUtil.SubString(vBBS_GasLevel.GetValue() as String,0,StringUtil.Find(vBBS_GasLevel.GetValue() as String,".") + 3),OPTION_FLAG_DISABLED)
	AddTextOption("$Current gas pressure",StringUtil.SubString(vBBS_GasPressure.GetValue() as String,0,StringUtil.Find(vBBS_GasPressure.GetValue() as String,".") + 3),OPTION_FLAG_DISABLED)
	AddTextOption("$Impending gas level",StringUtil.SubString(vBBS_GasLoad.GetValue() as String,0,StringUtil.Find(vBBS_GasLoad.GetValue() as String,".") + 3),OPTION_FLAG_DISABLED)
	AddEmptyOption()
	AddTextOptionST("CFG_ShowQueue","$Show gas queue","$Click")
EndEvent

String Function GetPrettyTime(String asTimeInMinutes)
	;Debug.Trace("BBS: Prettying " + asTimeInMinutes)
	Float fTimeInMinutes = asTimeInMinutes as Float
	;Debug.Trace("BBS: fTimeInMinutes: " + fTimeInMinutes)
	Int iMinutes = Math.Floor(fTimeInMinutes)
	;Debug.Trace("BBS: iMinutes: " + iMinutes)
	Int iSeconds = Math.Floor(((fTimeInMinutes - iMinutes) * 60) + 0.5)
	;Math.Floor((afValue * iMult) + 0.5) / iMult
	;Debug.Trace("BBS: iSeconds: " + iSeconds)
	String sZero = ""
	If iSeconds < 10
		sZero = "0"
	EndIf
	String sPrettyTime = iMinutes + ":" + sZero + iSeconds
	Return sPrettyTime
EndFunction

event OnConfigOpen()
	UpdateSettings()
endEvent

event OnConfigClose()
	ApplySettings()
endEvent

Function UpdateSettings()
	_sPresetNames = New String[5]
	_sPresetNames[0] = "$Arngeir"
	_sPresetNames[1] = "$Lydia"
	_sPresetNames[2] = "$Alduin"
	_sPresetNames[3] = "$Mick"
	_sPresetNames[4] = "$Custom"
EndFunction

Function ApplySettings()
	If MetaQuestScript.GasEnabled && !((vBBS_Enabled.GetValue() as Int) as Bool)
		MetaQuestScript.GasEnabled = False
	ElseIf !MetaQuestScript.GasEnabled && ((vBBS_Enabled.GetValue() as Int) as Bool)
		MetaQuestScript.GasEnabled = True
	EndIf
EndFunction

Function SetCustomPreset()
	_iPresetState = 4
	SetTextOptionValueST(_sPresetNames[_iPresetState],True,"CFG_Preset")
EndFunction

State CFG_ShowQueue

	Event OnSelectST()
		Float[] fGasQueue = MetaQuestScript.GasTracker.GasQueue
		Float fInterval = vBBS_DigestionSpeed.GetValue()
		String sGasQueue = "Time\t\t\tGas Level\n"
		Int i = 0
		While i < fGasQueue.Length
			sGasQueue += GetPrettyTime((fInterval * i) / 60.0) as String + "\t\t\t" + StringUtil.SubString(fGasQueue[i] as String,0,StringUtil.Find(fGasQueue[i] as String,".") + 3) + "\n"
			;AddTextOption(GetPrettyTime((fInterval * i) / 60), StringUtil.SubString(fGasQueue[i] as String,0,StringUtil.Find(fGasQueue[i] as String,".") + 3),OPTION_FLAG_DISABLED)
			i += 1
		EndWhile
		ShowMessage(sGasQueue,False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("$Show queue help")
	EndEvent
	
EndState

State CFG_Preset
	Event OnSelectST()
		If _iPresetState == 4
			Bool bConfirm = ShowMessage("$Really lose custom values",True)
			If !bConfirm
				Return
			EndIf
		EndIf
		_iPresetState += 1
		If _iPresetState > 3
			_iPresetState = 0
		EndIf

		If _iPresetState == 0 ; Low
			vBBS_DigestionSpeed.SetValue(10)
			vBBS_GasCheckInterval.SetValue(5)
			vBBS_GasMult.SetValue(0.75)
			vBBS_AftershockChanceMult.SetValue(0.4)
			vBBS_ReliefDelay.SetValue(3)
		ElseIf _iPresetState == 1 ; Med/Default
			vBBS_DigestionSpeed.SetValue(15)
			vBBS_GasCheckInterval.SetValue(3.5)
			vBBS_GasMult.SetValue(1.0)
			vBBS_AftershockChanceMult.SetValue(0.6)
			vBBS_ReliefDelay.SetValue(2)
		ElseIf _iPresetState == 2 ; High
			vBBS_DigestionSpeed.SetValue(20)
			vBBS_GasCheckInterval.SetValue(2.5)
			vBBS_GasMult.SetValue(1.25)
			vBBS_AftershockChanceMult.SetValue(0.8)
			vBBS_ReliefDelay.SetValue(1.5)
		ElseIf _iPresetState == 3 ; Insane
			vBBS_DigestionSpeed.SetValue(30)
			vBBS_GasCheckInterval.SetValue(1.5)
			vBBS_GasMult.SetValue(1.5)
			vBBS_AftershockChanceMult.SetValue(1.0)
			vBBS_ReliefDelay.SetValue(1.0)
		EndIf
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$Preset help")
	EndEvent

EndState

State CFG_Help
	Event OnSelectST()
		ShowMessage("$Detailed help")
	EndEvent

	Event OnHighlightST()
		SetInfoText("$Config help help")
	EndEvent
EndState

State CFG_Enabled

	Event OnSelectST()
		vBBS_Enabled.SetValue((!((vBBS_Enabled.GetValue() as Int) as Bool)) as Int)
		ForcePageReset()
	EndEvent

	Event OnDefaultST()
		vBBS_Enabled.SetValue(1)
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$Enable gas tracking info")
	EndEvent

EndState

State CFG_Walking

	Event OnSelectST()
		vBBS_EnableWalking.SetValue((!((vBBS_EnableWalking.GetValue() as Int) as Bool)) as Int)
		ForcePageReset()
	EndEvent

	Event OnDefaultST()
		vBBS_EnableWalking.SetValue(1)
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$Enable walking farts info")
	EndEvent

EndState

State CFG_Jumping

	Event OnSelectST()
		vBBS_EnableJumping.SetValue((!((vBBS_EnableJumping.GetValue() as Int) as Bool)) as Int)
		ForcePageReset()
	EndEvent

	Event OnDefaultST()
		vBBS_EnableJumping.SetValue(1)
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$Enable gas shout info")
	EndEvent

EndState

State CFG_FartShout

	Event OnSelectST()
		vBBS_GasShoutEnabled.SetValue((!((vBBS_GasShoutEnabled.GetValue() as Int) as Bool)) as Int)
		ForcePageReset()
	EndEvent

	Event OnDefaultST()
		vBBS_GasShoutEnabled.SetValue(1)
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$Enable gas shout info")
	EndEvent

EndState

State CFG_DigestionSpeed

	Event OnSliderOpenST()
		SetSliderDialogStartValue(vBBS_DigestionSpeed.GetValue())
		SetSliderDialogDefaultValue(15)
		SetSliderDialogRange(5.0, 30.0)
		SetSliderDialogInterval(1)
		SetCustomPreset()
	EndEvent

	Event OnSliderAcceptST(float a_value)
		vBBS_DigestionSpeed.SetValue(a_value)
		SetSliderOptionValueST(vBBS_DigestionSpeed.GetValue(),"{0} s")
		ForcePageReset()
	EndEvent

	Event OnDefaultST()
		vBBS_DigestionSpeed.SetValue(15)
		SetSliderOptionValueST(vBBS_DigestionSpeed.GetValue(),"{0} s")
		ForcePageReset()
	endEvent

	Event OnHighlightST()
		SetInfoText("$How quickly digestion progresses")
	EndEvent

EndState

State CFG_GasCheckInterval

	Event OnSliderOpenST()
		SetSliderDialogStartValue(vBBS_GasCheckInterval.GetValue())
		SetSliderDialogDefaultValue(3.5)
		SetSliderDialogRange(1.0, 15.0)
		SetSliderDialogInterval(0.5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		vBBS_GasCheckInterval.SetValue(a_value)
		SetSliderOptionValueST(vBBS_GasCheckInterval.GetValue(),"{1} s")
		SetCustomPreset()
	EndEvent

	Event OnDefaultST()
		vBBS_GasCheckInterval.SetValue(3.5)
		SetSliderOptionValueST(vBBS_GasCheckInterval.GetValue(),"{1} s")
		SetCustomPreset()
	endEvent

	Event OnHighlightST()
		SetInfoText("$How often pressure is updated")
	EndEvent

EndState

State CFG_GasMult

	Event OnSliderOpenST()
		SetSliderDialogStartValue(vBBS_GasMult.GetValue())
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.25, 5.0)
		SetSliderDialogInterval(0.25)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		vBBS_GasMult.SetValue(a_value)
		SetSliderOptionValueST(vBBS_GasMult.GetValue(),"{2}")
		SetCustomPreset()
	EndEvent

	Event OnDefaultST()
		vBBS_GasMult.SetValue(1.0)
		SetSliderOptionValueST(vBBS_GasMult.GetValue(),"{2}")
		SetCustomPreset()
	endEvent

	Event OnHighlightST()
		SetInfoText("$How much gas is produced by food")
	EndEvent

EndState

State CFG_AftershockChance

	Event OnSliderOpenST()
		SetSliderDialogStartValue(vBBS_AftershockChanceMult.GetValue() * 100)
		SetSliderDialogDefaultValue(60)
		SetSliderDialogRange(0, 95)
		SetSliderDialogInterval(5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		vBBS_AftershockChanceMult.SetValue(a_value / 100.0)
		SetSliderOptionValueST(vBBS_AftershockChanceMult.GetValue() * 100,"{0}%")
		SetCustomPreset()
	EndEvent

	Event OnDefaultST()
		vBBS_AftershockChanceMult.SetValue(0.6)
		SetSliderOptionValueST(vBBS_AftershockChanceMult.GetValue() * 100,"{0}%")
		SetCustomPreset()
	endEvent

	Event OnHighlightST()
		SetInfoText("$After breaking wind any remaining pressure")
	EndEvent

EndState

State CFG_ReliefDelay

	Event OnSliderOpenST()
		SetSliderDialogStartValue(vBBS_ReliefDelay.GetValue())
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(1.0, 3.0)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		vBBS_ReliefDelay.SetValue(a_value)
		SetSliderOptionValueST(vBBS_ReliefDelay.GetValue(),"{1}")
		SetCustomPreset()
	EndEvent

	Event OnDefaultST()
		vBBS_ReliefDelay.SetValue(1.0)
		SetSliderOptionValueST(vBBS_ReliefDelay.GetValue(),"{1}")
		SetCustomPreset()
	endEvent

	Event OnHighlightST()
		SetInfoText("$After breaking wind wait this long")
	EndEvent

EndState

State CFG_DairyIntolerance

	Event OnSliderOpenST()
		SetSliderDialogStartValue(vBBS_LactoseIntolerance.GetValue())
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(0.0, 2.0)
		SetSliderDialogInterval(0.5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		vBBS_LactoseIntolerance.SetValue(a_value)
		SetSliderOptionValueST(vBBS_LactoseIntolerance.GetValue(),"{1}")
		;SetCustomPreset()
	EndEvent

	Event OnDefaultST()
		vBBS_LactoseIntolerance.SetValue(0.0)
		SetSliderOptionValueST(vBBS_LactoseIntolerance.GetValue(),"{1}")
		;SetCustomPreset()
	endEvent

	Event OnHighlightST()
		SetInfoText("$Dairy intolerance help")
	EndEvent

EndState

State CFG_RawMeatIntolerance

	Event OnSliderOpenST()
		SetSliderDialogStartValue(vBBS_RawMeatIntolerance.GetValue())
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(0.0, 2.0)
		SetSliderDialogInterval(0.5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		vBBS_RawMeatIntolerance.SetValue(a_value)
		SetSliderOptionValueST(vBBS_RawMeatIntolerance.GetValue(),"{1}")
		;SetCustomPreset()
	EndEvent

	Event OnDefaultST()
		vBBS_RawMeatIntolerance.SetValue(2.0)
		SetSliderOptionValueST(vBBS_RawMeatIntolerance.GetValue(),"{1}")
		;SetCustomPreset()
	endEvent

	Event OnHighlightST()
		SetInfoText("$Raw meat intolerance help")
	EndEvent

EndState
