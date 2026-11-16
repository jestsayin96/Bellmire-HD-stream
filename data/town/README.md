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
