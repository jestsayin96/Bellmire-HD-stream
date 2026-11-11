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

LORE RULE: before adding monsters, bosses, classes, species, spells or NPC types, read the original game
(read only) — its bestiary, classes, races and lore files — and use what it already has first. Anything new
must fit its world and be named in its voice. Never state a dungeon floor count.
ASSETS: free CC0 only (Quaternius, KayKit, Kenney), downloaded into assets/<kind>/ with a LICENSE note.
Note: Quaternius "Bestiary" packs are NOT CC0 (QAL licence) - skip them.

## DESKTOP (town, people, magic) — files: town.gd, townsfolk.gd, town_nav.gd, spells.gd, raids.gd, daylight.gd, sfx.gd
- [x] D1. Phasing through buildings, for good: find every way people still walk through houses (routes
      that skip the navmesh, spawn/exit inside footprints, heroes' own movement, raiders, settlers, the
      town band). Every walker uses the navmesh; doors on the street side; local avoidance between people.
      tools/_townwalk.gd must report in_solid under 0.2% and a render must show it.
      DONE cycle 58: in_solid 0/6999 (was 64/7194 = 0.89%), raiders+defenders 0/4911, doors 67/67 reachable; renders/cycles/20261111_d1.
- [ ] D2. Spells aimed at the sky: bolts fly up at the ceiling/sky and still hit (the "4th of July").
      Fix the aim (source at the caster's hands, target the foe's chest, flat arc), give each spell a
      readable travel + impact. Then NEW spells from the lore for the caster classes (heal over time, ward,
      chain bolt, fire burst, frost slow, smite) wired into delve and raid combat. Render a fight and look.
- [ ] D3. Buildings that level up: each town level/tier visibly changes Bellmire - plots fill in, houses
      upgrade (bigger/stone storeys, signs, gardens), new buildings unlock (guild hall, market hall,
      stables, bathhouse, mage tower, keep walls in stone...). Render levels 1, 3, 5, 7 side by side.
- [ ] D4. More guards and the cavalry: more watch with patrol routes, gate guards, tower archers; mounted
      town guards (horses + riders, TOWN GUARDS ONLY) patrolling the roads and riding out at raids.
      Horses: CC0 (Quaternius animals) or a simple rig. Stables building from D3.
- [ ] D5. More animals: horses in paddocks, cows, sheep, pigs, chickens, dogs, cats, birds over the
      fields, ducks; herded and penned, never on rooftops.
- [ ] D6. Unique NPCs: named characters with jobs and daily routines from the lore (the chief, the smith,
      the healer, the innkeeper, the priest, a bard, a town crier who reads the Chronicle aloud, merchants
      with carts, children playing, beggars, a drunk at night). Each with a distinct look and a line in
      the Chronicle now and then.
- [ ] D7. Population cap + far-away LOD so long streams keep 100+ FPS (soak FPS fell 150 -> 82 at 211 people).
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
- [ ] L5. Character species: !enlist <class> <species> (human, elf, dwarf, halfling, orc, ... from the lore)
      with stat bonuses and a visible look (KayKit/Quaternius CC0 bodies, scale, skin tint).
- [ ] L6. More character models for heroes and townsfolk (KayKit Adventurers 2.0 etc., CC0).
- [ ] L7. Soak the delve 30 min with 6 fake viewers using the new classes/species/gear; fix what breaks.

## Needs Mr. E (not for the runs)
- Twitch follows/subs/bits/channel points: needs a Twitch token from him.
- Firefly icons / title art: made by him in Adobe.
