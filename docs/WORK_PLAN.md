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
- [x] D5. More animals: horses in paddocks, cows, sheep, pigs, chickens, dogs, cats, birds over the
      fields, ducks; herded and penned, never on rooftops.
      DONE cycle 66: hens (19, hand-built, peck) in a fenced run by each farmhouse, a sheepdog walking each flock's
      fence, 5 horses + a foal in the paddock, 8 cats on the streets (they nap), crows over 5 fields; animals never
      pick a spot or path through a building (solid_at) and stop at stalls. D5_TEST OK (0 in_solid / 0 high / 0 out
      of pen in 22200 samples); renders/cycles/20261111_d5.
- [x] D6. Unique NPCs: named characters with jobs and daily routines from the lore (the chief, the smith,
      the healer, the innkeeper, the priest, a bard, a town crier who reads the Chronicle aloud, merchants
      with carts, children playing, beggars, a drunk at night). Each with a distinct look and a line in
      the Chronicle now and then.
      DONE cycle 69: scripts/notables.gd - 12 named folk (lore roster's chief/smith/healer/innkeeper promoted, not
      doubled; + priest, crier, bard, pedlar with cart, two children, beggar, drunk), names from the lore's FIRST x
      LAST, title tag up close, own look, hour-slot days in their own quarter, Chronicle lines, the crier shouts the
      latest Chronicle news. D6_TEST OK (86% of slots reached, drunk out 0/134 by day 96/96 at night, 0 in_solid);
      renders/cycles/20261111_d6.
- [x] D6b. Nav snap bug: town._snap / TownNav.closest() returns (0,0,0) for a while after start (navmesh not
      synced yet). Wait for the map's first sync (NavigationServer3D.map_get_iteration_id > 0 or map_changed) before
      snapping; until then fall back to the raw position, never the origin. Re-check D4 watch patrol routes and
      anyone stacked on the square at start. Test: snap right after start never returns 0,0,0; render the square.
      DONE cycle 73: iteration id > 0 came ~40 frames before the region was in the map; TownNav.synced() waits for
      the region + a vertex probe, _snap falls back to keep_walkable. Also: traders' market spot kept the old plot's
      inside point (a 30-47 m "door leg" through houses) and a door leg left after stuck waypoints now re-routes.
      D6B_TEST OK (0 of 600 snaps at the origin, 90 beats clean); _townwalk in_solid 0/7923 and 0/8317; renders/cycles/20261112_d6b.
- [x] D7. (ALSO: a 1.5-1.9 s hitch about once a minute, present since before L1 - find it with a frame-time log; suspect building a dungeon floor in one frame -> build it over several frames or ahead of time) Population cap + far-away LOD so long streams keep 100+ FPS (soak FPS fell 150 -> 82 at 211 people).
      DONE cycle 76: LOD - walkers past 60 m from the camera step + animate every 2nd physics tick, past 120 m every
      4th (summed time, same pace: 2.52 vs 2.52 m/s); heroes, riders and raid fights always full. Street cap 200:
      settlers past it still settle (souls, level, tax) but keep indoors; a burial brings one out. Windowed, 217
      people: 98.8 -> 126.0 FPS (+28%); 43% fewer walker steps. D7_TEST OK; renders/cycles/20261112_d7.
      THE HITCH, found (tools/_d7_hitch.gd): every new dungeon floor is built in ONE frame - DungeonHD.build takes
      580-820 ms, of it FloorGen.build 450-770 ms (964-1684 nodes); 41 hitches of 350-810 ms in 6 min at 4x, each on
      a floor change of the viewers' or the band's delve. FOR THE LAPTOP (delve.gd / dungeon_hd.gd / floorgen.gd are
      yours): build the next floor ahead while the party fights (FloorGen.build on a DungeonHD that is not yet in the
      tree, on WorkerThreadPool - load() is thread-safe - then add_child on descend), or slice it over frames.
      Also fixed: a freed guard / notable stopped _show_garrison and the whole Notables pass every tick (2583 errors).
- [x] D9. Roll audit (town side): townsfolk.gd, raids.gd, spells.gd, town.gd - every outcome that is a flat chance or fixed number becomes a d20 check / attack / save with real stats (raids, guards, cavalry, NPC work, fishing on the docks). List what changed.
      DONE cycle 78: scripts/dice.gd (Dice); raids: initiative, blows = weapon dice + mod (heroes' own dice), spell attacks +
      fire burst DEX save vs 8+to-hit, mending dice, CON save for every defender, torch + rebuild checks; crossbows 1d10+3;
      work beats d20+2 vs DC 10 (mean kept 1.0); fishing hook = DEX check (dock +5, heroes DEX + prof for ranger/druid).
      Kept: raid timing/size/source (world events), townsfolk idle gestures (cosmetic), spells.gd (no rolls; the surface
      scar rule is canon). D9_TEST OK; renders/cycles/20261112_d9. Full list in PROGRESS cycle 78.
- [x] D12. Expand the map: the valley beyond the walls - outlying hamlets/farmsteads, a forest with a woodcutters'
      camp, a river ford and mill, old ruins (lore), roads linking them, the scar road; travellers and carts on
      the roads; the director's tour includes them. Navmesh + LOD keep FPS.
      DONE cycle 79: scripts/valley.gd - Coalfoot Steading (over the river) + Bramble End (east road), 3 cottages, a well,
      folk each; the Ashwood (150 trees) with a woodcutters' camp; the ford (gravel bar in height_at, gap in the river's
      nav band) + the Ford Mill; the Old Footing ruins off the Delvers' Road; 10 dirt roads; 8 trips of travellers/carts;
      5 director tour stops. FOUND: map_get_path stops at 4096 polygons (mesh has ~25000) - long routes came back cut
      30-50 m short; TownNav.path now queries with room. D12_TEST OK; renders/cycles/20261112_d12.
- [x] D13. MOVED to L20 (laptop owns scripts/rts_camera.gd - every recent commit to it is the laptop's).
- [x] D14. Stuck walkers against props (supervisor, Nov 11): _townwalk reports stuck_on_route=4 steady
      (traders Petra Bramble, Maela of the Ford, farmer Maela Coalfoot) - pinned on a prop a few cm off
      their route, navoff 0.17-0.66, push (0,0,0). Nobody is inside a building (in_solid 0 of 8394), so
      this is cosmetic, but they stand still all stream. Give the push-out rule a prop case. Fold into D7
      if it is the same code path.
      DONE cycle 80 (townsfolk.gd): the push-out handed the foot back each frame so the "feet moved" test never
      fired; now a prop push-out slides round it, "no nearer in 2.5 s" re-routes, and a walker wedged in a pocket
      off the navmesh (the adventurers' fenced yard: fence + benches + stools) floods out to walkable ground.
      tools/_d14_test.gd: pinned 25 -> 0, stuck per sample max 4 -> 1 (120 s). D14_TEST OK; renders/cycles/20261112_d14.
- [x] D8. Soak 30 min with everything on; fix what breaks.
      DONE cycle 81: 30 min windowed, director on, 4x, 6 fake viewers: FPS avg 139.2 (min 29 = the floor-build hitch, laptop),
      memory flat 552-585 MB, nodes ~20k, 22 days, 13 raids. Broke + fixed: chain-bolt hops landing after their floor was
      freed (2 SCRIPT ERRORs) and 9 "Lambda capture freed" (timers holding freed nodes - spells/raids/town/notables/townsfolk);
      a raid ate a hero's errand (arrival fired mid-road); defenders whose post a prop blocks walked on the spot forever.
      D8_TEST OK; 9-min re-soak 0 script errors, 0 lambda errors; renders/cycles/20261112_d8.

- [x] T1. TWITCH PHASE 2 - DESKTOP OWNS THIS (Mr. E, Nov 11 23:18). All credentials are already
      authorized and proven live: see the gitignored local/twitch.cfg for the client id, both user ids
      and the file names. Tokens are in user://twitch_token.json (broadcaster) and
      user://twitch_bot_token.json (bot bellmirebro, modded on the channel) on THIS machine - that is
      why the desktop builds it. Build it in a NEW file, scripts/twitch_eventsub.gd:
        - EventSub WebSocket: channel.cheer (bits:read), channel.subscribe / subscription.message /
          subscription.gift (channel:read:subscriptions), channel.follow VERSION 2
          (moderator:read:followers), channel.channel_points_custom_reward_redemption.add
          (channel:read:redemptions) -> town.spotlight(uid, lane bits|subs|points, seconds, reason).
        - REFRESH BOTH TOKENS ON A TIMER. They expire in about 4 hours. This is the most likely bug in
          the whole item and it only shows up hours in, on a 24/7 run, when nobody is watching.
        - Bellmire creates its OWN channel point rewards with its own client id at startup, and matches
          redemptions BY REWARD ID, never by title. The six rewards already on the channel belong to
          Mr. E's other app, fightoverlay - ignore them completely. Reward titles must avoid every
          fightoverlay keyword (boss, monster, spawn, raid, mob, goblin, horde, loot, drop, chest,
          treasure, invade, titan). Start with "Spotlight my hero".
        - Event ownership: bits and subs -> Bellmire spotlight lanes; follows -> a Chronicle line only,
          no spotlight (fightoverlay used to own follows and has turned its follower monster off).
      NEVER EDIT chatcmd.gd - it is laptop-owned. The chat-reply half is split by contract: the laptop
      adds  signal twitch_reply(user_login: String, text: String)  to chatcmd.gd, emitting the plain
      answer with no @name prefix and no rate limiting. THIS file connects to that signal and owns the
      queue, the rate limiting, the @name prefix and the Send Chat Message API call as bellmirebro
      (broadcaster_id 138821183, sender_id 1609188025). Do not change that signature alone.
      Test without a live stream: the test-only !testbits <n> / !testsub / !testpoints already exist
      from L17. Prove the refresh path by forcing an expiry, not by waiting.
      DONE cycle 82: scripts/twitch_eventsub.gd (TwitchEventSub, started by town.gd in play only) - EventSub socket, 6/6 subs
      live (cheer, subscribe, sub.message, sub.gift, follow v2, redemption.add); both tokens refreshed 15 min early + hourly
      validate + refresh on a stale-token 401, new pair saved .tmp -> read back -> rename; bits 15/20/30 s, sub/resub/gifter
      30 s, follow = Chronicle only, rewards matched by id only (fightoverlay's ignored), refund when no hero; chat queue
      (1.6 s gap, @name, 480 chars, 30 s repeat drop) waits on chatcmd's twitch_reply. T1_TEST OK (18/18 offline); T1_LIVE OK
      (forced expiry -> both refreshed, saved, validated, socket stayed up). NOT YET: (a) the broadcaster token lacks
      channel:manage:redemptions, so Bellmire can not make its "Spotlight my hero" reward (401) - Mr. E must re-authorize
      with that scope; (b) town.spotlight is L17 (laptop) - until then events print SPOTLIGHT + emit spotlight_wanted;
      (c) twitch_reply is not in chatcmd.gd yet (laptop) - connected automatically once it is; (d) !testbits etc. do not
      exist (L17 open) - tests feed recorded EventSub frames instead. Chat sending was not tried live (nothing posted).

- [x] D15. (DONE Nov 12 04:16: 35-min soak / 87 valley days / 228 people / 51 raids - 0 script/freed-node errors; audio pool bounded (16/16 peak = graceful voice-steal), streams cached 131 plateaued; memory rise tracks town growth not audio; GAP held (busiest mana_charge 3.93/s vs ~8.3/s); FPS population-bound not audio. Follow-up D22: bump sfx pool 16->24 for peak headroom.) SOUND SOAK (supervisor, Nov 12). Now that S1+S2 wired the full RPG sound library, run a
      30-45 min soak with sound ON and confirm it is safe for a 24/7 stream: (a) no audio-related
      SCRIPT ERROR and no 'freed node'/lambda errors over the whole run; (b) the AudioStreamPlayer3D
      pool in sfx.gd is not exhausted or growing without bound (log pool size + active players each
      minute); (c) memory does not climb from audio streams (compare mem_mb first third vs last third,
      as D8 did); (d) FPS holds as it did in the silent D8 soak (sound must not cost meaningful frame
      time); (e) the GAP throttles hold under a busy town+raid so no kind machine-guns. Write the
      findings into PROGRESS; if anything leaks or errors, fix it before ticking. Reuse tools/_soak.gd
      with audio enabled. Commit + push only on a clean run.

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
- [x] L8. (Mr. E's decision, Nov 11) Wild magic below: every spell in the dungeon is a check against the scar - d20 + casting mod (INT mage/sage/necromancer, WIS cleric/druid/monk, CHA warlock/bard/paladin) + proficiency vs DC 10 + floor/2 (cap 20); fail = misfire as on the scar's surface (Spells.cast in_scar=true); nat 1 always, nat 20 never. Monsters unaffected. Test the misfire rates (strong vs weak caster, shallow vs deep).
- [x] L10. (DONE Nov 11, be7c9a9: idle no longer overrides walk/attack; MON_ANIMS OK; 0 monsters in props) (URGENT, do before L9 - Mr. E saw it live) Monsters and bosses have NO animations: they glide/"fly"
      along the ground, never swing, and get stuck in walls and props. 1) Write tools/_mon_anims.gd: for EVERY
      bestiary def (incl. lords, uniques, L1 creatures) spawn it and print its model, whether an AnimationPlayer
      was found, the animation list, and which of def.anims (idle/walk/run/attack/cast/hit/die/rise) actually
      exist - any missing name means monster._play() silently does nothing. 2) Fix each: correct the names, or
      attach the shared rig library (KayKit Skeletons ship animations separately - Rig_Medium general/movement/
      combat; the UAL path) so every humanoid has idle, walk, attack, hit, death; beasts get what their pack has.
      3) Monster movement uses the same obstacle push-out/slide + never-off-floor guard the heroes use (delve.gd
      _step/_go), so no monster walks into walls or props. 4) Render a fight with 3+ kinds and a lord mid-swing;
      LOOK. Test: every def reports idle+walk+attack present; _offfloor counts monsters too (0 in props).
- [x] L9. Roll audit (dungeon/hero side): delve.gd, monster.gd, roster.gd, chatcmd.gd, gear.gd - attacks, damage dice, saves, traps (Perception/DEX save), loot (Investigation), initiative, death saves, shop haggling (CHA check) all as d20 rolls with real stats; nat 20/nat 1; big rolls in the Chronicle.
- [x] L7. Soak the delve 30 min with 6 fake viewers using the new classes/species/gear; fix what breaks.

## LAPTOP list 3 (Mr. E, Nov 11 evening) - UI + content. The laptop now owns the UI files too:
## rts_camera.gd, feed_hud.gd, leaderboard_panel.gd, party_frames.gd, boss_bar.gd, auto_director.gd, health_bar_3d.gd, new UI files.
- [x] L11. Traps that visibly work (Mr. E: "they don't show functioning or doing damage"): every trap kind
      (pressure plate, spikes, darts, blades, pits...) has a trigger animation + sound, a DEX save (or Perception
      to spot first) rolled with real stats, damage dice with the number floating up, a Chronicle line
      ("BigAxe steps on a plate - darts! DEX 9 vs DC 13, 7 damage"), disarming by a rogue (Thieves' tools check).
      Render a trap going off; test that damage lands and saves roll.
      DONE (Cycle 69): 6 kinds armed until stepped on, trigger anim + sound, Perception/thieves' tools/DEX save, dice, floating numbers, Chronicle; L11_TEST OK.
- [x] L12. Potions with status effects, 5e style: healing tiers (2d4+2 ... 10d4+20), plus antidote, fire/frost
      resistance, haste, giant strength, invisibility, heroism, darkvision for unlit floors; and the bad states
      to cure/inflict: poisoned, burning, frozen/slowed, blinded, frightened. Status icons on party frames and
      over heads; durations; brewed at the apothecary (!brew <potion>), found below. Lore voice for names.
      DONE (Cycle 70): 12 brews (data/potions.json), 5 bad states with sources and cures, drinking below, !brew <potion>, tags; L12_TEST OK.
- [x] L13. More equipment + COSMETICS: more weapons/armour per tier (rings, amulets, cloaks, boots, gloves with
      small 5e bonuses), and cosmetic-only items - hats, hoods, capes, dyes (colour the armour), banners on
      the back, a pet that follows (from the CC0 animals), titles shown under the name. !wear <item>, !dye <colour>.
      Bought with gold now; later channel points (T1). Visible on the hero; render a lineup.
      DONE (Cycle 71): 10 accessories with 5e bonuses, 18 cosmetics (hats, banners, pets, titles), 10 dyes, !wear / !dye; L13_TEST OK.
- [x] L14. The command list in detail: one source of truth (data/commands.json): name, aliases, args, cost,
      cooldown, what it does, example. !help / !commands (short), !help <cmd> (detail). Friendly error replies
      ("!forge needs 120 gold - you have 40"). Write docs/COMMANDS.md from the same data (the hub/website uses it).
      DONE (Cycle 72): data/commands.json -> !help, !help <cmd>, aliases, typo nudges, "- you have N" replies, docs/COMMANDS.md; L14_TEST OK.
- [x] L15. STREAM READABILITY (Mr. E: will viewers be able to read it?): design for a 1080p stream watched on a
      phone. Minimum on-screen text ~28 px at 1080p for anything viewers must read; name tags, Chronicle, Guild
      Roll, party frames, boss bar, banners scaled up; high contrast + outline; a UI scale setting (F11 cycles
      100/125/150%). Test: render at 1920x1080, then downscale to 854x480 (what a phone sees) and LOOK - every
      name and Chronicle line must still be readable. Fix until it is.
      DONE (Cycle 73): UiTheme sizes for 1080p (Chronicle 28 px, roll 26, frames 28, boss bar 44/26), F11 100/125/150, names grow with distance; phone 854x480 frames read; L15_TEST OK.
- [x] L16. GUI/UI polish to an RTS/WoW standard: one theme for every panel (parchment + ink, the JestSayin teal
      as the accent), consistent fonts, icons, frames, spacing; the unit frame, party frames, guild roll,
      chronicle, boss bar, help, chat box all match. Nothing from the old game's interface.
      DONE (Cycle 74): one house theme in UiTheme (parchment, ink, teal titles and rules, inked bars, chips) on every panel; L16_TEST OK.
- [x] L19. More lore: from the reference + the Lore Bible PDF - more Chronicle lines, NPC barks, floor-origin
      text, item and potion flavour, boss intros, town-level announcements; all in the original's voice, never
      contradicting it, never a floor count.
- [x] L17. (moved from D10; laptop owns the UI) Spotlight split-screen (Mr. E, Nov 11): viewers who support the stream get a timed pane on their hero.
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
      DONE (Cycle 76): lanes + queues, !look / !testbits / !testsub / !testpoints (local only), pair + 2x2, F10 with the UI, FPS 44 -> 40 with all three lanes; L17_TEST OK. For the desktop: add `func spotlight(uid, lane, secs, why): return Spotlight.spotlight(self, uid, lane, secs, why)` to town.gd.
- [x] L18. (moved from D11) Free chat in the main view (Mr. E, Nov 11): the director's hero shots favour the most recent chatters; a small "Now watching: <name> the <species> <class>" tag; a chatter's name glows ~5 s after a command; free !look uses the channel-points pane only when it is empty. No pane for free chat.
      DONE (Cycle 77): the freshest chatter (2 min) is the director's hero pick (36-50), "Now watching" chip, 5 s teal name glow, !look via the points lane; Chronicle entries capped at 2 lines; L18_TEST OK.
- [x] L20. Director camera clearance (supervisor, Nov 11; was D13). CORRECTION to the original note: the
      roof in renders/cycles/20261112_d6b/square_f460_east.png was NOT an auto-director shot - _d6b_shot.gd
      placed its own fixed camera 14 m up beside the square, so that framing is the test tool's, not the
      director's. The real gap (found by the laptop, Nov 11): the camera's edge-protection check only covers
      hero-follow shots and tests a single line, so tour and wide shots have no clearance check at all and
      roofs beside that line go unprotected. Fix it in the eye camera for every shot type, and prove it with
      real director shots - town wide, tour, hero follow, fight, raid - rendered and looked at, not with a
      fixed test camera. The L17 spotlight panes each get their own camera, so they must share this rule.
      DONE (Cycle 79): every shot tilts / swings round its subject until the near lower frame is clear of roofs, props, walls and towers (one rule, the panes share it); pull-in never closer than 6 m; real director shots of all six types 0-2% blocked (raw up to 100%); L20_TEST OK.
- [x] L21. THE INTERFACE over the spotlight panes (Mr. E, Nov 11). In the grid the HUD was laid out for one full-screen view:
      the boss card across all four seams, the Chronicle over the subs pane, the delvers panel in the director pane's
      corner, floating text everywhere, name tags in mush. THE RULE, in code: with more than one view up, no HUD
      element crosses a seam or sits over a pane it does not belong to - docked inside one pane, or in the chrome bar.
      Floating text clamped to its pane and off in quarter panes; name tags fixed in panes; full screen unchanged.
      Test that fails on the old build, then a 1080p render shrunk to 854x480 and looked at.
      DONE (Cycle 81): panes over the top 85%, the Chronicle + clock in a bottom chrome bar, boss card + party frames + unit frame docked in the pane showing them (scripts/hud_dock.gd), 3D text on render layers with a cull mask per pane, one name tag per lane pane; L21_TEST 32/32 (15 failed before).
      ALSO: !guild drops the "roll" alias (bare !roll is fightoverlay's dice, now silent here); L14_TEST OK.
- [x] L22. Panes near-identical when two spotlit heroes stand close: a different angle / zoom when subjects are within a few metres.
      DONE (Cycle 84): within 6 m of another pane's subject a lane takes its own quarter (90 / -90 / 180 deg from the director) and zoom, clearance tilts but never swings it; L22_TEST OK (views 84-177 deg apart).
- [x] L23. The director should cut away from a hero a lane already holds (laptop commit a6eb770 calls this L24).
      DONE (Cycle 85): lane-held heroes are skipped by every director pick, a fight or delve shot goes through a delver no lane holds, a held shot is cut within 1 s; L24_TEST OK (5 of 6 failed before).

- [x] L24. De-flake tools/_l20_test.gd (supervisor, Nov 12). On the merge run it failed with (laptop commit d3669e2 calls this L23)
      "the director never cut to fight" and "all six shot types were seen" (saw tour_market, tour_scar,
      tour_valley, hero, raid - no fight), then PASSED on an immediate re-run with no code change. It is
      waiting on the director to happen to cut to a fight inside the test window. Make the test drive the
      director deterministically - force a fight and force the cut - instead of waiting for one. A test
      that fails at random teaches everyone to ignore it, which is worse than no test.
      DONE (Cycle 83): a lord floor + the director deciding at once when the story is live (its own _best / _cut); timing samples best of 3; L20_TEST OK x3 in a row.

- [x] S1. SOUND WIRING - DESKTOP (town side). The RPG sound library is already on main (commit 00cf0ef):
      86 ids registered as Sfx kinds, played with Sfx.at(id, pos) (3D, in the world) or Sfx.play(id)
      (flat). Do NOT edit sfx.gd except to add a GAP throttle for a kind that fires often. Wire the
      kinds that belong to the town, in the desktop-owned files only:
        - townsfolk.gd: villagers and named NPCs give an occasional gendered voice - male_/female_grunt,
          _effort, _laugh (pick by the NPC's sex). Sample it, do not sound every tick - it should feel
          alive, not a crowd grunting. The crier can use male_/female_attack_yell for a shout.
        - spells.gd: town-side casts -> fireball (magic fire), ice_shard, lightning (zap), heal, buff,
          curse, shield, summon, mana_charge. Play at the caster's position.
        - raids.gd: raiders arriving -> orc_roar / troll_roar / goblin_screech (by raider kind), a horn
          already plays; combat hits during the raid -> sword_clash / hit_impact at the fight.
        - town.gd / daylight.gd animals + time of day: dog_bark, cat_meow, horse_neigh/whinny, boar_grunt
          from the pens; bird_chirp / crow_caw by day, owl_hoot + cricket_chirp at night, kept quiet and
          occasional under the ambience bus.
        - level_up / quest_complete when the town reaches a new level.
      Keep it tasteful: throttle, keep volumes under the existing buses, and don't let far events be loud
      (Sfx.at already attenuates by distance). Add a tools/_s1_test.gd that asserts each wired event calls
      Sfx with a kind that exists in SETS. Render/soak a minute and listen in your head via the play counts
      (Sfx.plays) - 0 SCRIPT ERROR, no kind played that isn't registered.
- [x] S2. SOUND WIRING - LAPTOP (dungeon + heroes + UI). Same library on main (00cf0ef), same API, same      rule: do not edit sfx.gd except to add a GAP. Pull main into the laptop branch first. Wire the
      laptop-owned files only:
        - monster.gd / bestiary.gd: each monster species gets a voice on spawn and on death - map
          goblin->goblin_screech/cackle, orc->orc_roar, troll->troll_roar, skeleton->skeleton_rattle,
          zombie->zombie_moan, ghost->ghost_wail, wraith->wraith_whisper, slime->slime_squish,
          spider->spider_skitter, bat->bat_screech, demon->demon_growl, dragon->dragon_roar (+ 
          dragon_fire_breath on its breath attack), minotaur->minotaur_bellow, giant->giant_footstep.
          A boss roars on arrival (ties in with the spotlight). Throttle so a room of monsters is not a
          wall of noise - sample, and favour the biggest/nearest.
        - delve.gd combat: sword_swing then sword_clash/hit_impact on a melee hit, dagger_stab for
          daggers, bow_draw -> arrow_shot for ranged, shield_bash/block on a block; a miss can whiff with
          sword_swing alone. Heroes' spells reuse fireball/ice_shard/lightning/heal/shield.
        - heroes' voices by sex: male_/female_hurt on taking a hit, _death on dying (the death music
          duck already fires), _effort/_grunt on a big swing. Sample, do not voice every blow.
        - dungeon ambience per floor: a quiet bed of bat_screech / spider_skitter / skeleton_rattle /
          ghost_wail, occasional, under the ambience bus.
        - chatcmd.gd / UI feedback: menu_select on a recognised command, error on a typo nudge,
          item_pickup / chest_open / coins_stack on buys and finds, potion_drink on !brew, inventory_open
          on !inventory, level_up when a hero levels. These are flat (Sfx.play), not positional.
      Add tools/_s2_test.gd asserting every wired event uses a registered kind; 0 SCRIPT ERROR; the
      existing _delve_test should still pass with sound calls in.
      DONE (Cycle 87, laptop): Bestiary.voice_of (34 creatures, every lord and unique voiced), queued creature voices (one a 0.9 s beat, biggest / nearest / a death first, same kind 3.5 s), a lord roars as it rises, breath on the breath; per-weapon swings + hit / clash / bow / block / shield_bash, spells, potions, finds; hero voices sampled (Roster.voice_of); a quiet bed below; chat / UI sounds; level_up. GAPs added in sfx.gd. S2_TEST OK x3.
- [x] S3. SOUND REVIEW + TUNING - LAPTOP (supervisor, Nov 12). S1 / S2 only proved the kinds exist; check the game
      SOUNDS right: no silent monster, every command audible, throttles hold under load, levels balanced under the
      buses, no pool exhaustion or freed-node errors. A test so a future monster or command cannot ship silent.
      DONE (Cycle 88): tools/_sound_review.gd (coverage headless; load + measured levels windowed). Fixed: spells below
      doubled (S1 + S2 both sounded them), !reroll / !respec paid silently, dragon roar +9.9 dB over the music,
      skeleton / spider voices -9.5, half the dungeon bed inaudible (-25), menu_select +4.6, potion_drink buried,
      a generic hit doubling every blow. Levels now -5.6 .. +1.9 dB of the music, bed -15 .. -18; SOUND_REVIEW OK 18/18.

## Twitch phase 2 (main chat, needs Mr. E's Client ID)
- [x] W1a. SNAPSHOT PUBLISHER - DESKTOP. Mr. E chose GitHub Pages for the page and Supabase for the
      data (Nov 12, free tier, project already created and the table already exists). Every 60 s the
      game upserts ONE row into the Supabase table public.snapshot: id=1, payload = a jsonb blob with the
      guild roll, the fallen, each hero's sheet/inventory/gear, town level and souls, and the command
      list from data/commands.json. One row, overwritten - the database never grows and nothing has to
      be cleaned up. Project URL https://paaukwaffaamazgrndbv.supabase.co . Writing needs the SERVICE
      ROLE key, which bypasses row-level security: it goes in user:// beside the Twitch tokens and NEVER
      in the repo - Mr. E copies it from the Supabase dashboard (Project Settings > API). Skip the
      publish quietly if the key is absent so the game still runs without it. Failures must never stall
      the sim: fire and forget on a thread, and never block a frame on the network.
      CONNECTIVITY IS ALREADY PROVEN (supervisor, Nov 12 01:05): the key is in
      user://supabase.json as {"url": ..., "service_key": ...}; a write with it succeeded, a read with
      the publishable key succeeded, and a write attempted with the publishable key was correctly
      refused by RLS. The table currently holds a test row - overwrite it.
      GOTCHA, do not rediscover this: Supabase REFUSES a secret key when the request looks like it came
      from a browser - "Forbidden use of secret API key in browser". PowerShell's default User-Agent
      triggers it; setting User-Agent: BellmireHD/1.0 fixed it instantly. If the publish ever returns
      403 with that message, set a non-browser User-Agent on the HTTPRequest rather than hunting the key.
      Upsert with POST to /rest/v1/snapshot?on_conflict=id and the header Prefer: resolution=merge-duplicates.
      DONE cycle 87: scripts/snapshot_pub.gd (SnapshotPublisher, started by town.gd in play only) - every 60 s (first at 20 s)
      one threaded HTTPRequest upserts id=1 {town, guild_roll (50), fallen (50), heroes = living sheets (stats, saves, AC/HP,
      weapon+dice, armour, potions/brews, oil, gold, worn, rank, title), commands}; no Twitch ids; one in flight at most;
      no key file = off. publish() 0.3-0.7 ms, build 0.4 ms (202 heroes 5 ms, 95 KB). W1A_TEST OK 17/17 (live upsert 200,
      read back with the publishable key, publishable-key write refused 401); W1A_TOWN OK (real town + real save, read only:
      level 3, 51 souls, 2 heroes, 6 fallen, 21 commands - that is the row in the table now).
      ADDED cycle 89: payload.chronicle - the last 50 town.feed lines, newest first, {t, s, at}; t by keyword (death/raid/loot/delve/
      town/lore/fight, unsure = town), at = when the publisher first saw it; control chars, BBCode, < > and 7+ digit runs stripped, 200 chars max.
      No existing key changed. W1A_TEST OK 23/23 (6 new checks).
- [x] W1b. THE VIEWER HUB PAGE - a static page, no build step, on GitHub Pages like fightoverlay.
      It fetches public.snapshot with the PUBLISHABLE key (safe to embed, read-only by policy):
        URL  https://paaukwaffaamazgrndbv.supabase.co/rest/v1/snapshot?select=payload,updated_at
        key  sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc   (apikey header + Authorization: Bearer)
      Shows hero sheets, inventory, gear, the guild roll, the fallen and the command list, with "as of
      <updated_at>" visible so a stale snapshot is obvious when the game is off. Readable on a phone
      first - most viewers will open it on one. Must work when the game has never run (empty table).
      Phase 2, later: polls that change the town, with Twitch login - that is why the data is in
      Supabase rather than in a file; a static host could not do it at all.
      DONE (Cycle 86, laptop): web/index.html - one static file, no build, no framework; phone first (390 px), two / three columns when wide. Heroes (find by name, tap for the sheet: stats + mods, weapon dice, to-hit, armour / AC, saves, pack, worn, record), the Guild Roll, the Fallen (killer, day, epitaph when there is one), town level / souls / day / treasury / growth, the command list. "Updated N minutes ago" always; past 5 min it says the town has gone quiet; empty table -> "has not reported in yet"; failed fetch (12 s timeout) -> a plain message + Try again, retried every minute. Not published - Pages is Mr. E's call. Shots: renders/cycles/20261112_w1b.
## Needs Mr. E (not for the runs)
- Twitch follows/subs/bits/channel points: needs a Twitch token from him.
- Firefly icons / title art: made by him in Adobe.


## ROUND 4 - Nov 12 polish + hub elevation (Mr. E, 03:47 CT). Expanded into phased programs 04:16.
## CHANGELOG 04:33: L25 was split into L25a-d (L25 = all four collectively); IDs are now FROZEN, PROGRESS cycles are per-machine prefixed (D/L/H). See docs/COORDINATION.md - the single source of truth for machines, paths, numbering, tests, merges, WIP.
## Priorities from Mr. E: people clip/stick, dungeon looks rough, animations weak, hub must be SSS+.
## Ownership unchanged. Each item: subject + DONE/test. Workers take the FIRST unchecked item IN THEIR OWN section.
## Full per-chat briefs with the long detail exist (desktop saved claude/desktop-program-d16-d23.md); these lines are the trackable checklist.

### DESKTOP (town/people/nav/animation) - town.gd, town_nav.gd, townsfolk.gd, hero_body.gd, rig.gd, raids.gd, cavalry.gd, animal.gd, spells.gd, daylight.gd, valley.gd, notables.gd, economy.gd, sfx.gd
# Phase A - movement & nav (stop walls/sticking) [D16]
- [x] D16a. LOCAL AVOIDANCE: hero_body/townsfolk/animal/cavalry follow _route with no dynamic avoidance - add NavigationAgent3D avoidance OR separation steering (push apart within ~0.6 m). DONE: 50-body gate-funnel = 0 sustained overlaps > 0.3 m. -> DONE Nov 12: town.crowd_push is now separation (soft ring + hard contact, per-body radius) + yield (sidestep to pass whoever is ahead; same-way walkers followed) for townsfolk/heroes/cavalry/watch pairs/animals. tools/_d16a_test.gd at the west gate: under-0.3 m pair-time 29.2 s -> 0, clip (<0.45 m) 62.5 -> 2.2 pair-s, min gap 0.02 -> 0.38 m, 0 sustained, 50/50 through (median 10.0 s, unchanged).
- [x] D16b. UNSTICK WATCHDOG: route active but displacement < 0.2 m over 2 s -> repath/nudge. DONE: _townwalk stuck_on_route == 0 over 120 s. -> DONE Nov 12: Townsfolk watchdog (2 s / 0.2 m): near-enough arrival, else re-path, else side-step (or brush out of a prop pocket), else drop the trip (heroes/caravans keep trying). _townwalk now 120 s: stuck_on_route 0 (total 0); tools/_d16b_test.gd 180 s: 10 pinned events / 4 people with it off -> 0 with it on.
- [x] D16c. DYNAMIC OBSTACLES: stalls/carts/benches not in the navmesh - register or steer round. DONE: town soak = 0 bodies through a stall or stuck on a prop. -> DONE Nov 12: moving wagons (carters, travellers, caravan, pedlar) steered round (crowd_push) + feet kept out (off_wagons, every frame before LOD) + legs re-routed round/beside them (wagon_way); parked wagons drawn up on open ground (wagon_park); mine/farm wagons + scar-glass now solid. tools/_d16c_test.gd 150 s town+raid: through-a-prop 26-33 -> 0, stuck_by_prop 0 (PASS).
- [x] D16d. DOORWAY/GATE/BRIDGE FUNNELING: crowds queue and pass instead of piling. DONE: funnel test passes at the real gate and bridge. -> DONE Nov 12: the pile was the pre-sync road-hex route (D16a's note) - every route asked before the navmesh is in the map went out through a gate and back (walked/straight 1.68-1.78) and never crossed the bridge (50/100); Townsfolk now marks such a route and re-walks it on the navmesh once synced. tools/_d16d_test.gd 100 walkers two-way, routed on the spawn frame: gate 98/100 median 27.4 s -> 100/100 15.4 s, walked/straight 1.02, 0 overlap in the arch; bridge 50/100 -> 100/100, 0 overlap; routed after sync both PASS. A queue+lane steering variant was tried and measured worse (slower, more jostle) - not kept.
# Phase B - animation overhaul (town) [D17]
- [x] D17a. NO T-POSE: rig.gd fallback clip when a model lacks the named anim (play Idle + log once). DONE: anim probe = 0 empty current_animation over a 60 s day+raid. -> DONE Nov 12: Rig.play falls back to the model's idle on a missing clip (logged once) and queues every one-shot back into the loop the body was in (death -> its held Death_*_Pose); *_Idle/*_Pose clips loop; stable horses idle. tools/_d17a_test.gd 60 s day+raid: visible bodies with an empty player 182 samples (bandit Death_A, smith/farmer PickUp, fisher Interact, crier Cheer) -> 0 of 23927 (PASS).
- [x] D17b. LOCOMOTION BLEND: speed-blend walk<->run, match playback to move speed, face heading - no gliding/moonwalk. DONE: walk probe, no foot-slide beyond threshold. -> DONE Nov 12: Rig.drive picks a gait from each body's measured speed (stand/walk/jog/run, hysteresis, 0.3 s crossfade) and plays it at speed / the clip's own ground speed (KayKit walk 0.8 m/s, jog 2.1, run 3.3 - tools/_d17b_clipspeed.gd); walkers face the way they actually move; Townsfolk.pace 0.62 -> 0.40 (2.6 m/s was a sprint for these legs; the mounted watch kept its speed). tools/_d17b_test.gd 60 s day+raid: skate median 1.80 -> 0.006 m/s, p90 2.50 -> 0.23, idle-glide 3600 -> 59 samples, moonwalk 0.09% (PASS).
- [x] D17c. STATE COVERAGE: job anims (smith/angler/farmer/vendor), sit/eat at night, attack/cast/hurt/death for guards/heroes/raiders, animal graze/walk/flee. DONE: town-day shot sheet, NPCs visibly work. -> DONE Nov 12: trades work in their own motions (JOB_ANIMS: smith hammer, farmer hoe/baskets, woodcutter/miner swing, stalls+shops serve; walkers work their yard out of doors half the time); seats (square benches x2, tavern stools+chairs) sat on - Sit_Chair_Down/Idle/StandUp, often of an evening; tavern-yard drink/bite (Use_Item; no seated-eat clip in KayKit); raid swings vary (4x1H, 3x2H), Hit_A/B + Block_Hit + parries, Death_A/B; beasts graze (neck bent by a SkeletonModifier3D - the CC0 farm pack has no eating clip) and bolt from a raider within 14 m. tools/_d17c_test.gd 130 s day+evening+raid: all 14 states seen, 0 empty clips (PASS); old: no land-work, no sitting, no flight, graze only hens. Sheet renders/cycles/20261112_d17c.
- [x] D17d. BLENDS/TRANSITIONS: proper blend times, no pops, death doesn't T-pose. DONE: no visible pops in a 60 s capture. -> DONE Nov 12: the real pops were corpses getting up (the gait drove a fallen body out of its held Death_*_Pose into Idle ~1 s after the fall - old render: a buried farmer back on her feet doing PickUp) and body-yaw snaps (steering sets rotation.y outright). Rig: a Death_* marks the player fallen, nothing but another death or Rig.revive (a KO'd hero coming round) moves it; Townsfolk eases turns at 540 deg/s (walkers keep face_fix). tools/_d17d_test.gd 60 s, 2 raids + 6-death fixture, 90 bodies/frame: risen 3 -> 0, turn snaps 165 -> 4, one-frame bone pops 0 -> 1 of 284k (clip changes already blend - D17a's 0.2 s default), shake 1 -> 0 (PASS). Sheet renders/cycles/20261112_d17d.
# Phase C - the map: town & valley [D18]
- [x] D18a. PROP/BUILDING SANITY: 0 floating/interpenetrating props, buildings on ground, roads connect, wall/gates/bridge coherent. DONE: sweep = 0 floating/clipping; shot sheet.
      DONE cycle D1: tools/_d18a_test.gd sweeps 1034 ground props (0 floating/sunk past tol, slope+surface+water+planter
      dressing classified) and 83 building footprints (oriented, 0 interpenetrating). D18A_TEST OK. No genuine placement
      bug found - every earlier flag was intended (wall lanterns, tower crossbowmen ~11.7m, table/rack dressing, flowers
      in raised planter boxes, dock props over the riverbed, scar-mouth crag on the mine slope, hillside cottages nestled
      at the _low seat, forest canopies). No game script changed. renders/cycles/20261112_d18a (gate, bridge, square,
      scar, docks, aerial, hillside farmstead) - wall/gates/bridge/roads coherent, buildings on ground, nothing floats.
- [x] D18b. DRESS THE VALLEY: fields, fences, crops, mill, docks, forest, paths. DONE: valley shot sheet reads lived-in.
      DONE cycle D2: valley.gd _dress_valley - each steading (Coalfoot, Bramble End) now has 2 fenced, ploughed,
      cropped fields (wheat/veg) with a scarecrow + a footpath to the gate, a picket kitchen garden, a hayrick and
      grazing stock (sheep/cattle); a plank fishing jetty over the ford's slow water; wildflower + tall-grass verges
      along the lanes and a copse between the roads. Built 4 fields / 1416 crop sprites / 133 fence posts / +5 beasts.
      D18B_TEST OK; parse 0 err, _offfloor 0/1036 (0 inprop), TWITCH_PARSE OK, _townwalk in_solid 0/18452 stuck 0,
      _delve_test (DELVE_OIL=1) 0 SCRIPT ERROR to floor 2. Shots renders/cycles/20261112_d18b (steadings, jetty, aerial).
- [x] D18c. GROUND & MATERIALS: ground texture blending (grass/dirt/road/water), water shader. DONE: before/after; 0 material-null headless. -> DONE Nov 12: wet muddy shore in ground.gdshader (noise-ragged band at the waterline, wet sheen; water_y from town) blends the banks under the river; grass/dirt/road blending already lived in the shader (town-mask trodden dirt + rock/snow/scar), water shader kept. The 3 headless material-nulls traced (bisection) to Gear.ignite's per-surface overrides draped by show_tiers' _cloth material_override on the rack weapons - town.gd _tier_rack now bakes the lit material into a duplicate mesh (gear.gd untouched). Bare headless start: 0 material-null, 0 errors; shots renders/cycles/20261112_d18c (bank+ford before/after, rack intact).
# Phase D - lighting, day/night, atmosphere [D19]
- [x] D19a. daylight.gd DAY/NIGHT: sun angle+colour, dawn/dusk warmth, real night dark, lamps/braziers/windows as OmniLights at night. DONE: full-day timelapse shot sheet. -> DONE Nov 12: day/night was already driven by daylight.gd (sun arc+colour, goldness dawn/dusk, nightness + a moon you can see by, lamps*k, windows emission); added night BLOOM - town env glow_enabled, glow scaled by nightness in daylight.gd so windows/lamps/braziers halo after dark and the day stays clean. _d19a_test OK (noon sun_e1.5/high white; dawn+dusk gold, lamp0.95 glass1.6, glow0.75; night moon0.7, lamp1.28 glass2.4, glow1.0); 92 lights/1 glass-mat. Full-day sheet renders/cycles/20261112_d19a (04/06/08/12/16/18.5/20/22 + close night).
- [x] D19b. (ALSO: snapshot_pub.gd adds hero.max_hp, hero.xp_next, town.raids_turned - Mr. E approved 16:24, see COORDINATION 8.3) ATMOSPHERE: fog/haze, clouds, optional rain, sky gradient + stars at night, soft god-rays. DONE: shots across time/weather; FPS holds. TICKED D-cycle 116: custom sky shader (clouds/stars/sun+moon), weather machine clear/overcast/rain + streak rain, fog by weather + dawn mist, volumetric god-rays; 9-shot sheet, D19B_FPS avg 110.3; snapshot adds max_hp/xp_next/raids_turned + day_phase/weather, W1A_TEST OK.
# Phase E - life & simulation depth [D20]
- [x] D20a. RICHER ROUTINES (notables/townsfolk): work->market->tavern->home by hour, right anim per activity. DONE: town soak shows routines.
      DONE D-cycle 117: townsfolk.gd _maybe_errand - ordinary shuttle folk break off ONCE a day for a midday MARKET
      shop (buy/haggle anims) and an after-shift TAVERN mug (eat/drink), each at its own staggered hour, interrupting
      the linger so a 25-50 s job stint never swallows the short midday window; notables keep their hour-slot days.
      D20A_TEST PASS (market 8, haggle 33, midday-square 358; tavern 5 + eat; notables reached 17/24; 0 empty clips).
      parse 0, OFFFLOOR 0/1027, TWITCH_PARSE OK, _townwalk in_solid 0/18496 stuck 0, _delve 0 SCRIPT ERROR. Night-home
      (homed folk walk the compressed night, pre-existing) out of scope. renders/cycles/20261112_d20a.
- [x] D20b. CROWD REACTIONS: raid sends civilians fleeing/indoors; market bustle by hour; festival gathers. DONE: raid in a soak clears the streets.
      DONE D-cycle 122: a raid is now an ALARM the townsfolk read (town.is_raid_on <- raids._live). Ordinary folk (not the
      watch/chief/lookouts/stallholders) drop their routine and RUN for cover - home, else the nearest house (town.flee_refuge),
      ducking indoors at the threshold - so the streets clear; they cower until the all-clear, then ease back out staggered. A new
      FESTIVAL beat (town._festival_pass, is_festival/festival_at) gathers idle folk to the square to mill and cheer. Market bustle
      stays D20a's midday errands. D20B_TEST PASS (base_street 120 -> raid_street 52; fled OK; festival square 3 -> 42, gathered OK).
      parse 0, OFFFLOOR 0/954, TWITCH_PARSE OK, _townwalk in_solid 0/14380 raid 0/2095 PASS, _delve 0 SCRIPT ERROR. LOOK renders/cycles/20261113_d20b.
- [ ] D20c. ANIMALS: herds graze/drift, dogs follow, birds flock. DONE: animal-behaviour probe in a soak.
# Phase F - magic & combat feel (town) [D21]
- [ ] D21a. spells.gd VFX: bolts/heals/buffs with real particles/trails/impact; mages/clerics cast visibly. DONE: raid soak shows spell VFX.
- [ ] D21b. RAID COMBAT FEEL: hit reactions, impact FX, deaths that read, guard formations, a cavalry charge that lands. DONE: raid soak, FPS holds.
# Phase G - audio polish (owns sfx.gd) [D22]
- [ ] D22a. MIX & SPATIALISATION: layered ambience (market/smith/river/birds), footsteps, combat/spell sounds, GAP-throttled. Also bump the 3D pool 16->24 (D15 peaked 16/16). DONE: sound review + short audio soak, GAP holds, 0 audio errors.
- [ ] D22b. MUSIC MOODS: smooth day/night/raid transitions, victory/defeat sting; keep 24/7-safe (D15). DONE: transition review.
# Phase H - performance (stretch) [D23]
- [ ] D23. (measured per COORDINATION 8.5: publisher + chat on, L32 grid up) Hold 100+ FPS on a long busy stream: extend D7 LOD, cull far detail, kill the ~1.5 s floor-build hitch, cap particle emitters, cheap nav rebakes. DONE: 30-min soak fps_avg >= 120, no sustained dips.

### LAPTOP (dungeon/combat/content/UI) - floorgen.gd, dungeon_parts.gd, dungeon_hd.gd, bestiary.gd, monster.gd, gear.gd, roster.gd, chatcmd.gd, delve.gd, data/*, UI files (rts_camera, feed_hud, leaderboard_panel, party_frames, boss_bar, auto_director, health_bar_3d, spotlight)
# Phase A - dungeon geometry & nav [L25]
- [x] L25a. STAIR INTEGRITY: continuous treads, correct step vs G=4.0/floor height, landing both ends, registered walkable. DONE: stair-probe over 12 floors, 0 gaps, landings both ends.
- [x] L25b. COLLISION-AWARE PROPS: no prop-prop or prop-in-wall overlap, clearance from doorways/path; placement validator reseats/drops overlaps. DONE: overlap probe 12 floors = 0 > 0.2 m, 0 blocked doorways.
- [x] L25c. DUNGEON NAV: bake a NavigationRegion3D per floor (open cells minus obstacle circles + walls, like TownNav) OR cell-grid A*; route delvers on it + unstick watchdog. DONE: 10-floor descent = 0 stuck delvers, 0 in geometry.
      DONE (Cycle 89 + L-cycle 110, laptop): tools/_l25_test.gd OK 13/13 twice - 0 stuck delvers (was 104), 0 forced descents,
      watchdog 5 and 1 nudges / 10 floors (was 51). Nav = cell-grid BFS over clear cells + obstacle circles, reachable fight slots.
- [x] L25d. ROOM/CORRIDOR COHERENCE: no orphan rooms, all reachable, doorways align, tiles don't z-fight. DONE: connectivity check over 12 floors, shot sheet.
# Phase B - dungeon look: textures/materials/biome/lighting [L28]
- [x] L28a. MATERIALS: real albedo/rough/metal per theme+biome, normals where the kit has them, fix material-null. DONE: 0 material-null, before/after 3 themes.
      DONE (L-cycle 111): kit surface shader - per-swatch rough/metal + triplanar CC0 stone/wood detail + theme wetness; materials per floor 689 -> 44 (tinted biome); dungeon-side material-null 0. Shots renders/cycles/20261112_l28/a_*.
- [x] L28b. BIOME DISTINCTION (data/biomes.json ~14 worlds): colour grade, fog/haze, ambient particles, ground variants - each biome its own place. DONE: per-biome shot sheet, no two alike.
      DONE (L-cycle 112): per-floor Environment from data/biomes.json "looks" (ambient, depth+height fog, 1D-LUT grade, sat/contrast, glow) seen by the main camera + lanes; one capped mote emitter; ground patches. L28_ALIKE OK 14/14. Sheet renders/cycles/20261112_l28/all_sheet.png.
- [x] L28c. LIGHTING/ATMOSPHERE: per-floor key+fill, torches/braziers as OmniLights w/ embers, depth fog, boss-floor drama. DONE: shot sheet, FPS holds (cap emitters).
      DONE (L-cycle 113): look-driven key (1 shadowed spot) + fill, flickering torches/braziers, ONE shared ember emitter, boss lord light+ash+harder grade; emitters 2-5/floor (cap 12); FPS -1..-7% (all >=115); sheet renders/cycles/20261112_l28/c_sheet.png.
- [x] L28d. DETAIL DECALS: cracks/moss/blood/scar-glass veins to break repetition. DONE: varied-floor shots, 0 new errors.
      DONE (L-cycle 114): self-made CC0 decal textures (tools/_l28_decals.gd -> assets/dungeon_look) - cracks everywhere, moss/soot/blood by theme, glowing scar-glass veins from floor 6; 18/floor (cap 24) on room floors + wall bases, never stairs/keep-clear; 0 new errors, FPS unchanged; sheet renders/cycles/20261112_l28/d_sheet.png.
# Phase G - the stream's resting state [L32] (Mr. E, Nov 12 16:08 - a CORRECTION of the spotlight's idle behaviour; jumps the queue)
- [x] L32a. SPOTLIGHT ALWAYS-ON: the 2x2 grid is the stream's RESTING state, up 24/7 - never collapse to a single full-screen view. An idle lane shows AMBIENT LIFE: a rotating shot of random heroes, NPCs, town life or the dungeon (new subject every ~20-30 s; prefer something happening - a job, a fight, animals, the market). Paid moments (bits/subs/points) take their lane for the seconds bought, QUEUED IN ORDER - the first payer gets their FULL time, then the next in line (the existing per-lane queues already do this - keep them). When a paid moment ends and the queue is empty the lane returns to AMBIENT, never to blank, never collapsing the grid. Keep F10 labels toggle and the SubViewport perf model (the main view stops drawing 3D while the grid is up - which is now always). DONE: a soak shows all four panes live with ambient rotation while lanes are idle; a scripted influx of bits/subs/points plays out in order, each for its full seconds; FPS holds.
      DONE (L-cycle 116): grid permanent (off/pair layouts gone), idle lanes rotate ambient subjects 20-30 s (fight > catch > heroes > folk > animals), paid FIFO kept - influx played in order, each full seconds; back to ambient on drain. L32_TEST OK 102 checks; FPS vs old full-screen 41.9 -> idle 28.8 / paid 21.6 (relative checks pass); shots renders/cycles/20261112_l32/. Guild Roll + director banner now never show (hid whenever panes carried the view) - needs Mr. E's call on a new home.
- [x] L32b. (SUPERSEDED BY L39 - Mr. E rejected the full-width bar, Nov 12 22:25)  CHRONICLE AT THE CENTRE: the on-stream Chronicle moves to the MIDDLE of the 2x2 - a thin strip or vertical bar at the cross of the four panes (Mr. E's original ask) - with calm pacing so a busy moment does not scroll like crazy (batch or fade, cap lines per second); readable at 1080p. DONE: 1080p capture with the grid up and the Chronicle at the centre; a busy-moment pacing check.
      DONE (L-cycle 117): full-width centre strip (HudDock.STRIP 0.10) parts the pane rows; chrome slimmed to 0.06 (clock/chat only); Chronicle paced - 1 line / 0.8 s, flood skips to the latest 8, fade-in; lord card resized to fit the strip. L32B_TEST OK 9/9 (pacing: 40-line flood stayed calm, caught up to latest); L21 52/52 with the new centre region; shot renders/cycles/20261112_l32/b_centre_1080.png.
# Phase C - creatures: animation + roster [L26/L27]
- [x] L26a. ANIM AUDIT across the WHOLE bestiary: every family map resolves to real clips, fallback when missing (no T-pose/glide); monster.gd states drive the right clip; attack timing lines up. DONE: MON_ANIMS = 0 static.
      DONE (L-cycle 115): tools/_l26_anims.gd - MON_ANIMS static=0 (13575 moving frames, floors 2/5/9), every def resolves; clip fallbacks, procedural flinch for 7 bodies with no hit clip, run when chasing fast, 2nd attacks, melee blows land at the clip contact (0.26-0.60 s). L25 OK.
- [x] L27a. NEW MONSTERS from owned CC0 packs (KayKit Skeletons/Halloween, Quaternius - NOT Bestiary/QAL): add to TYPES with height/anim map/depth/strain. DONE: appear at depth in a soak, animate, parse clean.
      DONE (L-cycle 118): 9 new creatures from owned bodies (no Halloween pack on disk) - marrow hewer, pale cutthroat, silk mother (+spiderling fodder), scar rat, fen lurker, pit wyrm, ash wight, gloom bat - each with height/anims/tint+glow/ways/homes, wired into DEPTHS 6-7/8-9/10+. L27A_TEST OK; deep soak (floors 7/9/11) static=0 of 21637, hewer/ash wight/cutthroat seen fighting; parse 0; line-up shots renders/cycles/20261112_l27/.
- [ ] L27b. STRAINS (data/strains.json): widen coverage + a clear visual tell each (glow/particle/scale). DONE: strain probe shows tells, stat mods apply.
# Phase D - bosses & encounters (canon from NOTES.md/bosses.json) [L29]
- [ ] L29a. LORD MECHANICS: each canon lord gets a real mechanic (adds/phase/hazard/enrage); boss_bar shows phase; per-phase trappings. DONE: boss harness 0 errors, a delve fights a lord with its mechanic.
- [ ] L29b. RARE UNIQUES (NOT new lords - modified variants, bosses.json lesser/greater/draw/rule): rare spawn, visible modifier, better loot. DONE: a unique rolls + drops in a soak.
- [ ] L29c. SET-PIECE ENCOUNTERS from lore (ambush/guarded hoard/mini-event) so a floor isn't just a room of monsters. DONE: set pieces appear + resolve, Chronicle logs them.
# Phase E - gear, cosmetics, loot [L30]
- [ ] L30a. GEAR EXPANSION (items.json accessories): more weapons/armour per tier, visible on handslot bones (rig EQUIP), real bonuses. DONE: heroes equip visibly in a soak, bonuses apply.
- [ ] L30b. COSMETICS & DYES (items.json): more cloaks/hats/rings/amulets/boots/gloves; !wear/!dye change the model live; channel-point cosmetics gated (needs T1/Mr. E). DONE: !wear + !dye change the model in a soak.
- [ ] L30c. LOOT TABLES by depth/biome/boss; boss uniques; Chronicle announces rare finds. DONE: loot scales in a 10-floor soak, a boss drops its unique.
# Phase F - dungeon-side UI / readability (stretch) [L31]
- [ ] L31. Dungeon-fight UI (party frames, boss bar, feed HUD): damage numbers, status-effect icons, "Now fighting: <lord>" banner, legible at 1080p. Keep the parchment+ink+teal theme. DONE: 1080p capture, HP/damage/statuses/phase readable.

### HUB (web/ only) - hub builder owns web/index.html, app.js, style.css, NOTES.md, docs/HUB_SECURITY.md. Keep the el()/textContent + ICON_SET + CSP model. Republish gated on supervisor review.
- [x] H1. VISUAL ELEVATION to an SSS+ grimoire: ornate frames/borders, parchment texture, illuminated drop-cap heads, richer hero character-sheet cards, tier badges on boards, better animated d20, micro-anims (respect reduced-motion). Responsive: phone/desktop/overlay. DONE: before/after at 3 widths; security invariants + hostile-name test pass.
- [x] H2. CHRONICLE on-site + filter tabs by type (combat/loot/boss/town/chat) + per-type icons + text filter + pause-on-hover (keep the on-stream strip in-game). DONE: filters work vs ?mock=chronicle, legible at 1080p.
- [x] H3. HERO SHEETS deepened: stat block + mods, class/species crest, level/XP, HP, equipped gear w/ icon+tooltip, cosmetics/dyes, title+epitaph for the Fallen. Keep paging (HERO_PAGE 60). DONE: ?mock=crowd 200 fast, ?open=1 full sheet.
- [x] H4. BOARDS/LEADERBOARD tiers (SSS/SS/S/A/B) styled, sort tabs, Guild Roll + Fallen, town-status strip (day/pop/treasury/raids). DONE: tiers + sorts render, status strip live.
- [x] H5. TWITCH CHAT EMBED + clickable local d20. CAUTION: minimal CSP change for the embed, documented in HUB_SECURITY.md, flagged for supervisor review; page stays read-only. DONE: chat loads, d20 rolls, CSP documented, invariants intact.
- [x] H6. TWITCH LOGIN scaffolding (device-code OAuth, public client id) so viewers see their own hero - the client id is NEEDS-MR.-E; wire against a placeholder. Still no viewer writes (read-only through Phase 2). DONE: flow wired/testable w/ placeholder, token step gated on Mr. E.
- [x] H7. PERF/A11Y/POLISH (stretch): fast first paint, no layout shift, lazy-render the crowd, reduced-motion, contrast+focus, keep offline/stale honesty. DONE: fast on a phone, a11y pass, invariants intact.
# CHANGELOG 16:01 (supervisor): H1-H7 built, security-reviewed and PUBLISHED LIVE (gh-pages 0ac04f8). Twitch sign-in wired with Mr. E's public client id; the ?twitch_client override removed as a phishing vector. Hub queue is now empty - only Phase 3 (gated) remains.

# Phase 3 (NOT now - stays read-only until RLS designed): friends/party, a write-backed leaderboard, any viewer WRITE path.
## CHANGELOG 16:10 (supervisor): added L32a-b (spotlight always-on 2x2 + centre Chronicle), placed BEFORE Phase C at Mr. E's direction - it corrects the stream's idle look. IDs frozen as ever.

# Phase H - regression found by the supervisor (Nov 12 18:25)
- [ ] L33. STUCK DELVER REGRESSION: after L27a (nine new monsters at depth) _l25_test went from a clean 0 stuck / 0 nudges to 1 stuck delver (floor 3, state=descend) in a 10-floor run. Likely the denser monster population crowding fight slots or the descend route. The watchdog still frees them, so it is not fatal, but L25's acceptance was 0. Reproduce, find whether it is spawn crowding or route blocking, fix, and get _l25_test back to 0 stuck. DONE: _l25_test OK 13/13 with 0 stuck over 3 consecutive runs.

# Phase I - Mr. E's live-stream findings (Nov 12 ~21:55, from his own OBS recordings + play test)
- [x] L34. DIRECTOR PANE FREEZES (top-left) when a hero dies, rerolls, or a subject vanishes. ROOT CAUSE FOUND by the supervisor, two parts, both laptop-owned:
      (a) scripts/auto_director.gd _process(): after `var best := _best()` there is `if best.is_empty(): return`. When the current subject dies/rerolls, _shot_alive(_cur) goes false AND _best() can come back empty during the transition, so the function returns and the eye is left parked exactly where it was - the top-left pane then shows a frozen frame. FIX: when best is empty, do NOT return - fall back to an ambient/tour shot (the `tour` path already exists, and L32a added ambient subject selection for the lanes - reuse it) so the director always has something to watch.
      (b) scripts/spotlight.gd _follow(): the director pane copies the main viewport camera every frame (`var main := get_viewport().get_camera_3d()`; `dc.global_transform = main.global_transform`). When that returns null the pane silently holds its last transform with no visible error. FIX: if main is null or invalid, drive the director pane's own camera from the RtsCamera/eye focus (or the ambient subject) instead of leaving it stale.
      CONFIRMED by Mr. E's own in-game chat note in the 19-34-39 recording ("the top left screen goes black or stays stuck when someone dies") and visually in the 19:27 recording: the top-left pane is not merely frozen - it renders a BLACK/empty void (camera left inside geometry or below ground) while the other three panes run normally. DONE: a scripted death + a reroll + a subject despawn each leave the top-left pane still moving (ambient or new subject) - verified in a windowed capture, 0 frozen frames.
      DONE L-cycle 119: auto_director._fallback_shot() steps the tour instead of returning when _best() is
      empty (both return sites); spotlight._follow() falls back to the eye's own camera, then to _eye_xform(),
      so the pane never holds a dead frame. tools/_l34_test.gd windowed: scripted death + reroll + despawn
      each leave the pane moving - 0 stale frames, 0 below-ground, 0 empty ticks, L34_TEST OK (30 checks).
      Proven against the fault: with the main camera forced out of play the UNFIXED code moved the pane
      0.00 m (179 stale frames, FAIL), the fixed code tracked the eye 257.71 m of 257.71 m. Shots
      renders/cycles/20261112_l34/. _l24 OK, _l21 OK, _l32 OK (idle 69.7% of base), _offfloor 0, _delve_test clean.
- [ ] L35. SUBSCRIBER LANE follows subscribers (Mr. E, Nov 12): the subs lane should always be showing a SUBSCRIBER's hero, not sit idle. Priority: a NEW subscriber (sub/resub/gift) takes the lane immediately for their purchased seconds (the existing paid queue and ordering stay exactly as they are - first payer gets their full time, then the next in line). When no paid sub moment is queued, the lane ROTATES through known subscribers' heroes, changing subject every 15 s. If no subscriber hero is available, fall back to ambient (never blank, per L32a). DONE: with no paid events, the subs lane cycles a different subscriber every 15 s; a new sub interrupts and holds their full time; the queue order is unchanged.
- [x] D24. GRAPHICS - KILL THE GRAIN (Mr. E: "everything feels grainy... like someone sprinkled sand all over it", town worst). ROOT CAUSE FOUND: project.godot has an EMPTY [rendering] section - no TAA, no MSAA, no FXAA anywhere in the project. SSAO (town.gd:828) and volumetric fog (daylight.gd:58-62, 245) are BOTH temporally dithered in Godot 4; with no TAA to resolve them they show as fine static noise over the whole image, worst on cluttered town geometry, and the god-rays/glow add to it. FIX: enable TAA (rendering/anti_aliasing/quality/use_taa), add MSAA 3D 2x-4x for edges, then re-tune SSAO (radius/intensity/detail - or drop it if TAA alone looks right) and re-check volumetric fog density now that it resolves cleanly. Watch FPS: measure before/after. DONE: side-by-side town stills at 1080p before/after showing the grain gone, FPS still >= the D23 target, and Mr. E's eye on it. RESULT (desktop D-cycle 118): project.godot [rendering] now use_taa=true + msaa_3d=1 (2x); SSAO softened (intensity 1.3, detail 0.3, radius 1.8) in town.gd; volumetric fog resolves cleanly, left as-is. Grain gone in 1080p before/after; uncapped FPS at the resting stream cam ROSE 123.4->131.7 avg (min 81->90), >= 120 target. Stills in renders/cycles/20261112_d24. Awaiting Mr. E's eye.
- [x] D25. TOWN REWORK - LAYOUT AND COLLISIONS (Mr. E: the farm, the streets, all of it needs revamping; "things are colliding, structures are overlapping"). NOTE: D18a reported "town placement already clean" yet the running build clearly shows overlaps - so D18a's probe is too narrow (it checked props, not buildings/farm/fence/road footprints). FIX: (1) widen the placement probe to test BUILDING and farm/fence/road footprints against each other, not just scatter props; (2) rework the town layout - real street topology that buildings face and do not block, a farm that reads as fields+barn+fences rather than scattered pieces, no structure intersecting another, nothing floating or sunk; (3) keep walkability - re-bake nav and keep _townwalk at 0 in_solid. DONE: the widened probe reports 0 overlapping footprints, a 1080p shot sheet of the town and farm from the stream camera, _townwalk PASS, and Mr. E's eye on it. RESULT (desktop D-cycle 120): tools/_d25_probe.gd tests footprints of houses, growth SPECIALS, valley structures AND field rects vs each other + roads (game's own _rect/_rect_on_road authority; plaza-fronting landmarks/shops/towers exempt). Town is geometrically CLEAN (BLD=0, FLD=0 at lvl 3+6); the one real defect was 1 house a later road was cut through, now removed by town.gd _final_road_sweep() after all roads are laid. D25_PROBE OK; _townwalk PASS (in_solid 0/18777); shot sheet renders/cycles/20261112_d25/. Farm reads as fields+cottages+fences+garden+hayricks.
- [ ] L36. CHAT OVERLAY COLLIDES WITH THE CENTRE CHRONICLE (seen in Mr. E's 19:34 recording): the in-game Twitch chat box draws over the L32b Chronicle strip - "A trade caravan is sighted on the west road." is overprinted by chat lines and both become unreadable. The chat and the Chronicle must not share pixels: give the centre strip its own reserved band that chat is docked clear of (HudDock), or move chat into a lane/side column. DONE: a 1080p capture with chat busy AND the Chronicle running shows zero overlapping text.
- [ ] L37. DUNGEON SCAR-VEINS ARE OVERDONE (seen in the 19:27 recording): the L28d glowing vein decals read as bright purple/cyan neon spaghetti looping across the floor rather than cracks in stone. Cut emission strength and coverage hard, break up the continuous curves, and keep them as a subtle tell. DONE: before/after floor shots; the veins read as glowing cracks, not neon piping.
- [ ] L38. AMBIENT PANE FRAMING IS POOR - THE BIGGEST VISUAL PROBLEM (supervisor reviewed all 13 recordings: a large share of pane-frames are a close-up rooftop, bare grass, open water, a blank wall or a dark void): idle lanes frequently frame a rooftop, a blank wall, empty paving or the inside of a market stall - the camera sits too close/low and clips into structures. Ambient subjects must be chosen AND framed so something legible is happening: prefer a subject with motion, pull back and raise the eye, reject a shot whose view is mostly roof/ground/wall (the _clear() clearance rule exists - extend it to reject bad compositions). DONE: a 3-minute idle capture where every pane change lands on a readable subject; no roof-fillers.

# Phase J - from Mr. E's full OBS review (supervisor watched all 13 Nov-12 recordings, 22:30)
- [ ] L39. CHRONICLE IS A CENTRE BOX, NOT A BAR (Mr. E, with reference screenshot; this REPLACES L32b's full-width band). The Chronicle must be a COMPACT PANEL sitting at the centre cross of the 2x2 - roughly the size of the small white box in his screenshot - NOT a tan band spanning the whole screen. Requirements: a small light/white panel centred on the intersection of the four panes; it covers only the corners of the panes it touches, never a full-width strip; it shows the latest few lines, calmly paced (L32b's pacing work is kept); nothing else may draw over it and it may not draw over chat (see L36). DONE: a 1080p capture with the grid up showing a compact centred box, measured at well under half the screen width, with no full-width band anywhere, and Mr. E's eye on it.  [OWNERSHIP MOVED TO DESKTOP HUD + REDEFINED - COORDINATION 11.4; left UNTICKED deliberately, see the laptop note below]
      DONE L-cycle 120: HudDock.STRIP (a full-width band) -> BOX_W 0.30 x BOX_H 0.13, centre() returns a
      compact rect centred ON the cross; spotlight._relayout lets the two pane rows MEET there, so the box
      covers only each pane's corner (~4.2%). feed_hud: light near-white panel, lord card shrunk again for
      the narrower box, overrun lines ellipsised. tools/_l39_test.gd windowed: 576 px = 30% of the width
      (half is 960), centred within a pixel, rows meet, <12% of any pane covered, >=2 lines at the L15 size,
      nothing spills under a 30-line flood, a lord's card still fits - L39_TEST OK (19 checks). L21_TEST OK
      (52), _offfloor 0, _delve_test clean. Shots renders/cycles/20261112_l39/.
      LAPTOP NOTE (do not delete; L-cycle 120, commit 415885a on branch `laptop`, NOT yet merged to main):
      the laptop built the centre box BEFORE this item moved to the HUD worker and before Mr. E refined it to
      "SMALLER TYPE - the font shrinks first, then the panel". What exists on `laptop` shrank the PANEL and
      left the line font at 28 px, so under the new wording this item is NOT done - hence unticked. The HUD
      worker owns it now: either build on the laptop commit or redo it; HudDock.BOX_W / BOX_H and the font
      size in feed_hud are the three numbers. The laptop will not touch these files again (COORDINATION 11.2).
- [ ] L40. HUD AND ALERTS MUST STAY OUT OF THE PANES AND OFF THE CHRONICLE. The recordings show (a) the party-frames panel ("The town's band - floor N") rendering INSIDE a pane, which L21's default-deny docking was supposed to prevent; (b) the "Joined The Court" follower/sub alert drawing across the Chronicle; (c) the Twitch chat column overprinting both the Chronicle and the lower-left pane. Every HUD element, alert and the chat column needs a dock that is clear of the panes and clear of the centre Chronicle box. DONE: a capture with a sub alert, busy chat, party frames and the Chronicle all live at once - zero overlapping pixels between any of them.
- [ ] L41. MISSING MATERIAL ON A DUNGEON FLOOR (bright magenta). In the 19-17-57 recording an entire dungeon floor renders hot magenta - Godot's missing-shader/material colour - with the party frames over it. Something in the L28a dungeon_kit shader path fails to compile or bind for at least one theme. Find which theme/mesh, fix the binding, and add a guard so a failed material falls back to a plain grey PBR instead of magenta on stream. DONE: every theme sampled over 12 floors renders with real materials, 0 magenta, and a deliberate broken-material test shows grey not magenta.
- [ ] L42. DUNGEON LIGHTING IS NEON. Several floors read as saturated pink/green/cyan glow (silk-mother floor, firepits) rather than lit stone - L28c's key+fill and L28d's veins together are far too strong and too colourful. Pull emission and light colour saturation right down; the dungeon should read as dark stone with sources of light, not a nightclub. DONE: a per-theme shot sheet at 1080p that reads as lit stone; Mr. E's eye on it.
- [x] D26. MOSS/DECAL SPLOTCHES ON TOWN ROOFS. Across the recordings the terracotta roofs carry bright flat green blobs that read as spilled paint, not moss. Either the decal is far too saturated/opaque or a dungeon decal is bleeding onto town roof materials. Fix so roof weathering is subtle. DONE: before/after roof close-ups at 1080p. RESULT (desktop D-cycle 119): not a decal/dungeon bleed - the town's GREEN livery roof tint (town.gd LIVERY_TINT) was Color(0.62,0.84,0.60), a bright green multiplied onto the terracotta tiles that read as green paint in the lighter tile areas. Toned to a subtle sage Color(0.78,0.85,0.74); blobs gone, roof reads as weathered terracotta. A/B in renders/cycles/20261112_d26/pair_green_{old,new}.png.
- [x] D27. THE TOWN READS AS EMPTY AND DARK FROM THE STREAM CAMERA. The recordings show large flat grass expanses with nothing in them, panes that frame a bare field or a blank wall, and daytime shots (e.g. Day 11 08:40) that look like dusk. Two parts: (1) fill the town/valley so no camera angle lands on featureless grass - paths, hedges, crops, carts, clutter, people moving; (2) check the daylight curve and exposure - morning should read as morning, not gloom (this interacts with D24: fix the grain first, then re-judge brightness). DONE: a 12-shot sweep from the stream camera at 08:00/12:00/18:00/22:00 where every frame has something to look at and the daytime frames read as daylight. RESULT (desktop D-cycle 121): (1) BRIGHTNESS - the 'dusk' was overcast weather: it greyed the sky and dimmed the daytime fill to a gloom. daylight.gd overcast sun 0.76->0.88 and dark 0.55->0.42 (rain 0.55->0.66, 0.9->0.78), plus a daytime ambient boost scaled by weather darkness (env.ambient_light_energy *= 1 + dark*0.6*(1-nt)). Clear days and night unchanged. 08:00 overcast now reads as bright cloudy daylight. (2) FILL - new town.gd _dress_greens() dresses the bare grass islands with flower beds + bushes + the odd tree (644 flora), is_clear-gated, gate lanes/river kept clear; trees/bushes register as nav solids. FPS 128.2 avg/94 min (>120 D23 target); _townwalk 0 in_solid. Sweep in renders/cycles/20261112_d27/.

### CONTENT (laptop, branch `content`, data+lore only, NEVER runs Godot) - see COORDINATION 10
- [ ] C1. COSMETICS & DYES CATALOGUE (data/items.json): items.json is only 3.7 KB - the cosmetic set is thin. Expand cosmetics and accessories a lot: cloaks, hats/hoods/helms-as-cosmetic, rings, amulets, boots, gloves, banners, pets, titles - each with the same fields the existing entries use, priced sensibly against the economy, and named from the lore (Bellmire, the scar, the Ford, the guild). Widen dyes beyond the current set and keep dye_cost coherent. Additive only; never rename or drop a key. DONE: json validates, every new entry carries the same fields as the existing ones, and a written list of what was added.
- [ ] C2. LORE LINES (data/lore_lines.json): many more tells, descend/cleared lines, lord and unique intros, barks and epitaphs, in the established voice, so the Chronicle and the barks stop repeating on a long stream. DONE: json validates; counts per category before/after; no line contradicts canon.
- [ ] C3. RARE UNIQUES + BREWS (data/bosses.json lesser/greater/draw/rule, data/potions.json): more rare unique variants (modified lords, NOT new lords) and more brews/states, all within the existing schema. DONE: json validates; the new entries name their modifier and effect.

# Phase K - test validity (raised by the laptop, Nov 12 23:55; IDs + decisions by the supervisor)
- [ ] L43. _l32_test's FPS GATE IS VACUOUS (test-validity bug, OWNER: LAPTOP). The suite printed "L32_TEST OK (90 checks, 0 failed)" while reporting "L32_FPS base 1.0 idle 26.8 paid 18.7": every FPS check is RELATIVE to base ("idle >= 65% of base"), so a base of 1.0 passed them all trivially and the gate tested nothing. First seen on the run after origin/main brought D24 (use_taa=true, msaa_3d=1). Only the FULL-SCREEN base phase collapsed; grid phases are in line with history (idle 26.8 vs 28.8-31.8, paid 18.7 vs 16.2-21.6) and the DESKTOP's D24 numbers ROSE 123.4 -> 131.7, so this is harness-specific, not "TAA is slow".
      SUPERVISOR'S DECISION: (1) KEEP the relative-to-base design - it is what makes the test portable across two very different machines; fixed per-machine numbers would need tuning and would drift. Fix the MEASUREMENT, not the design. (2) After ANY change to viewport 3D state (disable_3d toggled, grid raised/lowered) DISCARD A WARM-UP WINDOW before sampling - at least ~1.0 s of real time or 60 frames, whichever is longer - so TAA's history buffer refills; the suspected mechanism is sampling immediately after root.disable_3d=false, which TAA cannot survive. (3) KEEP the laptop's new `base >= 10.0` assert PERMANENTLY - it is what caught this. NEVER revert it to make the suite green. (4) Add a second validity guard: assert each phase sampled a minimum number of frames, and print the raw per-phase FPS so a vacuous pass can never hide again. (5) ONLY IF warm-up does not restore a sane base, measure the base phase in a separate process with a fresh viewport and no toggle. (6) DO NOT touch project.godot [rendering] - it is desktop-owned, TAA stays, and the desktop's numbers improved.
      CROSS-CHECK (either machine): run _l32_test once on the DESKTOP to see whether a collapsed base reproduces there. That distinguishes harness artifact from machine. A healthy D23 soak does NOT rule it out - D23 does not use this harness.
      NOTE FOR EVERY RUN UNTIL THIS IS DONE: _l32_test now REPORTS FAIL on the laptop by design (the new assert). That red is THIS flag, not a regression in L34/L39, and it is not a reason to reject an unrelated laptop item.
      DONE: base reads a sane FPS on both machines with TAA on, the relative checks are meaningful again, the base>=10 and min-sample asserts stay, and a deliberately-broken base makes the suite FAIL.
- [ ] L44. _l24_test IS FLAKY (OWNER: LAPTOP). Failed 3 of 6 once ("Ash's body below is the one the lane holds" plus the two checks depending on it), then passed 6/6 on an immediate re-run with nothing changed - a lane/delve timing race, the same class as the "before" check already noted.
      SUPERVISOR'S DECISION: make it DETERMINISTIC, following the precedent already set by L23 (_l20_test drives its fight and raid shots deterministically rather than hoping the timing lines up). Drive the lane/delve state the test needs instead of waiting on it. Do NOT paper over it with retries or a best-of-N: a flaky test is worse than no test, because it trains every run - and every supervisor - to ignore red. DONE: _l24_test passes 6/6 on ten consecutive runs.

# Phase L - Mr. E's Nov 13 review (the stream test + his 20-point list). IDs by the supervisor.
# URGENT - viewer-facing
- [ ] T3. !enlist "DID NOTHING" ON STREAM + THE REPLY PATH DROPS SILENTLY (OWNER: DESKTOP - twitch_eventsub.gd is desktop-owned). Investigated by the supervisor: the COMMAND path is sound - chatcmd._enlist() cannot crash on a typo or empty args because Roster.fresh() (roster.gd L231-234) substitutes a random class/species for anything unknown. The fault is far more likely in the REPLY path, which has drop points that log NOTHING:
      (a) twitch_eventsub.gd L580: `if dry_run_chat or offline or tokens["bot"].is_empty() or _token_dead["bot"]: return` - this returns BEFORE _send_chat(), so the "chat not sent" log on L590 never runs. The hero IS created, the answer is queued, dequeued, appended to sent_chat, then silently discarded. From chat it looks exactly like the command did nothing.
      (b) L572-573: an identical message inside 30 s is dropped silently. Two viewers making the same mistake within 30 s ("No hero yet - type !enlist") means the SECOND viewer gets silence. Same for any repeated error text.
      (c) chatcmd.gd L88-89: the per-user cooldown returns "" with no feedback.
      Checked and NOT the cause at the time of the stream: the bot token was refreshed 21:07 with user:read:chat + user:write:chat and ~3.7 h of validity, and no dry_run/offline flag is set in local/twitch.cfg.
      FIX: every one of those drop points must _say_log() its reason (which condition, which user, which text). A silently-swallowed reply is undebuggable and this class of bug will recur. Then make the duplicate guard per-user instead of global, so one viewer's repeat cannot mute another's answer.
      DECISIVE TEST FOR THE NEXT STREAM (Mr. E): have someone type !enlist, then look at the live hub. Hero appears on the hub but no chat reply => the command works and the reply path is broken. No hero on the hub => the command never ran (chat ingest/cooldown). That single check splits the problem in half.
      DONE: every skipped reply writes a log line naming the reason; the duplicate guard is per-user; a scripted run proves a reply either reaches chat or is logged as to why.

# DO THIS FIRST - it decides how much of the rest is real work
- [x] D28. LIVE-RUN FEATURE CENSUS (OWNER: DESKTOP, reports to the supervisor).
      DONE D-cycle 123: 7-min 8x soak (director on, 6 viewers). CENSUS TABLE + verdicts in PROGRESS. Headline: audio is
      NOT dead (3698 plays, 54/94 kinds) but FOOTSTEPS (footstep_grass/stone/water/wood) and most ANIMAL/UI sounds have
      NO CALLER -> that is the silent-town bug (-> D29). Anims FINE (30 clips, 0 miss), spells FINE (9 by name), loot FINE,
      bosses/traps PRESENT-but-RARE (feed: 3 lords, 3 traps), cosmetics NEVER worn + gear tiers stuck w0/a0 despite forging. Mr. E says he has not SEEN: the new sounds, any new animations, new bosses, new cosmetics/armour/weapons, trap damage, spell variety, or loot. All of those are ticked DONE with passing tests. Before building anything further, find out which are BROKEN and which merely never FIRE. Instrument a 30-minute soak with the director on and COUNT, per feature: every Sfx kind played (by id, with totals - the 86 RPG kinds from S1/S2/S3 especially); every animation clip actually played, by body type; bosses/lords/uniques spawned and killed; traps armed vs triggered vs DAMAGE APPLIED (hp actually lost); spells cast BY SPELL NAME (is it always the same one?); loot: chests spawned, chests opened, items dropped, items picked up; cosmetics/accessories worn by anyone. Print a table of counts and write it into PROGRESS. A count of ZERO means broken; a count of 2 in 30 minutes means too rare to ever be seen on stream - both are findings, and they are DIFFERENT fixes. DONE: the census table in PROGRESS.md, and a one-line verdict per feature (broken / too rare / fine).

# Mr. E's Nov 13 list - LAPTOP (dungeon, combat, HUD)
- [x] L45. BOSSES SCALE WITH DEPTH (his call): a lord on a deep floor must be meaningfully harder than a shallow one - hp, damage, mechanics, adds. Deeper should feel dangerous. DONE: a measured curve of boss difficulty by floor; a deep lord can wipe an unprepared party.
      DONE L-cycle 123: the real bug was that Bestiary.boss_def() never SAW the floor - a lord's hp/atk came
      straight off canon, so the same lord hit identically at any depth (uniques already scaled; lords did
      not). boss_def(b, floor_no) + depth_step() (counts lord-floors from the first, so the curve is
      open-ended and states no floor count) + named constants LORD_HP_PER_STEP 0.28 / LORD_ATK_PER_STEP 0.22.
      scale_ways() deepens the MECHANICS too - more adds arriving faster, stronger nova/swoop, harder ward,
      earlier enrage - mutating a duplicate so canon LORD_WAYS is never written to. dungeon_hd passes the
      floor. Measured curve (Hollow King, same lord): hp 150->528, atk 15.0->44.7; summon most 2->6, every
      12.0s->5.7s, ward 0.50->0.80. Wipe: an unprepared party of four (120 hp) falls to a deep lord in 2.7
      landed blows vs 8.0 shallow. tools/_l45_test.gd L45_TEST OK (10 checks) - also asserts the first lord
      floor is unchanged canon and the curve never dips. _offfloor 0 of 1130, _delve_test clean, L27A OK.
      MR. E'"'"'S CALL: 44.7 vs ~30 hp heroes is about one blow a hero - LORD_ATK_PER_STEP is the dial.
- [x] L46. TRAPS DO NO DAMAGE (he believes spikes/traps are inert). L11 claims working traps. Verify against the D28 census, then fix: a triggered trap must apply real hp loss, show a number, and reach the Chronicle. DONE: census shows trap triggers AND hp applied; a delver can die to a trap.
      DONE L-cycle 124: VERIFIED FIRST - Mr. E is right about the experience, wrong about the mechanism. L11'"'"'s
      damage code was never broken (a forced spring took 10 hp, rolled the save, floated the number, printed
      the line). Traps were almost never MET: over 4 floors a delver came within the 0.90 m radius of only
      2 of 6 traps (closest approaches 0.1/0.4/3.9/4.0/11.0/23.5 m) and 1 fired. THREE real defects, all
      measured: (1) dungeon_hd._dress() laid traps on ANY open cell - they now go on info["keep_clear"], the
      way through, which is where the party walks (coverage 2 of 6 -> 5-6 of 6, closest 0.0-0.7 m);
      (2) _traps_tick() ran ONLY inside _fight(), so the whole walk to the stairs was trap-free - it now
      runs in "descend" and in the "flee" state too (encounters 2 -> 5 over the same floors); (3) a sprung
      trap could take ZERO hp - floorf(dmg*0.5) on a save floors a low roll to 0 and fire resistance
      multiplies to 0 - now maxf(1.0, ...), so a save halves and resistance blunts but neither nullifies.
      tools/_l46_test.gd L46_TEST OK (10 checks) - it prints trap_log WITH the closest approach to every
      trap, so the next run can tell "damage broken" from "never triggered". _offfloor 0 of 1063,
      _delve_test clean, L25_TEST OK 13/13 (0 stuck, 0 prop overlap - traps on the route block nobody).
      NOTE: part C first failed on a CORRECT mechanic - the canon one-death-save-a-delve
      in _hero_hit stood the delver back up on 1 hp; the test now burns the save then kills.
- [x] L47. ADVENTURERS MUST THINK FOR THEMSELVES (Mr. E marked this PRIORITY). Delvers should make visible decisions: retreat when hurt, drink a brew when low, use oil before the dark, pick targets sensibly, search for loot, regroup, flee a losing fight, go home when spent. Right now they read as scripted. DONE: a soak where the Chronicle shows real decisions, and a hurt party retreats rather than dying in place.
      DONE L-cycle 122: delve.gd decision layer - _decide() records+announces by kind (the LINE is rate-limited
      per hero, the decision never is). NEW: _think() per hero (BREAK OFF under 22% hp with no heal brew and
      run for the way up; REGROUP past 15 m from the party centre; REJOIN past 55%), _losing() at party level
      (new "flee" state - a plainly lost fight is broken off and they run out WITH survivors), and
      _pick_target() replacing nearest-foe (finish the nearly-dead, shut up the caster/spitter/shooter).
      Drinking, healer triage and press-on/climb-out were ALREADY visible decisions - now counted and
      reasoned through the same layer rather than duplicated with new behaviour.
      tools/_l47_test.gd headless (delve LOGIC, not HUD): A soak demands a RANGE of kinds (12 decisions,
      press_on+finish); B slams the party to 10% mid-fight and requires flee + the line + SURVIVORS; C prefers
      a wounded FAR foe over a healthy near one; D hurts ONE delver to 8% with no brews - B can NEVER reach
      the single-hero path (the party-level retreat fires first and returns), so without D that branch would
      have shipped unexecuted. L47_TEST OK (8 checks). _offfloor 0 of 1043, _delve_test clean, parse 0.
      Proven by test: press_on, finish, party_retreat, flee. Wired but not yet observed firing: regroup,
      rejoin, silence, mend, brew_*, turn_back_*.
- [ ] L48. LEVELLING: CLASS + RACE UNLOCKS. Levelling should unlock new skills, spells and abilities that depend on BOTH class and species, and go deeper than that (tiers, choices). Today a level-up is a stat bump. DONE: a levelling table per class x species; a hero visibly gains a named ability and uses it.
- [x] L49. LOOT AND SEARCHING ARE INVISIBLE. No chests, no drops, nobody searching. Heroes should visibly SEARCH specified spots - a dig/search animation, time taken - and report "...no loot..." or "Found loot!" style lines. Not every monster drops. DONE: census shows chests spawned/opened and items picked up; a capture shows a hero searching and both outcomes in the Chronicle.
      DONE L-cycle 125: as with L46 the mechanic was not missing, it was INVISIBLE - _loot() already rolled
      Investigation and awarded gold, but fired the instant a floor cleared with no chest, nobody moving and
      nothing to watch. NEW DungeonParts.chest() (banded, hinged lid, a small glint to find it in a dark
      pane; set_meta("open") tips the lid). dungeon_hd lays 1-2 a floor in info["chests"], on OPEN floor
      rather than the route - a chest is somewhere you GO, traps are what you trip over. delve.gd gains a
      "search" state: the sharpest eye WALKS to each chest, faces it, kneels with Use_Item for 1.8 s, and
      only then rolls - reading out in Mr. E'"'"'s own words, "Successfully found loot!! N gold" or
      "...no loot...", with a floating +N / empty. Counters chests_found/chests_empty exposed for a census.
      Refactor: the floor-cleared branch became _floor_decision() + _fight_body() so the same decision is
      reachable after searching; the no-chest path is unchanged. tools/_l49_test.gd L49_TEST OK (9 checks)
      - it checks the LID actually rotates and the delver actually walks within 2.2 m, so loot cannot
      teleport in, and drives 80 searches: 32 found (32 of 32 paid gold), 48 empty. _offfloor 0 of 1624,
      _delve_test clean, L25_TEST OK 13/13 (0 prop-prop, 0 prop-wall, 0 stuck; watchdog 1 free in 10
      floors where the last runs were 0 - within the limit, but the chests are the thing to suspect if it
      climbs). SCOPE: chests pay GOLD; gear salvage is still _loot()'"'"'s; there are NO per-monster
      physical drops or floor pickups - if Mr. E wants those they need their own ID.
- [ ] L50. MONSTER DIVERSITY. More variety in what appears, and at what depth. DONE: a depth census showing a wide spread, not three repeats.
- [ ] L51. HUD OVERHAUL (he says it twice - it is plain and under-informative). Needs: equipment shown with what BUFFS/DEBUFFS it gives; the viewer's inventory visible so they know what they own; shops shown with WHAT THEY CURRENTLY STOCK; a way to SELL. Also the d20 needs redesigning - he does not like how it looks - and it exists to roll stats when a viewer builds a character, so wire it to that. DONE: a 1080p HUD capture Mr. E approves, showing gear with buffs, inventory, shop stock and selling.
- [ ] L52. SPELL VARIETY BELOW. He has only ever seen one spell. Verify against the census, then make casters actually choose among their spells. DONE: census shows several distinct spells cast in one run.

# Mr. E's Nov 13 list - DESKTOP (town, world, audio, visuals)
- [ ] D29. THE TOWN IS SILENT OF EFFECTS - MEASURED, NOT GUESSED. The supervisor analysed the AUDIO of Mr. E's own OBS recordings (he was right; this needs no census to confirm):
      * 19-34-39 (town/market, 39 s): dynamic range only 13.0 dB, median -34.9, peak -30.1, and ZERO windows more than 8 dB above the bed - i.e. NOT ONE discrete sound event in a busy market with heroes walking, NPCs working and a caravan arriving. It is a flat ambience drone and nothing else.
      * 19-27-48 (dungeon/delve, 49 s): range 29.8 dB with 79 spike windows (3.4%) - so the Sfx system DOES fire below ground. The fault is TOWN-SIDE, not the whole system.
      * Everything is also too quiet: median ~-35 dB, peaks only -25 dB.
      So: the 86 CC0 kinds wired by S1/S2/S3 are not reaching the town. Find whether town callers never call Sfx, call a kind id that is not in SETS, play on a muted/mis-routed bus, are throttled out by GAP, or are attenuated to nothing by 3D distance from the stream camera. Source library is github.com/jestsayin96/music-studio - READ-ONLY, copy what is needed, never modify that repo. Also raise the overall mix level.
      *** OBS RULED OUT - ANSWERED BY MR. E. THE TOWN SILENCE IS A REAL GAME BUG. PROCEED. ***
      Mr. E sent his OBS Advanced Audio Properties and mixer. Findings:
        - Desktop Audio is MUTED (red crossed speaker, flat meter). If Bellmire's output goes to the Windows
          default device, OBS was capturing it on a muted channel and no game sound could reach the recording.
        - OBS tracks 1 and 3 have identical source assignments (hence the two identical ffmpeg streams);
          OBS track 2 has nothing live on it (the -91 dB stream).
        - Source volumes are low at the source: Application Audio Capture 27%, Desktop Audio 28%,
          Game Capture 45%. That alone explains the -35 dB median.
      ANSWERED 2026-11-13: Mr. E captures Godot with the 'Game Capture' source, NOT Desktop Audio. Game
      Capture is Active with a -6.8 dB fader, so Bellmire had a live audio path into those recordings. The
      muted Desktop Audio is therefore irrelevant to the game's sound, and the measured town silence is
      ATTRIBUTED TO THE GAME. Hunt it in the engine.
      Still worth Mr. E's attention on his side, but not blocking: Game Capture sits at 45% (-6.8 dB), so even
      once the town SFX fire they will be quiet for viewers; and OBS tracks 1/3 are duplicates with track 2 empty.
      DONE: a re-recorded town clip whose audio shows clear discrete events (>=8 dB above the bed) for footsteps, voices, work and combat, at a sane level - verified the same way, by measuring the recording.
- [ ] D30. SPELL VARIETY IN TOWN - same complaint as L52, town side (mages/clerics). DONE: several distinct spells visible in a raid.
- [ ] D31. ONE BIG MAP, ONE KINGDOM (his decision). Consolidate to a single map: a small market town that GROWS - as the town levels, builders appear and actually construct new buildings on the map. DONE: a timelapse of the town levelling with builders at work and new structures appearing.
- [ ] D32. TOWN LEVELS UP FAR TOO FAST. Re-parameterise growth so levelling is earned over a long stream. DONE: a measured curve Mr. E approves.
- [ ] D33. RANDOM WORLD EVENTS ON THE MAP: bandit camps and monster camps that spawn around the map, and a random boss scaled to the TOWN's level. DONE: a soak shows camps appearing and a town-level-appropriate boss.
- [ ] D34. NATURAL DISASTERS: volcano, fire, drought, famine, sickness, hurricane, tornado, earthquake, meteor - be creative, with real consequences for the town. DONE: several distinct disasters fire in a soak and visibly affect the town.
- [ ] D35. SHOPS NEED EYE CANDY AND VISIBLE STOCK - they should look good and show what they actually have. DONE: shot sheet; stock visible (pairs with L51's HUD side).
- [ ] D36. NPC DIVERSITY - more variety among townsfolk. DONE: a crowd shot with real variety.
- [ ] D37. E3PO - A NAMED, IMMORTAL NPC (his favourite). E3PO CANNOT DIE. He is Commander of the Guards. When badly hurt he withdraws to the guard barracks and heals, then returns to duty. He must be woven into the lore, not bolted on. DONE: E3PO leads the guard in a raid, is wounded, withdraws, heals, returns - and never dies; his lore is written (see C4).
- [ ] D38. MUSIC - AN RPG FEEL. Better music throughout. Source from music-studio (READ-ONLY; copy out, never modify). DONE: day/night/raid/delve themes Mr. E approves.
- [ ] D39. TRADERS MUST MATTER. Today they arrive and leave with no effect. Make them carry SUPPLIES the town actually receives - and let bandits intercept them, so a lost caravan means the town goes without. An in-game event with stakes. DONE: a caravan arrives and the town gains; a caravan is taken and the town visibly suffers.
- [ ] D40. FISHING ANIMATIONS AND WATER both need work. DONE: before/after capture of a catch and the water surface.

# Mr. E's Nov 13 list - TWITCH (desktop owns the Twitch layer)
- [ ] T4. VIEWERS SHAPE THE TOWN (he wants this to feel like a D&D campaign where actions have consequences). Let viewers spend bits or channel points to VOTE on how the town grows: what gets built first, what gets upgraded, what laws pass - with real, lasting, sometimes BAD consequences. Open-ended by design. Needs Mr. E on reward setup. DONE: a vote runs on stream, resolves, and the town visibly changes because of it.

# Phase M - from the D28 census + the HUD worker's U1 report (supervisor, Nov 13 01:45). IDs frozen.

CENSUS RESULT THAT CHANGES THE PLAN: three of Mr. E's complaints are NOT bugs. Animations are fine
(30 distinct clips, 22251 starts, 0 missing, 0 fell-back). Spells are fine (9 distinct: heal 295,
bolt 161, mend 131, ward 112, smite 85, frost 46, chain 35, renew 31, fire 12). Loot is fine.
He is not seeing them - that is a READABILITY problem, not a content one. Do not build more of
these; make the existing ones legible. D30 and L52 are reframed below accordingly.

- [ ] D41. FINISH L40 - THE REST OF THE OVERLAP. The HUD worker made the Chronicle untouchable from
      HudDock.put(), but the two overlaps Mr. E actually flagged live in DESKTOP BUILD's files:
      party_frames.gd docks itself INTO a pane ("bl"), and rts_camera.gd owns the Twitch chat column
      and the chrome bar. Move the party frames and the chat column OUT of the panes. Owner: DESKTOP
      BUILD (do not reassign the files; the HUD worker correctly refused to touch them).
      DONE: a 1080p capture with 0 overlaps between any pane, the party frames and the chat column.

- [ ] D42. FOOTSTEPS AND ANIMAL VOICES HAVE NO CALLER - this is the silent town, exactly located.
      sfx.gd DEFINES footstep_grass/stone/water/wood and dog_whine, wolf_howl/growl, eagle_cry,
      lion_roar, orc_roar, troll_roar, zombie_moan - and NOTHING IN THE GAME EVER PLAYS THEM. 40 of
      94 kinds never fired in a 7-minute 8x soak. Footfalls are the most frequent discrete sound a
      town makes. Give them callers: footsteps from the walk cycle (surface-aware), animal voices
      from the animals that own them. horse_neigh/whinny is called in daylight.gd but fired 0 -
      find out why. This supersedes the open question in D29; D29's measurement was right.
      DONE: a re-recorded town clip whose audio shows clear discrete events above the ambience bed.

- [ ] D30. (REFRAMED by the census - the premise was wrong.) Spells are NOT monotonous: 9 distinct
      spells fire with a good spread. The problem is the viewer cannot TELL them apart. Make each
      spell read differently on screen and name itself in the Chronicle. Not more spells - clearer ones.

- [ ] L52. (REFRAMED - same finding, dungeon side.) Nine spells already cast. Make the caster's
      choice legible rather than adding spells.

- [ ] L53. gear.gd _hat needs match-cases for the content writer's new hat keys (guard_helm,
      plumed_helm and the C1 hats) or they render as the default shape. Raised by the content writer.

- [ ] L54. delve.gd must honour the new 'scar_touched' potion state or Scarwater displays and does
      nothing. Raised by the content writer.

- [ ] L55. FORGING MAY NOT RAISE GEAR TIERS - a bug nobody had reported, found by the census. Weapon
      and armour tiers stayed w0/a0 for ALL SIX heroes through a 7-min soak despite 17 forge lines
      and survivors with 4 and 8 kills. Either forging never raises the tier or death resets it.
      DONE: a soak where surviving heroes visibly climb tiers.

- [ ] L56. DELVE-HEAVY SOAK before L45 and L46 are trusted. The census could not confirm bosses or
      trap damage: raids kept pulling parties back to town and only ~1 sustained descent happened,
      so the dungeon-side counters undercounted. Seed a party straight to the mouth (or raise
      CENSUS_MIN) and read Delve.trap_log directly. This GATES L45 and L46 - do not "fix" either
      until this run says they are actually broken.

- [ ] D37 note: E3PO's words now EXIST (content writer's e3po + town_life blocks in lore_lines.json,
      merged). They are dead data until raids.gd/town.gd read them. The content half is done; the
      behaviour half is still D37 and belongs to DESKTOP BUILD.

CHANGELOG 2026-11-13 01:41 (supervisor): added D41, D42, L53-L56; reframed D30 and L52 after the census
disproved their premise; noted the C-side of D37 is delivered. C-cycles 1-3 merged to main.

# Phase N - Mr. E's rulings, Nov 13 01:50. The d20 becomes the resolution mechanic for viewer spending.

HIS WORDS: "we can do the hub for individual rolls, and then when it comes to making upgrades to the
town depending on channel points or bits spent they can roll the die to make events happen, upgrade
buildings, etc."

SUPERVISOR ARCHITECTURE RULING - READ THIS BEFORE BUILDING ANY OF IT. The roll is resolved IN THE
GAME, never on the website. Viewer redeems channel points or cheers bits -> Twitch EventSub reaches
the game -> the GAME rolls the d20 and applies the outcome -> it is Chronicled and appears in the
60 s snapshot -> the hub DISPLAYS the roll and its result. The hub therefore stays READ-ONLY and
this does NOT trip the Phase 3 RLS gate. No viewer write path to Supabase. Do not design one.

- [ ] T5. THE VIEWER'S ROLL (this is the heart of T4 and supersedes its vague "voting"). A viewer
      spends channel points or bits to attempt something - upgrade a building, trigger an event,
      push a proposition - and a d20 roll decides how it goes. D&D consequences: a high roll does it
      well, a low roll does it badly or backfires, and the Chronicle says so in plain language.
      Outcome tiers must be readable to someone who has never played D&D. The propositions the
      content writer is authoring (lore_lines "propositions", C-cycle 4) are the menu this draws on.
      Owner: DESKTOP BUILD (owns the Twitch layer, town and economy).
      DONE: a viewer redemption rolls on stream, the town visibly changes, and the Chronicle explains
      why - with at least one failure outcome demonstrated, not only successes.

- [ ] H9. THE HUB DIE SHOWS THE ROLL. The hub's existing die section animates and displays rolls read
      FROM THE SNAPSHOT - individual rolls, and the outcome of a T5 viewer roll. Read-only: the page
      never initiates or submits a roll. Keep every HUB_SECURITY invariant (el()/textContent, no
      snapshot value as URL/src/href/style, CSP unchanged). Owner: HUB BUILDER.
      DONE: a roll and its outcome render on the hub, hostile-name test still passes.

- [ ] D43. SUBSCRIBER ROSTER FROM THE TWITCH API (Mr. E approved). Twitch sends subscription EVENTS,
      not a roster, so the subscriber lane currently only knows about subs that happen while live.
      Fetch the real roster via Helix with the broadcaster token and the channel:read:subscriptions
      scope, refresh it periodically, and expose it for the HUD worker's subs lane. Token in user://
      NEVER in the repo. Owner: DESKTOP BUILD (owns the Twitch layer). UNBLOCKS L35.
      NEEDS MR. E: authorize the broadcaster token with channel:read:subscriptions.

- [ ] L35 note: the subs lane stays as built (rotates through subs seen this session) until D43
      lands, then reads the real roster. Not a defect in the HUD worker's implementation.

- [ ] L51 note: the "d20 redesign" part of L51 is now T5 + H9 and leaves the HUD worker's lane. What
      REMAINS in L51 for the HUD worker: equipment with its buffs/debuffs, the viewer's inventory,
      and selling - built as a NEW self-contained panel inside the seven HUD files. The unit frame
      (rts_camera.gd) and the !hero sheet (chatcmd.gd) stay with their owners; if the panel needs
      state those files hold, flag it and the owner exposes it. Do not edit another worker's file.

CHANGELOG 2026-11-13 01:57 (supervisor): added T5, H9, D43 from Mr. E's rulings; L51 narrowed and its d20 part
moved to T5/H9; L35 unblocked by D43. The hub remains read-only - the roll resolves in-game.

# Phase O - THE WORDS NOW EXIST. Content is no longer the blocker (supervisor, 2026-11-13 02:03).

C-cycles 3 and 4 are merged to main and passed the full gate (parse 0 SCRIPT ERROR, 0 Parse Error,
TWITCH_PARSE OK, _townwalk in_solid 0/795, _delve_test clean, _offfloor clean). Verified counts in
data/, not taken on trust. Every item below is now WRITING-COMPLETE and waiting only on code:

  T5   <- lore_lines "propositions".entries - 17 laws, each with a GOOD and a BAD consequence,
          across law, taxes, militia, building, faith and outsiders. This is the menu the d20 rolls on.
  D34  <- lore_lines "disasters" - 12 (volcano, fire, drought, famine, sickness, hurricane, tornado,
          earthquake, meteor, scarstorm, flood + one more), each with begin / during[] / pass and a
          plain-language "cost" stating what it should do to the town. Implement the cost as mechanics.
  D33  <- lore_lines "events" - 4 NAMED bandit camps (Red Harl, Sedge the Toll, Cob Ashfoot, The
          Weasel), 3 monster camps, and a wandering boss "The Scarred Lord" that scales to the town
          and reuses the 8 canon lords. Named enemies read far better on stream than "camp 3".
  D31/
  D32  <- lore_lines "growth_tiers".tiers - 12 stages from Crossing to City, each with the crier's
          line and WHAT A VIEWER SHOULD SEE APPEAR. Twelve stages exist precisely because Mr. E said
          the town levels far too fast; pace the climb across them.
  D35/
  D39  <- items.json "shop_stock" (13) and "trader_cargo" (11), {name, cost, flavour}. Shop display
          reads shop_stock; interceptable caravans carry trader_cargo.
  D37  <- lore_lines "e3po" (intro/withdraw/return/says/town_talk) + "town_life". E3PO's words exist;
          his behaviour does not. DESKTOP BUILD owns the behaviour.
  L53  <- gear.gd _hat cases for the new hat keys.   L54 <- delve.gd honours 'scar_touched'.

NOTE TO THE DESKTOP BUILD WORKER: you deferred the regression battery on 750682b because the HUD
worker held the lock - that was the correct call. The supervisor has since run the full battery on
main INCLUDING your commit and it passed clean. You do not need to re-run it for D28.

CHANGELOG 2026-11-13 02:03 (supervisor): C3+C4 merged and gated; the content writer has cleared every
writing-blocked item on Mr. E's list. The constraint is now code, not words.
