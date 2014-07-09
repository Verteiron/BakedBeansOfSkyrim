Scriptname vBBS_CorruptedVoiceMEScript extends ActiveMagicEffect  
{Inflict panic, randomly inflict paralyze, poison.}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

vBBS_MetaQuestScript Property MetaQuestScript Auto

Activator Property vBBS_SteamBlastAct Auto
Activator Property vBBS_PoisonGasAct Auto
Activator Property FXEmptyActivator Auto ; Actually vBBS_FXEmptyActivator, just in case they don't get cleaned up somehow, uninstalling the mod will delete them

Actor Property PlayerREF Auto

Idle Property IdleBracedPain Auto
Idle Property IdleBoyRitual Auto
Idle Property IdleGreybeardMeditateEnter Auto
Idle Property IdleGreybeardMeditateExit Auto
Idle Property IdleStop_loose Auto

Topic Property TopicToSay Auto
{Which topic has the info the target should say?}

Sound Property vBBS_CorruptedVoiceDrySM Auto
Sound Property vBBS_CorruptedVoiceSurroundSM Auto

Sound Property QSTUstengravRumble2DLPM Auto

Spell Property vBBS_CorruptedShoutDamageSpell Auto

Spell Property vBBS_GasPushSpell Auto

Spell Property vBBS_PoisonCloudAbility Auto

Spell Property vBBS_GasPushArea Auto

;--=== Variables ===--

Actor kTarget

Bool _bShaking = False

ObjectReference kGas
ObjectReference kSteam
ObjectReference kSpellSource
ObjectReference kSpellTarget
ObjectReference kSoundSource
;--=== Events ===--

Event OnEffectStart(Actor akTarget, Actor akCaster)
	Bool bInterior = PlayerREF.GetParentCell().IsInterior()
	kSoundSource = PlayerREF.PlaceAtMe(FXEmptyActivator)
	kSpellSource = PlayerREF.PlaceAtMe(FXEmptyActivator)
	kSpellTarget = PlayerREF.PlaceAtMe(FXEmptyActivator)
	_bShaking = True
	Int _iRumbleInstance = QSTUstengravRumble2DLPM.Play(kSoundSource)
	ShakeCamera(PlayerREF,0.4,2.0)
	DisablePlayerControls()
	Wait(0.25)
	PlayerREF.PlayIdle(IdleStop_loose)
	Wait(0.25)
	Game.ForceThirdPerson()
	
	;Debug.SendAnimationEvent(PlayerREF,"bleedOutStart")
	;Debug.SendAnimationEvent(PlayerREF,"WW_Stage1")
	;Debug.SendAnimationEvent(PlayerREF,"IdleActivatePickUpLow"); - FootScuffRight
	;Debug.SendAnimationEvent(PlayerREF,"IdleGreybeardMeditateEnter")
	;Debug.SendAnimationEvent(PlayerREF,"IdleBoyRitual")
	;PlayerREF.SetAngle(PlayerREF.GetPositionX(),PlayerREF.GetPositionY(),PlayerREF.GetPositionZ(),PlayerREF.GetAngleX(),PlayerREF.GetAngleY(),PlayerREF.GetAngleZ() + 180,1000,1080)
	Wait(0.25)
	PlayerREF.PlayIdle(IdleBracedPain)
	PlayerREF.SetExpressionOverride(13,100)
	ShakeCamera(PlayerREF,0.6,2.0)
	Wait(0.5)
	;PlayerREF.EnableAI(0)
	kGas = PlayerREF.PlaceAtMe(vBBS_PoisonGasAct,abInitiallyDisabled = True)
	MetaQuestScript.GasTracker.FillGasQueue(True)
	kGas.SetScale(2.0)
	kGas.SetAngle(180,0,PlayerREF.GetAngleZ())
	kGas.EnableNoWait(False)
	kSteam = PlayerREF.PlaceAtMe(vBBS_SteamBlastAct,abInitiallyDisabled = True)
	;kSteam.MoveToNode(PlayerREF,"NPC Pelvis [Pelv]")
	kSteam.MoveToNode(PlayerREF,"SkirtBBone02")
	;kSteam.MoveToNode(PlayerREF,"NPC Spine [Spn0]")
	kSteam.SetScale(0.75)
	kSteam.SetAngle(Math.cos(PlayerREF.GetAngleZ()) * -105,-Math.sin(PlayerREF.GetAngleZ()) * -105,0)
	;SpawnPoint.SetAngle(MultX * -15,MultY * -15,RandomInt(0,359))
	kGas.PlayGamebryoAnimation("animIdle02")
	kSteam.EnableNoWait(True)
	PlayerREF.SetExpressionOverride(10,25)
	kSpellSource.MoveTo(kSteam,Math.cos(PlayerREF.GetAngleZ() + 90) * 50,-Math.sin(PlayerREF.GetAngleZ() + 90) * 50,35)
	kSpellTarget.MoveTo(kSteam,Math.cos(PlayerREF.GetAngleZ() + 90) * 100,-Math.sin(PlayerREF.GetAngleZ() + 90) * 100,36)
	;kSpellSource.SetAngle(0,0,kSpellSource.GetAngleZ() + kSpellSource.GetHeadingAngle(kSpellTarget))
	kSteam.TranslateTo(kSteam.GetPositionX(),kSteam.GetPositionY(),kSteam.GetPositionZ(),kSteam.GetAngleX(),kSteam.GetAngleY(),359,100,90)
	;vBBS_CorruptedVoiceDrySM.Play(PlayerREF)
	;If !bInterior
		vBBS_CorruptedVoiceSurroundSM.Play(kSoundSource)
	;EndIf
	vBBS_GasPushSpell.RemoteCast(kSpellSource,PlayerREF,kSpellTarget) ;,kSteam)
	RegisterForSingleUpdate(0.25)
	PlayerREF.AddSpell(vBBS_PoisonCloudAbility,False)
	PlayerREF.SetExpressionOverride(12,100)
	vBBS_GasPushArea.Cast(PlayerREF)
	Wait(1.25)
	vBBS_GasPushArea.Cast(PlayerREF)
	PlayerREF.SetExpressionOverride(10,100)
	Wait(1.25)
	vBBS_GasPushArea.Cast(PlayerREF)
	PlayerREF.SetExpressionOverride(9,100)
	Wait(2.5)
	PlayerREF.RemoveSpell(vBBS_PoisonCloudAbility)
	MetaQuestScript.GasTracker.EmptyGasQueue(True)
	kSteam.DisableNoWait(True)
	kSpellSource.InterruptCast()
	;PlayerREF.EnableAI(1)
	_bShaking = False
	PlayerREF.PlayIdle(IdleStop_loose)
	;Debug.SendAnimationEvent(PlayerREF,"NPC_BumpedFromBack")
	Wait(1.0)
	EnablePlayerControls()
	;kSpellTarget.PushActorAway(PlayerREF,1.0)
	;Debug.SendAnimationEvent(PlayerREF,"IdleBoyRitualStand")
	;Debug.SendAnimationEvent(PlayerREF,"MT_BoyRitualStand")
	;Debug.SendAnimationEvent(PlayerREF,"bleedOutStop")
	;Debug.SendAnimationEvent(PlayerREF,"IdleGreybeardMeditateExit")
	PlayerREF.SetExpressionOverride(10,100)
	Wait(2.0)
	kGas.DisableNoWait(True)
	Sound.StopInstance(_iRumbleInstance)
	kSteam.Delete()
	PlayerREF.ClearExpressionOverride()
EndEvent

Event OnUpdate()
	If _bShaking
		vBBS_CorruptedShoutDamageSpell.Cast(PlayerREF)
		ShakeCamera(PlayerREF,1.0)
		RegisterForSingleUpdate(0.5)
	EndIf
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	Wait(1)
	kSpellSource.Delete()
	kSpellTarget.Delete()
	Wait(15)
	kSoundSource.Delete()
	kGas.Delete()
EndEvent


;--=== Functions ===--

Function SaySomething(Actor akTarget)
	If akTarget != Game.GetPlayer()
		If akTarget.IsCommandedActor() == 0 || akTarget.IsPlayerTeammate() == 0
			If TopicToSay != None
				akTarget.Say(TopicToSay)
			EndIf
		EndIf
	EndIf
EndFunction
