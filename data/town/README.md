# data/town - the authored town (D93)

Mr. E's ruling (Nov 15 16:57): Bellmire is HAND-BUILT. One map, roads first, then the square,
then buildings onto the blocks the roads make. Twelve levels for now; each level is a superset
of the one before (nothing ever moves when the town levels up - things only appear).

## Format "bellmire-town/1" (bellmire.json)

Units are metres. A position is `[x, z]` on the ground plane (height comes from the terrain).
`yaw` is degrees, 0 = the building's street side faces +Z (town.gd convention for the house glbs).
Every entry carries `level` (economy level 1..12): it stands from that level on.

- `roads`: `{id, pts: [[x, z], ...], width, level}` - a polyline swept by its full `width`.
  A one-point road is a paved disc.
- `square`: `{id, poly: [[x, z], ...], centre, level}` - convex or not, listed in order.
- `buildings`: `{id, shape, district, pos, yaw, half: [hx, hz], off: [ox, oz], door: [x, z], level}`
  - `pos` is the model origin, `off` the footprint centre in the model's own frame,
    `half` the footprint half extents (already scaled).
  - optional: `landmark` (lm_hall, lm_chapel, ...), `shop`, `back` (rear-rank house),
    `special` + `special_level` (a growth.gd special that takes this plot over at that level).
- `sites`: `{id, landmark, door, level}` - workplaces outside the wall (farms, mill, ...).
- `patches`: `{id, kind, poly, level}` - soil / dirt / cobble ground patches. Authored to the
  road polygons, never across one.

## Format "bellmire-town/2" - PER-TIER BUILDINGS (S170, 28 Nov 2026, game build)

Written down FIRST, before any loader, so art can author meshes against it and content's words
have a named reader. `/2` is strictly ADDITIVE: every `/1` file is a valid `/2` file with no tier
fields, and every new field below is optional with a default that reproduces `/1` exactly.

### The tier clock - one source, not copied here
A tier is 1, 2 or 3. The town level each tier starts at is `data/lore_lines.json`
`town_buildings.tier_levels` (today `{1: 1, 2: 5, 3: 9}`). The layout file does NOT repeat it.
An entry stands from its own `level`; its tier at town level L is the highest tier t with
`tier_levels[t] <= L` - but never below 1 once it stands. (A level-7 house rises at tier 2.)
- optional per entry: `tier_at: [l1, l2, l3]` overrides the clock for that one entry
  (ascending; `l1` may be omitted as `null` = the entry's own `level`).

### Buildings: `family` picks the meshes, `words` picks the text
- optional `family` (string). The mesh for tier t is `res://assets/buildings/town_<family>_t<t>.glb`.
  Defaults: a landmark's family is its landmark id without `lm_` (`lm_hall` -> `hall`);
  a house's family is `house_<shape>` (`shape: "a"` -> `house_a`).
- FALLBACK, so nothing ever goes missing: if `town_<family>_t<t>.glb` is absent (or has no
  `.import` sibling), use the highest t' < t that exists; if none exists, use the `/1` mesh for
  `shape` (`assets/buildings/<shape>.glb`, `mk_house_<shape>.glb`) at the `/1` `off`. So art can
  ship one family and one tier at a time and the town only ever gets better.
- optional `words` (string): a dotted path into `lore_lines.json` `town_buildings`. Defaults:
  landmark -> `landmarks.<family>`; house -> `districts.<district>`; site -> `sites.<landmark>`.
  The node at that path has `tiers[3]` of `{name, crier, plaque, see}`: `name` labels the building
  at tier t, `plaque` is its sign/tooltip, `crier` is spoken ONCE when it steps to tier t
  (never at tier 1 on founding), and `see` is the ART BRIEF for that tier's mesh.
  Content's moment-of-change lines (C-250), when they land, are read beside `crier` on the same node.

### The pivot contract (art, read this one)
All tiers of one family share ONE origin: the footprint centre, on the ground, street side
facing +Z. A tier swap changes the MESH only - never `pos`, `yaw`, `door` or `half`. So:
- a tiered family is authored with `off: [0, 0]` (the /1 `lm_hall` is 1.92 m off-centre; that is
  why art's design ships `town_hall_t1..t3` as a new re-centred family instead of editing it);
- `half` is the footprint of the LARGEST tier; the validator checks overlap against that, so a
  plot can never grow into its neighbour on upgrade;
- the door is where the largest tier's door is. A smaller tier stands back from it, never past it.
This is the well ladder's contract (`town_well_t1..t3.glb`) written down for every building.

### Roads, square, sites
- `roads[]`: optional `family` (default `road`). Tiers come from `town_buildings.roads.tiers`
  and are TOWN-WIDE by default (the whole network steps together, on the clock above); `tier_at`
  on one road overrides it (e.g. the gate-to-square road paves first). A road tier is a MATERIAL
  and kerb change - its `pts` and `width` never change.
- `square`: optional `centrepiece` (default `well`) reads `town_buildings.well_to_fountain.stages[]`,
  which carry their OWN `level` (five stages) - the centrepiece does not use the 3-tier clock.
  Stage i uses `town_well_t<i>.glb` with the same highest-existing fallback.
- `sites[]`: same `family` / `words` / fallback rules as buildings (`sites.<landmark>`).

### What reads it, and what does not yet
Nothing in the game reads `/2` yet: the loader is D93.4 and the tier swap is D31's visual half,
both game build. `tools/_d93_validate.gd` still validates `/1` geometry; a `/2` file passes it
unchanged, because every `/2` field is ignored by `/1` checks. Owed next, in this order: the
validator learns `tier_at` ordering + the largest-tier footprint rule, then the loader.

## Tools

- `tools/_d93_validate.gd` - the validator (D93.5). Pure data, runs in a second:
  `<godot> --headless --path . --script res://tools/_d93_validate.gd`
  Checks OVERLAP, ON_ROAD, ON_SQUARE, DOOR (door within 2 m of a road edge), UNREACHED (every
  door and site joins the square's road network) and PATCH. Prints one `D93_VALIDATE PASS|FAIL`
  line; full list in `renders/cycles/d93/validate.txt`. `JESTS_D93_IN=<file>` checks another
  file, `JESTS_D93_LEVEL=n` checks only what stands at level n.
- `tools/_d93_export.gd` - snapshots the town the GENERATOR builds into this format. It was
  used once (D93a) to measure the generated town. **It overwrites bellmire.json** - once hand
  authoring starts, run it only with `JESTS_D93_OUT` set to another path.

## Status

`bellmire.json` is currently the GENERATOR'S town, exported for measurement - it fails the
validator (see PROGRESS.md D93a). It is the "before" picture, not the authored town. Nothing in
the game reads this file yet; the loader is D93.4.
