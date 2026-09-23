Scriptname QS_ToggleSellAidEffectScript extends ActiveMagicEffect

; Attached to QS_ToggleSellModeMGEF, the sole effect on QS_ToggleSellModeAid.
; Reuses the same ToggleSellMode() the MCM checkbox/hotkey already call, then
; re-adds itself so using it from Aid never actually consumes the item.
QS_SellModeControllerScript Property QuestController Auto
Form Property SelfItem Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == Game.GetPlayer()
        QuestController.ToggleSellMode()
        akTarget.AddItem(SelfItem, 1, true)
    EndIf
EndEvent
