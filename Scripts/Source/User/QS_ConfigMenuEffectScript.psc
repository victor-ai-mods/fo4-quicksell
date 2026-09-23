Scriptname QS_ConfigMenuEffectScript extends ActiveMagicEffect

; Attached to QS_ConfigMenuMGEF, the sole effect on QS_ConfigMenuAid.
; Replaces the original NOTE/Holotape trigger (QS_ConfigHolotape +
; QS_HolotapePlayScript.OnRead()) - confirmed via Papyrus log that neither
; OnHolotapePlay nor OnRead() ever fires when a Voice-type Note/Holotape with
; no linked sound is read directly from the Pip-Boy (SKK's own working
; holotape instead uses Type=Terminal with a linked TERM record, which the
; engine opens natively with no script event at all - a different, riskier
; mechanism we deliberately avoided). Reusing the already-proven Aid item +
; MGEF + ActiveMagicEffect pattern instead.
QS_SellModeControllerScript Property QuestController Auto
Form Property SelfItem Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == Game.GetPlayer()
        ; Using an Aid item fires this in the same frame the Pip-Boy is still
        ; open in - Message.Show() can't reliably stack over a still-open
        ; Pipboy menu right then (confirmed: this is what caused the "use
        ; item" animation to get stuck and replay on every Pipboy open/close,
        ; with the menu never actually appearing). ShowSellConfirmation()
        ; avoids this by only calling Message.Show() after ContainerMenu has
        ; already closed (plus a 0.3s grace wait) - give the Pipboy one frame
        ; to finish its own item-use transaction here too before opening ours.
        Utility.Wait(0.1)
        QuestController.ShowConfigMenu()
        akTarget.AddItem(SelfItem, 1, true)
    EndIf
EndEvent
