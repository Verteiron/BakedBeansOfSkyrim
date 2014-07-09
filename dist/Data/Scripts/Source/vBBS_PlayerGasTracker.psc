Scriptname vBBS_PlayerGasTracker extends ReferenceAlias  
{Track when gassy foods are eaten and make player react accordingly}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

vBBS_MetaQuestScript Property MetaQuestScript Auto

Actor Property PlayerREF Auto

Formlist Property vBBS_GassyFood Auto

Formlist Property vBBS_STUPIDGassyFood Auto

Formlist Property vBBS_DairyFood Auto

Formlist Property vBBS_RawMeatFood Auto

Message Property vBBS_GasShoutEnabledMSG Auto

Message Property vBBS_GasShoutAddedMSG Auto

Message Property vBBS_GasShoutRemovedMSG Auto

Message Property vBBS_GasShoutHelpMSG Auto

Potion Property vBBS_FoodBeanChili Auto

Sound Property vBBS_BellySM Auto

Sound Property vBBS_LoudShortSM Auto

Sound Property vBBS_LoudMedSM Auto

Sound Property vBBS_LoudLongSM Auto

Sound Property vBBS_QuietShortSM Auto

Sound Property vBBS_QuietLongSM Auto

Spell Property vBBS_NoiseReactSpell Auto

Spell Property vBBS_CorruptedShoutFXSpell Auto

Float[] Property GasQueue Hidden
{Return the queue}
	Float[] Function Get()
		Return _fGasQueue
	EndFunction
	Function Set(Float[] afGasQueue)
		_fGasQueue = afGasQueue
	EndFunction
EndProperty

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

;--=== Variables ===--

Bool 	_bDebug = False

Bool 	_bSKSE

Bool	_bCancelGas = False

Bool 	_bEnableWalking = False

Bool 	_bEnableJumping = False

Bool 	_bHasGasShout = False

Float	_fUpdateQueueSpeed = 15.0 ; Time between queue updates in seconds

Float 	_fCurrentGasLevel

Float 	_fCurrentGasLoad

Float	_fCurrentGasPressure

Float 	_fLastGas

Float[] _fGasQueue 

Float[] _fGasCurve 

Float 	_fLastQueueTime

Int		_iBusyStateCounter

Form 	_kEquippedPower

;--=== Events ===--

Event OnInit()
	_fGasQueue 		= New Float[16] ; Upcoming gas levels
	_fGasCurve 		= New Float[12] ; 2 ghours of 10-gminute increments
	
	; This sets the base pattern for gas attacks.
	_fGasCurve[0]	= 0.1
	_fGasCurve[1]	= 0.4
	_fGasCurve[2]	= 0.7
	_fGasCurve[3]	= 1.0
	_fGasCurve[4]	= 1.0
	_fGasCurve[5]	= 1.0
	_fGasCurve[6]	= 0.9
	_fGasCurve[7]	= 0.8
	_fGasCurve[8]	= 0.7
	_fGasCurve[9]	= 0.5
	_fGasCurve[10]	= 0.3
	_fGasCurve[11]	= 0.1
	
	If SKSE.GetVersionRelease()
		_bSKSE = True
	EndIf

	If GetOwningQuest().IsRunning()
		RegisterForAnimationEvent(PlayerREF,"JumpUp")
		RegisterForAnimationEvent(PlayerREF,"footLeft")
		RegisterForAnimationEvent(PlayerREF,"footRight")
		;RegisterForAnimationEvent(PlayerREF,"BeginCastVoice")
		RegisterForSleep()
		RegisterForSingleUpdate(5)
		MetaQuestScript.Register(Self)
	EndIf
EndEvent

Event OnAnimationEvent(ObjectReference akSource, String asEventname)
	;DT("Animation event: " + asEventname)
	If _bEnableJumping && (asEventName == "JumpUp" && _fCurrentGasLevel > 0.25 && _fCurrentGasPressure > 0.25)
		DT("Player jumped! Bad idea...")
		PassGas()
		RegisterForSingleUpdate(3)
	ElseIf _bEnableWalking && (_fCurrentGasPressure > 0.4 && _fCurrentGasLevel > 0.5 && (asEventName == "footLeft" || asEventName == "footRight" ))
		If RandomInt(0,1)
			vBBS_QuietShortSM.Play(PlayerREF)
			_fCurrentGasPressure -= 0.05
			RegisterForSingleUpdate(vBBS_GasCheckInterval.GetValue()) ; Skip normal processing
		EndIf
	;ElseIf asEventName == "BeginCastVoice" && _fCurrentGasLevel >= 1.0
		;Wait(0.25)
		;PlayerREF.InterruptCast()
		;vBBS_LoudShortSM.Play(PlayerREF)
		;vBBS_CorruptedShoutFXSpell.Cast(PlayerREF)
		;_fCurrentGasLevel = 0
	EndIf
EndEvent

Event OnUpdate()
	UpdateGasLevel()
	Bool bHadGas = PassGas()
	Float fGasCheckInterval = vBBS_GasCheckInterval.GetValue()
	If bHadGas
		RegisterForSingleUpdate(vBBS_ReliefDelay.GetValue() * RandomFloat(fGasCheckInterval - 1.0,fGasCheckInterval + 1.0))
		PlayerREF.ClearExpressionOverride()
	Else
		RegisterForSingleUpdate(RandomFloat(fGasCheckInterval - 1.0,fGasCheckInterval + 1.0))
	EndIf
	UpdateConfig()
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	If vBBS_STUPIDGassyFood.HasForm(akBaseObject)
		DT("Player just ate a STUPID gassy food!")
		AddToGasQueue(akBaseObject,2.0)
	ElseIf vBBS_GassyFood.HasForm(akbaseObject)
		DT("Player just ate a gassy food!")
		AddToGasQueue(akBaseObject,1.0)
	EndIf
	If vBBS_DairyFood.HasForm(akbaseObject) && vBBS_LactoseIntolerance.GetValue() > 0; Considered separately
		DT("Player just ate a lactose-laden food!")
		AddToGasQueue(akBaseObject,vBBS_LactoseIntolerance.GetValue())
	EndIf
	If vBBS_RawMeatFood.HasForm(akbaseObject) && vBBS_RawMeatIntolerance.GetValue() > 0 ; Considered separately
		DT("Player just ate raw meat!")
		AddToGasQueue(akBaseObject,vBBS_RawMeatIntolerance.GetValue())
	EndIf
	If akBaseObject == vBBS_FoodBeanChili && vBBS_GasShoutEnabled.GetValue() > 0
		DT("Gods... Player just ate the chili!")	
		If !_bHasGasShout
			 _bHasGasShout = True
			 vBBS_GasShoutEnabledMSG.Show()
		Else
			FillGasQueue(True)
			ProcessGasQueue()
			ProcessGasQueue()
		EndIf
	EndIf
EndEvent

Event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	_bCancelGas = True
	GoToState("")
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	If PlayerREF.HasSpell(vBBS_CorruptedShoutFXSpell)
		PlayerREF.RemoveSpell(vBBS_CorruptedShoutFXSpell)
		PlayerREF.EquipItemEX(_kEquippedPower,0)
	EndIf
EndEvent

;--=== Functions ===--

Function UpdateGasLevel()
	Float fUpdateTime = GetCurrentRealTime()
	Float fTimeDiff = fUpdateTime - _fLastQueueTime
	If _bCancelGas
		EmptyGasQueue()
		_bCancelGas = False
	EndIf
	If fTimeDiff < _fUpdateQueueSpeed
		_fCurrentGasLevel = ((_fGasQueue[0] * (_fUpdateQueueSpeed - fTimeDiff)) + (_fGasQueue[1] * fTimeDiff)) / _fUpdateQueueSpeed
	Else
		ProcessGasQueue()
		_fCurrentGasLevel = _fGasQueue[0]
		_fLastQueueTime = GetCurrentRealTime()
	EndIf
	If _fCurrentGasPressure < -5
		_fCurrentGasPressure = -5
	EndIf
	vBBS_GasLevel.SetValue(_fCurrentGasLevel)
	vBBS_GasPressure.SetValue(_fCurrentGasPressure)
	vBBS_GasLoad.SetValue(_fCurrentGasLoad)
	;DT("Gas level is now " + _fCurrentGasLevel + ", Gas load is now " + _fCurrentGasLoad)
	If _fCurrentGasLevel >= 1.0 && !PlayerREF.HasSpell(vBBS_CorruptedShoutFXSpell) && _bHasGasShout && vBBS_GasShoutEnabled.GetValue() > 0
		PlayerREF.AddSpell(vBBS_CorruptedShoutFXSpell,False)
		_kEquippedPower = PlayerRef.GetEquippedObject(2)
		PlayerREF.EquipSpell(vBBS_CorruptedShoutFXSpell,2)
		vBBS_GasShoutAddedMSG.Show()
		vBBS_GasShoutHelpMSG.ShowAsHelpMessage("FartShout", 5, 30, 1)
	ElseIf _fCurrentGasLevel < 1.0 && PlayerREF.HasSpell(vBBS_CorruptedShoutFXSpell)
		PlayerREF.RemoveSpell(vBBS_CorruptedShoutFXSpell)
		PlayerREF.EquipItemEX(_kEquippedPower,0)
		vBBS_GasShoutRemovedMSG.Show()
	EndIf
EndFunction

Function EmptyGasQueue(bool abForceUpdate = False)
	;DT("Emptying gas queue and setting all levels to 0")
	Int i = _fGasQueue.Length
	While i > 0
		i -= 1
		_fGasQueue[i] = 0.0
	EndWhile
	_fCurrentGasPressure = 0.0
	_fCurrentGasLoad = 0.0
	_fCurrentGasLevel = 0.0
	If abForceUpdate
		UpdateGasLevel()
	EndIf
EndFunction

Function FillGasQueue(bool abForceUpdate = False)
	;DT("Filling gas queue and setting all levels to 1")
	Int i = _fGasQueue.Length
	While i > 0
		i -= 1
		_fGasQueue[i] = 1.0
	EndWhile
	_fCurrentGasPressure = 1.0
	_fCurrentGasLoad = 1.0
	_fCurrentGasLevel = 1.0
	If abForceUpdate
		UpdateGasLevel()
	EndIf
EndFunction

Function ProcessGasQueue()
	Float fGasTotal
	Int iGasLength = _fGasQueue.Length
	_fUpdateQueueSpeed = vBBS_DigestionSpeed.GetValue()
	Int i = 1	;Start at second entry
	While i < iGasLength
		_fGasQueue[i - 1] = _fGasQueue[i]
		fGasTotal += _fGasQueue[i - 1]
		i += 1
	EndWhile
	_fGasQueue[iGasLength - 1] = 0.0
	_fCurrentGasLoad = fGasTotal / iGasLength
	If _fCurrentGasLoad > 0.4
		vBBS_BellySM.Play(PlayerREF)
	EndIf
	;TraceGasQueue()
EndFunction

Bool Function PassGas()
	GotoState("Busy")
	Float fPassGasChance = RandomFloat(0.0,1.0)
	_fCurrentGasPressure += fPassGasChance * _fCurrentGasLevel
	;DT("Gas pressure is " + _fCurrentGasPressure)
	If (_fCurrentGasPressure > fPassGasChance && GetCurrentRealTime() - _fLastGas > 5) || _fCurrentGasPressure > 2.0
		If _fCurrentGasLevel > 0.5
			PlayerREF.CreateDetectionEvent(PlayerREF,(_fCurrentGasLevel * 100) as Int)
		EndIf
		GetLeveledSound(_fCurrentGasLevel * _fCurrentGasPressure).PlayAndWait(PlayerREF)
		If (_fCurrentGasLevel * _fCurrentGasPressure) > 0.6
			vBBS_NoiseReactSpell.Cast(PlayerREF)
		EndIf
		_fCurrentGasPressure -= _fCurrentGasLevel * _fCurrentGasPressure
		_fCurrentGasPressure -= AfterShock(_fCurrentGasLevel * fPassGasChance) ; Aftershocks delay the next event
		;DT("Gas pressure is now " + _fCurrentGasPressure)
		_fLastGas = GetCurrentRealTime()
		GotoState("")
		Return True
	Else
		;DT("Player did NOT just farted, gas pressure is now " + _fCurrentGasPressure)
		If _fCurrentGasLevel == 0 
			_fCurrentGasPressure /= 2
			If _fCurrentGasPressure < 0.01
				_fCurrentGasPressure = 0
			EndIf
		EndIf
		GotoState("")
		Return False
	EndIf
	GotoState("")
EndFunction

Sound Function GetLeveledSound(Float fGasLevel)
		If fGasLevel >= 1.0
			DT("Player just farted... good god, man, what the hell is wrong with you?")
			PlayerREF.SetExpressionOverride(9,100)
			Return vBBS_LoudLongSM
		ElseIf fGasLevel > 0.8
			DT("Player just farted loud and long")
			PlayerREF.SetExpressionOverride(12,100)
			Return vBBS_LoudMedSM
		ElseIf fGasLevel > 0.6
		PlayerREF.SetExpressionOverride(10,100)
			DT("Player just farted loud and proud")
			Return vBBS_LoudShortSM
		ElseIf fGasLevel > 0.4
			PlayerREF.SetExpressionOverride(13,100)
			DT("Player just farted not so quietly!")
			Return vBBS_QuietLongSM
		Else
			DT("Player just farted quietly!")
			Return vBBS_QuietShortSM
		EndIf
EndFunction

Float Function AfterShock(Float fGasChance)
	Float fRelief = fGasChance
	fGasChance *= vBBS_AftershockChanceMult.GetValue()
	;DT("Aftershock chance: " + fGasChance)
	If RandomFloat(0.0,1.0) < fGasChance
		Wait(RandomFloat(0.33,0.8))
		DT("   ... and again!")
		GetLeveledSound(fGasChance).PlayAndWait(PlayerREF)
		fRelief += AfterShock(fGasChance)
		Return fRelief
	EndIf
	Return 0
EndFunction

Function AddToGasQueue(Form akFoodItem, Float fSeverity = 1.0)
	
	Float fWeight = 0.16 ; 0.5 / 3
	If _bSKSE
		fWeight = akFoodItem.GetWeight() / 3.0
	EndIf
	fSeverity *= vBBS_GasMult.GetValue()
	Int iGQ = 2 + RandomInt(0,2) ; Randomly delay gas onset, but always by at least 2
	Float fRand = RandomFloat(-0.25,0.25)
	Int i = 0
	
	While i < _fGasCurve.Length
		Float fGasToAdd = (_fGasCurve[i] * fWeight * fSeverity)
		fGasToAdd += fGasToAdd * fRand ; Slightly randomize 
		_fGasQueue[iGQ] = _fGasQueue[iGQ] + fGasToAdd
		If _fGasQueue[iGQ] > 1
			_fGasQueue[iGQ] = 1.0
		ElseIf _fGasQueue[iGQ] < 0
			_fGasQueue[iGQ] = 0.0
		EndIf
		iGQ += 1
		i += 1
	EndWhile
	;TraceGasQueue()
EndFunction

Function TraceGasQueue()
	Int i = 0
	;DT("Gas Queue is now:")
	While i < _fGasQueue.Length
		DT("" + i + ": " + _fGasQueue[i])
		i += 1
	EndWhile
EndFunction

Function UpdateConfig()
	_bEnableWalking = (vBBS_EnableWalking.GetValue() as Int) as Bool
	_bEnableJumping = (vBBS_EnableJumping.GetValue() as Int) as Bool
	_bDebug = False
EndFunction

State Busy

	Event OnBeginState()
		_iBusyStateCounter = 0
	EndEvent

	Event OnAnimationEvent(ObjectReference akSource, String asEventname)
		;do nothing
	EndEvent

	Event OnUpdate()
		_iBusyStateCounter += 1
		RegisterForSingleUpdate(2.0)
		If _iBusyStateCounter > 1
			DT("Timing out of busy state!")
			GotoState("") ; We shouldn't be here this long
		EndIf
	EndEvent
	
	Bool Function PassGas()
		;do nothing
		Return False
	EndFunction

EndState

Function DT(String asDebugString)
	If _bDebug
		Debug.Trace("BBS: GasTracker: " + asDebugString)
	EndIf
EndFunction

