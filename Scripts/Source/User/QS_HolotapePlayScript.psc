Scriptname QS_HolotapePlayScript extends ObjectReference

; Attached to QS_ConfigHolotape (NOTE/Holotape). OnHolotapePlay never fired
; when played directly from the Pip-Boy (no vendor precedent for that usage,
; confirmed empirically - zero Papyrus log activity on use). OnRead() is the
; proven vanilla event for Pip-Boy-read notes/holotapes (DN020_ReadNote,
; MessageInABottleScript, etc. all use it), so the menu opens from there.
QS_SellModeControllerScript Property QuestController Auto

Event OnRead()
    QuestController.ShowConfigMenu()
EndEvent
