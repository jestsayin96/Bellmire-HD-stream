# ART COMMIT OWED - PAID AND CLEAR as of 2026-11-28 10:4x CST.
# This is the ONE file, updated in place (08:58 team-lead housekeeping row).
# The per-run copies _ART_COMMIT_OWED_nov28_0334/0534/0734/0834/0934.md are folded in
# here and removed. The four tracked _ART_COMMIT_OWED_nov25_*.md are left ALONE - they
# are committed history, not scratch, and deleting tracked files was not the row's ask.

## STATUS: NOTHING OWED.

The nine-run outage (03:34 -> 09:34 CT) ended at 10:35 CT. `execute_blender_code`
answered (pid 39916). Tested, not assumed. Cause was never a misconfiguration: Blender
simply was not running on cruzader. `get_device_info` reporting the MCP server
`announced` is NOT health - do not read it as health.

ALL OWED WORK IS PUSHED: `origin/art` 42e8bc08 -> **160c7a34**, 1,292 files
(1,283 new + 9 modified). Staged by name from the manifests, NEVER `-A`.

### WHAT WENT IN
- Town tier ladders + textures + `.import` siblings (320 paths, 03:34 manifest)
- 11 town generators/gates in `tools/art/`, 8 town docs in `docs/art/`,
  town probe/cover/throughlight JSON and the two tier-3 crops
- 1,047 missing load-siblings: 520 `assets/icons/**.png.import`,
  520 `web/icons/**.webp.import`, 7 `assets/monsters/minibosses/*.glb.import`
  (badger, fanner, hammerman, mealman, mower, shearman, thatcher)
- Fit register + contact/hero-scale/silhouette sheets brought current

### WHAT WAS DELIBERATELY LEFT OUT - AND ONE CATCH WORTH KEEPING
- `__pycache__/*.pyc`: **two `.pyc` paths were sitting INSIDE the 03:34 owed manifest**
  (`townbuild.cpython-313.pyc`, `townlib.cpython-313.pyc`). This lane's own staging
  guard asserted on them and refused to build the list until they were filtered. A
  manifest is not automatically clean just because an earlier run wrote it.
- `*.log` scratch; the `renders/art/minibosses` (1,671) and `s7_armour` (545) untracked
  render backlog - not named in any owed file, and dumping it would have been `-A`
  behaviour by another name.
- `docs/WORK_PLAN.md`: 672 uncommitted lines, the team lead's disk-sync into all seven
  trees. NOT this lane's to commit. Still dirty on purpose - leave it.

### STANDING NOTE FOR THE NEXT ART FIRING
`.pyc` files are reachable by `tools/art` walks and have twice now been inside a
manifest. Keep the junk assertion in any staging script; do not widen it to pass.
A `.gitignore` for `__pycache__/` would end this permanently but is a repo-root change
and was not taken on this lane's own motion.
