Scriptname QS_OpenBarterAidEffectScript extends ActiveMagicEffect

; Attached to QS_OpenBarterMGEF, the sole effect on QS_OpenBarterAid.
; Reuses the same OpenBarter() the MCM button/hotkey already call, then
; re-adds itself so using it from Aid never actually consumes the item.
QS_SellModeControllerScript Property QuestController Auto
Form Property SelfItem Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == Game.GetPlayer()
        QuestController.OpenBarter()
        akTarget.AddItem(SelfItem, 1, true)
    EndIf
EndEvent
