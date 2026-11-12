# Bellmire chat commands

Generated from `data/commands.json` by `tools/_commands_doc.gd` - edit the data, not this file.
Type them in the stream's Twitch chat. Each viewer may send one every 1.5 s (the game) / 3.0 s (Twitch reader).
Prices are list prices: the counter is a CHA check (haggling), and guild rank takes a cut.

| Command | Also | Arguments | Cost | What it does | Example |
|---|---|---|---|---|---|
| `!enlist` |  | [class] [people] | free | Raise your hero. Callings: knight, warden, barbarian, rogue, duelist, ranger, mage, sage, cleric, paladin, necromancer, monk, druid, warlock, bard. Peoples: human, elf, dwarf, halfling, orc, scarkin. Either order; leave either out and the valley picks. (no hero needed) | `!enlist knight dwarf` |
| `!hero` | !stats, !sheet |  | free | Your hero's sheet: people and calling, rank, level, AC, HP, to-hit, abilities, saves, weapon and its dice, armour, potions, oil, gold, record. | `!hero` |
| `!inventory` | !inv, !bag, !items |  | free | What your hero carries: title, weapon, armour, accessories, dye, brews, oil, gold, and the best fish caught. | `!inventory` |
| `!delve` |  |  | free (bring oil) | Walk to the scar and go down with the next party. Everyone carries their own oil; out of oil, the dark wins. | `!delve` |
| `!fish` |  |  | free | Walk to a dock and fish: junk to rare catches. | `!fish` |
| `!forge` |  | [kind / list] | 60 / 160 / 420 / 1100 gold by tier (rework at the top: a quarter) | Buy the next weapon tier at the smithy, in your calling's kinds: sword, greatsword, dagger, spear / axe, mace / staff, wand / crossbow, bow / quarterstaff, wraps. !forge list shows yours and the next price. The best tiers need Bellmire to grow; scarforged steel is only found below. | `!forge spear` |
| `!armoury` | !armory |  | 50 / 150 / 400 / 1000 gold by tier | Buy the next armour tier: leather, chainmail, plate, warded plate. It shows: boots, pauldrons, a helm. Scarwoven mail is only found below. | `!armoury` |
| `!brew` |  | [potion] [n] | Mending 35; others 40-480 gold | Buy brews at the apothecary. No name buys Draughts of Mending. Names: mending, greater, superior, supreme, antidote, emberward, hearthwarm, quickwater (haste), ogre (strength), shadow (unseen), bravecup (heroism), owl (darkvision). Heroes drink them below when they need to. | `!brew quickwater 2` |
| `!oil` | !lamp, !torch | [n] | 12 gold a flask | Buy lamp oil: one flask lights a floor for two delvers. | `!oil 3` |
| `!wear` |  | <item> / off <slot> | 30-420 gold, once | Buy and wear an accessory (rings, amulets, cloaks, boots, gloves - small bonuses) or a cosmetic (hats, banners, a pet, a title). Owned things are worn again for nothing. !wear off ring takes one off. | `!wear corgi` |
| `!dye` |  | <colour> | 25 gold | Dye your armour and cloak: black, white, red, blue, green, gold, purple, teal, brown, grey. | `!dye teal` |
| `!reroll` |  |  | free when dead; 120 gold alive | Dead: raise a new hero. Alive: throw your ability scores again (a worse throw keeps the old ones). | `!reroll` |
| `!respec` |  | <class> | 200 gold | Take up another calling, keeping your hero. | `!respec cleric` |
| `!guild` | !roll, !ranks |  | free | The Guild Roll: who stands highest. (no hero needed) | `!guild` |
| `!memorial` |  |  | free | The fallen, newest first. (no hero needed) | `!memorial` |
| `!deepest` |  |  | free | Who has been furthest down. (no hero needed) | `!deepest` |
| `!deadliest` |  |  | free | Who has killed the most. (no hero needed) | `!deadliest` |
| `!richest` |  |  | free | Who carries the most gold. (no hero needed) | `!richest` |
| `!patrons` | !benefactors |  | free | Those who have kept the valley going. (no hero needed) | `!patrons` |
| `!look` | !spotlight, !watch |  | free | Ask for a look at your hero: a 10-second pane in the channel-points lane (teal), only when nobody has redeemed it or is waiting. Cheers, subs and redeems get their own longer panes. | `!look` |
| `!help` | !commands, !valley | [command] | free | The command list; !help <command> for one in detail. (no hero needed) | `!help forge` |
