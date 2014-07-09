Scriptname vBBS_PlayerLoadGameAliasScript extends ReferenceAlias  

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

;--=== Variables ===--

;--=== Events ===--

Event OnPlayerLoadGame()
	(GetOwningQuest() as vBBs_MetaQuestScript).DoUpkeep()
EndEvent

Event OnUpdate()
	;Do nothing
EndEvent

;--=== Functions ===--
