# Quick Sell

A Fallout 4 mod. Published on Nexus Mods: https://www.nexusmods.com/fallout4/mods/109100

- **Sell Mode** — open any container, move items out of it or into it, close it, confirm: everything
  moved (the net difference per item) is sold for caps on the spot, at the price a real vendor would
  pay (Charisma and Cap Collector included), times your own percentage (10–100%). Items taken out are
  sold from your inventory, items put in are sold from the container. Sell Mode switches itself off
  after each confirmation dialog.
- **Mobile Barter** — the real vanilla barter menu with a hidden vendor, anywhere.
- Two MCM hotkeys, plus Aid items for controller players.

Requires F4SE and [Mod Configuration Menu](https://www.nexusmods.com/fallout4/mods/21497).
Tested on game version 1.10.163. The full user-facing description is on the
[Nexus page](https://www.nexusmods.com/fallout4/mods/109100).

## What is here

| Path | What |
|---|---|
| `QuickSell.esp` | The plugin, made in the Creation Kit: controller quest, confirmation message, hidden vendor (NPC, faction, cell, caps chest), Aid items |
| `Scripts/Source/User/QS_*.psc` | Papyrus source for every script the plugin uses |
| `MCM/Config/QuickSell/config.json` | The MCM page |
| `MCM/Config/QuickSell/keybinds.json` | What the MCM hotkeys call — without this file MCM accepts a hotkey and then silently resets it to None |
| `tools/patch_aid_items.py` | Binary fix applied to the CK-made `QuickSell.esp` in 1.5: the Aid items were Stimpak copies and kept its `PlayAnimOnItemUse` / `ObjectTypeStimpak` keywords, which let stimpak/animation mods swallow their use. Idempotent; run it again if the plugin is ever re-saved in the Creation Kit |

## Build

```
"D:\Games\Fallout 4\Papyrus Compiler\PapyrusCompiler.exe" "Scripts\Source\User" ^
    -i="Scripts\Source\User;D:\Games\Fallout 4\Data\Scripts\Source\User;D:\Games\Fallout 4\Data\Scripts\Source\Base" ^
    -o="build" -f="Institute_Papyrus_Flags.flg" -all
```

`Data\Scripts\Source\User` must contain `MCM.psc`, which ships with Mod Configuration Menu.
`Data\Scripts\Source\Base` is the vanilla script source unpacked from `Base.zip`.

To install by hand, copy `QuickSell.esp` into `Data\`, the compiled `build\*.pex` into
`Data\Scripts\`, and `MCM\` into `Data\MCM\`, then enable the plugin.

## License

[The Unlicense](LICENSE) — public domain. Do whatever you want with this code; no attribution
required.
