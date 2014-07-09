Scriptname vBBS_SayOnMagicHitNoTimer extends ActiveMagicEffect  
{Causes actor to say a line when hit by this spell}

Actor Property PlayerREF Auto

GlobalVariable Property GameDaysPassed Auto
GlobalVariable Property WICastNonHostileTimer Auto

Topic Property TopicToSay Auto
{Which topic has the info the target should say?}

Topic Property CombatTopicToSay  Auto  

Float Property TimeToAdd Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)

; ;	debug.trace(self + "OnEffectStart(" + akTarget + "," + akCaster + ")")

	If akTarget != PlayerREF
		If akTarget.GetCurrentScene() == None
			If (GameDaysPassed.value > WICastNonHostileTimer.value)
				If akTarget.IsCommandedActor() == 0 || akTarget.IsPlayerTeammate() == 0
					If akTarget.IsInCombat() == 0
; ;							debug.trace(self + "OnEffectStart() will call Say(" + TopicToSay + ")")
						WICastNonHostileTimer.SetValue(GameDaysPassed.GetValue() + TimeToAdd)
						akTarget.Say(TopicToSay)
					ElseIf CombatTopicToSay != None
						WICastNonHostileTimer.SetValue(GameDaysPassed.GetValue() + TimeToAdd)
						akTarget.Say(CombatTopicToSay)
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

EndEvent


