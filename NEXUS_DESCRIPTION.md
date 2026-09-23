# Quick Sell

Sell items instantly by moving them out of any container, priced like a real vendor would actually pay (Charisma + Cap Collector perk included). Plus Mobile Barter: a hidden vendor you can trade with anywhere, hotkey included. Configure via MCM or in-game with consumable items - controller friendly.

## What it does

**Sell Mode** — toggle it on (checkbox or hotkey), open any container (workbench, stash, dead body, whatever), move items between it and your inventory like normal, then close the container. A confirmation dialog pops up showing what changed, and if you confirm, the net items you picked up get instantly sold for caps — no trip to a vendor required.

Prices are based on what a **real vendor would actually pay** for the item: your Charisma and the Cap Collector perk are factored into the price the same way the game's own barter system calculates it, not just a flat cut of the item's base value. On top of that, you set your own percentage (10-100%) of that vendor price as a "tax" — so at 100% you get exactly what a vendor would pay, and lower settings simulate a worse deal.

**Mobile Barter** — a second, complementary feature: opens a real barter menu with a hidden vendor, anywhere, anytime. Unlike Sell Mode's instant-sell, this is the actual vanilla trade UI, so it fully respects your Barter perks, disposition, everything.

## Main features

- Sell Mode: transfer-to-sell workflow via any container, with a confirmation prompt before anything is sold
- Adjustable sell percentage (10-100%) of the computed real vendor price
- Mobile Barter: instant access to a real barter menu, anywhere
- Two global hotkeys (assignable in MCM): toggle Sell Mode, open Mobile Barter
- Controller-friendly: the "QuickSell Configurator" Aid item lets you grant two reusable items — "Sell Mode Switch" (toggle Sell Mode) and "Mobile Barter Beacon" (open Mobile Barter) — and adjust the sell percentage, all without touching a keyboard
- Settings are configured through MCM or via Aid item in-game

## Requirements

- [F4SE](https://f4se.silverlock.org/)
- [Mod Configuration Menu (MCM)](https://www.nexusmods.com/fallout4/mods/21497)

## Installation instructions

Install with your mod manager of choice (Vortex, MO2), or extract the archive into your `Data` folder manually. Enable the plugin. Open MCM in-game to configure.

## Known limitations

- English only.
- The vendor-price calculation uses Charisma and the Cap Collector perk (the two biggest factors). It does not currently account for smaller bonuses like the Barter Bobblehead, Junktown Vendor magazines, or Grape Mentats' price bonus (their Charisma component is still picked up automatically, just not their separate price multiplier).

## Compatibility

Quick Sell only adds its own new records (a quest, a hidden vendor cell/NPC, an MCM menu) — it doesn't touch any vanilla records, so it should be compatible with just about everything. The price calculation reads the game's own barter settings live, so economy-overhaul mods that change vendor pricing should be reflected automatically.

## Source code

Everything is on GitHub: [github.com/victor-ai-mods/fo4-quicksell](https://github.com/victor-ai-mods/fo4-quicksell) - the Papyrus scripts, the plugin and the MCM config.

The code is released under **The Unlicense**: public domain. Do whatever you want with it - copy it, change it, publish it, sell it, no permission and no credit needed.

## Development & testing

This mod was vibe-coded with [Claude Code](https://claude.com/claude-code). Tested only on game version **1.10.163** — if you're on a different version and run into issues, please report them.
