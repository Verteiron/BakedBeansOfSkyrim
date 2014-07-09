Scriptname vBBS_SelectiveKnockdownScript extends ActiveMagicEffect  
{Inflict panic, randomly inflict paralyze, poison.}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Float Property PushForceMax = 15.0 Auto

Float Property PushForceRadius = 350.0 Auto

;--=== Variables ===--

Actor kTarget

;--=== Events ===--

Event OnEffectStart(Actor akTarget, Actor akCaster)
	Float fTargetDistance = akCaster.GetDistance(akTarget) 
	Float fTargetHeading = ((akCaster.GetHeadingAngle(akTarget) + 360) as Int) % 360
	If fTargetHeading > 105 && fTargetHeading < 255 && fTargetDistance < PushForceRadius
		;Debug.Trace("BBS: PushActorAway(" + akTarget + "," + PushForceMax * ((PushForceRadius - fTargetDistance) / PushForceRadius) + ") Angle is " + fTargetHeading) 	
		akCaster.PushActorAway(akTarget,PushForceMax * ((PushForceRadius - fTargetDistance) / PushForceRadius))
	ElseIf fTargetDistance < PushForceRadius / 3
		akCaster.PushActorAway(akTarget,PushForceMax * (((PushForceRadius / 3) - fTargetDistance) / PushForceRadius))
	EndIf
EndEvent

Event OnUpdate()
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
EndEvent


;--=== Functions ===--
