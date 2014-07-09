Scriptname vBBS_NoiseReactMEScript extends activemagiceffect  
{Attract attention when there is a rude noise.}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Actor Property PlayerREF Auto

Topic Property TopicToSay Auto
{Which topic has the info the target should say?}

int Property AllowForTeammate = 0 Auto  

Topic Property CombatTopicToSay  Auto  

GlobalVariable Property vBBS_GasCommentTimer  Auto  

GlobalVariable Property GameDaysPassed  Auto  

;--=== Variables ===--

Actor kTarget

Bool _bGotMe

;--=== Events ===--

Event OnEffectStart(Actor akTarget, Actor akCaster)
	;debug.trace(self + "OnEffectStart(" + akTarget + "," + akCaster + ")")
	kTarget = akTarget
	If RandomInt(0,2) > 0
		_bGotMe = True
		akTarget.SetLookat(akCaster)
		akTarget.SetExpressionOverride(6,100) ; Disgust
	EndIf
	RegisterForSingleUpdate(RandomFloat(0.0,1.5))
EndEvent

Event OnUpdate()
	SaySomething(kTarget)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	If _bGotMe
		akTarget.ClearExpressionOverride()
		akTarget.ClearLookat()
	EndIf
EndEvent


;--=== Functions ===--

Function SaySomething(Actor akTarget)
	;Debug.Trace("BBS: vBBS_GasCommentTimer is " + vBBS_GasCommentTimer.GetValue() + ", GameDaysPassed is " + GameDaysPassed.GetValue() + ", " + (vBBS_GasCommentTimer.GetValue() - GameDaysPassed.GetValue()) + " until next comment.")
	If akTarget != Game.GetPlayer()
		If akTarget.GetCurrentScene() == None
			If GameDaysPassed.GetValue() > vBBS_GasCommentTimer.GetValue()
				If AllowForTeammate == 0
					If akTarget.IsCommandedActor() == 0 || akTarget.IsPlayerTeammate() == 0
						If akTarget.IsInCombat() == 0
							;debug.trace(self + "OnEffectStart() will call Say(" + TopicToSay + ")")
							vBBS_GasCommentTimer.SetValue(GameDaysPassed.GetValue() + 0.001)
							akTarget.Say(TopicToSay)
						ElseIf CombatTopicToSay != None
							vBBS_GasCommentTimer.SetValue(GameDaysPassed.GetValue() + 0.001)
							akTarget.Say(CombatTopicToSay)
						EndIf
					EndIf
				ElseIf akTarget.IsPlayerTeammate() == 1
					;debug.trace(self + "OnEffectStart() will call Say(" + TopicToSay + ")")
					vBBS_GasCommentTimer.SetValue(GameDaysPassed.GetValue() + 0.001)
					akTarget.Say(TopicToSay)
				EndIf
			EndIf
		EndIf
	EndIf

EndFunction