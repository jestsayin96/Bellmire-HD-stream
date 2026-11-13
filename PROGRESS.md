
## C-cycle 19 - the spend shelf, the tier gate, E3PO and the disasters (content, branch `content`, jestai, 2026-11-13) - authored + python-validated
- WHY THIS: the supervisor's streamable-today order - (1) what viewers buy, (2) tier-gated stock for
  D35/D39, (3) E3PO for D37, (4) disaster variants so repeats do not read identically. All four were
  taken in one cycle, two files touched: data/items.json and data/lore_lines.json.
- 1. THE SPEND SHELF, data/items.json:
  - ACCESSORIES 114 -> 130. Sixteen: rings bellfounder/quarryman/pilgrim, amulets ferrybell/votive/
    weighstone, cloaks thatcher/crane/pilgrim, boots towpath/pavers/ferrystep, gloves glazier/
    ropewalk/rivet/beeswax. One bonus each, costs inside the per-slot ranges already set, and a
    flavour that sells the thing rather than the stat - "Doubled at the shoulder, where the rope goes
    when the rope goes wrong", "Three thicknesses at the fingertip. Glass takes the careless hand."
  - COSMETICS 223 -> 253: 10 hats (50-250), 8 banners (90-140), 12 titles (80-300). Same trade spine
    as the accessories, so hat + banner + title + dye + ring buys a whole guild look rather than an
    orphan hat. DYES 137 (+16). dye_cost UNCHANGED at 25.
- 2. THE TIER GATE, data/items.json (feeds D35/D39):
  - shop_stock 99 -> 123 goods: TWO new goods at EVERY tier 1-12, each carrying its "tier" field, so
    a crossing sells thatch and a clay pot and a city sells a pomander and an empty gilt frame.
  - trader_cargo 48 -> 68: two per tier for tiers 3-12 (tiers 1-2 still have no caravans, by design).
  - stock_by_tier.shop_adds / cargo_adds extended in step, and the two representations were checked
    against each other: every added key exists in its catalogue, its `tier` field equals the tier it
    is listed under, nothing appears at two tiers, and nothing in either catalogue is ungated.
- 3. E3PO, data/lore_lines.json (feeds D37): raid 20 -> 28, disaster 20 -> 28, festival 16 -> 22,
  viewer_roll crit/high/low/fumble 9 -> 14 each. Voice unchanged - immortal, a little pompous, never
  cruel to a viewer who rolled badly ("A bad roll is not a bad soldier. Do it again.").
- 4. DISASTER VARIANTS, data/lore_lines.json: all THIRTEEN disasters widened in the same three places -
  during 14 -> 17, begin_alt 6 -> 8, pass_alt 6 -> 8 (91 new lines). Every line is specific to its
  disaster, not reusable filler: the ferryman walking the dry Ford in `drought`, boats in the market
  square in `flood`, chalk washed off the last door in `sickness`. `begin`, `pass` and `cost` are
  UNTOUCHED on every one - `cost` is the desktop's spec and content does not move it mid-build.
- VALIDATION OK (python only, no Godot): both edited files json.load() clean; each was read from
  HEAD, re-parsed after the edit and compared node by node - every pre-existing key present, every
  pre-existing scalar equal, no list shorter than it was, every pre-existing element still at its old
  index, top-level key order identical. Errors: 0. Shape checks: every new accessory matches one of
  the six existing keysets; every new cosmetic matches its kind's keyset; every colour and dye is
  /[0-9a-f]{6}/; every shop_stock and trader_cargo entry is exactly {name,cost,flavour,tier} with an
  int cost and 1 <= tier <= 12; every disaster still carries exactly {begin,during,pass,cost,
  begin_alt,pass_alt} and every new line is a str. Both files stay pure ASCII, LF, 2-space indent,
  trailing newline. bosses.json and potions.json were parsed clean and NOT edited this cycle.
- FORMATTING NOTE, deliberate and harmless: numstat is 177+/27- on items.json and 179+/46- on
  lore_lines.json. Every "removed" line is a former LAST element re-added byte for byte with a
  trailing comma (27 = the last entry of each extended block plus the last element of each extended
  tier array; 46 = the 7 extended e3po arrays plus 3 arrays on each of the 13 disasters). No value
  changed.
- CODE WIRING THIS IMPLIES (for the supervisor's tracker):
  1. D35/D39 CAN NOW FILTER WITHOUT A REVERSE MAP: `good.tier <= town_tier` over shop_stock, and
     `cargo.tier <= town_tier` over trader_cargo, give the same answer as walking stock_by_tier
     cumulatively. Both are maintained together; if they ever disagree, that is a content bug - report
     it, do not patch one side in .gd. OWNER: DESKTOP BUILD.
  2. A tier-1 shelf is now 11 goods and a tier-12 shelf is every good in the file. Any shop panel laid
     out for a fixed count will clip at the top tiers. OWNER: DESKTOP BUILD / DESKTOP HUD.
  3. A tier-1 or tier-2 caravan still has ZERO cargo by design. Code that assumes a caravan always has
     something to carry must handle the empty list, not crash on it. OWNER: DESKTOP BUILD.
  4. D37: the four viewer_roll buckets are now 14 lines each and `raid`/`disaster`/`festival` are
     28/28/22. Size off len(). Nothing was re-keyed.
  5. Disaster pickers that roll begin_alt/pass_alt by a hard-coded 0-5 will now never show the two new
     lines on any disaster. Roll against len(). OWNER: whoever owns D34.
  6. Nothing new needs wiring to FUNCTION: every key added this cycle is one the loaders already read.
- TICKING: WORK_PLAN left UNTICKED for the supervisor (COORDINATION 6+11). Not a WIP commit.
