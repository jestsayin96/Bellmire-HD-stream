# Jests HD Medieval Adventure — PLAN

The HD rebuild. Source of truth for every build cycle. Read with PROGRESS.md.

## What this is
An autonomous medieval town sim + dungeon delve, driven by Twitch chat.
Viewers become heroes in the roster, delve, die, and get written into the
chronicle. The town of **Bellmire** lives whether or not anyone is watching.

The old build (`trial-and-error`) has the systems and the lore but looks flat:
its kit assets are untextured vertex-coloured blocks. This rebuild keeps the
design and replaces the look.

## The look
Quaternius Medieval MegaKit — modular, PBR, stylised-realistic.
Half-timbered houses, stone bases, clay roofs, cobbled streets.
NOT photoreal Skyrim; that was weighed and rejected as a studio's worth of work.

## Scale — settled, do not relitigate
- Kit module: 2 m grid, storey height 3.123 m.
- A house is 4-8 m wide. Real-world metres everywhere. No toy scale.
- The old game modelled a house as 3.4 units (a 3.4 m building). That is why
  detail never paid off at street level.

## Hex — the standing decision
Mr. E previously said "lets do hex for now, maybe 1 day we can make it
continuous". Tonight he said he hates how the hexagons look.
**Resolution for this build:** keep hex COORDINATES (they drive pathing,
placement, `hex_dist`, neighbour queries) and drop the visible hex PLATES.
Terrain is continuous; the grid stays underneath as maths.
If Mr. E overrules this, it is a one-file change.

## Lore spine (from the old NOTES.md — do not invent new canon)
- **Bellmire**, a valley market town. Eight districts.
- **Wild-magic scarring**: a botched casting scars the ground; inside a scar
  every spell misfires in turn. The dungeon is one enormous scar — that is why
  a meadow sits under a mountain.
- **Jests** is either the accident (trapped in his own expanding mistake) or
  the deliberate (a wound that makes more of itself is an engine that never
  needs winding). Keep both readings alive; do not resolve it on screen.
- Nine classes, D&D 5e-style stats, AC, proficiency, death saves.
- Rotating bosses, creature strains, guild ranks that buy real privileges.
- 14 biomes. Every floor has an origin — a reason it exists.
- The chronicle narrates the town; no floor count is ever stated (canon:
  "the dungeon is still being built").

## Build order
1. Project skeleton + render settings.
2. Building assembly from MegaKit, done properly (see KNOWN ISSUES).
3. Town generation: districts on hex coords, continuous ground.
4. Port systems from the old game: roster, sim, chatcmd, bestiary, rewards.
5. Characters: reuse KayKit, unchanged for now (Mr. E's call).
6. Dungeon.
7. Chronicle + HUD.

## Conventions
- Blender renders: `view_transform = 'Standard'`. Sun energy near 1.0.
- Verify by rendering and LOOKING. Never mark done on assumption.
- Generators live in `C:\Users\morta\village_assets\tools`, not in the repo.
- Never edit the old project. Read only.
- No git from the build cycles; Mr. E handles git.

## Assets owned but unused
- `itch_quat_animals` — Quaternius Farm Animals, rigged + animated, CC0.
  Ships .blend/.fbx/.obj with NO glTF, which is why it was never used.
  Convert with the connected Blender. Closes "no animals" for free.
- `itch_gobkit_animals` — Duck, Corgi, Red fit the valley.

## Asset layout - DECIDED by Mr. E, 2026-11-08
Houses are exported from Blender as geometry ONLY, with no embedded textures.
The MegaKit's 26 textures live in the project once (25.2 MB total) and every
house points at shared StandardMaterial3D resources in
res://assets/kit/materials/. Material swap is by NAME at instantiation -
glTF preserves material names, so MI_Brick in Blender arrives as MI_Brick here.

Measured: one house glb went 49.77 MB -> 0.75 MB, a 66x reduction, with no
visible change. Four liveries cost four material duplicates built ONCE at
startup, not four more files and not one duplicate per house.

He chose this over porting the whole module assembler into GDScript
("keep it simple"). The trade-off he accepted: new house SHAPES still need a
Blender export each, but they now cost under a megabyte instead of fifty.
If house variety later becomes the bottleneck, the assembler port is the
upgrade path - the measurements it needs are all in megakit.py.


## ROADMAP - set by Mr. E, 2026-11-08 07:36 (supersedes any older order)
"Make the town and surrounding area pristine. Follow the lore. Make the
equipment, the clothing, the magic, animals, spell animations etc. Do all your
building blocks before moving on to the next task. Once that is done, start
making the monsters and bosses. Then pieces for the dungeon - furniture,
gates, cells, debris, traps, lava etc."

Finish each phase COMPLETELY (built, rendered, looked at, logged) before the next.

### Phase A - Bellmire, pristine and on-lore
- A1 District LANDMARKS planted at each district centre (lore: landmark first):
  keep = Chief's Hall with the inscription "MEASURE THE GRAIN. COUNT THE FLASKS.
  KEEP THE DOOR."; temple = chapel with bell tower; garrison = barracks + yard;
  mill = windmill (turning) + granary, watermill (turning wheel) on the river;
  craft = workshops row; market = square (done). Old roster workplaces too:
  Lumber Mill, Mine (in the hills), Archery Range.
- A2 Streets: lanterns, benches, flower boxes, signposts, hanging banners in
  district livery; tidy edges; no void past the map edge (skirt/fog/horizon).
- A3 Countryside: fields + fences + farmsteads, orchard, woodland, the mountain
  and the SCAR (dungeon mouth) - a meadow under a mountain, wild-magic marked.
- A4 Animals: convert Quaternius Farm Animals (+ GobKit duck/corgi), pens and
  wandering herds, birds.
- A5 Equipment: port Rig.equip/FAMILIES tiers + glow; weapon/shield/offhand on
  every class; town racks show stock.
- A6 Clothing: outfits/tints/attachments per class and role (KayKit bodies
  unchanged - Mr. E's standing call), guild-rank trims.
- A7 Magic + spell animations: per-class casts (bolt, heal, ward, mend),
  impacts, wild-magic misfire effect, scar shimmer.
### Phase B - Monsters and bosses (bestiary port, strains, rotating bosses)
### Phase C - Dungeon pieces: furniture, gates, cells, debris, traps, lava,
    and the rest of the kit.


## RULE (Mr. E, 2026-11-08)
Do NOT bring the old game's interface over (HUD, menus, settings screen, overlays). The HD game needs a NEW interface, designed for it. Game systems, rules and lore still port from the original; the interface does not.

## NEW INTERFACE direction (Mr. E, 2026-11-08 11:49)
Follow an RTS or WoW interface, or a mix: built new for the HD game (nothing from the old UI).
