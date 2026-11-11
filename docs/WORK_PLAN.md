# WORK PLAN 2 — Bellmire HD grows (Nov 11 2026 onward)

Two machines work at once, on DIFFERENT files so they never clash:
- DESKTOP (CruzaderPC, scheduled build runs, branch `main`): the town, its people, magic. Lock: docs/RUN_LOCK.txt
- LAPTOP (jestai, its own Claude Code session, branch `laptop`): monsters, bosses, gear, classes, species.
  Lock: docs/RUN_LOCK_LAPTOP.txt. It pulls `main` and merges it into `laptop` before each item; Claude in the
  main chat merges `laptop` into `main` when an item is tested.

Each run: take the FIRST unchecked item in ITS OWN section. Same loop as before: read the code, edit, parse
check (0 SCRIPT ERROR / Parse Error), the item's test + render + LOOK, the standard checks (_delve_test,
_offfloor, _twitch_parse, _townwalk), tick it here with one line, PROGRESS.md cycle, commit + push
(desktop -> main, laptop -> laptop), lock IDLE.

DnD RULE (Mr. E, Nov 11): the game is D&D at heart - almost every action is decided by a ROLL, not a
flat chance or a fixed number. Attacks: d20 + to-hit vs AC; damage: weapon dice + mod; saves: d20 + save
vs DC; skills (fishing, haggling, tracking, picking a lock, spotting a trap, sneaking, calming a horse,
the town's work) as ability checks d20 + mod (+ proficiency if trained) vs a DC; spells as checks/saves;
initiative; advantage/disadvantage where it fits; nat 20 / nat 1. Use the character's real stats (roster.mod,
roster.prof, save_bonus). Big rolls can show in the Chronicle ("BigAxe rolls a 20!").

LORE RULE: before adding monsters, bosses, classes, species, spells or NPC types, read the original game
(read only) — its bestiary, classes, races and lore files — and use what it already has first. Anything new
must fit its world and be named in its voice. Never state a dungeon floor count.
THE ORIGINAL lives at C:\Users\morta\OneDrive\MortalScorpion\OneDrive\Public\Documents\trial-and-error
(NOT C:\Users\morta\OneDrive\Public, which is an empty stub). Its spells: player.gd fire (38 dmg, 24 m/s,
orange) + frost (24 dmg, 32 m/s, blue), cast from +1.1 m, 1 m ahead; NOTES.md LORE BIBLE: scar misfire rule.
ASSETS: free CC0 only (Quaternius, KayKit, Kenney), downloaded into assets/<kind>/ with a LICENSE note.
Note: Quaternius "Bestiary" packs are NOT CC0 (QAL licence) - skip them.

## DESKTOP (town, people, magic) — files: town.gd, townsfolk.gd, town_nav.gd, spells.gd, raids.gd, daylight.gd, sfx.gd
- [x] D1. Phasing through buildings, for good: find every way people still walk through houses (routes
      that skip the navmesh, spawn/exit inside footprints, heroes' own movement, raiders, settlers, the
      town band). Every walker uses the navmesh; doors on the street side; local avoidance between people.
      tools/_townwalk.gd must report in_solid under 0.2% and a render must show it.
      DONE cycle 58: in_solid 0/6999 (was 64/7194 = 0.89%), raiders+defenders 0/4911, doors 67/67 reachable; renders/cycles/20261111_d1.
- [x] D2. Spells aimed at the sky: bolts fly up at the ceiling/sky and still hit (the "4th of July").
      Fix the aim (source at the caster's hands, target the foe's chest, flat arc), give each spell a
      readable travel + impact. Then NEW spells from the lore for the caster classes (heal over time, ward,
      chain bolt, fire burst, frost slow, smite) wired into delve and raid combat. Render a fight and look.
      DONE cycle 59: cause = health bars counted in Monster._height(), so bar and bolt aim climbed every frame;
      HealthBar3D holds its height, Spells aims hands->chest (cap 2.4 m), flat arc; chain/fire/frost/smite/renew
      + ward in raid combat (mage/sage/cleric cast at 8 m). _d2_spells D2_SPELLS OK; renders/cycles/20261111_d2.
      FOR THE LAPTOP: monster.gd _local_bounds() should skip HealthBar3D; delve.gd casters can call the new
      kinds: Spells.cast(kind, caster, target_body, in_scar, more_bodies) + Spells.flight() for the landing.
      LAPTOP HALF DONE (Cycle 63): bars skip in Monster bounds; delve casters use the books + menders; D2_DELVE OK.
- [x] D3. Buildings that level up: each town level/tier visibly changes Bellmire - plots fill in, houses
      upgrade (bigger/stone storeys, signs, gardens), new buildings unlock (guild hall, market hall,
      stables, bathhouse, mage tower, keep walls in stone...). Render levels 1, 3, 5, 7 side by side.
      DONE cycle 64: scripts/growth.gd - 56 house plots fill 23/31/39/45/51/56 over the lore's 6 levels (staked
      lots till then); gardens/signs+lamps/stone plinth+chimney/+1 storey/pennants; palisade -> stone wall at 4;
      Market Hall 3, Town Stables 4, Delvers' Guild + Bathhouse 5, Mage Tower 6. D3_TEST OK; renders/cycles/20261111_d3
      (the lore has 6 levels, not 7: rendered 1, 3, 5, 6).
- [x] D4. More guards and the cavalry: more watch with patrol routes, gate guards, tower archers; mounted
      town guards (horses + riders, TOWN GUARDS ONLY) patrolling the roads and riding out at raids.
      Horses: CC0 (Quaternius animals) or a simple rig. Stables building from D3.
      DONE cycle 65: all 8 gate posts manned, 2 crossbowmen per watchtower who shoot raiders (bolts fly, d20 on
      landing), watch 12/14/16 walkers on wall/market/bridge beats by level ("sworn into the watch"); scripts/
      cavalry.gd - Knight on the Quaternius CC0 horse, 2/3/4 riders at levels 4/5/6 ride a gate loop from the
      Town Stables, ride out at raids (hp 80). D4_TEST OK; renders/cycles/20261111_d4.
- [ ] D5. More animals: horses in paddocks, cows, sheep, pigs, chickens, dogs, cats, birds over the
      fields, ducks; herded and penned, never on rooftops.
- [ ] D6. Unique NPCs: named characters with jobs and daily routines from the lore (the chief, the smith,
      the healer, the innkeeper, the priest, a bard, a town crier who reads the Chronicle aloud, merchants
      with carts, children playing, beggars, a drunk at night). Each with a distinct look and a line in
      the Chronicle now and then.
- [ ] D7. (ALSO: a 1.5-1.9 s hitch about once a minute, present since before L1 - find it with a frame-time log; suspect building a dungeon floor in one frame -> build it over several frames or ahead of time) Population cap + far-away LOD so long streams keep 100+ FPS (soak FPS fell 150 -> 82 at 211 people).
- [ ] D9. Roll audit (town side): townsfolk.gd, raids.gd, spells.gd, town.gd - every outcome that is a flat chance or fixed number becomes a d20 check / attack / save with real stats (raids, guards, cavalry, NPC work, fishing on the docks). List what changed.
- [ ] D10. Spotlight split-screen (Mr. E, Nov 11): viewers who support the stream get a timed pane on their hero.
      FIXED LANES in a 2x2 grid, each with its own queue and colour-coded frame:
        top-left     = the director (always, the main view)
        top-right    = BITS / cheers lane (gold frame) - any cheer 15 s, 50+ bits 20 s, 100+ bits 30 s
        bottom-left  = SUBSCRIBERS lane (purple frame) - new sub / resub / gift 30 s, gift bomb: each gifter 30 s
        bottom-right = CHANNEL POINTS lane (teal frame) - 15 s; free !look 10 s when it is otherwise empty
      Only lanes with someone in them open: no spotlights = full-screen director; one lane busy = director +
      that pane side by side; more = the 2x2 (an empty lane shows the director's wide view of the town).
      Each pane: a SubViewport + Camera3D following that hero (into the scar too), half resolution, the
      viewer's name + class + "cheered 500 bits" / "subscribed" / "redeemed <reward>" across the top, a thin
      timer bar. API: town.spotlight(uid, lane, seconds, reason). Test with local commands (!look, and
      test-only !testbits <n> / !testsub / !testpoints) and a tool that fills all lanes and renders the grid.
      F10 hides pane labels. Watch FPS.
      FREE CHAT (no pane, the main view instead): the director's hero shots favour the most recently active
      chatters (ahead of random heroes, behind raids/lords/fights); a small "Now watching: <name> the <species>
      <class>" banner in the main view; their name glows above their hero for ~5 s after any command; free
      !look borrows the channel-points lane for 10 s only when it is empty.
- [ ] D11. Free chat in the main view (Mr. E, Nov 11): the director's hero shots favour the most recent chatters; a small "Now watching: <name> the <species> <class>" tag; a chatter's name glows ~5 s after a command; free !look uses the channel-points pane only when it is empty. No pane for free chat.
- [ ] D8. Soak 30 min with everything on; fix what breaks.

## LAPTOP (dungeon, combat content, heroes) — files: bestiary.gd, monster.gd, floorgen.gd, dungeon_hd.gd, dungeon_parts.gd, gear.gd, roster.gd, chatcmd.gd, delve.gd, data/*
- [x] L1. More monsters: new CC0 creature models (KayKit Skeletons/Halloween, Quaternius CC0 monster packs),
      each with stats, behaviour and a home biome/theme from the lore's bestiary; new strains.
      DONE (Cycle 58): 6 creatures from owned CC0 bodies, ways in a fight, home themes, 2 strains; L1_TEST OK.
- [x] L2. More bosses: a set of floor lords and rare uniques (from the lore), each with a mechanic
      (summons, enrage, area attack), a name card and the boss bar; never two of the same in a row.
      DONE (Cycle 59): a mechanic for each of the eight lords, five rare uniques (one from the memorial); L2_TEST OK.
- [x] L3. More weapons and armour: more tiers and kinds (axes, spears, maces, bows, staves, shields,
      helms, chest, boots) using KayKit/Quaternius CC0 meshes; visible on the hero; priced in the shops;
      !forge / !armoury pick from them; drops on deep floors.
      DONE (Cycle 60): 10 weapon kinds x 5 tiers, worn armour, found-only tier 5, !forge <kind>, deep finds; L3_TEST OK.
- [x] L4. More classes: from the lore first (it has knight, mage, ranger, barbarian, cleric, rogue, sage,
      duelist); add more (e.g. paladin, necromancer, monk, druid, warlock, bard) with 5e-style saves,
      a weapon, a spell or ability, and !enlist support.
      DONE (Cycle 61): paladin, necromancer, monk, druid, warlock, bard - saves, weapon kind, ability, cloak; L4_TEST OK.
- [x] L5. Character species: !enlist <class> <species> (human, elf, dwarf, halfling, orc, ... from the lore)
      with stat bonuses and a visible look (KayKit/Quaternius CC0 bodies, scale, skin tint).
      DONE (Cycle 62): human, elf, dwarf, halfling, orc + the scarkin; bonuses, traits, proportions, skin, parts; L5_TEST OK.
- [x] L6. More character models for heroes and townsfolk (KayKit Adventurers 2.0 etc., CC0).
- [ ] L8. (Mr. E's decision, Nov 11) Wild magic below: every spell in the dungeon is a check against the scar - d20 + casting mod (INT mage/sage/necromancer, WIS cleric/druid/monk, CHA warlock/bard/paladin) + proficiency vs DC 10 + floor/2 (cap 20); fail = misfire as on the scar's surface (Spells.cast in_scar=true); nat 1 always, nat 20 never. Monsters unaffected. Test the misfire rates (strong vs weak caster, shallow vs deep).
- [ ] L9. Roll audit (dungeon/hero side): delve.gd, monster.gd, roster.gd, chatcmd.gd, gear.gd - attacks, damage dice, saves, traps (Perception/DEX save), loot (Investigation), initiative, death saves, shop haggling (CHA check) all as d20 rolls with real stats; nat 20/nat 1; big rolls in the Chronicle.
- [x] L7. Soak the delve 30 min with 6 fake viewers using the new classes/species/gear; fix what breaks.

## Twitch phase 2 (main chat, needs Mr. E's Client ID)
- [ ] T1. Device-code OAuth (public client, no secret) -> token saved in user:// only. EventSub WebSocket:
      bits (channel.cheer), channel points (channel.channel_points_custom_reward_redemption.add), follows,
      subs -> town.spotlight(uid, lane bits|subs|points, seconds, reason) + in-game effects. Chat replies: !stats / !hero / !inventory answered in
      Twitch chat as "@name ..." (Send Chat Message API), rate-limited.

## Needs Mr. E (not for the runs)
- Twitch follows/subs/bits/channel points: needs a Twitch token from him.
- Firefly icons / title art: made by him in Adobe.
