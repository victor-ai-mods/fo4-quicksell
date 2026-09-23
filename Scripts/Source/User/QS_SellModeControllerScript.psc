Scriptname QS_SellModeControllerScript extends Quest

; ============================================================
; Bound directly by MCM (PropertyValueBool / PropertyValueInt
; in config.json) — MCM reads and writes these live, no
; OnConfigInit/OnSettingChange plumbing needed.
; ============================================================
Bool Property SellModeActive = false Auto
Int Property SellPercent = 75 Auto

; ============================================================
; Wired by hand in the Creation Kit after the forms exist.
; ============================================================
Message Property ConfirmSellMessage Auto
ObjectReference Property VendorRef Auto
Form Property QS_ConfigHolotapeItem Auto
Form Property QS_ToggleSellModeAidItem Auto
Form Property QS_OpenBarterAidItem Auto
Message Property ConfigMenuMessage Auto
Message Property SellPercentMenuMessage Auto

; ============================================================
; Internal tracking state (net transfer per Form while a
; container menu is open and Sell Mode is active).
; ============================================================
Bool bContainerMenuOpen = false
Bool bOpeningBarter = false
ObjectReference OtherContainerRef
Form[] TrackedForms
Int[] TrackedAmounts
Int TrackedCount = 0

Event OnQuestInit()
    TrackedForms = new Form[128]
    TrackedAmounts = new Int[128]
    ; Vanilla requirement (ScriptObject.psc): "Objects without filters CANNOT
    ; receive inventory add/remove events!" - the filter goes on the listening
    ; script instance (self), not the observed object - confirmed against
    ; vanilla MinRadiantOwned07Script.psc, which does the same remote-event
    ; setup for Game.GetPlayer() OnItemAdded.
    Self.AddInventoryEventFilter(None)
    RegisterForRemoteEvent(Game.GetPlayer(), "OnItemAdded")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnItemRemoved")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    RegisterForMenuOpenCloseEvent("ContainerMenu")
EndEvent

Event ObjectReference.OnItemAdded(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    ; akSourceContainer/akDestContainer are both None for the remote-item
    ; self-grant in QS_ToggleSellAidEffectScript/QS_OpenBarterAidEffectScript
    ; (an Aid item re-adding itself after use, not a real container transfer)
    ; - ignore those so they can't stomp OtherContainerRef mid-sale.
    If SellModeActive && bContainerMenuOpen && akSourceContainer
        OtherContainerRef = akSourceContainer
        TrackDelta(akBaseItem, aiItemCount)
    EndIf
EndEvent

Event ObjectReference.OnItemRemoved(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    If SellModeActive && bContainerMenuOpen && akDestContainer
        OtherContainerRef = akDestContainer
        TrackDelta(akBaseItem, -aiItemCount)
    EndIf
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    GrantConfigHolotape()
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    If asMenuName == "ContainerMenu"
        If abOpening
            ; MCM's "SellModeActive" checkbox is a raw PropertyValueBool
            ; binding (writes the property directly, calls no function), so
            ; there is no reliable hook to re-apply the filter when Sell Mode
            ; is turned on for a save that predates this fix. This event fires
            ; on every container open regardless, so re-apply it here too.
            Self.AddInventoryEventFilter(None)
            ; Same rationale as the filter re-apply above: this is the one
            ; event already registered for every existing save, so it's the
            ; reliable retroactive bootstrap for players who updated from a
            ; version before the config holotape existed.
            GrantConfigHolotape()
            bContainerMenuOpen = true
            ClearTracking()
        Else
            ; Small grace window: some "quick take" container UIs fire
            ; the menu-close event slightly before the matching
            ; OnItemAdded/OnItemRemoved lands, so don't drop tracking
            ; the instant the menu closes.
            Utility.Wait(0.3)
            bContainerMenuOpen = false
            ShowSellConfirmation()
        EndIf
    EndIf
EndEvent

Function TrackDelta(Form akItem, Int aiDelta)
    If !akItem || aiDelta == 0
        Return
    EndIf
    Int idx = TrackedForms.Find(akItem)
    If idx == -1
        If TrackedCount >= 128
            Return
        EndIf
        TrackedForms[TrackedCount] = akItem
        TrackedAmounts[TrackedCount] = aiDelta
        TrackedCount += 1
    Else
        TrackedAmounts[idx] += aiDelta
    EndIf
EndFunction

; Fires automatically on ContainerMenu close; also callable
; manually from the MCM "bManualPrompt" button as a fallback.
Function ShowSellConfirmation()
    If TrackedCount == 0 || !OtherContainerRef
        ClearTracking()
        Return
    EndIf

    Int choice = ConfirmSellMessage.Show()
    SellModeActive = false
    MCM.RefreshMenu()
    If choice == 0
        ProcessSale()
    EndIf
    ClearTracking()
EndFunction

Function ProcessSale()
    Actor player = Game.GetPlayer()
    Float sellFraction = GetVendorSellFraction(player)
    Int i = 0
    While i < TrackedCount
        Form item = TrackedForms[i]
        Int net = TrackedAmounts[i]
        If item && net != 0
            ObjectReference holder
            Int qty = net
            If net > 0
                holder = player
            Else
                holder = OtherContainerRef
                qty = -net
            EndIf
            Int price = ((item.GetGoldValue() as Float) * sellFraction * SellPercent / 100.0 + 0.5) as Int
            holder.SellItem(item, price, qty, true, None, player)
        EndIf
        i += 1
    EndWhile
EndFunction

; Fraction of an item's base Gold Value that a real vendor would actually pay,
; replicating the vanilla barter formula (fBarterMax/fBarterMin scaled by
; Charisma, Cap Collector perk ranks, capped at fBarterSellMax) - read live
; from game settings so economy-overhaul mods are respected automatically.
; SellPercent is applied on top of this, i.e. it's now a cut of the real
; vendor price instead of a cut of the raw base value.
Float Function GetVendorSellFraction(Actor akPlayer)
    Float barterMax = Game.GetGameSettingFloat("fBarterMax")
    Float barterMin = Game.GetGameSettingFloat("fBarterMin")
    Float cha = akPlayer.GetValue(Game.GetCharismaAV())
    Float priceFactor = barterMax - (barterMax - barterMin) * (cha / 10.0)

    Float sellMult = 1.0
    Perk capCollectorRank1 = Game.GetFormFromFile(0x001D2456, "Fallout4.esm") as Perk
    Perk capCollectorRank2 = Game.GetFormFromFile(0x000D75E2, "Fallout4.esm") as Perk
    If capCollectorRank1 && akPlayer.HasPerk(capCollectorRank1)
        sellMult *= 1.10
    EndIf
    If capCollectorRank2 && akPlayer.HasPerk(capCollectorRank2)
        sellMult *= 1.20
    EndIf

    Float fraction = sellMult / priceFactor
    Float sellCap = Game.GetGameSettingFloat("fBarterSellMax")
    If fraction > sellCap
        fraction = sellCap
    EndIf
    Return fraction
EndFunction

Function ClearTracking()
    TrackedCount = 0
    OtherContainerRef = None
EndFunction

Function GrantConfigHolotape()
    If QS_ConfigHolotapeItem && Game.GetPlayer().GetItemCount(QS_ConfigHolotapeItem) == 0
        Game.GetPlayer().AddItem(QS_ConfigHolotapeItem, 1, true)
    EndIf
EndFunction

; ---- Config menu (QS_ConfigHolotape -> QS_HolotapePlayScript.OnRead()) ----

Function ShowConfigMenu()
    Int choice = ConfigMenuMessage.Show()
    If choice == 0
        GrantAidItem(QS_ToggleSellModeAidItem, "Sell Mode Switch")
        ShowConfigMenu()
    ElseIf choice == 1
        GrantAidItem(QS_OpenBarterAidItem, "Mobile Barter Beacon")
        ShowConfigMenu()
    ElseIf choice == 2
        ShowSellPercentMenu()
        ShowConfigMenu()
    EndIf
EndFunction

Function GrantAidItem(Form akItem, String asDisplayName)
    If akItem && Game.GetPlayer().GetItemCount(akItem) == 0
        Game.GetPlayer().AddItem(akItem, 1, true)
    EndIf
    Debug.Notification(asDisplayName + " added to Aid")
EndFunction

; MCM "Add mod management items to Aid" button - recovers all three Aid
; items at once (Configurator + whichever of Sell Mode Switch/Mobile Barter
; Beacon the player already unlocked through it), in case any were lost,
; sold, or scrapped. Kept separate from GrantConfigHolotape(), which only
; ever re-grants the Configurator itself and is also called automatically
; on load/container-open - that automatic path should stay opt-in for the
; other two items, not hand them out to players who never unlocked them.
Function GrantAllAidItems()
    GrantAidItem(QS_ConfigHolotapeItem, "QuickSell Configurator")
    GrantAidItem(QS_ToggleSellModeAidItem, "Sell Mode Switch")
    GrantAidItem(QS_OpenBarterAidItem, "Mobile Barter Beacon")
EndFunction

Function ShowSellPercentMenu()
    Int choice = SellPercentMenuMessage.Show(SellPercent as Float)
    If choice == 0
        SellPercent += 5
        If SellPercent > 100
            SellPercent = 100
        EndIf
        MCM.RefreshMenu()
        Debug.Notification("Sell price: " + SellPercent + "%")
        ShowSellPercentMenu()
    ElseIf choice == 1
        SellPercent -= 5
        If SellPercent < 10
            SellPercent = 10
        EndIf
        MCM.RefreshMenu()
        Debug.Notification("Sell price: " + SellPercent + "%")
        ShowSellPercentMenu()
    EndIf
EndFunction

; ---- MCM button callbacks (config.json "CallFunction") ----

Function ManualShowSellConfirmation()
    ShowSellConfirmation()
EndFunction

Function ToggleSellMode()
    SellModeActive = !SellModeActive
    If SellModeActive
        Debug.Notification("Sell Mode: enabled")
    Else
        Debug.Notification("Sell Mode: disabled")
    EndIf
    MCM.RefreshMenu()
EndFunction

Function OpenBarter()
    ; Re-entrancy guard against a near-simultaneous double call (hotkey
    ; pressed right as the Mobile Barter Beacon's effect fires, or vice
    ; versa) opening two overlapping barter menus at once.
    If bOpeningBarter
        Return
    EndIf
    If !VendorRef
        Return
    EndIf
    bOpeningBarter = true
    Actor vendorActor = VendorRef as Actor
    If vendorActor
        ; The vendor never leaves its own hidden cell - confirmed by direct
        ; testing that ShowBarterMenu() doesn't need it anywhere near the
        ; player or 3D-loaded, and that it never needs to be
        ; Disabled/repositioned between uses either (that's what caused
        ; merchant inventory to take ~20s to resync on the next open). Since
        ; the player never gets physically or visually near it, none of the
        ; hide/shrink/no-collision workarounds that would matter for a
        ; visible vendor are needed.
        VendorRef.Enable()
        vendorActor.ShowBarterMenu()
    EndIf
    bOpeningBarter = false
EndFunction

; ---- MCM hotkey callbacks ("Hotkeys" page, "type": "hotkey" controls) ----
; MCM calls these directly by name (matching the control's "id") when the
; assigned key is pressed anywhere in-game - not via OnMCMSettingChange.

Function SellModeToggleHotkey()
    ToggleSellMode()
EndFunction

Function OpenBarterHotkey()
    OpenBarter()
EndFunction
