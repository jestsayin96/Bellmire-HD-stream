"use strict";
// ============================================================================
// Bellmire HD - the viewer hub (W1b). Read-only, no backend, no framework.
//
// SECURITY (docs/HUB_SECURITY.md): every string from the snapshot is viewer-
// controlled and hostile until proven otherwise. It reaches the DOM ONLY through
// createElement + textContent, via the el() helper below. There is no innerHTML,
// insertAdjacentHTML, document.write, eval or new Function anywhere in this file,
// and no snapshot field is ever used as a URL, src or href. The strict CSP is the
// second wall. The <colour> canary in !dye must render its angle brackets.
//
// The look is argued for in web/NOTES.md (not served).
// ============================================================================

const URL_SNAPSHOT = "https://paaukwaffaamazgrndbv.supabase.co/rest/v1/snapshot?select=payload,updated_at";
const KEY = "sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc";
const REFRESH_MS = 60000;      // the game publishes every 60 s
const STALE_MIN = 5;           // past this, the town has gone quiet (the game is likely off)
const TIMEOUT_MS = 12000;      // a fetch that hangs is a failed fetch
const HERO_PAGE = 60;          // heroes drawn at once (a busy night has 200+)

const params = new URLSearchParams(location.search);
const TEST = params.get("state");   // empty | fail | stale (local checks)
const MOCK = params.get("mock");    // chronicle | crowd | roll | bands | fallen (local checks)
const OVERLAY = params.has("overlay");  // ?overlay=1 : the thin on-stream (OBS) column
// overlay mode: a narrow, dark, glanceable column over the stream. Same data, same
// security - a body class the stylesheet reshapes; no separate code path for snapshot data.
if (OVERLAY) document.documentElement.classList.add("overlay");

const $ = (id) => document.getElementById(id);
let last = null;               // {payload, updated_at} of the last good read
let lastError = "";
let heroFilter = "";
let heroShown = HERO_PAGE;

// ---------------------------------------------------------------- safe helpers
// el(): text goes in as text, always. This is the only path snapshot data takes
// to the DOM in the whole file.
function el(tag, cls, text) {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text != null) n.textContent = String(text);
  return n;
}
function frag(parent, ...kids) { for (const k of kids) if (k) parent.append(k); return parent; }

// icon(): an <svg><use> pointing at one of the page's own <symbol> glyphs. The id
// is ALWAYS a fixed, whitelisted string from this file - a snapshot value only
// ever chooses WHICH known icon, it is never written into the DOM. No <img>, no
// external request. (docs/HUB_SECURITY.md: nothing from the snapshot becomes markup.)
const SVGNS = "http://www.w3.org/2000/svg";
const XLINK = "http://www.w3.org/1999/xlink";
const ICON_SET = new Set([
  "blade", "ranged", "arcane", "blunt", "shield", "potion", "flask", "coin",
  "fight", "death", "raid", "town", "lore", "loot", "delve", "other",
  "flame",   // H10: a burning delver's status glyph. "death" already serves the fallen.
  "hut", "well", "stall", "chapel", "anvil", "tower", "ford", "wall",   // H18: the town's buildings
]);
function icon(id, cls) {
  const key = ICON_SET.has(id) ? id : "other";      // whitelist: unknown -> a safe default
  const svg = document.createElementNS(SVGNS, "svg");
  svg.setAttribute("class", "ic" + (cls ? " " + cls : ""));
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("focusable", "false");
  const use = document.createElementNS(SVGNS, "use");
  use.setAttribute("href", "#ic-" + key);           // fixed literal; never snapshot data
  use.setAttributeNS(XLINK, "xlink:href", "#ic-" + key);
  svg.append(use);
  return svg;
}
// a weapon's name chooses a category icon by keyword; anything unknown is a blade
function weaponIcon(name) {
  const w = String(name || "").toLowerCase();
  if (/bow|crossbow|sling|arbalest/.test(w)) return "ranged";
  if (/staff|wand|rod|scepter|sceptre|focus|tome|grimoire/.test(w)) return "arcane";
  if (/mace|hammer|club|maul|flail|axe|warhammer|quarterstaff|wrap|fist|bare hands|knuckle/.test(w)) return "blunt";
  return "blade";   // sword, dagger, spear, blade, greatsword, rapier, ...
}
// a class crest: the calling's signature icon. Unknown callings fall back to a blade.
function classIcon(cls) {
  const c = String(cls || "").toLowerCase();
  if (/mage|sage|necromancer|warlock|druid|sorcer|wizard|cleric|priest/.test(c)) return "arcane";
  if (/ranger|hunter|archer|scout/.test(c)) return "ranged";
  if (/barbarian|monk|brawler|fighter/.test(c)) return "blunt";
  if (/knight|paladin|warden|guard|defender/.test(c)) return "shield";
  return "blade";   // rogue, duelist, bard, and the rest carry a blade
}

// esc() is kept for the two legacy innerHTML sites that remain (status line and
// the "nothing yet" messages) - both build from the page's OWN strings, never
// from the snapshot. New code does not use it.
function esc(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
const cap = (s) => String(s ?? "").replace(/\b\w/g, (c) => c.toUpperCase());
const num = (n) => Number.isFinite(+n) ? (+n).toLocaleString("en") : "-";
const n0 = (v) => { const x = +v; return Number.isFinite(x) ? x : 0; };
const modOf = (v) => { const m = Math.floor((+v - 10) / 2); return (m >= 0 ? "+" : "") + m; };
const arr = (a) => Array.isArray(a) ? a : [];
const nameOf = (r) => String(r && r.name != null ? r.name : "");
// the first argument that is a present, finite number (else null). Lets a forward-
// compatible field render only when the publisher actually sends it - never a zero
// stood in for "absent", and never an invented value (web/NOTES.md honesty rule).
const pickNum = (...vals) => { for (const v of vals) if (v != null && v !== "" && Number.isFinite(+v)) return +v; return null; };

function ago(iso) {
  const t = Date.parse(iso);
  if (!Number.isFinite(t)) return null;
  const s = Math.max(0, Math.round((Date.now() - t) / 1000));
  if (s < 45) return { s, text: "just now" };
  const m = Math.round(s / 60);
  if (m < 60) return { s, text: m === 1 ? "a minute ago" : m + " minutes ago" };
  const h = Math.round(m / 60);
  if (h < 36) return { s, text: h === 1 ? "an hour ago" : h + " hours ago" };
  const d = Math.round(h / 24);
  return { s, text: d === 1 ? "a day ago" : d + " days ago" };
}
function when(iso) {
  const t = new Date(iso);
  return isNaN(t) ? "" : t.toLocaleString(undefined, { weekday: "short", hour: "2-digit", minute: "2-digit", day: "numeric", month: "short" });
}
// a hero's sigil: the first two letters of their own name, upper-cased. No image
// (the payload has none, and building an <img> from snapshot data is forbidden).
function initials(name) {
  const letters = String(name || "").replace(/[^A-Za-z0-9]/g, "");
  return (letters.slice(0, 2) || "?").toUpperCase();
}

// ---------------------------------------------------------------- crests (H15)
// A coat of arms for every hero, drawn as inline SVG the PAGE owns. The hero's name
// is hashed and the hash only picks INDICES into the fixed whitelists below (a field
// division, two tinctures, one charge). No snapshot value is ever written into the
// SVG: every path string and colour here is a constant in this file, so a hostile
// name still yields a valid crest and can never become markup, a URL or a style.
// Deterministic: the same name always gives the same arms, on every reload.
const CREST_SHIELD = "M6 6H94V58C94 92 70 110 50 116C30 110 6 92 6 58Z";
const CREST_TINCT = ["#2a1c10", "#f3e6c4", "#1d8f8a", "#c6922f"];   // ink, parchment, teal, gold
const CREST_DIV = [                                                 // paths for the second tincture
  null,                                                             // plain field
  "M50 0H100V120H50Z",                                              // per pale
  "M0 60H100V120H0Z",                                               // per fess
  "M0 0L100 120H0Z",                                                // per bend
  "M50 0H100V60H50Z M0 60H50V120H0Z",                               // quarterly
  "M0 78L50 42L100 78V120H0Z",                                      // chevron
  "M0 86H100V120H0Z",                                               // base
];
const CREST_CHARGE = (() => {
  let star = "";
  for (let i = 0; i < 10; i++) {
    const r = i % 2 ? 9 : 22, a = -Math.PI / 2 + i * Math.PI / 5;
    star += (i ? "L" : "M") + (50 + r * Math.cos(a)).toFixed(1) + " " + (56 + r * Math.sin(a)).toFixed(1);
  }
  return [
    star + "Z",                                                                    // mullet
    "M43 34H57V49H72V63H57V80H43V63H28V49H43Z",                                    // cross
    "M60 34A24 24 0 1 0 60 82A18 18 0 1 1 60 34Z",                                 // crescent
    "M50 33L69 58L50 83L31 58Z",                                                   // lozenge
    "M47 32H53V68H47Z M37 68H63V74H37Z M47 74H53V86H47Z",                          // sword
    "M33 84V50H38V43H43V50H47V43H53V50H57V43H62V50H67V84Z",                        // tower
    "M30 58a20 20 0 1 0 40 0a20 20 0 1 0 -40 0Z M40 58a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z",  // annulet
    "M40 44a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z M30 66a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z M50 66a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z", // trefoil
  ];
})();
const crestMemo = new Map();
function crestRecipe(name) {
  const key = String(name == null ? "" : name).toLowerCase();
  let r = crestMemo.get(key);
  if (r) return r;
  let a = 2166136261;                                  // FNV-1a over the name, then a seeded mixer
  for (let i = 0; i < key.length; i++) { a ^= key.charCodeAt(i); a = Math.imul(a, 16777619) >>> 0; }
  const next = () => {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), a | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return (t ^ (t >>> 14)) >>> 0;
  };
  const div = next() % CREST_DIV.length;
  const ta = next() % CREST_TINCT.length;
  const tb = (ta + 1 + (next() % (CREST_TINCT.length - 1))) % CREST_TINCT.length;
  const spare = [];
  for (let i = 0; i < CREST_TINCT.length; i++) if (i !== ta && (div === 0 || i !== tb)) spare.push(i);
  const tc = spare[next() % spare.length];
  const ch = next() % CREST_CHARGE.length;
  r = { div, ta, tb, tc, ch };
  if (crestMemo.size > 600) crestMemo.clear();
  crestMemo.set(key, r);
  return r;
}
function crestDefs() {                                  // the shared shield clip, added once
  if (document.getElementById("coa-clip")) return;
  const svg = document.createElementNS(SVGNS, "svg");
  svg.setAttribute("class", "coa-defs"); svg.setAttribute("width", "0"); svg.setAttribute("height", "0");
  svg.setAttribute("aria-hidden", "true"); svg.setAttribute("focusable", "false");
  const clip = document.createElementNS(SVGNS, "clipPath");
  clip.setAttribute("id", "coa-clip");
  const p = document.createElementNS(SVGNS, "path");
  p.setAttribute("d", CREST_SHIELD);
  clip.append(p); svg.append(clip); document.body.append(svg);
}
function crestPath(d, fill, stroke) {
  const p = document.createElementNS(SVGNS, "path");
  p.setAttribute("d", d); p.setAttribute("fill", fill);
  if (stroke) { p.setAttribute("stroke", stroke); p.setAttribute("stroke-width", "2.5"); p.setAttribute("stroke-linejoin", "round"); }
  return p;
}
// coat(name, size): size is a page class suffix ("sm" | "md" | "lg"), never snapshot data.
function coat(name, size) {
  crestDefs();
  const r = crestRecipe(name);
  const svg = document.createElementNS(SVGNS, "svg");
  svg.setAttribute("class", "coa coa-" + (size === "sm" || size === "lg" ? size : "md"));
  svg.setAttribute("viewBox", "0 0 100 120");
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("focusable", "false");
  const g = document.createElementNS(SVGNS, "g");
  g.setAttribute("clip-path", "url(#coa-clip)");
  g.append(crestPath("M0 0H100V120H0Z", CREST_TINCT[r.ta]));
  if (CREST_DIV[r.div]) g.append(crestPath(CREST_DIV[r.div], CREST_TINCT[r.tb]));
  g.append(crestPath(CREST_CHARGE[r.ch], CREST_TINCT[r.tc], CREST_TINCT[0]));
  svg.append(g, crestPath(CREST_SHIELD, "none", CREST_TINCT[3]));
  return svg;
}

// ---------------------------------------------------------------- status line
function showStatus() {
  const st = $("status");
  st.className = "status";
  let html;
  if (last) {
    const a = ago(last.updated_at);
    const age = a ? a.text : "at an unknown time";
    const stale = TEST === "stale" || !a || a.s > STALE_MIN * 60;
    if (stale) {
      st.classList.add("stale");
      html = `<span><b>Last word from the town ${esc(age)}</b> (${esc(when(last.updated_at))}). The game is probably not running right now, so this may be out of date.</span>`;
    } else {
      st.classList.add("live");
      html = `<span><b>Updated ${esc(age)}</b> &middot; live while the stream's game runs</span>`;
    }
    if (lastError) {
      st.classList.add("bad");
      html = `<span><b>Couldn't reach the town just now</b> (${esc(lastError)}). Showing what it said ${esc(age)}.</span><button type="button" id="retry">Try again</button>`;
    }
  } else if (lastError) {
    st.classList.add("bad");
    html = `<span><b>Couldn't reach the town's records</b> (${esc(lastError)}). The page will try again in a minute.</span><button type="button" id="retry">Try again</button>`;
  } else {
    st.classList.add("stale");
    html = `<span><b>Bellmire has not reported in yet.</b> The page will check again every minute.</span>`;
  }
  st.innerHTML = html;    // page-owned strings only; never snapshot data
  const r = $("retry");
  if (r) r.onclick = () => { r.disabled = true; r.textContent = "Asking…"; load(); };
}

// ---------------------------------------------------------------- the fetch
async function load() {
  try {
    if (TEST === "fail") throw new Error("test: no answer");
    const ctl = new AbortController();
    const timer = setTimeout(() => ctl.abort(), TIMEOUT_MS);
    let res;
    try {
      res = await fetch(URL_SNAPSHOT, { headers: { apikey: KEY, Authorization: "Bearer " + KEY }, cache: "no-store", signal: ctl.signal });
    } finally { clearTimeout(timer); }
    if (!res.ok) throw new Error("the records answered " + res.status);
    let rows = await res.json();
    if (TEST === "empty") rows = [];
    const row = arr(rows)[0];
    lastError = "";
    const payload = row && row.payload && typeof row.payload === "object" ? row.payload : null;
    if (payload) {
      last = row;
      render(MOCK ? withMock(payload) : payload);
    } else if (MOCK) {
      // local check only: the town has not reported, but a ?mock= was asked for.
      // Render the mock over an empty town so the checks run without live data.
      render(withMock({}));
    } else {
      last = null;
      renderNothing();
    }
  } catch (e) {
    lastError = e && e.name === "AbortError" ? "no answer in " + TIMEOUT_MS / 1000 + " s" :
      (e && e.message && !/fetch|network/i.test(e.message) ? e.message : "you may be offline, or the records are down");
    if (!last) renderNothing(true);
  }
  showStatus();
}

const SECTIONS = ["boards", "state", "dice", "heroes", "bands", "chronicle", "lore", "bestiary", "roll", "fallen"];

function renderNothing(failed) {
  const box = $("nothing");
  box.classList.remove("hide");
  box.innerHTML = failed       // page-owned strings only
    ? `<h2>The town's records are out of reach</h2><p>Nothing could be read just now. Check your connection; the page tries again every minute on its own.</p>`
    : `<h2>Bellmire has not reported in yet</h2><p>The town sends its news here while the stream's game is running. Once it does, the boards, every hero's sheet, the Guild Roll and the Fallen appear on this page.</p>`;
  for (const id of SECTIONS) if (id !== "dice") $(id).classList.add("hide");   // the die always works
  $("town").replaceChildren();
  $("nHeroes").textContent = "";
  $("nFallen").textContent = "";
  { const nb = $("nBands"); if (nb) nb.textContent = ""; }
  renderCommands(null);
  renderRolls(null);
}

// ---------------------------------------------------------------- the page
// Payload version gate. v1 is today's shape; v2 adds p.parties (the H10/D46 "bands
// below" contract); v3 adds the per-hero Satchel sell fields (the H11 contract). All
// are accepted so the hub keeps working the moment the publisher bumps the version;
// every new field is read DEFENSIVELY either way (absent -> honest empty state), so
// pre-accepting a version shows nothing until that field actually arrives. Anything
// OUTSIDE this set is an honest "this page needs an update", never a guess. ACTION for
// the desktop: publish the Satchel sell fields as v = "3" (or extend this set BEFORE
// shipping a different number). See docs/HUB_SECURITY.md (H11).
const KNOWN_V = new Set(["1", "2", "3", "4"]);   // v4 (H23): initiative, speed, gear by slot, status, per-hero last_seen + events
function render(p) {
  if (p && p.v != null && !KNOWN_V.has(String(p.v))) {
    showProblem("Bellmire is speaking a newer dialect than this page understands (format " +
                String(p.v).slice(0, 8) + "). The page needs an update.");
    return;
  }
  $("nothing").classList.add("hide");
  for (const id of SECTIONS) $(id).classList.remove("hide");
  const t = p.town || {};
  $("townName").textContent = t.name ? String(t.name) : "the Guild Hall";
  renderTown(t);
  renderBoards(arr(p.heroes), arr(p.fallen));
  renderHeroes(arr(p.heroes));
  renderBands(p.parties != null ? p.parties : p.bands);
  renderChronicle(p.chronicle, { auto: true });
  try { renderState(t, p); } catch (e) { /* the new tab must never break the rest of the page */ }
  renderRoll(arr(p.guild_roll));
  renderFallen(arr(p.fallen));
  renderCommands(p.commands);
  renderRolls(p.rolls);
  renderLore();
  try { renderBestiary(p); } catch (e) { /* the Bestiary must never break the rest of the page */ }
}

// The town-status strip (H4): the day, the population, the treasury and - the day
// the publisher sends one - the raids turned back, plus a real growth-to-next-level
// bar. Every value is a published number rendered as textContent through el(); the
// bar fill is a CSSOM number, never snapshot text. Nothing is invented: a field that
// the town block does not carry simply does not appear.
function renderTown(t) {
  const box = $("town");
  box.replaceChildren();
  const pill = (k, v) => { const li = el("li"); li.append(el("span", "tk", k), el("span", "tv", v)); box.append(li); };
  if (t.level != null) pill("Town level", t.level);
  if (t.souls != null) pill("Souls", num(t.souls));
  if (t.day != null) pill("Day", t.day);
  if (t.treasury != null) pill("Treasury", num(t.treasury) + " g");
  if (t.renown) pill("Renown", num(t.renown));
  // Raids: forward-compatible. The town block in scripts/snapshot_pub.gd carries no
  // raids count today, so this shows ONLY if the publisher adds one - never a made-up
  // number. A clearly-named "turned back / repelled / held / won" field reads as a
  // defence tally; a bare "raids" reads as an occurrence count. (web/NOTES.md contract.)
  const repelled = pickNum(t.raids_turned, t.raids_repelled, t.raids_held, t.raids_won);
  if (repelled != null) pill("Raids turned back", num(repelled));
  else { const raids = pickNum(t.raids); if (raids != null) pill("Raids", num(raids)); }
  // Growth to the next town level: both score and next_level_at are published, so this
  // is a true progress bar, not an invented denominator. Shown only when a real target
  // exists; otherwise the strip is just the facts above.
  const g = growthBar(t);
  if (g) box.append(g);
}

// a growth-to-next-level bar for the town strip, on the dark ground. Honest: it draws
// only when the publisher gives a positive next_level_at, and the fill is score/target
// as a CSSOM number (never snapshot text), the same safe pattern as the hero HP/XP bars.
function growthBar(t) {
  if (t.score == null || !(+t.next_level_at > 0)) return null;
  const score = n0(t.score), next = n0(t.next_level_at);
  const ratio = Math.max(0.02, Math.min(1, score / next));
  const li = el("li", "grow");
  li.setAttribute("role", "img");
  const toLevel = t.level != null ? "to town level " + (n0(t.level) + 1) : "to the next town level";
  li.setAttribute("aria-label", "Growth " + score + " of " + next + " " + toLevel);
  const track = el("div", "growtrack");
  const fill = el("span", "growfill");
  fill.style.setProperty("--grow", ratio);   // CSSOM number only
  track.append(fill);
  li.append(el("span", "tk", "Growth"), track, el("span", "tv growv", num(score) + " / " + num(next)));
  return li;
}

// ============================================================ THE STATE OF BELLMIRE (H18)
// The place, not just its people: a ladder of the town's growth, the live numbers as
// tiles, a roster of what stands, and a timeline of what has befallen it. Every string
// - a town name, a building name, a remembered chronicle line - reaches the DOM only
// through el() (createElement + textContent). Icons come from ICON_SET; a snapshot
// value only ever chooses WHICH known icon. The only snapshot number that styles
// anything is the growth fraction, set through the CSSOM as a number. No fetch, no URL.
// The ladder and the canon roster read the frozen lore (H12) as-is: no parallel words.
const CANON_BUILDINGS = [               // page-owned: [label, match key, icon, town level it arrives at, lore tier index]
  ["The Huts", "hut", "hut", 1, 0], ["The Well", "well", "well", 2, 1], ["The Guild Post", "guild", "town", 3, 2],
  ["Market Square", "market", "stall", 5, 4], ["The Chapel", "chapel", "chapel", 6, 5], ["Craft Row", "craft", "anvil", 7, 6],
  ["The Garrison", "garrison", "tower", 8, 7], ["The Ford", "ford", "ford", 9, 8], ["The First Wall", "wall", "wall", 10, 9],
  ["Corner Towers", "tower", "tower", 11, 10],
];
const BUILDING_ICON_KEYS = [["well", "well"], ["hut", "hut"], ["home", "hut"], ["house", "hut"], ["market", "stall"], ["stall", "stall"],
  ["chapel", "chapel"], ["temple", "chapel"], ["forge", "anvil"], ["smith", "anvil"], ["craft", "anvil"], ["garrison", "tower"],
  ["barrack", "tower"], ["tower", "tower"], ["wall", "wall"], ["gate", "wall"], ["ford", "ford"], ["bridge", "ford"], ["guild", "town"]];
function buildingIcon(name) {           // keyword -> a whitelisted id; never a snapshot value used as one
  const n = String(name || "").toLowerCase();
  for (const [k, id] of BUILDING_ICON_KEYS) if (n.indexOf(k) >= 0) return id;
  return "town";
}
const TOWN_SCALE = /disaster|\bfire\b|burn|drought|famine|sickness|plague|hurricane|tornado|earthquake|meteor|scarstorm|flood|blight|volcano|cold ?snap|festival|\bfair\b|harvest|siege|bandit|camp|grows into|falls back|stands as|raid/i;
function townStamp(ts) {
  const d0 = new Date(); d0.setHours(0, 0, 0, 0);
  const d = new Date(ts), dd = new Date(ts); dd.setHours(0, 0, 0, 0);
  const n = Math.round((d0 - dd) / 86400000);
  let tm = ""; try { tm = d.toLocaleTimeString("en", { hour: "2-digit", minute: "2-digit" }); } catch (e) { tm = ""; }
  return (n <= 0 ? "Today" : n === 1 ? "Yesterday" : n + " days gone") + (tm ? " \u00b7 " + tm : "");
}
function stTile(k, v) {
  const d = el("div", "st-tile");
  d.append(el("span", "st-k", k), el("span", "st-v", v));
  return d;
}
function renderState(t, p) {
  t = t && typeof t === "object" ? t : {};
  const lore = LORE_FROZEN && LORE_FROZEN.growth_tiers;
  const tiers = arr(lore && lore.tiers).filter((x) => x && typeof x === "object" && x.name);
  const N = tiers.length;
  const lvl = t.level != null && t.level !== "" && Number.isFinite(+t.level) && N ? Math.max(1, Math.min(N, Math.floor(+t.level))) : 0;
  // ---- H18.1 the ladder
  const ladder = $("stLadder"), cap = $("stLadderCap");
  ladder.replaceChildren();
  if (!N) { ladder.append(el("li", "empty", "The town has not yet named its stages.")); cap.textContent = ""; }
  else {
    tiers.forEach((tr, i) => {
      const st = !lvl ? "ahead" : i + 1 < lvl ? "done" : i + 1 === lvl ? "now" : "ahead";
      const li = el("li", "rung " + st);
      if (st === "now") li.setAttribute("aria-current", "step");
      const body = el("div", "rg-body");
      body.append(el("span", "rg-name", String(tr.name)));
      if (st === "now" && tr.see) body.append(el("span", "rg-see", String(tr.see)));
      li.append(el("span", "rg-dot", String(i + 1)), body,
        el("span", "st-sr", st === "done" ? " (reached)" : st === "now" ? " (the town is here)" : " (still ahead)"));
      ladder.append(li);
    });
    const left = N - lvl;
    cap.textContent = !lvl ? "Bellmire has not yet said how far it has come."
      : left > 0 ? String(tiers[lvl - 1].name) + " - " + left + (left === 1 ? " stage" : " stages") + " still to climb."
      : "Bellmire has climbed every rung.";
  }
  // ---- the live numbers, as tiles
  const tiles = $("stTiles"); tiles.replaceChildren();
  if (lvl) tiles.append(stTile("Town level", lvl + " of " + N));
  if (t.day != null && t.day !== "") tiles.append(stTile("Day", num(t.day)));
  if (t.souls != null && t.souls !== "") tiles.append(stTile("Souls", num(t.souls)));
  if (t.treasury != null && t.treasury !== "") tiles.append(stTile("Treasury", num(t.treasury) + " g"));
  const repelled = pickNum(t.raids_turned, t.raids_repelled, t.raids_held, t.raids_won);
  if (repelled != null) tiles.append(stTile("Raids turned back", num(repelled)));
  else { const raids = pickNum(t.raids); if (raids != null) tiles.append(stTile("Raids", num(raids))); }
  if (t.renown) tiles.append(stTile("Renown", num(t.renown)));
  if (!tiles.childElementCount) tiles.append(el("p", "empty", "The town has not sent its numbers yet."));
  const grow = $("stGrow"); grow.replaceChildren();
  if (t.score != null && +t.next_level_at > 0) {
    const score = n0(t.score), next = n0(t.next_level_at);
    const wrap = el("div", "st-grow");
    wrap.setAttribute("role", "img");
    wrap.setAttribute("aria-label", "Growth " + score + " of " + next + " toward the next stage");
    const track = el("div", "st-track"), fill = el("span", "st-fill");
    fill.style.setProperty("--grow", Math.max(0.02, Math.min(1, score / next)));   // CSSOM number only
    track.append(fill);
    wrap.append(el("span", "st-k", "Growth to the next stage"), track, el("span", "st-gv", num(score) + " / " + num(next)));
    grow.append(wrap);
  }
  // ---- H18.2 what stands
  const roster = $("stRoster"), rtag = $("stRosterTag"); roster.replaceChildren();
  const live = [];
  for (const b of arr(t.buildings != null ? t.buildings : p && p.buildings)) {
    const o = typeof b === "string" ? { name: b } : b && typeof b === "object" ? b : null;
    const name = o ? cleanName(o.name).trim().slice(0, 60) : "";
    if (!name) continue;
    const does = ctrlStrip(o.does != null ? o.does : o.desc != null ? o.desc : o.what != null ? o.what : "").slice(0, 140);
    live.push({ name, built: o.built !== false, does });
  }
  const bld = (name, ic, built, line, tag) => {
    const li = el("li", "bld " + (built ? "built" : "unbuilt"));
    li.append(icon(ic, "bld-ic"));
    const b = el("div", "bld-body");
    b.append(el("span", "bld-name", name));
    if (line) b.append(el("span", "bld-line", line));
    b.append(el("span", "bld-tag", tag));
    li.append(b);
    return li;
  };
  if (live.length) {
    rtag.textContent = "as the town reports it";
    const have = live.map((b) => b.name.toLowerCase());
    for (const b of live) roster.append(bld(b.name, buildingIcon(b.name), b.built, b.does, b.built ? "standing" : "not yet raised"));
    for (const c of CANON_BUILDINGS) {
      if (have.some((n) => n.indexOf(c[1]) >= 0)) continue;
      const tr = tiers[c[4]];
      roster.append(bld(c[0], c[2], false, tr && tr.see ? String(tr.see) : "", "not yet raised"));
    }
  } else {
    rtag.textContent = "canon, not live - read from the town's level";
    for (const c of CANON_BUILDINGS) {
      const tr = tiers[c[4]], built = lvl >= c[3] && lvl > 0;
      roster.append(bld(c[0], c[2], built, tr && tr.see ? String(tr.see) : "", built ? "standing" : "not yet raised"));
    }
  }
  // ---- H18.3 what has befallen it: the browser's own Chronicle history, town-scale only
  const tl = $("stTime"), ttag = $("stTimeTag"); tl.replaceChildren();
  chronMemEnsure();
  const rows = arr(chronMem).filter((r) => r && typeof r.s === "string" && (r.t === "raid" || (r.t === "town" && TOWN_SCALE.test(r.s) && !/^Day \d+ begins/i.test(r.s))))
    .sort((x, y) => histTs(y) - histTs(x)).slice(0, 14);
  ttag.textContent = "kept by this browser";
  if (!rows.length) tl.append(el("li", "empty", "Bellmire has known only quiet days."));
  for (const r of rows) {
    const li = el("li", "tm " + (r.t === "raid" ? "raid" : "town"));
    li.append(icon(/fire|burn|volcano|meteor/i.test(r.s) ? "flame" : r.t === "raid" ? "raid" : "town", "tm-ic"));
    const b = el("div", "tm-body");
    b.append(el("span", "tm-when", townStamp(histTs(r))), el("span", "tm-text", r.s));
    li.append(b);
    tl.append(li);
  }
}

// ============================================================ THE BOARDS
// Research (web/NOTES.md): top-3 emphasis is real, but a bare global top-10 is
// hostile to everyone outside it - so the leader is featured, the top three wear
// gold/silver/bronze sigils, value bars show the spread, and a name lookup pins
// any hero's real row and rank underneath (the neighbourhood view, as far as a
// page with no login can reach). Five boards: the research caps it there.
const BOARDS = [
  { key: "gold",     tab: "Gold",      title: "Most gold",        unit: "gold",     dead: false, second: "level",   secondLabel: "level" },
  { key: "deepest",  tab: "Deepest",   title: "Deepest floor",    unit: "floor",    dead: true,  second: "kills",   secondLabel: "kills" },
  { key: "kills",    tab: "Deadliest", title: "Deadliest",        unit: "kills",    dead: true,  second: "deepest", secondLabel: "floor" },
  { key: "delves",   tab: "Delves",    title: "Most delves",      unit: "delves",   dead: false, second: "deepest", secondLabel: "floor" },
  { key: "standing", tab: "Standing",  title: "Highest standing", unit: "standing", dead: false, second: "kills",   secondLabel: "kills" },
];
const BOARD_TOP = 10;
let boardKey = "gold";
let boardFind = "";

function boardRanked(spec, heroes, fallen) {
  const living = heroes.map((h) => ({ r: h, dead: false }));
  const gone = spec.dead ? fallen.map((f) => ({ r: f, dead: true })) : [];
  const rows = living.concat(gone).filter((e) => e.r && typeof e.r === "object");
  rows.sort((a, b) =>
    n0(b.r[spec.key]) - n0(a.r[spec.key]) ||
    n0(b.r[spec.second]) - n0(a.r[spec.second]) ||
    nameOf(a.r).localeCompare(nameOf(b.r), "en", { sensitivity: "base" }));
  // assign shared places (1,2,2,2,5) over everyone with a positive value
  const ranked = rows.filter((e) => n0(e.r[spec.key]) > 0);
  let place = 0, prev = null;
  ranked.forEach((e, i) => {
    const v = n0(e.r[spec.key]);
    if (v !== prev) { place = i + 1; prev = v; }
    e.place = place;
  });
  return ranked;
}

function subline(spec, r) {
  const bits = [];
  const cls = r.class ? cap(r.class) : "";
  if (r.level != null) bits.push((cls ? cls + ", " : "") + "level " + r.level);
  else if (cls) bits.push(cls);
  if (r[spec.second] != null && spec.secondLabel !== "level" && spec.second !== spec.key)
    bits.push(num(r[spec.second]) + " " + spec.secondLabel);
  return bits.join("  ·  ");
}

// a hero's tier from their rank on the board. SSS/SS/S descending, the gacha/
// fighting-game convention; the LETTERS carry the meaning so it stays colourblind
// -safe, colour only reinforces it (web/NOTES.md). Tier is a flourish on top of
// the exact rank, which is still shown.
function tierOf(place) {
  if (place <= 1) return { label: "SSS", cls: "sss" };
  if (place <= 3) return { label: "SS", cls: "ss" };
  if (place <= 6) return { label: "S", cls: "s" };
  if (place <= 10) return { label: "A", cls: "a" };
  return { label: "B", cls: "b" };
}

// one board row. featured=true is the leader's bigger treatment.
function boardRow(spec, e, max, opts) {
  opts = opts || {};
  const t = tierOf(e.place);
  const li = el("li", "brow t-" + t.cls + (e.dead ? " gone" : "") + (opts.featured ? " lead" : "") + (opts.self ? " self" : ""));
  li.style.setProperty("--fill", max > 0 ? (n0(e.r[spec.key]) / max) : 0);

  const rank = el("span", "brank");
  const med = el("span", "tier", t.label);
  med.setAttribute("aria-label", "Tier " + t.label + ", rank " + e.place);
  rank.append(med, el("span", "rnum2", "#" + e.place));
  li.append(rank);

  const mid = el("span", "bmid");
  const line = el("span", "bname");
  if (e.place <= 5) line.append(coat(nameOf(e.r), "sm"));
  line.append(document.createTextNode(nameOf(e.r) || "(no name)"));
  if (e.dead) frag(line, el("span", "tag", "fallen"));
  mid.append(line, el("span", "bsub", subline(spec, e.r)));
  li.append(mid);

  const val = el("span", "bval");
  val.append(el("b", null, num(e.r[spec.key])), el("span", "bunit", spec.unit));
  li.append(val);
  return li;
}

function renderBoards(heroes, fallen) {
  const spec = BOARDS.find((b) => b.key === boardKey) || BOARDS[0];

  const tabs = $("boardTabs");
  tabs.replaceChildren();
  for (const b of BOARDS) {
    const on = b.key === spec.key;
    const t = el("button", "chip" + (on ? " on" : ""), b.tab);
    t.type = "button";
    t.setAttribute("role", "tab");
    t.setAttribute("aria-selected", on ? "true" : "false");
    t.addEventListener("click", () => { boardKey = b.key; renderBoards(heroes, fallen); $("boards").scrollIntoView({ block: "nearest" }); });
    tabs.append(t);
  }

  const ranked = boardRanked(spec, heroes, fallen);
  const topBox = $("boardTop");
  const listBox = $("boardList");
  const selfBox = $("boardSelf");
  const note = $("boardNote");
  topBox.replaceChildren();
  listBox.replaceChildren();
  selfBox.replaceChildren();
  $("boardCount").textContent = "";

  if (!ranked.length) {
    listBox.append(el("li", "empty", heroes.length
      ? "Nobody has earned a place on this board yet."
      : "No heroes yet. Type !enlist in chat to raise one."));
    note.textContent = "";
    return;
  }

  const max = n0(ranked[0].r[spec.key]);
  const top = ranked.slice(0, BOARD_TOP);
  // the leader is featured above the rule; the rest form the list
  topBox.append(boardRow(spec, top[0], max, { featured: true }));
  for (const e of top.slice(1)) listBox.append(boardRow(spec, e, max, {}));

  // find-your-hero: pin the matched hero's real row + rank beneath the top ten
  const q = boardFind.trim().toLowerCase();
  if (q) {
    const hit = ranked.find((e) => nameOf(e.r).toLowerCase().includes(q));
    if (hit && hit.place > BOARD_TOP) {
      selfBox.append(el("p", "selfnote", "Further down the board:"));
      selfBox.append(boardRow(spec, hit, max, { self: true }));
    } else if (hit) {
      selfBox.append(el("p", "selfnote", nameOf(hit.r) + " is in the top ten, at number " + hit.place + "."));
    } else {
      selfBox.append(el("p", "selfnote", "No hero by that name holds a place on this board."));
    }
  }

  const counted = spec.dead ? "the living and the fallen" : "living heroes";
  $("boardCount").textContent = ranked.length + " ranked";
  note.textContent = ranked.length > BOARD_TOP
    ? spec.title + ": the top ten of " + ranked.length + ", counting " + counted + ". Bars show each hero against the leader."
    : spec.title + ", counting " + counted + ".";
}

// ============================================================ HEROES (unchanged look, safe render)
// ============================================================ MY HERO (H11)
// A viewer with no login can mark ONE hero as theirs so it is easy to find each
// visit - the hub stand-in for the on-stream Satchel (L51) that always kept a viewer's
// own hero in view, which D48/L63 took OFF the stream. Only the hero NAME is remembered,
// in THIS browser, as a per-viewer convenience: it is never a secret, never sent
// anywhere, never used to choose any page behaviour beyond matching a hero by name.
// Like every snapshot string it reaches the DOM ONLY through el()/textContent, and it
// is only ever string-COMPARED against hero names - never built into a selector, URL,
// src, href or style. Storage throws in private windows, so every access is wrapped;
// the page works with or without it. (docs/HUB_SECURITY.md, H11.)
const MY_HERO_KEY = "bellmire.myhero";
const cleanName = (s) => String(s == null ? "" : s).replace(/[\u0000-\u001f\u007f]/g, "").slice(0, 25);
function getMyHero() { try { return cleanName(localStorage.getItem(MY_HERO_KEY) || ""); } catch (e) { return ""; } }
function storeMyHero(name) {
  const n = cleanName(name);
  try { if (n) localStorage.setItem(MY_HERO_KEY, n); else localStorage.removeItem(MY_HERO_KEY); } catch (e) {}
}
function setMyHero(name) {                       // store + repaint the heroes section
  storeMyHero(name);
  if (last) renderHeroes(arr((MOCK ? withMock(last.payload) : last.payload).heroes));
}
function isMyHero(h) { const m = getMyHero().toLowerCase(); return !!m && String((h && h.name) || "").toLowerCase() === m; }

// The "your hero" banner at the top of the Heroes section. Shows the pinned name as
// textContent, whether that hero is among the living right now, and quick actions.
// Honest: if the pinned hero is not in the snapshot it says so and invents nothing.
function renderMyHeroBanner(hs) {
  const box = $("myHero");
  if (!box) return;
  box.replaceChildren();
  const mine = getMyHero();
  if (!mine) { box.classList.add("hide"); return; }
  box.classList.remove("hide");
  const live = arr(hs).find((h) => String(h.name || "").toLowerCase() === mine.toLowerCase());
  const line = el("p", "mhline");
  line.append(el("span", "mhlabel", "Your hero: "));
  const nm = el("b", "mhname"); nm.append(document.createTextNode(mine));   // viewer text
  line.append(nm);
  if (live) {
    const show = el("button", "linkbtn", "Show"); show.type = "button";
    show.addEventListener("click", () => {
      const card = [...$("heroList").querySelectorAll("details.hero")]
        .find((d) => (d.querySelector(".hname") || {}).textContent === String(live.name));
      if (card) { card.open = true; card.scrollIntoView({ block: "center", behavior: "smooth" }); }
    });
    line.append(document.createTextNode("  \u00b7  "), show);
  } else {
    line.append(el("span", "mhgone", " \u2014 not among the living right now (fallen, or not raised yet)."));
  }
  const un = el("button", "linkbtn", "Unpin"); un.type = "button";
  un.addEventListener("click", () => setMyHero(""));
  line.append(document.createTextNode("  \u00b7  "), un);
  box.append(line);
}

// ---------------------------------------------------------------- the Satchel (H11)
// The viewer's sellable items and what the counter would pay for them - the hub home
// for the on-stream Satchel's sell sheet (L51), which L63 took off the stream. READ-
// ONLY and forward-compatible exactly like the HP/XP bars and the bands: the block
// appears ONLY when the snapshot actually carries sellable items, and invents no item,
// price or total. Every item name is viewer/lore text and reaches the DOM ONLY via
// el()/createTextNode; prices and the total are PAGE-COMPUTED numbers set as text,
// never snapshot markup; the kind only SELECTS a whitelisted ICON_SET glyph - no field
// is ever used as a URL/src/href/style. The contract is pinned in docs/HUB_SECURITY.md.
const SATCHEL_ICON = {
  weapon: "blade", sword: "blade", blade: "blade", dagger: "blade", spear: "blade",
  bow: "ranged", ranged: "ranged", staff: "arcane", wand: "arcane", arcane: "arcane",
  hammer: "blunt", mace: "blunt", blunt: "blunt", armour: "shield", armor: "shield",
  shield: "shield", potion: "potion", brew: "potion", oil: "flask", flask: "flask",
  gold: "coin", coin: "coin", loot: "loot", treasure: "loot", gem: "loot", trinket: "loot",
};
function satchelIconId(kind) { return SATCHEL_ICON[String(kind || "").toLowerCase()] || "loot"; }
function sellOf(it) {
  const s = it.sell != null ? it.sell : it.value != null ? it.value
          : it.sell_price != null ? it.sell_price : it.price != null ? it.price : it.worth;
  return (s != null && Number.isFinite(+s)) ? Math.max(0, Math.round(+s)) : null;
}
function satchelRows(h) {
  const rows = [];
  const gear = (g, iconId, note) => {
    if (!g || !g.name) return; const s = sellOf(g); if (s == null) return;
    rows.push({ name: cap(g.name), qty: 1, sell: s, icon: iconId, note });
  };
  gear(h.weapon || {}, weaponIcon((h.weapon || {}).name), "equipped");
  gear(h.armour || {}, "shield", "equipped");
  const raw = arr(h.satchel != null ? h.satchel : h.inventory != null ? h.inventory : h.items);
  for (const it of raw) {
    if (!it || typeof it !== "object") continue;
    const name = firstStr(it.name, it.item, it.label, it.title);
    if (!name) continue;
    const qty = Math.max(1, Math.round(n0(it.qty) || n0(it.count) || n0(it.n) || 1));
    rows.push({ name: name.slice(0, 60), qty, sell: sellOf(it), icon: satchelIconId(firstStr(it.kind, it.slot, it.type, it.cat)) });
    if (rows.length >= 40) break;
  }
  return rows;
}
function satchelBlock(h) {
  const rows = satchelRows(h);
  if (!rows.length) return null;
  const wrap = document.createDocumentFragment();
  wrap.append(el("p", "eyebrow", "Satchel \u2014 what the counter would pay"));
  const list = el("ul", "satchel");
  for (const r of rows) {
    const li = el("li", "sitem");
    li.append(icon(r.icon, "sic"));
    const nm = el("span", "sname");
    nm.append(document.createTextNode(r.name));                 // viewer text: textContent
    if (r.qty > 1) nm.append(el("span", "sqty", " \u00d7" + r.qty));
    if (r.note) nm.append(el("span", "stag", r.note));
    li.append(nm);
    li.append(el("span", "sprice", r.sell == null ? "\u2014" : num(r.sell * r.qty) + " gold"));
    list.append(li);
  }
  wrap.append(list);
  const stated = n0(h.satchel_total) || n0(h.sell_total);
  let sum = 0, priced = false;
  for (const r of rows) if (r.sell != null) { sum += r.sell * r.qty; priced = true; }
  const foot = el("p", "satchelfoot");
  if (stated > 0) foot.append(el("span", "sk", "Counter pays "), el("b", null, num(stated)), el("span", "sk", " gold"));
  else if (priced) foot.append(el("span", "sk", "Counter would pay "), el("b", null, num(sum)), el("span", "sk", " gold for the priced items"));
  else foot.append(el("span", "sk", "No sell prices quoted yet."));
  wrap.append(foot);
  return wrap;
}

function renderHeroes(hs) {
  $("nHeroes").textContent = hs.length ? hs.length : "";
  $("heroesNote").textContent = hs.length ? `${hs.length} living` : "";
  renderMyHeroBanner(hs);
  const q = heroFilter.trim().toLowerCase();
  let list = q ? hs.filter((h) => String(h.name || "").toLowerCase().includes(q)) : hs.slice();
  const box = $("heroList");
  box.replaceChildren();
  if (!hs.length) { box.append(el("p", "empty", "No living heroes yet. Type !enlist in chat to raise one.")); $("heroMore").classList.add("hide"); return; }
  if (!list.length) { box.append(el("p", "empty", "No hero by that name. (Fallen heroes are in The Fallen.)")); $("heroMore").classList.add("hide"); return; }
  // H11: the viewer's pinned hero floats to the front, opens and is marked, so it is
  // the first thing they see - the hub's replacement for the on-stream Satchel.
  let mineName = "";
  const mineKey = getMyHero().toLowerCase();
  if (mineKey) {
    const idx = list.findIndex((h) => String(h.name || "").toLowerCase() === mineKey);
    if (idx > 0) { const m = list.splice(idx, 1)[0]; list.unshift(m); }
    if (idx >= 0) mineName = String(list[0].name);
  }
  const openNames = new Set();
  if (mineName) openNames.add(mineName);
  if (params.get("open") === "all") list.slice(0, 6).forEach((x) => openNames.add(String(x.name)));
  else if (params.get("open") && list[0]) openNames.add(String(list[0].name));
  for (const h of list.slice(0, heroShown)) box.append(heroCard(h, openNames.has(String(h.name)), mineName !== "" && String(h.name) === mineName));
  const more = $("heroMore");
  if (list.length > heroShown) {
    more.classList.remove("hide");
    more.replaceChildren();
    const b = el("button", "linkbtn", `Show more (${heroShown} of ${list.length})`);
    b.type = "button";
    b.addEventListener("click", () => { heroShown += HERO_PAGE; renderHeroes(hs); });
    more.append(b);
  } else more.classList.add("hide");
}

function kv(dt, ...dd) {
  const w = el("div", "kv");
  w.append(el("dt", null, dt));
  const d = el("dd");
  for (const x of dd) d.append(typeof x === "string" ? document.createTextNode(x) : x);
  w.append(d);
  return w;
}

// The HP bar. The snapshot carries hp but no max hp, so a true current/max gauge
// needs a denominator the data does not give. This is forward-compatible: if the
// publisher ever adds max_hp / hp_max / maxhp, it becomes a real depletion bar
// that colours by ratio; until then it shows a full "vitality" bar with the
// number, claiming nothing about injury (web/NOTES.md). One line flips it over.
function hpBar(h) {
  const max = n0(h.max_hp) || n0(h.hp_max) || n0(h.maxhp) || n0(h.hpmax) || 0;
  const hp = n0(h.hp);
  const hasMax = max > 0 && max >= hp;
  const ratio = hasMax ? Math.max(0.03, Math.min(1, hp / max)) : 1;
  const grade = !hasMax ? "flat" : ratio <= 0.25 ? "low" : ratio <= 0.5 ? "mid" : "ok";
  const wrap = el("div", "hpbar " + grade);
  wrap.setAttribute("role", "img");
  wrap.setAttribute("aria-label", hasMax ? "Hit points " + hp + " of " + max : "Hit points " + hp);
  const track = el("div", "hptrack");
  const fill = el("span", "hpfill");
  fill.style.setProperty("--hp", ratio);     // CSSOM number only, never snapshot text
  track.append(fill);
  wrap.append(el("span", "hpk", "HP"), track, el("span", "hpv", hasMax ? num(hp) + " / " + num(max) : num(hp)));
  return wrap;
}

// The level + XP bar. Like HP, the snapshot has xp but no per-hero next-level
// threshold, so it is forward-compatible: if the publisher adds xp_next /
// next_xp / xp_to_next / to_next, it draws a real progress bar to the next level;
// otherwise it shows the level and the xp earned, with a quiet filled bar and no
// invented denominator.
function xpBar(h) {
  const next = n0(h.xp_next) || n0(h.next_xp) || n0(h.xp_to_next) || n0(h.to_next) || 0;
  const xp = n0(h.xp);
  const hasNext = next > 0 && next >= xp;
  const ratio = hasNext ? Math.max(0.03, Math.min(1, xp / next)) : 1;
  const wrap = el("div", "xpbar" + (hasNext ? "" : " flat"));
  wrap.setAttribute("role", "img");
  wrap.setAttribute("aria-label", hasNext ? "Level " + n0(h.level) + ", " + xp + " of " + next + " xp to next"
                                          : "Level " + n0(h.level) + ", " + xp + " xp");
  wrap.append(el("span", "lvl", "Lv " + n0(h.level)));
  const track = el("div", "xptrack");
  const fill = el("span", "xpfill");
  fill.style.setProperty("--xp", ratio);
  track.append(fill);
  wrap.append(track, el("span", "xpv", hasNext ? num(xp) + " / " + num(next) : num(xp) + " xp"));
  return wrap;
}

// a weapon/armour card with its item icon and a full-name tooltip
function gearCard(iconId, label, value, tip) {
  const c = el("div", "gcard");
  if (tip) c.title = String(tip);          // tooltip: a property, never parsed as markup
  c.append(icon(iconId, "gic"));
  const t = el("div", "gt");
  t.append(el("span", "gl", label), el("span", "gv", value));
  c.append(t);
  return c;
}
// a carried-item chip with an icon
function carryChip(iconId, text) {
  const c = el("div", "cchip");
  c.title = String(text);
  c.append(icon(iconId, "cic"), el("span", null, text));
  return c;
}

function heroCard(h, isOpen, isMine) {
  const det = el("details", "hero" + (isMine ? " mine" : ""));
  const sum = el("summary");
  // the crest: the hero's initials in a class-tinted ring, with the calling's icon
  const sg = el("span", "hsigil cls-" + classIcon(h.class), initials(h.name));
  sg.title = (h.species ? cap(h.species) + " " : "") + cap(h.class || "adventurer");
  const crest = el("span", "hcrest");
  crest.setAttribute("aria-hidden", "true");
  crest.append(icon(classIcon(h.class)));
  sg.append(crest);
  const idb = el("span", "hid");
  idb.append(el("span", "hname", nameOf(h) || "(no name)"));
  // name gets the full body width; the class line and the AC/HP pair share a row below it
  const meta = el("span", "hmeta");
  const what = el("span", "hwhat",
    `${cap(h.species)} ${cap(h.class)}, level ${h.level}`.trim() + (h.rank ? "  ·  " + h.rank : ""));
  const quick = el("span", "hquick");
  quick.append(el("span", "hq", "AC"), el("b", null, h.ac), el("span", "hq", "HP"), el("b", null, h.hp));
  meta.append(what, quick);
  idb.append(meta);
  if (h.title) idb.append(el("span", "htitle", h.title));
  const coa = coat(h.name, "md");
  coa.classList.add("hcoa");
  sum.append(sg, idb, coa);
  det.append(sum);

  // lazy-render: the full sheet is built on first open, not for all 60+ cards up
  // front. A busy night is 200 heroes; most cards are never opened.
  let built = false;
  const build = () => { if (built) return; built = true; det.append(heroSheet(h)); };
  det.addEventListener("toggle", () => { if (det.open) build(); });
  if (isOpen) { det.open = true; build(); }
  return det;
}

// ============================================================ H20: THE CHARACTER SHEET
// A sheet, not a stat line. Built from the snapshot row ONLY: a field the publisher does
// not send is drawn as a deliberate empty cell (dashed, "not published") and named in a
// foot line - never estimated, never derived (no modifier-based initiative, no guessed max
// HP). Every string reaches the DOM via el()/textContent; the HP/XP fills are CSSOM
// numbers; icons are ICON_SET ids; the only snapshot-chosen thing is WHICH known icon.
// Living heroes build from p.heroes; the fallen build the same sheet from their memorial
// row (mode "fallen"), where most combat fields are honestly empty.
const SHEET_SLOTS = [   // [label, gear-object key, icon, source]  - source: "w" weapon, "a" armour, "" extra
  ["Main hand", "main_hand", null, "w"], ["Off hand", "off_hand", "shield", ""],
  ["Head", "head", "loot", ""], ["Body", "body", "shield", "a"],
  ["Hands", "hands", "loot", ""], ["Feet", "feet", "loot", ""],
  ["Cloak", "cloak", "loot", ""], ["Neck", "neck", "loot", ""], ["Ring", "ring", "loot", ""],
];
function sheetPayload() { try { return last ? (MOCK ? withMock(last.payload) : last.payload) : null; } catch (e) { return null; } }
const slotText = (v) => (v == null ? "" : typeof v === "object" ? (v.name != null ? String(v.name).trim() : "") : String(v).trim());
// does `text` name `key` (lower-cased) as a whole word? Short names must not match inside other words.
function namesIn(text, key) {
  const s = String(text).toLowerCase();
  let i = s.indexOf(key);
  while (i >= 0) {
    const before = i === 0 ? "" : s[i - 1], after = s[i + key.length] || "";
    if (!/[a-z0-9]/.test(before) && !/[a-z0-9]/.test(after)) return true;
    i = s.indexOf(key, i + 1);
  }
  return false;
}
// the H14 history (live + remembered in this browser), filtered to the lines naming THIS hero
function personalLines(name, ring) {
  // H23.2: the publisher's own per-hero ring (h.events, newest first, [{t, s, at}]) wins when it
  // carries anything; each row goes through the same chronShape as a live line. Else name-match.
  if (Array.isArray(ring) && ring.length) {
    const own = chronEntries(ring).slice(0, 8);
    if (own.length) return own;
  }
  const key = String(name || "").trim().toLowerCase();
  if (!key) return [];
  const p = sheetPayload();
  chronMemEnsure();
  const live = p ? chronEntries(p.chronicle) : [];
  const liveKeys = new Set(live.map(histKey));
  const rem = chronMem.filter((r) => !liveKeys.has(histKey(r))).map((r) => Object.assign(chronShape(r), { ts: histTs(r) }));
  return live.concat(rem).filter((e) => namesIn(e.s, key)).slice(0, 8);
}
// where is this hero right now, in the town's own voice. Returns chips + any honest gap.
function heroConditions(h, fallen, gaps) {
  const out = [];
  if (fallen) {
    const day = pickNum(h.day);
    out.push({ cls: "st-fallen", ic: "death", text: "Fallen" + (day != null && day > 0 ? " on day " + num(day) : "") });
    return out;
  }
  const p = sheetPayload();
  const key = nameOf(h).trim().toLowerCase();
  let member = null, band = null;
  if (p && Array.isArray(p.parties)) {
    for (const b of normalizeParties(p.parties)) {
      const m = b.members.find((x) => x.name.trim().toLowerCase() === key);
      if (m) { member = m; band = b; break; }
    }
  }
  if (band) {
    out.push({ cls: "st-band", ic: "delve", text: "Delving with " + (band.name || "a band") + (band.floor != null ? ", floor " + num(band.floor) : "") });
    if (member.status === "burning") out.push({ cls: "st-burning", ic: "flame", text: "Burning" });
    else if (member.status === "fallen") out.push({ cls: "st-fallen", ic: "death", text: "Down in the dark" });
    else if (member.status === "other" && member.statusText) out.push({ cls: "st-other", ic: null, text: member.statusText });
  } else if (p && Array.isArray(p.parties)) {
    out.push({ cls: "st-town", ic: "town", text: "Not in any band the town reports" });
  }
  const own = firstStr(h.status, h.state, h.activity, h.where).toLowerCase().trim();
  if (own) {
    const canon = PARTY_STATUS[own];
    if (canon === "burning" && !out.some((c) => c.cls === "st-burning")) out.push({ cls: "st-burning", ic: "flame", text: "Burning" });
    else if (canon === "fallen") out.push({ cls: "st-fallen", ic: "death", text: "Down" });
    else if (!canon) out.push({ cls: "st-other", ic: null, text: titleCase(own).slice(0, 28) });
  } else if (!band) gaps.push("what the hero is doing now (status / state)");
  const max = pickNum(h.max_hp, h.hp_max, h.maxhp, h.hpmax), hp = pickNum(h.hp);
  const mhp = member && member.max != null ? member.max : max;
  const chp = member && member.hp != null ? member.hp : hp;
  if (mhp != null && chp != null && mhp > 0 && chp / mhp <= 0.5 && !(member && member.status === "fallen")) out.push({ cls: "st-hurt", ic: null, text: "Wounded" });
  return out;
}
function sheetCell(k, v, sub, gap) {
  const c = el("div", "stat" + (gap ? " unpub" : ""));
  c.append(el("div", "k", k), el("div", "v", gap ? "\u2014" : v), el("div", "m", gap ? "" : (sub || "")));
  if (gap) c.title = "The town does not publish this yet.";
  return c;
}
function sheetSec(title) {
  const sec = el("section", "ssec");
  sec.append(el("p", "eyebrow", title));
  return sec;
}
const signed = (n) => (n >= 0 ? "+" : "\u2212") + Math.abs(n);

function heroSheet(h, mode) {
  const fallen = mode === "fallen";
  const s = h.stats && typeof h.stats === "object" ? h.stats : {};
  const gaps = [];
  const sheet = el("div", "sheet charsheet" + (fallen ? " fallen" : ""));

  // ---- identity: crest, name, title, calling, level; the pin sits at the right
  const sid = el("div", "sid");
  sid.append(coat(h.name, "lg"));
  const who = el("div", "swho");
  who.append(el("div", "sname", nameOf(h) || "(no name)"));
  if (h.title) who.append(el("div", "stitle", String(h.title)));
  const lv = pickNum(h.level);
  const callingTxt = `${cap(h.species)} ${cap(h.class)}`.trim() || "Adventurer";
  who.append(el("div", "scall", callingTxt + (lv != null && lv > 0 ? ", level " + num(lv) : "") + (h.rank ? "  \u00b7  " + h.rank : "")));
  sid.append(who);
  if (!fallen) {
    // H11: pin this hero as "mine" so it is easy to find next visit
    const mineNow = isMyHero(h);
    const pin = el("button", "pinbtn" + (mineNow ? " on" : ""), mineNow ? "Your hero \u2014 unpin" : "Pin as my hero");
    pin.type = "button";
    pin.setAttribute("aria-pressed", mineNow ? "true" : "false");
    pin.title = "Remembered in this browser only, so your hero is easy to find next time.";
    pin.addEventListener("click", () => setMyHero(mineNow ? "" : (h.name || "")));
    sid.append(pin);
  }
  sheet.append(sid);

  // ---- H20.2 condition and state, with an honest "last seen"
  const conds = el("div", "sconds");
  for (const c of heroConditions(h, fallen, gaps)) {
    const chip = el("span", "scond " + c.cls);
    if (c.ic) chip.append(icon(c.ic, "bmic"));
    chip.append(document.createTextNode(c.text));
    conds.append(chip);
  }
  if (!fallen && last) {
    const a = ago(last.updated_at);
    const stale = TEST === "stale" || !a || a.s > STALE_MIN * 60;
    // H23.2: a per-hero last_seen (ISO string, validated; never a URL/style) says when THIS hero
    // last acted - distinct from the whole-town updated_at, which only says the town reported.
    const ls = typeof h.last_seen === "string" && CHRON_AT_OK.test(h.last_seen) ? ago(h.last_seen) : null;
    if (ls) {
      conds.append(el("span", "sseen" + (stale ? " stale" : ""),
        "Last seen " + ls.text + (stale ? " \u2014 but the town itself last reported " + (a ? a.text : "at an unknown time") + ", so this sheet may be out of date" : "")));
    } else {
      conds.append(el("span", "sseen" + (stale ? " stale" : ""),
        stale ? "Last word from the town " + (a ? a.text : "at an unknown time") + " \u2014 this sheet may be out of date"
              : "As of the town's last word, " + a.text));
      gaps.push("a per-hero 'last seen' time (the sheet can only say when the whole town last reported)");
    }
  }
  if (conds.childNodes.length) sheet.append(conds);

  // ---- fallen: the manner of it, in the town's words
  if (fallen) {
    const doom = el("div", "sdoom");
    const cause = h.killed_by ? String(h.killed_by) : "";
    const day = pickNum(h.day);
    if (cause || (day != null && day > 0)) doom.append(el("p", "sdline", "Taken by " + (cause || "the dark") + (day != null && day > 0 ? ", day " + num(day) : "") + "."));
    if (h.epitaph) doom.append(el("p", "sepi", "\u201c" + String(h.epitaph) + "\u201d"));
    if (doom.childNodes.length) sheet.append(doom);
    else sheet.append(el("p", "empty", "The town wrote no epitaph for this one."));
  } else {
    sheet.append(hpBar(h));
    sheet.append(xpBar(h));
    if (pickNum(h.max_hp, h.hp_max, h.maxhp, h.hpmax) == null) gaps.push("max HP (HP shows as vitality, not a depletion bar)");
    if (pickNum(h.xp_next, h.next_xp, h.xp_to_next, h.to_next) == null) gaps.push("XP to next level");
  }

  // ---- abilities
  const ab = sheetSec("Abilities");
  const stats = el("div", "stats");
  const missingStats = [];
  for (const k of ["str", "dex", "con", "int", "wis", "cha"]) {
    const v = pickNum(s[k]);
    if (v == null) missingStats.push(k.toUpperCase());
    stats.append(sheetCell(k, v != null ? v : "", v != null ? modOf(v) : "", v == null));
  }
  if (missingStats.length) gaps.push("ability scores (" + missingStats.join(", ") + ")");
  ab.append(stats);
  sheet.append(ab);

  // ---- combat
  const cb = sheetSec("Combat");
  const cg = el("div", "stats combat");
  const ac = pickNum(h.ac), hpv = pickNum(h.hp), maxv = pickNum(h.max_hp, h.hp_max, h.maxhp, h.hpmax);
  const th = pickNum(h.to_hit), pf = pickNum(h.prof), ini = pickNum(h.initiative, h.init), spd = pickNum(h.speed);
  cg.append(
    sheetCell("AC", ac, "", ac == null),
    sheetCell("HP", hpv != null ? num(hpv) : "", maxv != null && maxv >= (hpv || 0) ? "of " + num(maxv) : "", hpv == null),
    sheetCell("To hit", th != null ? signed(th) : "", "", th == null),
    sheetCell("Prof.", pf != null ? signed(pf) : "", "", pf == null),
    sheetCell("Initiative", ini != null ? signed(ini) : "", "", ini == null),
    sheetCell("Speed", spd, "", spd == null),
  );
  if (ac == null) gaps.push("armour class");
  if (hpv == null && !fallen) gaps.push("hit points");
  if (th == null) gaps.push("to-hit bonus");
  if (pf == null) gaps.push("proficiency bonus");
  if (ini == null) gaps.push("initiative");
  if (spd == null) gaps.push("speed");
  cb.append(cg);
  const sv = el("dl", "kvlist");
  const svTxt = h.saves ? String(h.saves) : "";
  sv.append(kv("Saves", svTxt ? svTxt : el("span", "gapnote", "not published")));
  if (!svTxt) gaps.push("saving throws");
  cb.append(sv);
  sheet.append(cb);

  // ---- gear by slot: an empty slot is drawn as an empty slot, never omitted
  const gb = sheetSec("Gear by slot");
  const grid = el("div", "slots");
  const gear = h.gear && typeof h.gear === "object" ? h.gear : (h.equipment && typeof h.equipment === "object" ? h.equipment : {});
  const w = h.weapon, ar = h.armour != null ? h.armour : h.armor;
  const unpubSlots = [];
  for (const [label, key, ic, src] of SHEET_SLOTS) {
    let val = "", known = false;
    if (src === "w") { known = true; val = slotText(w) || slotText(gear[key]); }
    else if (src === "a") { known = true; val = slotText(ar) || slotText(gear[key]); }
    else if (gear[key] !== undefined) { known = true; val = slotText(gear[key]); }
    const cell = el("div", "slot" + (val ? " filled" : " vacant") + (known ? "" : " unpub"));
    const wi = src === "w" ? weaponIcon(val) : ic;
    cell.append(icon(wi || "blade", "sic"));
    const tx = el("div", "stx");
    tx.append(el("span", "sl", label));
    if (val) {
      let line = cap(val);
      if (src === "w" && w && typeof w === "object" && w.dice) line += "  \u00b7  " + w.dice;
      if (src === "a" && ac != null) line += "  \u00b7  AC " + ac;
      tx.append(el("span", "sv", line));
      cell.title = line;
    } else {
      tx.append(el("span", "sv none", known ? (src === "w" ? "Empty \u2014 bare hands" : src === "a" ? "Empty \u2014 no armour" : "Empty") : "\u2014"));
      cell.title = known ? label + " is empty." : "The town does not publish this slot yet.";
      if (!known) unpubSlots.push(label.toLowerCase());
    }
    cell.append(tx);    // H23.3: the slot text block was built but never attached
    grid.append(cell);
  }
  if (unpubSlots.length) gaps.push("gear slots (" + unpubSlots.join(", ") + ")");
  gb.append(grid);
  // cosmetics: a dye swatch colour comes from a WHITELISTED class, never an inline style
  if (h.worn || h.dye) {
    const cos = el("div", "cosmetics");
    if (h.worn) cos.append(el("span", "cositem", String(h.worn)));
    if (h.dye) {
      const d = String(h.dye).trim();
      const known = /^(black|white|red|blue|green|gold|purple|teal|brown|gr[ae]y)$/i.test(d);
      const chip = el("span", "dyechip" + (known ? " dye-" + d.toLowerCase().replace("gray", "grey") : ""));
      const sw = el("span", "dyeswatch"); sw.setAttribute("aria-hidden", "true");
      chip.append(sw, document.createTextNode(cap(d) + " dye"));
      cos.append(chip);
    }
    gb.append(cos);
  }
  sheet.append(gb);

  // ---- carrying + satchel (living only)
  if (!fallen) {
    const cr = sheetSec("Carrying");
    const carry = el("div", "carry");
    const brew = h.brews ? String(h.brews) : (+h.potions ? `${num(h.potions)} Mending` : "no brews");
    carry.append(carryChip("potion", brew), carryChip("flask", `${num(h.oil)} oil`), carryChip("coin", `${num(h.gold)} gold`));
    cr.append(carry);
    sheet.append(cr);
    // Satchel (H11): appears only when the snapshot carries items to sell; never faked.
    const satchel = satchelBlock(h);
    if (satchel) sheet.append(satchel);
  }

  // ---- the record, then THIS hero's own chronicle (H20.3)
  const rc = sheetSec("Record");
  const rec = el("dl", "kvlist");
  const dp = pickNum(h.deepest), kl = pickNum(h.kills), dl = pickNum(h.delves);
  rec.append(
    kv("Deepest", dp != null && dp > 0 ? "floor " + num(dp) : el("span", "gapnote", dp === 0 ? "never below the town" : "not published")),
    kv("Foes slain", kl != null ? num(kl) : el("span", "gapnote", "not published")),
  );
  if (!fallen) rec.append(kv("Delves", dl != null ? num(dl) : el("span", "gapnote", "not published")), kv("Standing", num(h.standing)));
  rc.append(rec);
  sheet.append(rc);

  const life = sheetSec("Their own chronicle");
  const lines = personalLines(h.name, fallen ? null : h.events);
  if (!lines.length) {
    life.append(el("p", "empty", "No line in the chronicle names them yet. (The hub remembers about two days of it, in this browser.)"));
  } else {
    const ul = el("ul", "plife");
    for (const e of lines) {
      const li = el("li", "pl kind-" + e.key);
      li.append(icon(e.icon, "chipic"));
      li.append(el("span", "pls", e.s));
      const a = e.at ? ago(e.at) : (e.ts ? ago(new Date(e.ts).toISOString()) : null);
      if (a) li.append(el("span", "plw", a.text));
      ul.append(li);
    }
    life.append(ul);
    const deaths = lines.filter((e) => e.t === "death").length;
    if (deaths) life.append(el("p", "plnote", deaths === 1 ? "The chronicle records one death." : "The chronicle records " + deaths + " deaths."));
  }
  sheet.append(life);

  // ---- H20.4: what the sheet wanted and the town did not send
  const wanted = ["background / origin", "alignment", "skills and proficiencies", "spells and spell slots", "hit dice", "inventory beyond the satchel"];
  const gp = el("p", "sgaps");
  gp.append(el("b", null, "Not yet sent by the town: "), document.createTextNode(gaps.concat(wanted).join("; ") + "."));
  sheet.append(gp);
  return sheet;
}

// ============================================================ THE GUILD ROLL
function renderRoll(rows) {
  const box = $("rollList");
  box.replaceChildren();
  if (!rows.length) { box.append(el("li", "empty", "The roll is empty - nobody has earned a place yet.")); return; }
  rows.forEach((r, i) => {
    const li = el("li", r.alive === false ? "gone" : "");
    li.append(el("span", "pos", i + 1));
    const mid = el("span", "rmid");
    const nm = el("span", "rname");
    nm.append(document.createTextNode(nameOf(r)));
    mid.append(nm, el("span", "rrank", `${r.rank}, level ${r.level}` + (r.alive === false ? "  ·  fallen" : "")));
    li.append(mid);
    const sc = el("span", "rscore");
    sc.append(el("b", null, num(r.standing)), el("span", "rsub", `${num(r.kills)} kills  ·  floor ${num(r.deepest)}`));
    li.append(sc);
    box.append(li);
  });
}

// ============================================================ THE FALLEN (H16: Hall of the Fallen)
// A memorial, not a list. Every field is optional and defended: a missing one is simply
// not drawn (an honest blank) - never "undefined", never a guess. All text goes through
// el()/textContent; the crest is page-owned heraldry chosen by hashing the name (H15).
// The epitaph is whatever the snapshot carries (the town writes it at the hero's death);
// the frozen lore (H12) holds no epitaph set, so there is no parallel list here.
function fallenText(v) {                       // string | {name} | null -> trimmed text or ""
  if (v == null) return "";
  if (typeof v === "object") return v.name != null ? String(v.name).trim() : "";
  return String(v).trim();
}
function fallenRow(label, value, cls) {
  const row = el("div", "gfact" + (cls ? " " + cls : ""));
  row.append(el("span", "gk", label), el("span", "gv", value));
  return row;
}
function renderFallen(fs) {
  $("nFallen").textContent = fs.length ? fs.length : "";
  const box = $("fallenList");
  box.replaceChildren();
  if (!fs.length) { box.append(el("p", "empty", "No one has fallen. Yet.")); return; }
  for (let fi = 0; fi < fs.length; fi++) {
    const f = fs[fi];
    if (f == null || typeof f !== "object") continue;
    const g = el("article", "grave");
    g.dataset.fi = String(fi);            // H24: integer the page owns, so the finder can land here
    const head = el("div", "ghead");
    head.append(coat(nameOf(f), "md"));
    const who = el("div", "gwho");
    who.append(document.createTextNode(nameOf(f)));
    const klass = f.class ? String(f.class) : "";
    const lvl = Number.isFinite(+f.level) && +f.level > 0 ? "level " + num(f.level) : "";
    const rec = [klass ? "the " + klass : "", lvl].filter(Boolean).join(", ");
    if (rec) who.append(el("span", "grec", rec));
    head.append(who);
    g.append(head);
    // their earned title, if they carried one, kept with them on the memorial
    if (f.title) g.append(el("div", "gtitle", String(f.title)));
    if (f.epitaph) g.append(el("div", "gepi", "\u201c" + String(f.epitaph) + "\u201d"));
    const facts = el("div", "gfacts");
    const cause = f.killed_by ? String(f.killed_by) : "";
    const day = +f.day > 0 ? "day " + num(f.day) : "";
    if (cause || day) facts.append(fallenRow("Taken by", [cause, day].filter(Boolean).join(", "), "gcause"));
    if (Number.isFinite(+f.deepest) && +f.deepest > 0) facts.append(fallenRow("Deepest", "floor " + num(f.deepest)));
    if (Number.isFinite(+f.kills) && +f.kills > 0) facts.append(fallenRow("Slain", num(f.kills) + (+f.kills === 1 ? " foe" : " foes")));
    const wep = fallenText(f.weapon), arm = fallenText(f.armour != null ? f.armour : f.armor);
    if (wep || arm) {
      const row = el("div", "gfact gwore");
      row.append(el("span", "gk", "Wore"));
      const gv = el("span", "gv");
      if (wep) frag(gv, icon(weaponIcon(wep), "gico"), el("span", null, cap(wep)));
      if (wep && arm) gv.append(el("span", "gsep", " \u00b7 "));
      if (arm) frag(gv, icon("shield", "gico"), el("span", null, cap(arm)));
      row.append(gv);
      facts.append(row);
    }
    if (facts.childNodes.length) g.append(facts);
    // H20: the same character sheet, read from the memorial row; built lazily on first open
    const sd = el("details", "gsheet");
    sd.append(el("summary", null, "Read their sheet"));
    let sbuilt = false;
    sd.addEventListener("toggle", () => { if (sd.open && !sbuilt) { sbuilt = true; sd.append(heroSheet(f, "fallen")); } });
    if (params.get("open") === "all") { sd.open = true; sbuilt = true; sd.append(heroSheet(f, "fallen")); }
    g.append(sd);
    box.append(g);
  }
}

// ============================================================ BANDS BELOW (H10)
// The parties currently delving, read from the snapshot's parties array. The hub
// has room the stream does not, so it shows EVERY active band, not just one. This
// is the viewer side of D46 (which takes the band panel off the stream and puts the
// band into the snapshot). Forward-compatible exactly like the rolls feed and the
// hero HP bars: the section shows an honest empty state until the publisher sends
// p.parties, and invents nothing - no band, no member, no health it was not given.
//
// CONTRACT (pinned for D46, also in docs/HUB_SECURITY.md). p.parties is an array;
// every field optional and defended. Canonical key, then accepted aliases:
//   name    the band's display name          (band, party, title)  - viewer text
//   floor   integer dungeon floor it is on    (depth)
//   members array of per-member objects:
//     name    the hero's name                (who, hero)           - viewer text
//     hp      current hit points             (health)
//     max_hp  max hit points                 (hp_max, maxhp, hpmax)
//     status  ok | fallen | burning | ...     (state, condition)
//     class   the calling, optional          (calling)             - viewer text
// When p.v becomes "2" the publisher carries this (see the version gate above).
// Every string reaches the DOM only through el()/textContent; HP widths are page-
// computed CSSOM numbers, never snapshot text; `status` only ever picks a whitelisted
// icon + CSS class; no field is EVER used as a URL/src/href/style.
const PARTY_MAX = 24, MEMBER_MAX = 12;
// status -> a canonical key. unknown non-empty -> "other" (shown as its own text);
// absent -> "ok" (healthy: no tag, just the bar). fallen/burning carry an icon + class.
const PARTY_STATUS = {
  ok: "ok", alive: "ok", fine: "ok", well: "ok", up: "ok", healthy: "ok", active: "ok", delving: "ok",
  fallen: "fallen", dead: "fallen", down: "fallen", slain: "fallen", ko: "fallen", out: "fallen",
  burning: "burning", afire: "burning", aflame: "burning", ablaze: "burning", ignited: "burning", onfire: "burning",
};
const STATUS_META = {
  fallen:  { label: "fallen",  icon: "death", cls: "st-fallen" },
  burning: { label: "burning", icon: "flame", cls: "st-burning" },
};
function partyMember(m) {
  const rawS = firstStr(m.status, m.state, m.condition).toLowerCase().trim();
  const status = PARTY_STATUS[rawS] || (rawS ? "other" : "ok");
  return {
    name: firstStr(m.name, m.who, m.hero).slice(0, 40),
    hp: pickNum(m.hp, m.health),
    max: pickNum(m.max_hp, m.hp_max, m.maxhp, m.hpmax),
    cls: firstStr(m.class, m.calling).slice(0, 24),
    status: status,
    statusText: status === "other" ? titleCase(rawS).slice(0, 24) : "",
  };
}
function normalizeParties(raw) {
  return arr(raw)
    .filter((p) => p && typeof p === "object")
    .map((p) => ({
      name: firstStr(p.name, p.band, p.party, p.title).slice(0, 60),
      floor: (function () { const v = pickNum(p.floor, p.depth); return v != null && v >= 0 ? Math.round(v) : null; })(),
      members: arr(p.members != null ? p.members : (p.roster != null ? p.roster : p.heroes))
        .filter((m) => m && typeof m === "object")
        .map(partyMember)
        .filter((m) => m.name || m.hp != null)
        .slice(0, MEMBER_MAX),
    }))
    .filter((p) => p.name || p.members.length)
    .slice(0, PARTY_MAX);
}
// a member's HP bar - the same safe pattern as the hero hpBar: a real depletion bar
// when max_hp is published, a flat vitality bar otherwise, the fill a CSSOM number
// (never snapshot text). A fallen member reads empty and grey. Claims nothing it
// was not told.
function memberHpBar(m) {
  const max = n0(m.max), hp = n0(m.hp);
  const fallen = m.status === "fallen";
  const hasMax = max > 0 && max >= hp;
  let ratio = hasMax ? Math.max(0.03, Math.min(1, hp / max)) : 1;
  if (fallen) ratio = 0;
  const grade = fallen ? "gone" : !hasMax ? "flat" : ratio <= 0.25 ? "low" : ratio <= 0.5 ? "mid" : "ok";
  const wrap = el("div", "hpbar " + grade);
  wrap.setAttribute("role", "img");
  wrap.setAttribute("aria-label", fallen ? "Fallen" : hasMax ? "Hit points " + hp + " of " + max : "Hit points " + hp);
  const track = el("div", "hptrack");
  const fill = el("span", "hpfill");
  fill.style.setProperty("--hp", ratio);     // CSSOM number only, never snapshot text
  track.append(fill);
  wrap.append(el("span", "hpk", "HP"), track, el("span", "hpv", fallen ? "\u2014" : hasMax ? num(hp) + " / " + num(max) : num(hp)));
  return wrap;
}
function memberRow(m) {
  const li = el("li", "bmember" + (m.status === "fallen" ? " gone" : "") + (m.status === "burning" ? " burning" : ""));
  const top = el("div", "bmtop");
  const nm = el("span", "bmname");
  nm.append(document.createTextNode(m.name || "(no name)"));        // viewer text: textContent
  if (m.cls) nm.append(el("span", "bmcls", "  \u00b7  " + cap(m.cls)));
  top.append(nm);
  const meta = STATUS_META[m.status];
  if (meta) {
    const tag = el("span", "bmtag " + meta.cls);
    tag.append(icon(meta.icon, "bmic"));                            // whitelisted glyph id
    tag.append(document.createTextNode(meta.label));
    top.append(tag);
  } else if (m.status === "other" && m.statusText) {
    top.append(el("span", "bmtag st-other", m.statusText));         // unknown status: its own name, as text
  }
  li.append(top);
  if (m.hp != null) li.append(memberHpBar(m));
  return li;
}
function partyCard(p) {
  const card = el("div", "bandcard");
  const head = el("div", "bandhead");
  const nm = el("span", "bandname");
  nm.append(document.createTextNode(p.name || "A band"));           // viewer text: textContent
  head.append(nm);
  if (p.floor != null) head.append(el("span", "bandfloor", "Floor " + num(p.floor)));
  const total = p.members.length;
  const fallen = p.members.filter((m) => m.status === "fallen").length;
  if (total) head.append(el("span", "bandmeta",
    total + (total === 1 ? " delver" : " delvers") + (fallen ? "  \u00b7  " + fallen + " fallen" : "")));
  card.append(head);
  const ul = el("ul", "bandmembers");
  if (!p.members.length) ul.append(el("li", "empty", "No members reported for this band."));
  else for (const m of p.members) ul.append(memberRow(m));
  card.append(ul);
  return card;
}
function renderBands(raw) {
  const box = $("bandList");
  if (!box) return;
  const note = $("bandNote"), count = $("bandCount"), nb = $("nBands");
  const parties = normalizeParties(raw);
  box.replaceChildren();
  if (nb) nb.textContent = parties.length ? parties.length : "";
  if (!parties.length) {
    box.append(el("p", "empty", "No bands are delving right now. When a party goes down into the scar it appears here \u2014 every member, with their health and whether they still stand."));
    if (count) count.textContent = "";
    if (note) note.textContent = "";
    return;
  }
  parties.forEach((p, bi) => { const cardEl = partyCard(p); cardEl.dataset.bi = String(bi); box.append(cardEl); });   // H24: integer index
  const heads = parties.reduce((a, p) => a + p.members.length, 0);
  if (count) count.textContent = parties.length + (parties.length === 1 ? " band" : " bands");
  if (note) note.textContent = parties.length + (parties.length === 1 ? " band" : " bands")
    + " in the scar now, " + heads + (heads === 1 ? " delver" : " delvers")
    + " in all. The hub shows every active band; the stream no longer has to.";
}

// ============================================================ THE CHRONICLE
// The known kinds get an icon and a nice plural label; any OTHER kind the game
// publishes still gets its own chip (a generic glyph + its own name, Title-cased),
// so a new event type needs no page change. The kind string is sanitised for the
// CSS class and whitelisted for the icon - it is never written to the DOM as
// markup, only as textContent in the chip label and the entry heading.
const CHRON_KINDS = [
  { t: "fight", label: "Fights", one: "Fight" }, { t: "death", label: "Deaths", one: "Death" },
  { t: "raid", label: "Raids", one: "Raid" }, { t: "town", label: "Town", one: "Town" },
  { t: "lore", label: "Lore", one: "Lore" }, { t: "loot", label: "Loot", one: "Loot" },
  { t: "delve", label: "Delves", one: "Delve" },
];
const CHRON_ICON = new Set(CHRON_KINDS.map((k) => k.t));   // kinds that have a drawn glyph
const CHRON_MAX = 50;
let chronOff = new Set();          // kind keys switched OFF
let chronText = "";                // free-text filter
let chronHero = "", chronTopic = "all";   // H21.2 hero + event-kind filters (persisted, page-local)
let chronFocusKeep = 0;            // the moment currently marked (until the viewer changes a filter)
let chronFocusId = null;           // H21.4 a moment id (an integer the page owns) to open on
const chronOpen = new Map();       // H21.1 episode key -> viewer's open/fold choice
let chronHeroSig = "";
let chronData = null;              // the latest raw chronicle (for hover-paused repaints)
let chronHover = false;            // true while the pointer is over the feed
let chronPending = false;          // an auto-refresh arrived while hovering

const titleCase = (s) => String(s).replace(/[_-]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

function chronEntries(raw) {
  return arr(raw)
    .filter((e) => e && typeof e === "object" && typeof e.s === "string" && e.s.trim() !== "")
    .slice(0, CHRON_MAX)
    .map(chronShape);
}
function chronShape(e) {
      const rawT = String(e.t == null ? "" : e.t).toLowerCase().trim();
      const t = /^[a-z0-9][a-z0-9 _-]{0,23}$/.test(rawT) ? rawT : "other";   // sane key, else "other"
      const known = CHRON_KINDS.find((k) => k.t === t);
      return { t, known: !!known, label: known ? known.one : (t === "other" ? "Other" : titleCase(t)),
                icon: CHRON_ICON.has(t) ? t : "other",
               key: t.replace(/[^a-z0-9]+/g, "-"),           // for the CSS class only
               s: String(e.s), at: typeof e.at === "string" ? e.at : "" };
}

// ---- H14: the chronicle remembers. A small rolling history lives in THIS browser only
// (localStorage; no write path to any server, no fetch). Newest first, hard-capped at
// CHRON_HIST_MAX rows / 48 h / CHRON_HIST_BYTES, oldest dropped first. Everything read
// back is attacker-controlled text that has crossed one storage round-trip, so it is
// re-validated field by field and then shaped by the SAME chronShape + el()/textContent
// path as a live line. Storage may be absent, full or throw: every access is wrapped and
// the page renders fine with the history empty.
const CHRON_HIST_KEY = "bellmire.chron.v1";
const CHRON_HIST_MAX = 300, CHRON_HIST_MS = 48 * 3600000, CHRON_HIST_BYTES = 120000, CHRON_S_CAP = 400;
const CHRON_AT_OK = /^\d{4}-\d\d-\d\dT[0-9:.]{5,16}(Z|[+-]\d\d:\d\d)?$/;
let chronMem = [];                 // remembered rows [{t, s, at, k}], newest first
let chronMemLoaded = false;
const CHRON_SEQ_KEY = "bellmire.chron.seq.v1", CHRON_SEEN_KEY = "bellmire.chron.seen.v1", CHRON_F_KEY = "bellmire.chron.f.v1";
let chronSeq = 0, chronSeenAtLoad = 0;
const histTs = (r) => { const a = Date.parse(r.at); return isFinite(a) ? a : (r.k || 0); };
const histKey = (r) => r.t + "|" + r.s;
function histClean(a) {
  const out = [];
  for (const r of arr(a).slice(0, CHRON_HIST_MAX * 2)) {
    if (!r || typeof r !== "object" || typeof r.s !== "string") continue;
    const s = ctrlStrip(r.s).slice(0, CHRON_S_CAP);
    if (!s) continue;
    const rt = String(r.t == null ? "" : r.t).toLowerCase().trim();
    const at = typeof r.at === "string" && r.at.length <= 40 && CHRON_AT_OK.test(r.at) ? r.at : "";
    out.push({ t: /^[a-z0-9][a-z0-9 _-]{0,23}$/.test(rt) ? rt : "other", s, at,
               k: typeof r.k === "number" && isFinite(r.k) ? r.k : Date.now(),
               n: Number.isInteger(r.n) && r.n > 0 && r.n < 2e9 ? r.n : 0 });
  }
  return out;
}
function chronMemEnsure() {
  if (chronMemLoaded) return;
  chronMemLoaded = true;
  try {
    const raw = localStorage.getItem(CHRON_HIST_KEY);
    chronMem = raw && raw.length <= CHRON_HIST_BYTES * 2 ? histClean(JSON.parse(raw)) : [];
  } catch (e) { chronMem = []; }
  try { chronSeq = Math.max(0, parseInt(localStorage.getItem(CHRON_SEQ_KEY), 10) || 0); } catch (e) { chronSeq = 0; }
  for (const r of chronMem) if (r.n > chronSeq) chronSeq = r.n;
  try { const v = parseInt(localStorage.getItem(CHRON_SEEN_KEY), 10); chronSeenAtLoad = isFinite(v) && v > 0 && v <= Date.now() ? v : 0; } catch (e) { chronSeenAtLoad = 0; }
  const away = parseFloat(params.get("away"));      // local check: pretend the last look was N hours ago
  if (isFinite(away) && away >= 0.5 && away <= 72) chronSeenAtLoad = Date.now() - away * 3600000;
  chronFiltLoad();
}
// fold the live entries into the history, prune, cap, persist.
function chronRemember(live) {
  chronMemEnsure();
  const now = Date.now(), by = new Map();
  for (const r of chronMem) { if (!r.n) r.n = ++chronSeq; if (!by.has(histKey(r))) by.set(histKey(r), r); }
  for (const e of live) {
    const r = { t: e.t, s: ctrlStrip(e.s).slice(0, CHRON_S_CAP), at: CHRON_AT_OK.test(e.at) ? e.at : "", k: now };
    if (!r.s) continue;
    const old = by.get(histKey(r));
    if (old) { if (!old.at && r.at) old.at = r.at; } else { r.n = ++chronSeq; by.set(histKey(r), r); }
  }
  let rows = [...by.values()].filter((r) => histTs(r) >= now - CHRON_HIST_MS)
    .sort((a, b) => histTs(b) - histTs(a)).slice(0, CHRON_HIST_MAX);
  let json = "";
  try {
    json = JSON.stringify(rows);
    while (json.length > CHRON_HIST_BYTES && rows.length) { rows.pop(); json = JSON.stringify(rows); }
  } catch (e) { rows = []; }
  chronMem = rows;
  try { localStorage.setItem(CHRON_HIST_KEY, json || "[]"); } catch (e) { /* full or blocked: carry on in memory */ }
  try { localStorage.setItem(CHRON_SEQ_KEY, String(chronSeq)); } catch (e) {}
}
// the town's own voice for a day divider
function dayVoice(ts) {
  const d0 = new Date(); d0.setHours(0, 0, 0, 0);
  const d = new Date(ts); d.setHours(0, 0, 0, 0);
  const n = Math.round((d0 - d) / 86400000);
  return n <= 0 ? "Earlier today, by the bells" : n === 1 ? "Yesterday, as the town tells it" : "Two days gone, and not forgotten";
}

// ---- H21: the campaign journal. Episodes, filters, "while you were away", moment links.
// Everything below is page-local: state lives in this browser's localStorage under
// page-owned keys, every read is re-validated, and the only text that reaches the DOM
// from the snapshot or the history is the chronicle line / a hero name, via el() only.
// A moment link is "#moment-<n>" where n is an integer the PAGE assigned to a remembered
// line - no snapshot string is ever written into a URL, src, href or style.
const CHRON_DISASTER = /disaster|\bfire\b|burn|drought|famine|sickness|plague|hurricane|tornado|earthquake|meteor|scarstorm|flood|blight|volcano|cold ?snap/i;
const CHRON_FESTIVAL = /festival|\bfair\b|harvest|feast|celebrat|revel|tournament|carnival/i;
const CHRON_TOPICS = [
  { k: "all", label: "Every kind of event", test: () => true },
  { k: "raid", label: "Raids", test: (e) => e.t === "raid" || /\braid|bandit|siege/i.test(e.s) },
  { k: "disaster", label: "Disasters", test: (e) => CHRON_DISASTER.test(e.s) },
  { k: "festival", label: "Festivals", test: (e) => CHRON_FESTIVAL.test(e.s) },
  { k: "death", label: "Deaths", test: (e) => e.t === "death" },
  { k: "delve", label: "Delves", test: (e) => e.t === "delve" },
  { k: "growth", label: "Town growth", test: (e) => e.t === "town" || /grows into|town level|\bbuilt\b|raised/i.test(e.s) },
];
function chronFiltLoad() {
  try {
    const raw = localStorage.getItem(CHRON_F_KEY);
    if (!raw || raw.length > 4000) return;
    const f = JSON.parse(raw);
    if (!f || typeof f !== "object") return;
    chronHero = typeof f.h === "string" ? ctrlStrip(f.h).slice(0, 40) : "";
    chronTopic = CHRON_TOPICS.some((x) => x.k === f.t) ? f.t : "all";
    chronOff = new Set(arr(f.o).filter((k) => typeof k === "string" && /^[a-z0-9][a-z0-9 _-]{0,23}$/.test(k)).slice(0, 24));
  } catch (e) { /* unreadable: start unfiltered */ }
}
function chronFiltSave() {
  try { localStorage.setItem(CHRON_F_KEY, JSON.stringify({ h: chronHero, t: chronTopic, o: [...chronOff] })); } catch (e) {}
}
const CHRON_EP_GAP = 90 * 60000, CHRON_EP_SPAN = 6 * 3600000, CHRON_AWAY_MIN = 30 * 60000;
const plural = (n, one, many) => num(n) + " " + (n === 1 ? one : many);
// a one-line sense of a stretch, built only from page-owned words and counts
function chronSense(items) {
  const c = {}; let dis = 0, fes = 0;
  for (const e of items) { c[e.t] = (c[e.t] || 0) + 1; if (CHRON_DISASTER.test(e.s)) dis++; if (CHRON_FESTIVAL.test(e.s)) fes++; }
  const lead = c.death ? "A hard stretch" : dis ? "Trouble in the town" : c.raid ? "Steel at the gate" : fes ? "Merrymaking" : c.delve ? "Delvers in the dark" : c.town ? "The town changed" : "A quiet stretch";
  const parts = [];
  if (c.death) parts.push(plural(c.death, "death", "deaths"));
  if (c.raid) parts.push(plural(c.raid, "raid", "raids"));
  if (c.delve) parts.push(plural(c.delve, "delve", "delves"));
  if (c.town) parts.push(plural(c.town, "town report", "town reports"));
  if (dis) parts.push(plural(dis, "disaster line", "disaster lines"));
  if (fes) parts.push(plural(fes, "festival line", "festival lines"));
  return lead + (parts.length ? " - " + parts.join(", ") : "") + ".";
}
function chronRange(a, b) {   // a newest, b oldest
  const tm = (ts) => { try { return new Date(ts).toLocaleTimeString("en", { hour: "2-digit", minute: "2-digit" }); } catch (e) { return ""; } };
  const x = tm(b), y = tm(a);
  return x === y ? x : x + " \u2013 " + y;
}
function chronGapText(ms) {
  const m = Math.round(ms / 60000);
  if (m < 90) return plural(m, "minute", "minutes");
  const h = Math.round(m / 60);
  return h < 36 ? "about " + plural(h, "hour", "hours") : "about " + plural(Math.round(h / 24), "day", "days");
}
// ---- H21.3 while you were away
let chronAway = null, chronAwayDone = false, chronAwayDismissed = false, chronHiddenAt = 0;
function chronScore(e) {
  let s = e.t === "death" ? 5 : e.t === "raid" ? 4 : e.t === "town" ? 3 : e.t === "delve" ? 2 : 1;
  if (CHRON_DISASTER.test(e.s)) s += 3;
  if (CHRON_FESTIVAL.test(e.s)) s += 2;
  return s;
}
function chronAwayCompute(liveCount) {
  chronAwayDone = true;
  chronAway = null;
  const seen = chronSeenAtLoad, now = Date.now();
  if (!seen || now - seen < CHRON_AWAY_MIN) return;
  const rows = chronMem.map((r) => Object.assign(chronShape(r), { ts: histTs(r) }));
  const fresh = rows.filter((e) => e.ts > seen);
  const oldestMem = rows.length ? Math.min.apply(null, rows.map((e) => e.ts)) : now;
  const incomplete = now - seen > CHRON_HIST_MS
    || (liveCount >= CHRON_MAX && oldestMem > seen)
    || (rows.length >= CHRON_HIST_MAX && oldestMem > seen);
  chronAway = { gap: now - seen, fresh, incomplete };
}
function paintAway() {
  const box = $("chronAway");
  if (!box) return;
  box.replaceChildren();
  const a = chronAway;
  if (!a || chronAwayDismissed) { box.classList.add("hide"); return; }
  box.classList.remove("hide");
  const head = el("div", "away-head");
  head.append(el("strong", null, "While you were away"), el("span", "away-gap", chronGapText(a.gap) + " since you last looked"));
  const dis = el("button", "chip clear", "Dismiss");
  dis.type = "button";
  dis.addEventListener("click", () => { chronAwayDismissed = true; paintAway(); });
  head.append(dis);
  box.append(head);
  if (!a.fresh.length) {
    box.append(el("p", "away-sum", "Nothing new has been written since you last looked."));
  } else {
    const c = {};
    for (const e of a.fresh) c[e.t] = (c[e.t] || 0) + 1;
    const parts = [];
    if (c.death) parts.push(plural(c.death, "death", "deaths"));
    if (c.raid) parts.push(plural(c.raid, "raid", "raids"));
    if (c.delve) parts.push(plural(c.delve, "delve", "delves"));
    if (c.town) parts.push(plural(c.town, "town report", "town reports"));
    const top = a.fresh.map((e) => ({ e, s: chronScore(e) })).sort((x, y) => y.s - x.s || y.e.ts - x.e.ts).slice(0, 5)
      .sort((x, y) => y.e.ts - x.e.ts).map((x) => x.e);
    box.append(el("p", "away-sum", plural(a.fresh.length, "line", "lines") + " written" + (parts.length ? " - " + parts.join(", ") : "") +
      (a.fresh.length > top.length ? ". The ones that matter most:" : ".")));
    const ul = el("ul", "away-list");
    for (const e of top) {
      const li = el("li");
      const ag = ago(e.at);
      if (ag) li.append(el("span", "away-t", ag.text));
      li.append(document.createTextNode(e.s));      // viewer text: text node only
      ul.append(li);
    }
    box.append(ul);
  }
  box.append(el("p", "away-note", a.incomplete
    ? "The town reports only its latest " + CHRON_MAX + " lines and this browser keeps about two days, so part of that gap may be missing - this is a summary of what is here, not a full record."
    : "This is what the town's latest report and this browser's memory hold."));
}
function chronMarkSeen(force) {
  try { if (force || document.visibilityState !== "hidden") localStorage.setItem(CHRON_SEEN_KEY, String(Date.now())); } catch (e) {}
}
document.addEventListener("visibilitychange", () => {
  if (!chronAwayDone) return;
  if (document.visibilityState === "hidden") { chronHiddenAt = Date.now(); chronMarkSeen(true); return; }
  if (chronHiddenAt && Date.now() - chronHiddenAt >= CHRON_AWAY_MIN) {   // came back to a long-hidden tab
    chronSeenAtLoad = chronHiddenAt; chronAwayDone = false; chronAwayDismissed = false; chronAway = null;
  }
  chronHiddenAt = 0;
});
window.addEventListener("pagehide", () => { if (chronAwayDone) chronMarkSeen(true); });
// ---- H21.4 a moment you can point at
function momentLink(n, btn) {
  const flash = (m) => { btn.textContent = m; setTimeout(() => { btn.textContent = "Link"; }, 1800); };
  try { history.replaceState(null, "", "#moment-" + (n | 0)); } catch (e) {}
  try { navigator.clipboard.writeText(location.href).then(() => flash("Copied"), () => flash("In address bar")); } catch (e) { flash("In address bar"); }
}
// ---- H21.2 the tool row (hero + event selects). Names come from the snapshot roster and are
// written as option text via el(); the select's own value is only ever COMPARED, never rendered.
function chronToolsSync() {
  const sel = $("chronHero"), top = $("chronTopic"), clr = $("chronClear");
  if (top) top.value = chronTopic;
  if (sel) {
    const p = sheetPayload(), names = new Set();
    if (p) for (const h of arr(p.heroes).concat(arr(p.fallen))) { const n = cleanName(nameOf(h)); if (n) names.add(n); }
    if (chronHero) names.add(chronHero);
    const list = [...names].sort((a, b) => a.localeCompare(b)).slice(0, 400);
    const sig = chronHero + "\u0001" + list.join("\u0001");
    if (sig !== chronHeroSig) {              // leave an open dropdown alone when nothing changed
      chronHeroSig = sig;
      sel.replaceChildren();
      const all = el("option", null, "Every hero"); all.value = ""; sel.append(all);
      for (const n of list) { const o = el("option", null, n); o.value = n; sel.append(o); }
    }
    sel.value = chronHero;
  }
  if (clr) clr.classList.toggle("hide", !(chronHero || chronTopic !== "all" || chronOff.size || chronText.trim()));
}

// store the latest data and repaint. An AUTO refresh (from the 60 s poll) is held
// back while the viewer is reading the feed (pointer over it), so a busy moment
// does not reshuffle lines under them; the held update is applied when they leave.
// A user action (chip, search, clear) always paints at once.
function renderChronicle(raw, opts) {
  if (raw !== undefined) {
    chronData = raw;
    if (Array.isArray(raw)) {
      const le = chronEntries(raw);
      chronRemember(le);
      if (!chronAwayDone) chronAwayCompute(le.length);
      chronMarkSeen(false);
    }
  }
  const auto = opts && opts.auto;
  if (auto && chronHover && $("chronList").childElementCount) { chronPending = true; return; }
  chronPending = false;
  paintChronicle();
}

function paintChronicle() {
  const raw = chronData;
  const chips = $("chronChips"), list = $("chronList"), note = $("chronNote"), find = $("chronFind"), tools = $("chronTools");
  chips.replaceChildren();
  list.replaceChildren();
  const hasData = Array.isArray(raw);
  if (find) find.classList.toggle("hide", !hasData);
  if (tools) tools.classList.toggle("hide", !hasData);
  paintAway();
  if (!hasData) {
    note.textContent = "The chronicle will appear here once the town reports it.";
    note.className = "note quiet";
    return;
  }
  chronMemEnsure();
  if (chronFocusId != null) {     // a moment link: show everything so the line can be found
    chronHero = ""; chronTopic = "all"; chronOff = new Set(); chronText = ""; if (find) find.value = "";
  }
  chronToolsSync();
  const live = chronEntries(raw);
  const idByKey = new Map(chronMem.map((r) => [histKey(r), r.n]));
  const liveKeys = new Set(live.map(histKey));
  const now = Date.now();
  for (const e of live) { const t = Date.parse(e.at); e.ts = isFinite(t) ? t : now; e.n = idByKey.get(histKey(e)) || 0; }
  const rem = chronMem.filter((r) => !liveKeys.has(histKey(r)))
    .map((r) => Object.assign(chronShape(r), { rem: true, ts: histTs(r), n: r.n || 0 }));
  const entries = live.concat(rem).sort((x, y) => y.ts - x.ts);
  if (!entries.length) {
    note.textContent = "Nothing has been written in the chronicle yet.";
    note.className = "note quiet";
    return;
  }

  // one chip per kind actually present: known kinds first (canonical order), then
  // any novel kinds the game published, alphabetically.
  const seen = new Map();   // key -> {key, label, icon, count}
  for (const e of entries) {
    const g = seen.get(e.t) || { t: e.t, key: e.key, icon: e.icon, label: e.known ? CHRON_KINDS.find((k) => k.t === e.t).label : e.label, count: 0 };
    g.count++; seen.set(e.t, g);
  }
  const order = CHRON_KINDS.filter((k) => seen.has(k.t)).map((k) => seen.get(k.t))
    .concat([...seen.values()].filter((g) => !CHRON_ICON.has(g.t)).sort((a, b) => a.label.localeCompare(b.label)));
  for (const g of order) {
    const on = !chronOff.has(g.t);
    const c = el("button", "chip kind-" + g.key + (on ? " on" : ""));
    c.type = "button";
    c.setAttribute("aria-pressed", on ? "true" : "false");
    c.append(icon(g.icon, "chipic"), document.createTextNode(g.label), el("span", "cnt", g.count));
    c.addEventListener("click", () => { if (chronOff.has(g.t)) chronOff.delete(g.t); else chronOff.add(g.t); chronFiltSave(); paintChronicle(); });
    chips.append(c);
  }
  if (chronOff.size) {
    const clear = el("button", "chip clear", "Show all kinds");
    clear.type = "button";
    clear.addEventListener("click", () => { chronOff.clear(); chronFiltSave(); paintChronicle(); });
    chips.append(clear);
  }

  const q = chronText.trim().toLowerCase();
  const hkey = chronHero.trim().toLowerCase();
  const topic = CHRON_TOPICS.find((x) => x.k === chronTopic) || CHRON_TOPICS[0];
  const pass = (e) => !chronOff.has(e.t) && (!q || e.s.toLowerCase().includes(q)) && (!hkey || namesIn(e.s, hkey)) && topic.test(e);
  const anyFilter = !!(q || hkey || chronOff.size || chronTopic !== "all");
  const shownAll = entries.filter(pass);
  if (!shownAll.length) {
    note.className = "note quiet";
    note.textContent = q ? "No entries match \u201c" + q + "\u201d" + (chronOff.size ? " in the kinds shown." : ".")
      : (hkey || chronTopic !== "all") ? "Nothing in the journal matches that hero and event."
      : "Every kind is switched off - tap a chip to bring the chronicle back.";
    return;
  }

  // ---- H21.1 episodes: stretches split by a long quiet gap or by length
  const eps = [];
  for (const e of entries) {
    const cur = eps[eps.length - 1];
    if (cur && cur.last - e.ts <= CHRON_EP_GAP && cur.first - e.ts <= CHRON_EP_SPAN) { cur.items.push(e); cur.last = e.ts; }
    else eps.push({ first: e.ts, last: e.ts, items: [e] });
  }
  let drawn = 0, sawEarlier = false;
  for (const ep of eps) {
    const items = ep.items.filter(pass);
    if (!items.length) continue;
    const hasLive = ep.items.some((e) => !e.rem);
    const key = "e" + ep.last;
    const focusIn = chronFocusId != null && ep.items.some((e) => e.n === chronFocusId);
    const dflt = drawn === 0 || anyFilter;     // the newest stretch (or any filter hit) is open; older ones fold
    let open = focusIn ? true : (chronOpen.has(key) ? chronOpen.get(key) : dflt);
    if (!hasLive && !sawEarlier) { sawEarlier = true; list.append(el("li", "cdiv cdiv-earlier", "Earlier")); }
    const li = el("li", "cep" + (open ? " open" : ""));
    const hid = "cep-" + drawn;
    const head = el("button", "cep-head");
    head.type = "button";
    head.setAttribute("aria-expanded", open ? "true" : "false");
    head.setAttribute("aria-controls", hid);
    head.append(el("span", "cep-title", drawn === 0 && now - ep.first < CHRON_EP_GAP ? "Now, as the town tells it" : dayVoice(ep.first)),
      el("span", "cep-when", chronRange(ep.first, ep.last) + " \u00b7 " + plural(items.length, "line", "lines")),
      el("span", "cep-sense", chronSense(items)));
    const body = el("ol", "cep-list");
    body.id = hid;
    body.hidden = !open;
    head.addEventListener("click", () => {
      open = !open;
      chronOpen.set(key, open);
      li.classList.toggle("open", open);
      head.setAttribute("aria-expanded", open ? "true" : "false");
      body.hidden = !open;
    });
    drawn++;
    li.append(head, body);
    for (const e of items) {
      const row = el("li", "centry kind-" + e.key + (e.rem ? " remembered" : "") + (e.n && e.n === chronFocusKeep ? " focus" : ""));
      if (e.n) row.id = "moment-" + e.n;           // an integer the page assigned
      const badge = el("span", "cbadge");
      badge.setAttribute("aria-hidden", "true");
      badge.append(icon(e.icon));                 // whitelisted glyph id
      row.append(badge);
      const cb = el("div", "cbody");
      const ch = el("div", "chead");
      ch.append(el("span", "ckind", e.label));    // textContent; a novel kind shows its own name, escaped
      const a = ago(e.at);
      if (a) {
        const time = el("time", "cwhen", a.text);
        time.dateTime = e.at;
        time.title = when(e.at);
        ch.append(time);
      }
      if (e.n) {
        const lk = el("button", "cmoment", "Link");
        lk.type = "button";
        lk.title = "Link to this moment (opens on this line in a browser that remembers it)";
        lk.setAttribute("aria-label", "Copy a link to this moment");
        lk.addEventListener("click", () => momentLink(e.n, lk));
        ch.append(lk);
      }
      cb.append(ch, el("p", "cline", e.s));       // viewer text: textContent
      row.append(cb);
      body.append(row);
    }
    list.append(li);
  }
  note.className = "note";
  note.textContent = (shownAll.length === entries.length
    ? entries.length + (entries.length === 1 ? " entry" : " entries")
    : "Showing " + shownAll.length + " of " + entries.length) + ", newest first, in " + plural(drawn, "stretch", "stretches") +
    (drawn > 1 ? " - tap one to fold or open it." : ".");
  if (chronFocusId != null) {
    const target = document.getElementById("moment-" + chronFocusId);   // id built from an integer we own
    chronFocusId = null;
    if (target) { chronFocusKeep = +target.id.slice(7) || 0; target.classList.add("focus"); try { target.scrollIntoView({ block: "center" }); } catch (e) {} }
    else { note.className = "note quiet"; note.textContent = "That moment is no longer in this browser's memory - it keeps only about two days of the chronicle."; }
  }
}

// ============================================================ COMMANDS
const FALLBACK_CMDS = { order: ["enlist", "hero", "delve", "help"], commands: {
  enlist: { args: "[class] [people]", short: "Raise your hero: a calling and a people, either order.", example: "!enlist knight dwarf" },
  hero: { short: "Your hero's sheet.", example: "!hero" },
  delve: { short: "Go down into the scar with your hero.", example: "!delve" },
  help: { args: "[command]", short: "The command list; !help <command> for one in detail.", example: "!help forge" } } };

function renderCommands(c) {
  const src = c && c.commands && Object.keys(c.commands).length ? c : FALLBACK_CMDS;
  const cs = src.commands;
  const order = arr(src.order).filter((k) => cs[k]).concat(Object.keys(cs).filter((k) => !arr(src.order).includes(k)));
  const box = $("cmdList");
  box.replaceChildren();
  for (const k of order) {
    const d = cs[k] || {};
    const det = el("details", "cmd");
    const sum = el("summary");
    const nm = el("span", "cname", "!" + k);        // k is a command key, not viewer text, but still textContent
    sum.append(nm);
    if (d.args) sum.append(el("span", "cargs", d.args));   // the <colour> canary: textContent keeps the brackets literal
    sum.append(el("span", "cshort", d.short || d.what || ""));
    det.append(sum);
    const body = el("div", "cbody2");
    if (d.what && d.what !== d.short) body.append(el("div", null, d.what));
    if (d.cost) { const r = el("div"); r.append(el("b", null, "Cost: "), document.createTextNode(String(d.cost))); body.append(r); }
    if (d.needs_hero) body.append(el("div", null, "Needs a living hero."));
    if (arr(d.aliases).length) {
      const al = el("div", null, "Also: ");
      d.aliases.forEach((a, i) => { if (i) al.append(document.createTextNode(" ")); al.append(el("code", null, "!" + a)); });
      body.append(al);
    }
    if (d.example) { const r = el("div"); r.append(document.createTextNode("Try: "), el("code", null, d.example)); body.append(r); }
    det.append(body);
    box.append(det);
  }
}

// ============================================================ THE DIE
// A true CSS 3D icosahedron. The value is chosen first (crypto.getRandomValues
// with rejection sampling so all twenty faces are equally likely), then the die
// is thrown, tumbles, and settles with the rolled face square to the camera -
// it lands on the number the page reports, never near it. No network, no tie to
// the game's dice. Honours prefers-reduced-motion. Research: web/NOTES.md.

// The face geometry is generated by web/tools/gen_d20.py (committed) so it can be
// rebuilt and checked rather than trusted. D20_FACES: [value, the 16-value
// matrix3d that turns that face to the camera].
// ---- BEGIN generated by web/tools/gen_d20.py - do not hand-edit ----
const D20_FACES = [

  [1, [0.0,-0.35682,-0.93417,0,0.0,0.93417,-0.35682,0,1.0,0.0,0.0,0,0,0,0,1]],
  [2, [0.0,0.35682,-0.93417,0,0.0,0.93417,0.35682,0,1.0,-0.0,0.0,0,0,0,0,1]],
  [3, [0.30902,-0.75576,-0.57735,0,-0.80902,0.11026,-0.57735,0,0.5,0.6455,-0.57735,0,0,0,0,1]],
  [4, [0.30902,0.75576,-0.57735,0,0.80902,0.11026,0.57735,0,0.5,-0.6455,-0.57735,0,0,0,0,1]],
  [5, [0.80902,-0.46709,-0.35682,0,-0.5,-0.86603,0.0,0,-0.30902,0.17841,-0.93417,0,0,0,0,1]],
  [6, [0.30902,0.75576,-0.57735,0,-0.80902,-0.11026,-0.57735,0,-0.5,0.6455,0.57735,0,0,0,0,1]],
  [7, [0.30902,-0.75576,-0.57735,0,0.80902,-0.11026,0.57735,0,-0.5,-0.6455,0.57735,0,0,0,0,1]],
  [8, [0.80902,0.46709,-0.35682,0,-0.5,0.86603,0.0,0,0.30902,0.17841,0.93417,0,0,0,0,1]],
  [9, [0.5,0.86603,0.0,0,0.30902,-0.17841,-0.93417,0,-0.80902,0.46709,-0.35682,0,0,0,0,1]],
  [10, [0.5,-0.86603,0.0,0,0.30902,0.17841,-0.93417,0,0.80902,0.46709,0.35682,0,0,0,0,1]],
  [11, [0.5,-0.86603,0.0,0,-0.30902,-0.17841,0.93417,0,-0.80902,-0.46709,-0.35682,0,0,0,0,1]],
  [12, [0.5,0.86603,0.0,0,-0.30902,0.17841,0.93417,0,0.80902,-0.46709,0.35682,0,0,0,0,1]],
  [13, [0.0,0.93417,0.35682,0,1.0,-0.0,0.0,0,0.0,0.35682,-0.93417,0,0,0,0,1]],
  [14, [0.5,-0.6455,0.57735,0,-0.30902,-0.75576,-0.57735,0,0.80902,0.11026,-0.57735,0,0,0,0,1]],
  [16, [0.0,-0.93417,0.35682,0,1.0,0.0,0.0,0,0.0,0.35682,0.93417,0,0,0,0,1]],
  [17, [0.5,0.6455,0.57735,0,-0.30902,0.75576,-0.57735,0,-0.80902,0.11026,0.57735,0,0,0,0,1]],
  [15, [0.5,0.6455,0.57735,0,0.30902,-0.75576,0.57735,0,0.80902,-0.11026,-0.57735,0,0,0,0,1]],
  [18, [0.5,-0.6455,0.57735,0,0.30902,0.75576,0.57735,0,-0.80902,-0.11026,0.57735,0,0,0,0,1]],
  [19, [0.30902,0.17841,0.93417,0,0.80902,0.46709,-0.35682,0,-0.5,0.86603,0.0,0,0,0,0,1]],
  [20, [0.30902,-0.17841,0.93417,0,-0.80902,0.46709,0.35682,0,-0.5,-0.86603,0.0,0,0,0,0,1]],
];
// ---- END generated ----

function rollD20() {
  const b = new Uint8Array(1);
  for (let i = 0; i < 64; i++) {
    crypto.getRandomValues(b);
    if (b[0] < 240) return (b[0] % 20) + 1;      // 240 = 12 x 20, so 1..20 are equally likely
  }
  crypto.getRandomValues(b);
  return (b[0] % 20) + 1;
}

// build the twenty triangular faces once, each carrying its number
function buildDie() {
  const cage = $("d20cage");
  if (!cage || cage.childElementCount) return;
  // each face's placement is carried by its .fN class in style.css (generated by
  // the same tool); here we only attach its number. No inline transform needed.
  D20_FACES.forEach(([value], idx) => {
    const face = el("span", "d20face f" + idx);
    face.append(el("span", "pip", value));
    cage.append(face);
  });
}

// the resting rotation that brings a given value's face to the camera
function restFor(value) {
  const found = D20_FACES.find(([v]) => v === value);
  return found ? found[1] : D20_FACES[0][1];
}

const D20_HIST = 10;
let d20hist = [];
let d20busy = false;
let d20spins = 0;

function d20Verdict(v) {
  if (v === 20) return "A natural twenty. The hall roars.";
  if (v === 1) return "A one. The hall goes quiet.";
  if (v >= 15) return "A strong roll.";
  if (v >= 8) return "A fair roll.";
  return "A poor roll.";
}

function paintHist() {
  const box = $("d20hist");
  box.replaceChildren();
  if (!d20hist.length) { box.append(el("li", "empty", "Nothing rolled yet.")); return; }
  for (const v of d20hist) box.append(el("li", "hroll" + (v === 20 ? " crit" : v === 1 ? " crat" : ""), v));
}


function setUpDie() {
  const btn = $("d20"), cage = $("d20cage"), say = $("d20result");
  if (!btn || !cage) return;
  buildDie();
  const calm = matchMedia("(prefers-reduced-motion: reduce)").matches;

  // settle on 20 at rest, before the first roll, so the die reads as a die
  cage.style.transform = "matrix3d(" + restFor(20).join(",") + ")";
  paintHist();

  btn.addEventListener("click", () => {
    if (d20busy) return;
    d20busy = true;
    const value = rollD20();
    btn.classList.remove("crit", "crat", "land");
    say.textContent = "Rolling…";

    const settle = () => {
      d20spins += 2;
      const base = "matrix3d(" + restFor(value).join(",") + ")";
      cage.style.transform = calm ? base
        : `rotateX(${d20spins * 360}deg) rotateY(${d20spins * 360}deg) ${base}`;
    };

    if (calm) {
      settle();
      finish();
    } else {
      btn.classList.add("rolling");
      // let the tumble run, then settle onto the face and flourish
      setTimeout(() => {
        btn.classList.remove("rolling");
        settle();
        setTimeout(finish, 650);                   // matches the settle transition
      }, 520);
    }

    function finish() {
      btn.classList.add("land");
      btn.classList.toggle("crit", value === 20);
      btn.classList.toggle("crat", value === 1);
      say.textContent = value + " · " + d20Verdict(value);
      d20hist.unshift(value);
      if (d20hist.length > D20_HIST) d20hist.length = D20_HIST;
      paintHist();
      d20busy = false;
    }
  });
}
setUpDie();

// ---------------------------------------------------------------- the town's rolls (H9)
// The d20 is resolved IN THE GAME: a viewer spends channel points or bits, the game
// rolls and applies the outcome (T5). The result rides the 60 s snapshot as p.rolls
// (newest first) and shows here. This page only DISPLAYS it - it never initiates or
// submits a roll, so the hub stays read-only (docs/HUB_SECURITY.md). Forward-
// compatible, exactly like the hero HP/XP bars: the section lights up the day the
// publisher sends the field and shows an honest empty state until then. It invents
// no roll and never derives an outcome from the number.
//
// CONTRACT (also in web/NOTES.md). Each entry is an object; every field optional and
// defended. Canonical key, then accepted aliases:
//   n      1..20, the face rolled     (roll, d20, face, value)
//   by     the roller's display name  (who, name, viewer)      - viewer text
//   what   what was attempted         (title, proposition, action) - viewer text
//   tier   outcome band: crit|good|mixed|bad|fumble (aliases in TIER_ALIAS)
//   result the plain-language outcome (s, text, line)          - viewer text
//   cost   what was spent, e.g. "500 channel points" (spent)
//   at     ISO timestamp              (time)
// Every string reaches the DOM only through el()/textContent; `tier` only ever picks
// a whitelisted CSS class; no field is ever used as a URL/src/href/style.
const ROLL_FEED_MAX = 30;
const TIER = {
  crit:   { label: "Triumph" },
  good:   { label: "It goes well" },
  mixed:  { label: "A mixed result" },
  bad:    { label: "It goes badly" },
  fumble: { label: "A fumble" },
};
const TIER_ALIAS = {
  crit: "crit", critical: "crit", triumph: "crit", nat20: "crit",
  good: "good", success: "good", great: "good", pass: "good", win: "good",
  mixed: "mixed", partial: "mixed", neutral: "mixed",
  bad: "bad", fail: "bad", failure: "bad", backfire: "bad", loss: "bad",
  fumble: "fumble", botch: "fumble", disaster: "fumble", nat1: "fumble",
};
function rollFaceOf(r) {
  const v = pickNum(r.n, r.roll, r.d20, r.face, r.value);
  return (v != null && v >= 1 && v <= 20) ? Math.round(v) : null;
}
function rollTierOf(r) {
  const raw = String(r.tier ?? r.band ?? r.result_tier ?? "").toLowerCase().trim();
  return TIER_ALIAS[raw] || null;          // unknown or absent -> no tier claimed
}
function firstStr(...vals) { for (const v of vals) if (v != null && String(v).trim() !== "") return String(v); return ""; }

function normalizeRolls(raw) {
  return arr(raw)
    .filter((r) => r && typeof r === "object")
    .map((r) => ({
      face: rollFaceOf(r),
      by: firstStr(r.by, r.who, r.name, r.viewer).slice(0, 40),
      what: firstStr(r.what, r.title, r.proposition, r.action).slice(0, 180),
      result: firstStr(r.result, r.s, r.text, r.line).slice(0, 400),
      cost: firstStr(r.cost, r.spent).slice(0, 60),
      tier: rollTierOf(r),
      at: typeof r.at === "string" ? r.at : (typeof r.time === "string" ? r.time : ""),
    }))
    .filter((r) => r.face != null || r.result || r.what)   // drop entries with nothing to show
    .slice(0, ROLL_FEED_MAX);   // cap AFTER dropping empties, so a padded publisher array still fills the feed
}

// throw the die to a KNOWN value and settle on that face. Used by the town-roll
// display (H9); it never chooses the value and never contacts anything. A standalone
// twin of the viewer-tap animation, sharing the d20busy guard so the two never fight.
function throwDie(value, done) {
  const btn = $("d20"), cage = $("d20cage");
  if (!btn || !cage) { if (done) done(); return; }
  d20busy = true;
  btn.classList.remove("crit", "crat", "land");
  const calm = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const settle = () => {
    d20spins += 2;
    const base = "matrix3d(" + restFor(value).join(",") + ")";
    cage.style.transform = calm ? base
      : `rotateX(${d20spins * 360}deg) rotateY(${d20spins * 360}deg) ${base}`;
  };
  const finish = () => {
    btn.classList.add("land");
    btn.classList.toggle("crit", value === 20);
    btn.classList.toggle("crat", value === 1);
    d20busy = false;
    if (done) done();
  };
  if (calm) { settle(); finish(); }
  else {
    btn.classList.add("rolling");
    setTimeout(() => { btn.classList.remove("rolling"); settle(); setTimeout(finish, 650); }, 520);
  }
}

let lastRollKey = null;      // internal only (never written to the DOM): detects a new top roll
function rollKey(r) { return JSON.stringify([r.at, r.by, r.face, r.result]); }

// one entry in the rolls feed. Mirrors a chronicle row: a die-face badge, a head
// (who / what / tier / when) and the plain-language outcome line.
function rollEntry(r) {
  const li = el("li", "rentry" + (r.tier ? " tier-" + r.tier : "")
    + (r.face === 20 ? " crit" : r.face === 1 ? " crat" : ""));
  const face = el("span", "rface");
  face.setAttribute("aria-hidden", "true");
  face.append(el("span", "rfacen", r.face != null ? r.face : "\u00b7"));
  li.append(face);
  const body = el("div", "rbody");
  const head = el("div", "rhead");
  head.append(el("span", "rby", r.by || "A viewer"));          // viewer text: textContent
  if (r.what) head.append(el("span", "rwhat", r.what));
  if (r.tier) head.append(el("span", "rtier rt-" + r.tier, TIER[r.tier].label));  // whitelisted class
  const a = ago(r.at);
  if (a) { const time = el("time", "rwhen", a.text); time.dateTime = r.at; time.title = when(r.at); head.append(time); }
  body.append(head);
  if (r.cost) body.append(el("span", "rcost", r.cost));
  if (r.result) body.append(el("p", "rline", r.result));
  li.append(body);
  return li;
}

// announce the latest town roll on the shared die. On first sight, a busy die, or
// reduced motion, it just settles to the face; a genuinely new roll tumbles to it.
function announceTownRoll(r, first) {
  const say = $("d20result"), cage = $("d20cage"), btn = $("d20");
  const calm = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const setText = () => {
    if (!say) return;
    say.replaceChildren();
    say.append(el("b", null, String(r.face)));
    say.append(document.createTextNode(" \u00b7 " + (r.by ? r.by + "\u2019s roll for the town" : "the town\u2019s roll")));
    if (r.tier) { say.append(document.createTextNode(" \u2014 ")); say.append(el("span", "rt rt-" + r.tier, TIER[r.tier].label)); }
  };
  if (first || d20busy || calm) {
    if (cage && !d20busy) cage.style.transform = "matrix3d(" + restFor(r.face).join(",") + ")";
    if (btn && !d20busy) { btn.classList.remove("rolling"); btn.classList.toggle("crit", r.face === 20); btn.classList.toggle("crat", r.face === 1); }
    setText();
  } else {
    if (say) say.textContent = "The town rolls\u2026";
    throwDie(r.face, setText);
  }
}

function renderRolls(raw) {
  const feed = $("rollFeed"), note = $("rollNote");
  if (!feed || !note) return;
  const rolls = normalizeRolls(raw);
  feed.replaceChildren();
  if (!rolls.length) {
    lastRollKey = null;     // so the next real roll animates fresh
    note.className = "note quiet";
    note.textContent = "No rolls from the town yet. When a viewer spends channel points or bits to roll the die for the town \u2014 to pass a law, set off an event or raise a building \u2014 the roll and how it turns out appear here. The die is thrown in the game; this page only reports it.";
    return;
  }
  for (const r of rolls) feed.append(rollEntry(r));
  note.className = "note";
  note.textContent = rolls.length + (rolls.length === 1 ? " roll" : " rolls") + " from the town, newest first. The die above shows the latest.";
  const top = rolls[0];
  const key = rollKey(top);
  if (key !== lastRollKey) {
    const first = lastRollKey === null;
    lastRollKey = key;
    if (top.face != null) announceTownRoll(top, first);
  }
}

// ---------------------------------------------------------------- problem state
function showProblem(msg) {
  const box = $("nothing");
  if (box) {
    box.classList.remove("hide");
    box.replaceChildren();
    box.append(el("h2", null, "This page needs an update"), el("p", null, msg));
  }
  for (const id of SECTIONS.concat(["commands"])) { const e = $(id); if (e && id !== "dice") e.classList.add("hide"); }
  const st = $("status");
  if (st) { st.className = "status bad"; st.textContent = "Showing nothing rather than guessing."; }
}

// ---------------------------------------------------------------- Guild chat (H8)
// Twitch chat, NATIVELY - no iframe. The old embed (H5) was broken for any viewer
// whose browser blocks third-party cookies (Brave, Safari, strict Chrome - most of
// them now): Twitch's page inside the frame could never keep its login, so the
// input stayed dead. Mr. E hit this live on Brave, Nov 12. So the hub now speaks
// Twitch's own chat protocol (IRC over WebSocket) itself:
//   READ - anonymously, for everyone, no login and no cookies at all.
//   SEND - with the viewer's own sign-in token (H6), whose grant now carries the
//          two chat scopes. The message goes to Twitch; still nothing to OUR backend.
// Opt-in is kept: nothing contacts Twitch until the viewer opens the chat.
// SECURITY (docs/HUB_SECURITY.md, H8): every incoming line is attacker-controlled
// viewer text and reaches the DOM only through el()/textContent. No wire value is
// ever used as a URL, style, selector or markup; name colours are a fixed page
// palette chosen by hash. Outgoing text strips CR/LF and control characters so a
// message can never smuggle an IRC command. The socket host is a hard-coded
// constant. Messages render as plain text - no emote images, by design.
const TWITCH_CHANNEL = "jestsayin96";          // Mr. E's channel - a constant, never a runtime value
const TW_IRC = "wss://irc-ws.chat.twitch.tv:443";   // constant; never from any runtime value
const CHAT_MAX = 150;                               // lines kept on screen
let chatWS = null, chatTries = 0, chatTimer = null, chatOpened = false, chatLastSend = 0;

function ctrlStrip(s) { return String(s ?? "").replace(/[\u0000-\u001f\u007f]/g, " ").trim(); }
function chatStatus(text, cls) {
  const st = $("chatStatus"); if (!st) return;
  st.className = "chatstatus" + (cls ? " " + cls : "");
  st.textContent = text;                            // page-authored or stripped wire text; textContent regardless
}
function chatColor(name) {                          // fixed palette by hash - never a wire colour value
  let h = 0; for (const c of String(name)) h = (h * 31 + c.codePointAt(0)) >>> 0;
  return "cc" + (h % 6);
}
function chatLine(name, text, cls, mid, user) {
  const list = $("chatList"); if (!list) return;
  const li = el("li", "cl" + (cls ? " " + cls : ""));
  // data-* values are inert attribute text (never parsed as markup); lookups below
  // iterate and compare strings - no selector is ever built from wire data.
  if (mid) li.dataset.mid = mid;
  // moderation (CLEARCHAT) names the LOGIN, so that - not the display-name - is the match key
  if (user) li.dataset.user = String(user).toLowerCase();
  if (name) li.append(el("b", "cn " + chatColor(name), name));
  li.append(el("span", "ct", text));
  const pinned = list.scrollHeight - list.scrollTop - list.clientHeight < 48;
  list.append(li);
  while (list.childElementCount > CHAT_MAX) list.firstElementChild.remove();
  if (pinned) list.scrollTop = list.scrollHeight;
}
function parseIrcTags(s) {
  const out = {};
  for (const kv of s.split(";")) {
    const eq = kv.indexOf("="); if (eq === -1) { out[kv] = ""; continue; }
    out[kv.slice(0, eq)] = kv.slice(eq + 1).replace(/\\(.)/g, (_, c) =>
      c === "s" ? " " : c === "n" ? "\n" : c === "r" ? "\r" : c === ":" ? ";" : c);
  }
  return out;
}
function chatHandle(raw) {
  if (raw.startsWith("PING")) { if (chatWS && chatWS.readyState === 1) chatWS.send("PONG :tmi.twitch.tv"); return; }
  let rest = raw, tags = {};
  if (rest.startsWith("@")) { const sp = rest.indexOf(" "); if (sp === -1) return; tags = parseIrcTags(rest.slice(1, sp)); rest = rest.slice(sp + 1); }
  let prefix = "";
  if (rest.startsWith(":")) { const sp = rest.indexOf(" "); if (sp === -1) return; prefix = rest.slice(1, sp); rest = rest.slice(sp + 1); }
  const sp = rest.indexOf(" ");
  const cmd = sp === -1 ? rest : rest.slice(0, sp);
  const paramsRaw = sp === -1 ? "" : rest.slice(sp + 1);
  let trailing = "";
  if (paramsRaw.startsWith(":")) trailing = paramsRaw.slice(1);
  else { const c = paramsRaw.indexOf(" :"); if (c !== -1) trailing = paramsRaw.slice(c + 2); }
  const nick = prefix.split("!")[0];
  if (cmd === "PRIVMSG") {
    const action = /^\u0001ACTION (.*)\u0001$/.exec(trailing);     // "/me does a thing"
    const text = ctrlStrip(action ? action[1] : trailing);
    const name = ctrlStrip(tags["display-name"] || nick) || "someone";
    if (text) chatLine(name, text, action ? "sys" : "", ctrlStrip(tags.id || ""), nick);
  } else if (cmd === "NOTICE") {
    const t = ctrlStrip(trailing); if (t) chatLine("", t, "sys");   // e.g. "You are sending messages too quickly"
  } else if (cmd === "USERNOTICE") {
    const sm = ctrlStrip(tags["system-msg"] || ""); if (sm) chatLine("", sm, "sys");
  } else if (cmd === "CLEARCHAT") {
    const list = $("chatList"); if (!list) return;
    const who = ctrlStrip(trailing).toLowerCase();
    if (who) { for (const li of [...list.children]) if (li.dataset.user === who) li.remove(); }
    else list.replaceChildren();
  } else if (cmd === "CLEARMSG") {
    const id = ctrlStrip(tags["target-msg-id"] || ""); const list = $("chatList");
    if (id && list) for (const li of [...list.children]) if (li.dataset.mid === id) li.remove();
  } else if (cmd === "RECONNECT") { chatConnect(); }
}
function chatInputState() {
  const inp = $("chatInput"), btn = $("chatSend"); if (!inp || !btn) return;
  const authed = !!(twToken && twLogin);
  const up = chatWS && chatWS.readyState === 1;
  inp.disabled = btn.disabled = !(authed && up);
  inp.placeholder = authed ? (up ? "Say something to the town…" : "Connecting…")
                           : "Sign in with Twitch (under Heroes) to talk — reading needs nothing.";
}
function chatConnect() {
  if (MOCK === "chat") return;                       // the mock feeds chatHandle directly
  if (chatWS) { try { chatWS.onclose = null; chatWS.close(); } catch (e) {} chatWS = null; }
  const authed = !!(twToken && twLogin);
  let ws;
  try { ws = new WebSocket(TW_IRC); } catch (e) { chatRetry(); return; }
  chatWS = ws;
  chatStatus("Reaching the guild hall…");
  ws.onopen = () => {
    chatTries = 0;
    ws.send("CAP REQ :twitch.tv/tags twitch.tv/commands");
    if (authed) { ws.send("PASS oauth:" + twToken); ws.send("NICK " + twLogin); }
    else ws.send("NICK justinfan" + (10000 + Math.floor(Math.random() * 80000)));
    ws.send("JOIN #" + TWITCH_CHANNEL);
    chatStatus(authed ? "In the hall as " + twLogin + "." : "Reading the channel's chat. Sign in under Heroes to talk.", authed ? "ok" : "");
    chatInputState();
  };
  ws.onmessage = (ev) => { for (const line of String(ev.data).split("\r\n")) if (line) chatHandle(line); };
  ws.onclose = () => { chatWS = null; chatInputState(); chatRetry(); };
}
function chatRetry() {
  if (!chatOpened) return;
  clearTimeout(chatTimer);
  const wait = Math.min(30000, 2000 * Math.pow(2, Math.min(chatTries++, 4)));
  chatStatus("Chat lost its footing — trying again shortly.", "bad");
  chatTimer = setTimeout(chatConnect, wait);
}
function chatSend() {
  const inp = $("chatInput"); if (!inp) return;
  const text = ctrlStrip(inp.value).slice(0, 450);   // CR/LF stripped: no IRC command smuggling
  if (!text) return;
  if (!(twToken && twLogin)) { chatStatus("Sign in with Twitch (under Heroes) to talk here.", "warn"); return; }
  if (!chatWS || chatWS.readyState !== 1) { chatStatus("Not connected just now — one moment.", "warn"); return; }
  const now = Date.now();
  if (now - chatLastSend < 1200) { chatStatus("Easy — one message a breath.", "warn"); return; }
  chatLastSend = now;
  chatWS.send("PRIVMSG #" + TWITCH_CHANNEL + " :" + text);
  chatLine(twLogin, text, "me", "", twLogin);        // Twitch does not echo your own line back
  inp.value = "";
}
function openGuildChat() {
  if (chatOpened) return;
  chatOpened = true;
  const btn = $("chatLoad"); if (btn) btn.classList.add("hide");
  const panel = $("chatPanel"); if (panel) panel.classList.remove("hide");
  if (MOCK === "chat") {                             // local check: the hostile name must render as text
    const H = "<img src=x onerror=alert(1)>";
    const Htag = H.replace(/ /g, "\\s");          // IRCv3 tag escaping, as the real wire would carry it
    chatHandle("@id=m1;display-name=Brum :brum!brum@brum.tmi.twitch.tv PRIVMSG #" + TWITCH_CHANNEL + " :A health to the guild!");
    chatHandle("@id=m2;display-name=" + Htag + " :evil!evil@evil.tmi.twitch.tv PRIVMSG #" + TWITCH_CHANNEL + " :" + H);
    chatHandle(":tmi.twitch.tv NOTICE #" + TWITCH_CHANNEL + " :A notice from the hall, rendered as text.");
    chatStatus("Mock chat — nothing is connected.", "");
    chatInputState();
    return;
  }
  chatConnect();
}
(function () {
  const btn = $("chatLoad"); if (btn) btn.addEventListener("click", openGuildChat);
  const send = $("chatSend"); if (send) send.addEventListener("click", chatSend);
  const inp = $("chatInput");
  if (inp) inp.addEventListener("keydown", (e) => { if (e.key === "Enter") { e.preventDefault(); chatSend(); } });
})();

// ---------------------------------------------------------------- Twitch sign-in (H6)
// Device-code OAuth. A viewer signs in so the page can spotlight THEIR hero and, if
// they choose, talk in the guild chat (H8) as themselves. The token is the viewer's
// own, held in memory only (never localStorage), never sent to our backend, and used
// for exactly two things: reading their own Twitch login, and sending THEIR chat
// lines to Twitch when THEY press send. No write to our backend, ever.
//
// LIVE: TWITCH_CLIENT_ID is Mr. E's registered public client id (Bellmire Hub Login),
// baked in as a const and not overridable at runtime. Clicking the button runs the
// device grant below (per the Twitch docs); nothing contacts Twitch before the click.
// The empty-id branch in twitchSignIn() is kept as a defensive fallback only.
const TWITCH_CLIENT_ID = "mpblygfdxvdpnr0dvi3andjlvb4y0r";  // Bellmire Hub Login: PUBLIC client, device-code grant, chat scopes only. Not overridable at runtime.
const TW_DEVICE = "https://id.twitch.tv/oauth2/device";
const TW_TOKEN = "https://id.twitch.tv/oauth2/token";
const TW_USERS = "https://api.twitch.tv/helix/users";
const TW_SCOPES = "chat:read chat:edit";         // the guild chat (H8) and nothing more; was "" before H8
let twToken = null;                              // in memory only, this session only
let twLogin = null;                              // the signed-in viewer's own login, memory only
let twPolling = false;

function signinSay(html, cls) {
  const box = $("signinState");
  if (!box) return;
  box.className = "signinstate" + (cls ? " " + cls : "");
  box.replaceChildren();
  if (typeof html === "string") { box.append(document.createTextNode(html)); return; }
  for (const n of html) box.append(n);
}

async function twitchSignIn() {
  if (twPolling) return;
  if (!TWITCH_CLIENT_ID) {
    // defensive fallback: if the id were ever blanked, explain instead of calling Twitch
    signinSay("Twitch sign-in isn't set up yet — it needs Mr. E to register the app and add its client id. Until then, type your hero's name in the box below.", "gated");
    return;
  }
  try {
    signinSay("Asking Twitch for a code…");
    const body = "client_id=" + encodeURIComponent(TWITCH_CLIENT_ID) + "&scopes=" + encodeURIComponent(TW_SCOPES);
    const res = await fetch(TW_DEVICE, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body });
    if (!res.ok) throw new Error("Twitch said " + res.status);
    const d = await res.json();
    // show the user code + where to enter it (textContent / createElement only)
    const strong = el("b", null, String(d.user_code || "").toUpperCase());
    const uri = String(d.verification_uri || "https://www.twitch.tv/activate");
    const link = el("a", "signinlink", uri.replace(/^https?:\/\//, ""));
    // the link href is a Twitch verification URL from Twitch's own response, not snapshot data;
    // still, only allow the known activate host to be clickable, else show it as text.
    if (/^https:\/\/(www\.)?twitch\.tv\//.test(uri)) { link.href = uri; link.target = "_blank"; link.rel = "noopener noreferrer"; }
    signinSay([document.createTextNode("Go to "), link, document.createTextNode(" and enter the code "), strong], "code");
    pollForToken(String(d.device_code || ""), Math.max(5, n0(d.interval) || 5), Date.now() + (n0(d.expires_in) || 600) * 1000);
  } catch (e) {
    signinSay("Couldn't reach Twitch sign-in just now. Try again in a moment.", "bad");
  }
}

async function pollForToken(deviceCode, intervalS, deadline) {
  twPolling = true;
  while (Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, intervalS * 1000));
    let res;
    try {
      const body = "client_id=" + encodeURIComponent(TWITCH_CLIENT_ID) +
        "&scopes=" + encodeURIComponent(TW_SCOPES) +
        "&device_code=" + encodeURIComponent(deviceCode) +
        "&grant_type=urn:ietf:params:oauth:grant-type:device_code";
      res = await fetch(TW_TOKEN, { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body });
    } catch (e) { continue; }
    if (res.ok) {
      const t = await res.json();
      twToken = String(t.access_token || "");    // memory only
      twPolling = false;
      await spotlightMe();
      return;
    }
    // 400 authorization_pending / slow_down: keep waiting until the deadline
  }
  twPolling = false;
  signinSay("That code expired before sign-in finished. Tap to try again.", "bad");
}

async function spotlightMe() {
  try {
    signinSay("Signed in — finding your hero…");
    const res = await fetch(TW_USERS, { headers: { "Client-Id": TWITCH_CLIENT_ID, Authorization: "Bearer " + twToken } });
    if (!res.ok) throw new Error("users " + res.status);
    const j = await res.json();
    const login = String((j.data && j.data[0] && j.data[0].login) || "").toLowerCase();
    twLogin = login || null;
    highlightMyHero(login);
    if (chatOpened) chatConnect();                 // reconnect the guild chat with their own voice
  } catch (e) {
    signinSay("Signed in, but couldn't read your Twitch name just now.", "bad");
  }
}

// match the viewer's Twitch login to a hero and spotlight it. Read-only, DOM only.
function highlightMyHero(login) {
  const p = last ? (MOCK ? withMock(last.payload) : last.payload) : null;
  const heroes = p ? arr(p.heroes) : [];
  const mine = heroes.find((h) => String(h.name || "").toLowerCase() === login);
  if (!mine) {
    signinSay("You're signed in as " + login + ", but no living hero carries that name yet. Type !enlist in chat to raise one.", "ok");
    return;
  }
  storeMyHero(mine.name);               // H11: remember the signed-in viewer's own hero
  heroFilter = login; heroShown = HERO_PAGE;
  renderHeroes(heroes);
  const card = [...$("heroList").querySelectorAll("details.hero")]
    .find((d) => (d.querySelector(".hname") || {}).textContent === String(mine.name));
  if (card) { card.open = true; card.classList.add("mine"); card.scrollIntoView({ block: "center", behavior: "smooth" }); }
  signinSay("Spotlighting your hero, " + String(mine.name) + ".", "ok");
}

(function () {
  const btn = $("signinBtn");
  if (btn) btn.addEventListener("click", twitchSignIn);
})();

// ============================================================ LORE (H12)
// A FROZEN copy of data/lore_lines.json from the main branch, bundled so the page
// needs no new fetch and no CSP change. The content is Twitch-era text and may
// still carry hostile markup; it reaches the DOM ONLY through el()/textContent,
// and every icon is a whitelisted ICON_SET glyph. See docs/HUB_SECURITY.md (H12).
const LORE_SRC_SHA  = "1669c1b";
const LORE_SRC_DATE = "2026-11-14";
const LORE_FROZEN = {"town_life":{"crier":["Grain measured, flasks counted, door kept - Bellmire stands another day!","Fresh off the river: trout, and a tale with every one.","The guild takes names at the post. Bring your own courage.","Lamps lit, walls walked, all's well - or well enough.","Another delver down the scar. Put a copper on them coming back up.","Walls walked, gates kept, and the bell has nothing to say!","Caravan on the road - bring coin or bring your back!","New names on the guild post. Read them while they are fresh.","The apothecary has flasks and the guild has holes to put them in!","Taxes measured, not guessed - the Hall says so.","Rain by evening. The crier is never wrong twice running.","Measure the grain, count the flasks, keep the door - and the crier keeps his voice!","Two up from the scar this morning, and both of them walking!","The bell has no clapper and even less to say. All's well!","Market day! Bring coin, bring elbows!","The Watch walked the wall twice and found nothing worth a second turn.","Flasks on the shelf, grain in the measure - Bellmire keeps its own accounts!","A lord came up out of the scar and went back down in pieces - hear it twice for a copper!","E3PO stood the night gate himself. Sleep easy, Bellmire.","Three down the scar before breakfast. The guild post is open and the ink is wet!","Stone on the road, masons on the wall - look lively or be built into it!","The Ford is running high. Cross at the ferry or cross at your own funeral!","Lost: one goat, answers to nothing. Found: one goat, answers to nobody!","The Hall sits at noon. Bring your grievance and bring it short!","Bandits on the west road, says the carter. Says it every week, mind.","Flasks counted twice today, on account of yesterday!","A caravan winters here, and the lanes are tight. Mind your elbows and your purse!","The night was quiet, the gate held, and the crier slept like an honest man!","New law posted at the Hall. Read it, or have it read to you at the gallows!","'Hear it, pay it, pass it on! Bellmire, your news!'","'Second bell! Any body with hands and a name, the drill yard calls!'","'Lost: one grey cat by the ford. Found: three. Come and argue!'","'Prices on the board, honest or you'll hear about it!'"],"market":["Two coppers the carp, and the carp is grinning.","Dye by the ounce - name a colour, Bellmire keeps it now.","Scarglass! Cheap, and only slightly cursed!","Boots that have walked further than you have, half off.","Ale by the jug, and the jug is honest.","Nails, hooks, and a hammer that has seen things!","Salt off the coast road - you will taste the journey.","Wool off the hill, and it still smells of the hill.","Bread this morning; bread-shaped by this afternoon.","Lamp oil! Burns slow, and you will want the slow sort.","Rope by the fathom, and it has held a man before!","Scarstone, polished - it only looks at you a little!","Candles! Burn one for the delvers, buy two for yourself!","Hooks, lines, and a river that owes you nothing!","Cheese with a crust you could roof a barn with!","Fresh ink and honest parchment - write home while you still can!","A hat that has never once been rained on. Not once!","Secondhand steel - all of it came back up. Most of it alone.","Wax and wick! Burn one for the ones still down there!","Charcoal by the sack, and the sack is nearly full!","Thread, needles, and a patch for whatever the scar did to you!","Smoked river fish - it has been through worse than you have!","Horn cups, horn combs, horn everything - we had a good year for horns!","Pickles! Older than some of my customers!","Blankets off the hill flocks, thick enough to stand up on their own!","Boots resoled while you wait, and you will wait!","Honey when the hives are ours to take it from. Today they are!","Lanterns, hooks and a long pole - everything a man needs to not go in after it!","The baker's boy is undercutting his father two stalls down.","A fishwife has a crow in a cage. She is not selling it; she wants it on record.","The salt stall weighs twice and smiles once.","The potter will take a chipped cup in trade and knock a copper off."],"growth":["The masons raised a new course on the wall today.","A second well dug, and the queue at the first one shorter.","They are building where the fields used to stop.","The guild post has two doors now. Both kept.","The smith has an apprentice, and the apprentice has eyebrows. For now.","A proper gate, hung and swinging true.","The road out is cobbled as far as the ford.","They are putting glass in the chapel windows.","A second row of stalls, and a queue for them.","The barracks took on ten more. E3PO looked almost pleased.","The ditch is dug, the stakes are in, and the masons are measuring stone.","A new row of chimneys on the east side, all of them smoking.","They have hung a lamp at the ford. It burns all night now.","The guild post took on a clerk, and the clerk took on a queue.","A tannery, downwind - and the town voted on which wind.","The market square has flagstones where the mud was.","A second smith, and the two of them already disagree.","They are cutting a road where the fields used to stop.","They have roofed the old well, and the water tastes of less sky.","A stone granary going up by the Hall, and the masons will not say how much.","Drains under the high street. The town smells of digging instead of worse.","The chapel has a clapper on order, and opinions arriving free.","A second gate cut in the north wall, because the first one had a queue.","The guild post painted its door. The door is still kept.","A bath house, of all things, and a line outside it already.","They are laying a wharf at the Ford, long enough for two boats to argue over.","The yard has a practice dummy that E3PO himself broke in half. They built a stronger one.","Lamps the whole length of the high street now. The dark stops at the wall.","Another roof goes up; another kettle gets hung.","The ward lists a new name. Nobody argues it.","A second well is being dug, and a first argument is being had over it.","Market Day has outgrown its square. The square is being argued with."]},"growth_tiers":{"tiers":[{"name":"Crossing","crier":"A handful of huts at a river crossing. Somebody calls it Bellmire.","see":"Three or four huts, a cart, a cookfire."},{"name":"Hamlet","crier":"Bellmire is a hamlet now - a well dug, and a reason to stay.","see":"A well, a few more homes, a fenced garden or two."},{"name":"The Guild Post","crier":"The guild plants a post at Bellmire. The post has a door, and the door is kept.","see":"The guild post building, and the town's first lamp."},{"name":"Village","crier":"Bellmire is a village. The scar has a name, and so do we.","see":"Homes clustered along a cart-track, chickens, a shared pen."},{"name":"Market Day","crier":"Market day comes to Bellmire. Measure the grain.","see":"A market square with a few stalls, and the first outside traders."},{"name":"The Chapel","crier":"A chapel and a bell-tower rise. The bell has no clapper, and rings anyway.","see":"The temple and its tower, and a small graveyard behind it."},{"name":"Craft Row","crier":"The smiths and masons raise Craft Row. Count the flasks.","see":"Workshops trailing smoke, a forge-glow, the mill wheel turning."},{"name":"The Garrison","crier":"Bellmire raises a garrison. The guard has a yard now - and a Commander.","see":"Barracks and a training yard, guards on patrol, E3PO up on the wall."},{"name":"Market Town","crier":"Bellmire stands as a proper market town. The caravans know the road.","see":"A paved square, more districts, a busy Ford with its Ferryman."},{"name":"The First Wall","crier":"Stone goes up where the fields used to stop. Keep the door.","see":"A low wall around the town's heart, and a gatehouse over the road."},{"name":"Walled Town","crier":"Bellmire is a walled town now. Let them come.","see":"A full curtain wall, corner towers, a district banner on each quarter."},{"name":"City in all but Charter","crier":"Bellmire is a city in all but the charter - and the scar is deeper than it has ever been.","see":"Dense districts, a second ring of homes outside the wall, traffic at every gate."}]},"e3po":{"intro":["E3PO takes the wall. The whole guard stands straighter.","The Commander is on the field. Nobody tells him to be careful.","The gate opens, and it is only E3PO coming out to meet them.","E3PO arrives at a walk. Running would suggest doubt.","The Commander's voice reaches the back of the square before he does.","E3PO comes up the stair to the wall at the same pace he always does.","The Commander takes his place at the gate and the guard stop checking the horizon.","E3PO arrives already giving orders, which saves everyone a moment.","The Commander steps onto the wall. The night gets smaller.","E3PO arrives with his helm under his arm and his opinion ready.","Boots on stone, slow and even. That will be the Commander.","E3PO comes out of the gatehouse already unimpressed.","The Commander takes the step nobody else wants and stands on it.","E3PO is here. Whatever this is, it is his problem now, and he prefers it that way.","The Commander comes through the crowd and the crowd closes behind him, facing out.","E3PO reaches the wall without hurrying, and the hurrying stops.","The Commander arrives, looks at the problem, and names it. That is usually enough.","E3PO puts his back to the gate. Everything else can be worked out from there.","The Commander walks past the trembling end of the line and stands at it.","E3PO steps out of the dark into the lamplight, which is the only warning anyone gets.","The Commander takes the wall and the whole guard remembers the drill at once.","E3PO arrives late, on purpose, so the men learn they can hold without him.","E3PO comes out at a walk. Nothing about today is going to be hurried.","The Commander is at the gate before the horn has finished.","Boots on stone, in step, one pair louder than the rest. That is him.","E3PO takes his post and the whole wall exhales.","The Commander arrives in full harness on a quiet day, because quiet days end.","E3PO steps into the gateway and makes it look narrower than it is.","The guard snaps to without being told. He has not even spoken yet.","The Commander is where he always is. That is the point of him."],"says":["Hold the line. The line holds because I say so.","I have died exactly never. Let us keep the record.","Measure the grain, count the flasks, and leave the gate to me.","A guard who runs is a guard I must replace, and I hate paperwork.","They do not pay me to fall. They do not pay me at all - I simply refuse to leave.","The door stays shut. That is the whole job, and I am very good at it.","Wounded? I prefer 'briefly inconvenienced'.","Bellmire sleeps because I do not.","Shapes, not numbers. That goes for raiders too.","I do not require a monument. A kept door will do.","If the gate holds and the grain is counted, the day is a success. The rest is weather.","Call me Commander. 'Sir' is for men who might retire.","Shut the door, count the grain, and let me worry about the rest.","Courage is a habit. Start with standing still.","I was here before the wall. I will be here after it, if the masons keep this up.","A quiet night is the best work we ever do, and nobody writes it down.","The scar can have the deep. It cannot have the doorstep.","I do not need you brave. I need you where I put you.","Twenty years and no one has got past me. I would call that a record; I call it Tuesday.","If you must run, run toward something. Preferably me.","Grain, flasks, door. Everything else is a rumour.","I have no plan for losing. I never found the time to write one.","Hold your ground. Ground is the only thing here that cannot run.","You want glory. I want Thursday to be boring.","Fear is fine. Fear that moves its feet is a problem.","I have buried better men than me. That is the whole reason I stay.","Do not thank me. Shut the door behind you.","The deep sends up monsters and we send down volunteers. I do not love the trade.","There is no trick to it. Stand where you are told, for longer than you want to.","I am not brave. I am simply still here, which looks the same from a distance.","I am not the wall. I am what the wall is for.","Every door in this town shuts. Mine shuts last.","Do not ask me how old I am. Ask the gate; it remembers more.","A town is a promise that somebody is awake. I am the somebody.","You will have braver days than this. Today I want a steady one.","I do not win fights. I outlast them. Try it, it is cheaper.","The scar is patient. I have the advantage there.","Keep your spear where I can see it and your fear where you can.","I have never once been rescued and I am not starting a fashion.","Report to me, not about me.","They call me immortal. I call it a long habit of not leaving.","Bellmire has buried everyone who built it. That is the job of a town.","If you want my post, you will have to wait a very long while.","Stand here. If something comes through, it came through me first, so take your time.","Keep the door. Everything else is decoration.","I do not need sleep. I need the wall to still be there in the morning.","A gate is a promise. I am the one who keeps it.","You may panic after. I shall tell you when after is.","Two things never leave this post: the bell and me.","Courage is a habit. Start it now, you will want it later.","If the wall falls, step back one pace and be a wall.","I have no grave to visit. Count yourselves lucky it is mine.","Hold your ground. The ground has held mine for longer than you think.","The scar eats spells. It has never once eaten a spear.","Fear is fine. Moving is not.","I do not shout to frighten you. I shout so you can find me.","Drink after the gate is shut. Not one flask before.","Nobody in this town dies of my carelessness. That is the whole oath.","When I withdraw, I come back. Learn the second half.","Stand where I put you and the night is a short one.","A quiet watch is a watch that worked. Do not sulk.","I was not built for retreat and I was not built well for stairs.","Say my name if it helps. It usually does.","Measure the grain. Count the flasks. I shall keep the door."],"town_talk":["They say E3PO has held the gate since before there was a gate.","Old-timers swear E3PO has outlived three of his own gravestones.","The children drill with sticks and name the loudest one E3PO.","No raider has taken the Keep door while the Commander draws breath - which is to say, never.","The guild keeps a chair for E3PO at every feast. He never sits; he watches the door.","The Watch say the Commander's armour has more dents than the gate has nails.","There is a standing wager at the tavern on what could fell E3PO. Nobody has collected.","The masons built the new wall a hand taller because he asked twice.","They tried to carve him a statue. He made them turn it to face the door.","Every recruit hears the same first words: 'The door stays shut.'","The Watch say the Commander sleeps standing up, and only to set an example.","They reckon E3PO has worn out more armourers than armour.","A child asked the Commander what he is afraid of. He thought about it for a long time and said 'paperwork'.","The bakers keep him a loaf he never takes, and bake it anyway.","Two generations of this town have been told off by the same man in the same voice.","Nobody can name the day E3PO arrived, which is how you know the story is old.","The Watch measure a hard night by how many times the Commander said nothing.","They say the first wall was built around wherever E3PO happened to be standing.","Three innkeepers have retired on bets about the Commander's age.","He knows every guard's mother's name. Nobody knows how.","The graveyard has no stone for E3PO. The masons keep offering.","They say if the bell ever gets a clapper, he will still hear the gate first.","Recruits are told not to try out-standing him. They try anyway. They stop.","A caravan master swore he saw E3PO on the wall at dawn and at midnight. Same posture, same dent.","The Watch say the Commander has never once been seen running, in any emergency, ever.","They say he has had three suits of armour and only one dent he keeps.","The gatekeeper's grandfather was told off by E3PO for the same thing, in the same words.","A tanner swears the Commander remembers his wedding, which was forty years back.","They say the scar has tried E3PO twice and gone back down both times.","The Watch keep a tally of nights the Commander slept. It is a short tally.","The schoolmistress uses E3PO to teach the children what reliable means.","The guild post keeps his name off the ledgers - he never asked for pay, so there is nothing to write.","A delver swore the Commander walked her home from the scar's edge without a word.","They say the architect drew the gate around the Commander's shoulders and got the measurements right.","No innkeeper in Bellmire will take his coin. He leaves it anyway, under the cup.","The gravediggers say E3PO knows where every one of them is, by row.","The children's game is called Hold The Door. Nobody wants to be the raiders.","They say Bellmire has two bells: the one with no clapper, and the Commander.","They say the mason who cut E3PO's gravestone gave up and sold it as a doorstep.","The tally-man gave up counting the Commander's years and wrote 'yes'.","Mothers tell their children E3PO sleeps. The children have never seen it.","Bets on the wall: how many winters the Commander has stood. The pot has never paid.","Half the guard copies his stance. The other half copies his voice and gets caught.","The alehouse keeps a chair for E3PO. It has never been sat in and never been moved.","They say the gate was hung around him, not the other way about.","A trader asked who the statue by the gate was. The statue answered him.","Every guard captain since has been measured against him and come up short on purpose.","They say the scar misfires every spell in Bellmire except whatever keeps the Commander standing.","A priest offered him last rites once, hopefully. He declined, politely, for the ninth time.","Children dare each other to make the Commander laugh. One claims to have done it.","The guild post keeps his old spear on the wall. He keeps asking for it back.","They say if you are lost in the valley, walk until someone shouts at you. That is the road home.","Nobody remembers hiring him. The ledger simply starts with him in it.","The town has one true relic and it answers when you call it."]},"lord_intros":{"hollow_king":"The braziers in the hall burn blue, and then burn cold.","grubmother":"The floor is wet, and getting wetter.","rattling_host":"Somewhere ahead, something counts its own bones out loud.","nightwing":"Every torch on the floor gutters at once.","gravewyrm":"The dungeon was built around this, and it knows it.","ossuary_lord":"It has waited a very long time. A little longer is nothing.","pale_duchess":"A lady laughs somewhere ahead, very politely.","mourncoil":"Breath steams. Then the steam freezes."},"unique_intros":{"gnawbone":"The walls squeal.","mother_silk":"The threads across the doorway are new.","weeping_bowman":"A string twangs in the dark, and something weeps after it.","cinderjack":"Someone has been playing with the firepits.","kept":"A voice the guild knew calls a name the guild remembers."},"disasters":{"volcano":{"begin":"The mountain above the scar wakes - ash on the wind, and the sky goes copper.","during":["Ash falls on Bellmire; the sun is a dull coin behind the smoke.","The river runs grey, and the fish float up dead.","Cinders tick off the roof-tiles all night; nobody opens a shutter.","The crier reads the day's news through a cloth over his mouth.","The ash drifts into the grain store through a gap nobody knew was there.","Sheep come down off the high pasture coughing, and do not go back up.","The chapel bell rings muffled, packed with grey.","Children write their names in the ash on the shutters. By morning it has written over them.","A cart leaves two clean ruts in the grey, and nothing else does.","The guild post sells cloth masks and is out of them by noon.","Lamps are lit at midday; the copper sky gives nothing to work by.","Ash sits a finger deep on the chapel steps and is swept twice a day.","Grey settles on the market bread, and the bread sells anyway.","The high pasture is gone under ash; the shepherds bring everything down.","Ash falls like grey snow and the cookfires are put out to save the air.","The mountain speaks again and every bell in Bellmire answers it badly.","Carts queue at the Ford with everything a household can lift.","The water butts are skimmed twice a day and still run grey.","A roof goes in under the weight of its own ash, and nobody was under it.","The crier's voice carries badly; the ash eats it before the far side of the square.","The guild post weighs ash out of the grain and charges for honest weight.","Every doorstep is swept, and every doorstep is grey again by dusk.","The forge works blind, the smoke of its own making lost in the bigger smoke.","Bellmire counts the flasks early this week, because the lamps burn all day."],"pass":"The mountain settles. Ash greys every roof, but the air clears.","cost":"A buried harvest and sickened livestock; the worst-hit district must be rebuilt."},"fire":{"begin":"Fire in Craft Row - a forge banked wrong, and the wind unkind.","during":["The bucket line runs from the river; the Watch beats at the flames.","Smoke rolls over the square as the smiths' roofs go up.","Craft Row is a tunnel of heat; the Watch wets the next roof down and waits.","Somebody's apprentice runs back in for the tools and is dragged out again.","The wind turns, and the bucket line turns with it, cursing.","A roof-beam goes down and the whole square flinches.","They pull a smith off his own forge; he fights them the whole way out.","Sparks ride the night air toward the thatch, and every eye follows them up.","They pull down the shed between the forge and the next roof to starve it.","Buckets come up the line faster than hands can empty them.","A smith's tools glow in the ruin, too hot to carry for an hour.","Somebody counts heads in the square, twice, and then a third time.","The wind drops, and the bucket line gains a yard on it.","Soot comes off the Row and settles on the washing three streets away.","The chapel bell rings itself hoarse and nobody is spare to stop it.","They run a wet line of cloth along the next row and dare the fire to cross it.","A child is handed up the bucket line and over the heads to the far side.","The bucket line runs from the river to Craft Row and does not break.","A roof is pulled down on purpose, to stop the fire using it as a road.","Soot in the bread, soot in the ale, and the market sells both.","The smiths stand in the square with their tools and nowhere to put them.","The chapel bell rings for the line to change hands.","The guild post hands out wet sacking and writes down every one.","Somebody carries the ledgers out before the furniture, and is thanked for it."],"pass":"The fire is out. A row of workshops is char and cinder.","cost":"Buildings in one district burned down and rebuilt from nothing; the smiths sit idle until then."},"drought":{"begin":"No rain since the thaw. The river drops, and the wells go shy.","during":["The crops stand yellow and brittle in the field.","The queue at the well starts before dawn.","The mill-wheel stands still in a riverbed of stones.","Dust comes off the fields in sheets and settles on the market bread.","The well rope goes down further each morning and comes up lighter.","Dust walks the cart-track where the mud used to be.","The miller stops the wheel. There is no water to turn it.","Cattle are driven to the Ford and find it ankle-deep.","The Ford can be crossed dry-shod, and nobody is pleased about it.","Water is carted from upriver and sold by the bucket.","The fields crack into plates you could lift out whole.","The chapel prays for rain at every bell, and the bell is busy.","Thunder at dusk and no rain under it. That is the cruellest part.","The garden plots are given up so the grain can drink.","The river shows its bones at the Ford and the ferryman walks across.","Water is rationed by the bucket and counted by the chapel.","The fields crack open wide enough to lose a boot in.","The well-rope is spliced longer, twice.","Cattle are walked to the river and walked back thinner.","The millrace is a mud lane; the miller sits in his own doorway.","Dust comes off the market floor and settles on everything for sale.","The chapel is full, and nobody is pretending otherwise.","Water is rationed by the bucket, and the counting is done in public.","The grain is cut early and short, because waiting costs more than cutting."],"pass":"Rain, at last. The river climbs, and Bellmire drinks easy again.","cost":"A harvest cut to nothing and thinning livestock; morale sinks until the wells fill."},"famine":{"begin":"The barns are near bare, and spring is a long way off.","during":["Rations at the guild post; the thin get thinner.","A copper will not buy bread that is not there.","The guild post weighs every portion and still sends people away short.","Children are fed first, and the adults have agreed not to discuss it.","The barn is measured twice a day now, and the number never improves.","The guild post cuts the ration and does not meet anyone's eye.","Folk eat the seed grain, which is tomorrow eaten today.","A family leaves for downriver in the dark, so nobody has to say goodbye.","The tavern serves broth and calls it broth, which is honest of it.","Snares go out along every hedge and come back empty more often than not.","The guild post weighs a child's ration against a man's and gives both to the child.","Folk eat what the hens were owed, and the hens stop laying.","The market board is bare, and the stallholders stand behind it anyway.","Nobody talks about the dogs. There are fewer of them.","The grain is measured in front of witnesses now, every morning.","People eat the seed corn and do not discuss what that means for spring.","The chapel door stays open all night and the queue does not shorten.","Bread is weighed in front of the buyer, every loaf, no exceptions.","The seed corn is guarded, because eating it ends more than this winter.","The market has stalls and no goods; people come anyway, for the company.","A household gives up its laying hen and the street notices.","Soup from the chapel, thin and hot and gone in an hour.","The guild post lends against next year's harvest and charges for the doubt.","Nobody speaks of the stores above a murmur, as if loudness would spend them."],"pass":"The first harvest comes in, and Bellmire eats again.","cost":"The town shrinks as the weak are lost; no growth until the barns refill."},"sickness":{"begin":"A fever walks the homes. The apothecary names it, then runs short of cures.","during":["Doors chalked with a warning mark; the healers do not sleep.","The chapel bell tolls more than anyone likes.","The healers run out of simples before they run out of patients.","Market day is called off; the square has never looked bigger.","Doors are marked in chalk, and the chalk is running out.","The apothecary works the night through and brews water with a name on it.","The chapel keeps its lamps lit for the ones who will not see morning.","The Watch carry food to the marked doors and set it down without knocking.","The healers work in shifts and lose track of which shift is theirs.","The chapel sets out water for whoever is still walking.","Nobody shakes a hand in Bellmire this week.","They bury at dawn, in ones, with the fewest hands that will do.","The Ford turns travellers back, politely, with a spear held level.","A house goes quiet, and the chalk mark stays up a week past needing to.","Doors are marked in chalk and the marks are not argued with.","The apothecary works through the night and the queue is longer at dawn.","The Watch leaves bread at the marked doors and does not knock.","The quarantine holds at the Ford; the traders shout across the water.","The apothecary works through the night and writes down every flask.","Nobody shares a cup at market, and nobody has to be told twice.","A street is shut at both ends and fed over the barricade.","The chapel takes the worst cases, because it has the room and the roof.","Work stops in Craft Row - half the benches are empty and the other half are careful.","The crier reads the day's count from a distance, and the square keeps it."],"pass":"The fever burns itself out. Bellmire counts its dead and opens the windows.","cost":"The population falls, and a quarantine freezes trade and work while it lasts."},"hurricane":{"begin":"A great storm drives inland, and the sky turns the colour of a bruise.","during":["Roofs peel away; the river bursts its low banks.","Nobody walks the wall in this.","The gate bar is doubled and the horses are brought inside the hall.","Something large goes past the window sideways and nobody goes to look.","Thatch goes over the square in sheets, like a flock that forgot how.","The Watch rope themselves together to cross the open ground.","Every shutter in Bellmire is either barred or gone.","The river comes up the lane and knocks at the low doors.","The road lamps are taken in; there is nothing out there to hold them.","Rain comes sideways and finds every gap in every wall.","The chapel roof holds, which surprises the mason who built it.","Nobody sleeps, and everybody pretends to.","The orchard loses its oldest tree and half the fruit of the rest.","The gate stays shut. Whatever is outside can wait out the night.","Every shutter in Bellmire is barred and half of them are not enough.","The wind takes a roof whole and sets it down in the square, almost gently.","Nobody crosses the square. The square is not crossable.","Thatch leaves the roofs in sheets and is not seen again.","The river comes over the low bank with the wind pushing it.","A tree comes down across the west road and lies there all night.","Shutters hammer all night; nobody in the low district sleeps.","The market stalls are carried away whole and found in the fields.","The bucket line forms for water coming in, not going out.","The guild post's sign is taken off its hooks and never recovered."],"pass":"The storm blows through. Bellmire is sodden and battered, but standing.","cost":"Roofs and buildings torn across the town, fields flooded, and days of repair."},"tornado":{"begin":"A finger of wind drops out of the storm and walks toward the town.","during":["It takes a barn whole and sets it down in splinters.","Mind the sky - it has not lifted yet.","Carts are roped to posts and the posts are not reassuring.","It walks the far field twice and turns, and the whole town watches the turn.","It takes the fence line, the hay cart and the cart's horse, in that order.","The sound arrives before the wind does, and nobody forgets it.","Folk go flat in the ditches and hold on to the grass.","A door lands in the square. Nobody owns it.","It crosses the river and takes a column of water up with it.","The pens are opened on purpose - better scattered than roofed.","It walks the hedge line, and afterward the hedge is simply not there.","The air goes green and very quiet, and then it does not.","Folk count it across the fields the way they count thunder.","It touches the mill yard, leaves the mill, and takes the yard.","It walks the fields like something deciding, and the town watches it decide.","The cellars fill with people and the bell is left to ring alone.","A barn goes up and does not come down anywhere anyone can find.","The wind takes one house and leaves its neighbour's shutters latched.","Livestock is scattered over a mile of open country.","A cart is found in a tree and left there, because nobody can reach it.","The lane it cut runs straight through the town and out the other side.","Thatch, hurdles and a chapel bench come down in the next field.","A wall stands with no house behind it, and does not fall for days.","Nobody counts the sheep until the wind has fully gone."],"pass":"The wind lifts and is gone, leaving a straight scar of wreckage.","cost":"A random line of buildings flattened, and livestock scattered or lost."},"earthquake":{"begin":"The ground rolls - the scar shudders, and so does everything above it.","during":["Walls crack; the clapperless bell swings and almost rings.","Aftershocks, and nobody trusts a roof.","The well comes up muddy and the masons will not say why yet.","Every door in Bellmire sticks, and one wall leans that did not lean before.","The bell with no clapper rings anyway, and nobody finds that funny tonight.","Masonry comes off the gatehouse in the aftershock.","Folk sleep in the square rather than under their own beams.","A crack opens along the chapel floor and runs out under the door.","The masons walk the walls with chalk, marking what cannot be slept under.","The scar groans, and the delvers come up and stay up.","A chimney comes down into the lane and misses everybody.","The well water tastes of stone for three days.","Nobody rings the bell on purpose; it manages on its own.","The gate will not shut square, and the garrison props it.","The ground moves twice more while they are still counting the first.","Masons walk the walls tapping stone and shaking their heads.","Nobody sleeps indoors. The square is full of blankets.","Aftershocks come at no useful interval; nobody sleeps indoors.","The masons chalk every crack and come back to see if it has grown.","A well goes dry, and a different well comes up muddy.","The scar's mouth is wider this morning than it was last night.","The square fills with households and their bedding, by choice.","The bell with no clapper rings in its frame and unsettles everyone.","A wall is propped with timber and the timber is watched."],"pass":"The shaking stops. Bellmire checks its walls, and its dead.","cost":"Walls and buildings cracked or down town-wide; the scar may gape a little deeper."},"meteor":{"begin":"A star falls - too slow, too bright - and comes down past the fields.","during":["The impact lights the night; the ground is scorched for a mile.","Something glitters in the new crater, and it hums like the scar.","Carters give the crater a wide berth; the horses refuse it outright.","The scar hums all night, as if something answered.","The orchard burns in rows, tree after tree, very neatly.","The crater glows all night and hums if you stand too close.","The first fool down the crater wall comes back up with a fistful of glass.","The guild post has a man on the crater by morning, counting.","The crater throws a light on the clouds you could read by.","Grass fires walk the field edge and are beaten out with coats.","The guild post puts a guard on the glass and a price on it by noon.","Two delvers go down the crater wall on a rope, for a wager.","Every dog in Bellmire faces the crater and will not be turned.","The stone cools slowly, and the night smells of struck flint.","The crater glows for three nights and nobody will sleep near it.","Scavengers come to the crater and the Watch turns them back at the rim.","Glass lies in the crater, and the glass remembers the heat.","The crater smokes for days and nobody will say it is safe.","Scarglass is picked out of the rim by hand and weighed at the guild post.","The orchard burns in rows, neatly, as if planted that way.","A watch is set on the crater, less for the town than for the thieves.","Everything near the fall is warm to the touch and stays warm.","Traders arrive early, asking about glass before asking about the dead.","The crier reads the toll, then the price of scarglass, in that order."],"pass":"The fires burn out. A crater smokes where the orchard used to stand.","cost":"An outlying district or the orchard is destroyed - but the crater yields scarglass worth a fortune."},"scarstorm":{"begin":"The scar flares, and wild magic rolls up out of the dungeon mouth and over the town.","during":["Every spell cast in Bellmire goes wrong; the lamps burn strange colours.","The livestock speak for a heartbeat, and the well runs uphill.","The apothecary corks everything and sits on the box.","A delver's lamp burns green, and the dark leans in to look.","A door opens onto a different room than it did this morning.","Every candle in the chapel burns blue and will not be put out.","A cooper's barrel fills itself with river water, and nobody touches it.","The casters sit it out, hands in their laps, useless and insulted.","Shadows fall the wrong way across the square, and nobody mentions it.","A hedge flowers out of season, all at once, and then forgets.","The chapel bell rings a note that is not one of its own.","A delver's blade goes cold enough to burn the hand holding it.","The crier reads his notice twice and it says different things.","Birds fly one circle over the scar and will not break it.","The scar breathes out, and the air in the lower streets goes wrong.","Lamps burn purple at the scar's edge and the Watch pulls back a street.","Nothing comes out of the scar. That is the part that frightens people.","No spell holds while it lasts; casters stand in the square with nothing to offer.","A house is a slightly different shape by morning and will not be argued with.","The guild post's weights read differently every hour and are set aside.","Somebody comes out of the storm scar-touched, and it is not yet clear which way.","The bell with no clapper rings clean, once, and will not do it again.","The lamps burn colours and the oil is spent at twice the rate.","Nobody walks near the scar's mouth, and the watch is doubled anyway."],"pass":"The scar quiets. The magic settles, mostly, and the town tallies what changed.","cost":"Spellcasters are useless while it lasts; random buildings warp, and a few folk are scar-touched for good or ill."},"flood":{"begin":"The thaw comes all at once. The river climbs the banks, and keeps climbing.","during":["The low district is ankle-deep, then knee-deep.","The Ford is gone under brown water; no crossing today.","The grain store is moved up a floor by every pair of hands in town.","Boats in the lane where carts should be, and someone fishing out of a window.","The Ford is gone - only the posts show where it was.","Stores go up to the Keep a sack at a time, through knee-deep water.","A hen coop sails past the chapel with the hens still aboard.","The Watch mark the water on the gatepost each hour. The marks keep climbing.","The chapel keeps the pews stacked and the floor under an inch of river.","The low district moves upstairs and lives there.","The bridge posts are all that show of the road to the Ford.","A cellar gives up its stores in a slow brown stream.","Fish are taken in the lane, which is funny for a day and then is not.","The gatehouse step is the measure now, and everybody checks it.","The lower streets take water to the knee and then to the waist.","Boats work the market square, which nobody finds funny.","Grain goes up to the Keep sack by sack, by a line that does not stop.","The low district is moved upstairs, one household helping the next.","The grain store's bottom row is lost and counted as lost out loud.","Boats work the lanes where carts worked last week.","The traders stand on the far bank and shout their prices across.","The chapel floor is under water and the service is held on the steps.","The well is fouled by the river and roped off for drinking.","Everything that can be lifted has been lifted; the rest is being watched."],"pass":"The water drops back, leaving mud in every doorway - but the town held.","cost":"Riverside buildings and stores ruined; the Ford and its trade shut until the river falls."},"blight":{"begin":"A black rot is in the grain - it came up in one field and did not stop there.","during":["Whole rows are cut and burned before the rot can walk to the next field.","The miller turns away sack after sack, and says nothing, which is worse.","The rot shows black at the stalk and climbs from there.","Field hands burn their gloves at the end of the day, just in case.","Bread goes up a copper, then another, and the baker stops apologising.","The guild post buys grain from downriver at a price it will not read aloud.","A farmer stands at his field edge all afternoon doing nothing at all.","They plough the worst acre under and sow nothing in it.","The smoke of burning rows hangs over the fields all week.","Seed grain is set aside and guarded, because next year is in the sack.","A field is written off at noon and burned by dusk.","The baker mixes in what he can and calls it bread, generously.","Hands are scrubbed at the field gate before anyone walks home.","Downriver grain comes up the road under guard and is counted twice.","The fields go black in patches that spread while you watch them.","They burn one field to save the next and argue about it for years after.","The apothecary tests the grain and will not say what she found.","Infected fields are burned, deliberately, with the whole town watching.","Grain prices climb at the market and are read out anyway.","The seed corn is locked and a guard is put on the lock.","Traders come upriver with grain and name a price nobody likes.","The reeve walks the rows daily, marking what is still clean.","Bread is smaller this week and will be smaller next week.","The stores are measured twice, by two different people, in public."],"pass":"The blight burns out at the field edge. What is left of the harvest comes in early.","cost":"Most of the standing harvest is lost; food prices climb and the stores do not refill this season."},"coldsnap":{"begin":"The cold comes early and hard - the Ford freezes over in a night.","during":["Firewood costs what wine cost last week, and the queue for it is longer.","The Watch walk in pairs now, because one man alone stops moving.","The Ford is a road now, and nobody trusts it enough to use it.","The forge is the warmest room in Bellmire, and the smith charges for the privilege.","Water freezes in the bucket between the well and the door.","Caravans turn back at the hill, and the market has empty boards.","They bring the lambs indoors and share the floor with them.","The chapel takes in whoever has no fire, and the chapel is full.","Nails of ice hang off every eave, long enough to be dangerous.","The well head is thawed each morning with a kettle.","One oven bakes for the whole street, to save the wood.","The garrison drills indoors and complains, which keeps it warm.","Cattle breath stands in the byre like smoke that will not leave.","Two nights running, nobody goes further than the next door.","The river takes a skin of ice and the ferry stops for the first time in years.","Firewood doubles in price by noon and the Watch stands over the woodpile.","The old and the young are moved into the Keep hall together.","Livestock is brought indoors and lives among the household.","Building stops: the mortar will not set and nobody pretends it will.","The Ford is ice, so the trade is ice too - nothing moves either way.","Firewood is rationed and the rationing is read out by the crier.","The wells are broken open with a mallet each morning.","Work in Craft Row halts; the forge is the warmest room in Bellmire.","The chapel is full because the chapel is heated."],"pass":"The thaw comes. The Ford runs again, and Bellmire counts who it kept.","cost":"Livestock lost and work stopped: building, trade and the fields all halt until the thaw."}},"events":{"bandit_camps":[{"name":"The Gallows Oak","leader":"Red Harl","appears":"Red Harl's lot have taken the west road. No caravan reaches the Ford unbled.","while":"Trade caravans are robbed; the market runs short and prices climb.","cleared":"Red Harl hangs from his own Gallows Oak. The west road is open again."},{"name":"The Mire Nest","leader":"Sedge the Toll","appears":"Sedge the Toll holds the fen path and taxes everyone who is not her.","while":"Every trader by the fen pays Sedge first; the town's cut shrinks.","cleared":"Sedge the Toll pays her own toll at last. The fen path clears."},{"name":"The Burnt Mill","leader":"Cob Ashfoot","appears":"Cob Ashfoot's raiders have holed up in the burnt mill, firing a field a night to keep the town afraid.","while":"A field burns most nights; harvest and morale both drop.","cleared":"The Burnt Mill burns one last time. Cob Ashfoot runs, and keeps running."},{"name":"Scarside Camp","leader":"The Weasel","appears":"The Weasel's crew squat at the scar's edge, robbing the delvers who climb out.","while":"Returning delvers are waylaid; their gold and loot never reach Bellmire.","cleared":"Scarside Camp is cleared. Delvers come up to friends now, not knives."},{"name":"The Drover's Rest","leader":"Juno Blackhand","appears":"Juno Blackhand has taken the drovers' inn on the north road and left the sign hanging.","while":"Livestock driven to market never arrive; the pens stand empty on market day.","cleared":"The Drover's Rest changes hands again. Juno Blackhand does not leave with it."},{"name":"The Quarry Camp","leader":"Old Peck","appears":"Old Peck's lot have moved into the worked-out quarry and are selling Bellmire its own stone back.","while":"Cut stone and lime go missing; building in town stalls for want of either.","cleared":"The Quarry Camp is emptied out. The stone comes down the road at an honest price."},{"name":"The Lampless Road","leader":"Wick Harrow","appears":"Wick Harrow's crew put out the road lamps one by one, and work the dark they made.","while":"Nobody travels after dusk; the night trade stops and the Ford shuts early.","cleared":"The lamps burn the whole length of the road again. Wick Harrow walks it in chains."},{"name":"The Weir Camp","leader":"Marek Two-Coin","appears":"Marek Two-Coin has fortified the old weir and charges the river for using itself.","while":"River trade pays twice; the Ford's takings fall while the weir stands.","cleared":"The Weir Camp is broken open. The river runs toll-free again."},{"name":"The Ashen Barrow","leader":"Grell the Patient","appears":"Grell the Patient has dug into the barrow mound and watches the market road out of it.","while":"Market-bound carts are picked off; stalls stand empty on market day.","cleared":"The barrow is emptied of the living. Grell the Patient stays behind in it."},{"name":"The Hollow Stand","leader":"Ivett Crow","appears":"Ivett Crow's archers hold the wood where the road bends, and they do not miss twice.","while":"Couriers and tax carts are lost at the bend; news and coin both arrive late or not at all.","cleared":"The Hollow Stand is cleared. The road bends past nothing worse than trees."},{"name":"The Shepherd's Fold","leader":"Dunn Halfhand","appears":"Dunn Halfhand has taken the high fold and keeps whatever flock he finds in it.","while":"Wool and mutton stop coming down off the hills; the cloth trade and the tavern both feel it.","cleared":"The Fold changes shepherd. Dunn Halfhand leaves with a quarter hand and no flock."},{"name":"The Lime Kiln","leader":"Mad Tibb","appears":"Mad Tibb's crew sleep in the lime kiln and come out white as ghosts to work the road.","while":"Lime and mortar never reach the masons; whatever Bellmire is building stops where it stands.","cleared":"The kiln is cold and empty. Mad Tibb is walked back to town the colour of chalk."},{"name":"The Sunken Boat","leader":"Hask the Ferryman's Brother","appears":"Hask has swamped a boat across the narrows and robs whoever stops to haul it clear.","while":"The narrows are blocked; barges wait, and what they carry spoils in the hold.","cleared":"The Sunken Boat burns to the waterline. Hask swims for the far bank and is met on it."},{"name":"Blackbrier Hide","leader":"Iver Cutgrass","appears":"Iver Cutgrass has cut a camp into the blackbrier where no horse can follow.","while":"Foot traffic on the south track is robbed; the smaller traders stop coming at all.","cleared":"Blackbrier Hide is burned out. The south track carries packs again."},{"name":"The Charcoal Camp","leader":"Mother Soot","appears":"Mother Soot and her burners hold the charcoal stands above the wood.","while":"Charcoal runs short; the forge works half days and smith prices climb.","cleared":"The Charcoal Camp is taken. The forge burns a full day again."},{"name":"The Rook Field","leader":"Carrow Dace","appears":"Carrow Dace has set his crew in the rook field, where the crop stands tall enough to hide a man.","while":"Harvest carts are stopped at the field edge; grain comes in short at the measure.","cleared":"The Rook Field is cut early and cleared. The measure fills honestly again."},{"name":"The Salt Road Camp","leader":"Tam Pell","appears":"Tam Pell has taken the salt road where it narrows, and charges the narrow part.","while":"Salt and cured stores arrive dear; preserved food in town spoils faster for want of it.","cleared":"The Salt Road Camp is broken. Salt comes in at the old price."},{"name":"The Beekeeper's Hut","leader":"Hollis Grin","appears":"Hollis Grin has turned the beekeeper out of his own hut and kept the bees.","while":"Honey, wax and candle stock dry up; the apothecary brews slower without wax.","cleared":"Hollis Grin is stung out of the hut. The beekeeper goes back to his bees."},{"name":"The Dry Ferry","leader":"Nils Odd","appears":"Nils Odd has taken the old ferry landing upriver and runs his own crossing at his own rates.","while":"Half the river trade goes around Bellmire entirely; the Ford takes less each day.","cleared":"The Dry Ferry is sunk at its moorings. The river comes back to the Ford."},{"name":"The Ox Road Camp","leader":"Bram Sallow","appears":"Bram Sallow holds the ox road and takes a beast from every team that passes.","while":"Hauling costs double; stone, timber and grain all arrive late and dear.","cleared":"The Ox Road Camp is cleared out. The teams come in whole."}],"monster_camps":[{"name":"The Bone Field","of":"risen dead","appears":"Something below spat up its dead, and they are gathering in the north field.","while":"The dead multiply nightly and gnaw at the outlying farms.","cleared":"The Bone Field is put down. The north field is only a field again."},{"name":"The Slime Warren","of":"slimes","appears":"A slime nest has taken the old quarry, and it doubles every night it is left alone.","while":"The quarry is lost, and the nest creeps toward the homes.","cleared":"The Slime Warren is burned out. The quarry stops twitching."},{"name":"The Belltower Roost","of":"cave bats","appears":"A roost of cave bats has taken the bell-tower; they foul the wells and spook every horse in town.","while":"The wells need watching, and the beasts are restless while they hang there.","cleared":"The Roost is cleared. The bell-tower is quiet. Almost."},{"name":"The Sedge Mound","of":"bog frogs","appears":"The fen has gone loud - bog frogs the size of dogs have mounded up in the sedge.","while":"The fen path is lost, and the fishers work the river or not at all.","cleared":"The Sedge Mound is cleared. The fen is merely unpleasant again."},{"name":"The Silk Barn","of":"cave spiders","appears":"A barn on the south road has gone white - cave spiders came up out of the scar and took it.","while":"The south road is spun shut; nothing moves past the barn after dusk.","cleared":"The Silk Barn burns. The south road is clear, and nothing is watching it."},{"name":"The Gnaw Pits","of":"scar rats","appears":"Scar rats have got into the old root pits, and they are not the size rats are meant to be.","while":"Stores are gnawed through nightly; what the town keeps, it keeps losing.","cleared":"The Gnaw Pits are flooded out. The stores hold their weight overnight again."},{"name":"The Drowned Pen","of":"bog lurkers","appears":"Something came up the flooded ditch and has settled in the stock pen at the water's edge.","while":"Livestock go a head a night, and the herds will not drink near the water.","cleared":"The Drowned Pen is cleared and the ditch dug out. The herds drink again."},{"name":"The Candle Wood","of":"scar wisps","appears":"Lights have taken the coppice east of town, and they walk the paths at dusk like a procession.","while":"The woodcutters refuse the coppice; firewood and charcoal run short in town.","cleared":"The Candle Wood goes dark. The cutters go back in by daylight, then by dusk."},{"name":"The Kiln Nest","of":"fire beetles","appears":"Fire beetles have bored into the brick kiln and glow in its mouth all night.","while":"The kiln cannot be fired; brick, tile and pottery all stop at once.","cleared":"The Kiln Nest is smoked out. The kiln fires clean, and the tiles come again."},{"name":"Gibbet Hill","of":"risen dead","appears":"The hanged have got up off Gibbet Hill, and they keep to the road they knew.","while":"The north road belongs to the dead after dark; nothing travels it and the post stops.","cleared":"Gibbet Hill is put down and the ground turned. The road is only a road."},{"name":"The Granary Swarm","of":"scar wasps","appears":"A nest the size of a cart hangs in the granary roof, and this is not the season for it.","while":"The granary cannot be worked; stored grain spoils where it stands.","cleared":"The Granary Swarm is burned out. The grain is turned, and most of it is saved."},{"name":"The Stone Yard","of":"cave trolls","appears":"Two things out of the deep have taken the mason's yard and are eating the mortar.","while":"Cut stone and finished work are wrecked nightly; every build in town slows.","cleared":"The Stone Yard is retaken. The masons find their tools, and a troll's tooth in a block."},{"name":"The Thornwake","of":"scar hounds","appears":"Something hound-shaped dens in the thornwake, and it hunts in a pack now.","while":"Flocks and herds are taken nightly; the pens empty and the drovers will not go out.","cleared":"The Thornwake is cleared. The flocks sleep out again."},{"name":"The Reed Hollow","of":"bog leeches","appears":"The reed hollow has gone thick with leeches the size of a forearm.","while":"Nobody will cut reed or draw water there; thatch and water both come from further off.","cleared":"The Reed Hollow is drained and burned. The reed cutters go back down."},{"name":"Potter's Field","of":"risen dead","appears":"The nameless graves in Potter's Field are opening from the inside.","while":"The dead wander in from the south each night; the gate shuts an hour earlier.","cleared":"Potter's Field is put down and dug over. The south gate keeps its hours."},{"name":"The Rookery Barn","of":"grave moths","appears":"Grave moths have taken the rookery barn, and the cloud of them is visible from the wall.","while":"Stored cloth, wool and grain sacks are eaten through; the market loses a stall a week.","cleared":"The Rookery Barn is smoked out. What is stored stays stored."},{"name":"The Split Stone","of":"cave centipedes","appears":"Something long and many-legged is coming up through the Split Stone, one after another.","while":"The quarry stands idle; building work in town stops where the stone runs out.","cleared":"The Split Stone is sealed and the nest burned. The quarry rings again."},{"name":"The Hog Mire","of":"mire boars","appears":"The mire boars have grown wrong and bold, and they hold the lower fields.","while":"The lower fields are rooted up; this season's crop is halved where they walk.","cleared":"The Hog Mire is cleared, and the town eats well for a week."},{"name":"The Chalk Pit","of":"bone crawlers","appears":"The chalk pit has filled with crawling things made mostly of other things' bones.","while":"Lime and chalk stop coming up; mortar runs out and the masons down tools.","cleared":"The Chalk Pit is cleared to the floor. The masons take up tools again."}],"wandering_boss":{"name":"The Scarred Lord","appears":"A lord has climbed out of the scar and walks the open country - and it has grown to match the town it hunts.","while":"It razes an outlying farm each day it roams, and draws the dark along behind it.","cleared":"The wandering lord falls in the open field. Bellmire drags the body home as proof.","note":"Scales to the town's level: a lesser lord early, a greater lord once Bellmire is a city. Reuse the eight canon lords; never a new one."}}};

// chapter tabs: id, label, icon (from ICON_SET), builder.
const LORE_CHAPTERS = [
  { id: "town",    label: "Town life",     icon: "town",  build: loreTownLife },
  { id: "growth",  label: "The town's growth", icon: "town",  build: loreGrowth   },
  { id: "e3po",    label: "Commander E3PO", icon: "shield", build: loreE3po    },
  { id: "lords",   label: "The dark lords", icon: "raid",  build: loreLords   },
  { id: "tales",   label: "Tales of the valley", icon: "lore", build: loreTales  },
];
let loreTab = "town";

function loreLines(arr) {
  // Render a list of lore strings as plain paragraphs. Every string goes through
  // el()/textContent - the hostile-name canary in ?mock=lore must render as text.
  const box = el("div", "lore-lines");
  for (const s of (Array.isArray(arr) ? arr : [])) {
    if (typeof s !== "string" || !s) continue;
    box.append(el("p", "lore-line", s));
  }
  return box;
}

function loreSubhead(text, iconId) {
  const h = el("h3", "lore-sub");
  if (iconId) h.append(icon(iconId, "lore-ic"));
  h.append(el("span", "lore-sub-t", text));
  return h;
}

function loreTownLife(box, src) {
  const tl = (src && src.town_life) || {};
  const sets = [
    { key: "crier",  label: "The crier's calls" },
    { key: "market", label: "At the market" },
    { key: "growth", label: "As the town grows" },
  ];
  for (const g of sets) {
    const lines = Array.isArray(tl[g.key]) ? tl[g.key] : [];
    if (!lines.length) continue;
    box.append(loreSubhead(g.label, "town"));
    box.append(loreLines(lines));
  }
}

function loreGrowth(box, src) {
  const tiers = (src && src.growth_tiers && Array.isArray(src.growth_tiers.tiers))
    ? src.growth_tiers.tiers : [];
  if (!tiers.length) { box.append(el("p", "lore-line", "The town has not yet named its stages.")); return; }
  const ol = el("ol", "lore-growth");
  for (const t of tiers) {
    if (!t || typeof t !== "object") continue;
    const li = el("li", "lore-tier");
    const head = el("div", "lore-tier-head");
    head.append(icon("town", "lore-ic"));
    head.append(el("span", "lore-tier-name", t.name || "a stage"));
    li.append(head);
    if (t.crier) li.append(el("p", "lore-line crier", t.crier));
    if (t.see)   li.append(el("p", "lore-line see", t.see));
    ol.append(li);
  }
  box.append(ol);
}

function loreE3po(box, src) {
  const e = (src && src.e3po) || {};
  const sets = [
    { key: "intro",     label: "When the Commander first speaks" },
    { key: "says",      label: "Things the Commander says" },
    { key: "town_talk", label: "The Commander on the town" },
  ];
  for (const g of sets) {
    const lines = Array.isArray(e[g.key]) ? e[g.key] : [];
    if (!lines.length) continue;
    box.append(loreSubhead(g.label, "shield"));
    box.append(loreLines(lines));
  }
}

function loreLords(box, src) {
  const li = (src && src.lord_intros) || {};
  const ui = (src && src.unique_intros) || {};
  const groups = [
    { label: "The deep lords", obj: li },
    { label: "The named ones", obj: ui },
  ];
  for (const g of groups) {
    const keys = Object.keys(g.obj || {});
    if (!keys.length) continue;
    box.append(loreSubhead(g.label, "raid"));
    const list = el("div", "lore-lords");
    for (const k of keys) {
      const text = g.obj[k];
      if (typeof text !== "string" || !text) continue;
      const row = el("div", "lore-lord");
      const nm  = el("div", "lore-lord-name");
      nm.append(icon("raid", "lore-ic"));
      // key is a page-owned lookup key, but render as text anyway (never markup).
      nm.append(el("span", "lore-lord-key", String(k).replace(/_/g, " ")));
      row.append(nm);
      row.append(el("p", "lore-line", text));
      list.append(row);
    }
    box.append(list);
  }
}

function loreTaleBlock(name, stages, iconId) {
  const card = el("article", "lore-tale");
  const head = el("h4", "lore-tale-head");
  head.append(icon(iconId || "lore", "lore-ic"));
  head.append(el("span", "lore-tale-name", name));
  card.append(head);
  for (const stg of stages) {
    if (!stg || !stg.text) continue;
    const row = el("p", "lore-line " + stg.cls);
    row.append(el("span", "lore-stage", stg.label + " "));
    row.append(document.createTextNode(stg.text));
    card.append(row);
  }
  return card;
}

function loreTales(box, src) {
  const dis = (src && src.disasters) || {};
  const evs = (src && src.events) || {};
  // Disasters: begin/during/pass/cost.
  const dKeys = Object.keys(dis);
  if (dKeys.length) {
    box.append(loreSubhead("Disasters", "raid"));
    const grid = el("div", "lore-tales");
    for (const k of dKeys) {
      const d = dis[k] || {};
      const during = Array.isArray(d.during) ? d.during.join(" ") : (d.during || "");
      const stages = [
         { label: "Begins:",  text: d.begin,  cls: "stg-begin" },
         { label: "During:",  text: during,   cls: "stg-during" },
         { label: "Passes:",  text: d.pass,   cls: "stg-pass" },
         { label: "Cost:",    text: d.cost,   cls: "stg-cost" },
      ];
      grid.append(loreTaleBlock(String(k).replace(/_/g, " "), stages, "raid"));
    }
    box.append(grid);
  }
  // Bandit camps / monster camps: appears/while/cleared.
  for (const [key, label, ic] of [["bandit_camps", "Bandit camps", "raid"], ["monster_camps", "Monster camps", "fight"]]) {
    const list = Array.isArray(evs[key]) ? evs[key] : [];
    if (!list.length) continue;
    box.append(loreSubhead(label, ic));
    const grid = el("div", "lore-tales");
    for (const c of list) {
      if (!c || typeof c !== "object") continue;
      const title = (c.name ? c.name : "a camp") + (c.leader ? " - " + c.leader : "") + (c.of ? " (" + c.of + ")" : "");
      const stages = [
        { label: "Appears:", text: c.appears, cls: "stg-begin" },
        { label: "While:",   text: c["while"], cls: "stg-during" },
        { label: "Cleared:", text: c.cleared, cls: "stg-pass" },
      ];
      grid.append(loreTaleBlock(title, stages, ic));
    }
    box.append(grid);
  }
  // Wandering boss: a single block.
  const wb = evs.wandering_boss;
  if (wb && typeof wb === "object") {
    box.append(loreSubhead("The wandering boss", "death"));
    const stages = [
      { label: "Appears:", text: wb.appears, cls: "stg-begin" },
      { label: "While:",   text: wb["while"], cls: "stg-during" },
      { label: "Cleared:", text: wb.cleared, cls: "stg-pass" },
      { label: "Note:",    text: wb.note,    cls: "stg-cost" },
    ];
    box.append(loreTaleBlock(wb.name || "the wanderer", stages, "death"));
  }
}

function renderLore() {
  const stamp = $("loreStamp");
  if (stamp) { stamp.textContent = "frozen from the game's own words (" + LORE_SRC_SHA + ", " + LORE_SRC_DATE + ")"; }
  const chipBox = $("loreChips");
  if (chipBox && !chipBox.firstChild) {
    for (const c of LORE_CHAPTERS) {
      const btn = el("button", "chip", c.label);
      btn.setAttribute("type", "button");
      btn.setAttribute("role", "tab");
      btn.dataset.tab = c.id;
      btn.addEventListener("click", () => { loreTab = c.id; renderLore(); });
      chipBox.append(btn);
    }
  }
  // mark selected chip
  if (chipBox) for (const b of chipBox.children) {
    const on = b.dataset && b.dataset.tab === loreTab;
    b.classList.toggle("on", !!on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  }
  // Chapter body
  const body = $("loreBody");
  if (!body) return;
  body.textContent = "";    // wipe; every child below is built with el().
  const src = (MOCK === "lore") ? LORE_FROZEN_MOCK : LORE_FROZEN;
  const ch  = LORE_CHAPTERS.find(c => c.id === loreTab) || LORE_CHAPTERS[0];
  try { ch.build(body, src); }
  catch (e) { body.append(el("p", "lore-line", "A chapter could not be drawn.")); }
}


// ---------------------------------------------------------------- bestiary (H19)
// What Bellmire has learned about what is down there. Words come ONLY from the frozen
// lore bundle (lord_intros, unique_intros, events.monster_camps) read as-is; this page
// invents no monster text. A sigil is a page-owned roundel: the name is hashed through
// the same FNV + mixer as the crests (crestRecipe) and the hash only picks INDICES into
// the constant whitelists below, so a lord's mark is drawn from a different charge set
// than any hero's crest and a hostile name can never become markup, URL or style.
// A beast is MET only when the browser's own remembered Chronicle names it; until then
// it is a RUMOUR - sigil and name present, everything else veiled. Optional numbers
// (faced, killed, deepest, standing) are read from p.bestiary[<page-owned key>] only
// when the publisher sends them; today it does not, and the page never estimates them.
const SIGIL_TINCT = ["#2a1c10", "#5a2a22", "#1d8f8a", "#c6922f", "#3a352e"];   // ink, oxblood, teal, gold, ash
const SIGIL_RING = "M50 4A46 46 0 1 1 49.99 4Z";
const SIGIL_DIV = [
  null,
  "M50 0H100V100H50Z",                    // per pale
  "M0 50H100V100H0Z",                     // per fess
  "M0 0L100 100H0Z",                      // per bend
  "M50 0L100 50L50 100L0 50Z",            // lozenge field
  "M0 74L50 36L100 74V100H0Z",            // chevron
];
const SIGIL_CHARGE = [
  "M30 28L45 28L38 78Z M55 28L70 28L62 78Z",                                       // fangs
  "M20 68C20 42 34 32 46 24C40 40 40 54 44 68Z M80 68C80 42 66 32 54 24C60 40 60 54 56 68Z",   // horns
  "M12 50C30 24 70 24 88 50C70 76 30 76 12 50Z M38 50a12 12 0 1 0 24 0a12 12 0 1 0 -24 0Z",   // eye
  "M28 22L40 22L52 80L42 80Z M46 18L58 18L70 76L60 76Z M62 22L74 22L84 70L76 70Z",             // claw
  "M50 16C58 36 74 46 70 66C68 80 58 86 50 86C42 86 32 80 30 66C28 52 40 46 42 36C46 44 48 34 50 16Z",   // flame
  "M12 64C26 38 44 30 50 22C56 30 74 38 88 64C76 58 66 60 58 68C54 60 46 60 42 68C34 60 24 58 12 64Z",  // wings
  "M28 28H72V42H42V50H72V74H28V60H58V56H28Z",                                      // coil
  "M24 76L28 36L40 54L50 28L60 54L72 36L76 76Z",                                    // broken crown
  "M24 30L32 22L78 68L70 76Z M76 30L68 22L22 68L30 76Z",                            // crossed bones
];
function sigil(name, size) {
  const r = crestRecipe("sigil|" + String(name == null ? "" : name));
  const dv = r.div % SIGIL_DIV.length, ch = r.ch % SIGIL_CHARGE.length;
  const ta = r.ta % SIGIL_TINCT.length;
  const tb = (ta + 1 + (r.tb % (SIGIL_TINCT.length - 1))) % SIGIL_TINCT.length;
  let tc = (tb + 1 + (r.tc % (SIGIL_TINCT.length - 1))) % SIGIL_TINCT.length;
  if (tc === ta) tc = (tc + 1) % SIGIL_TINCT.length;
  if (tc === tb) tc = (tc + 1) % SIGIL_TINCT.length;
  if (!document.getElementById("sig-clip")) {
    const defs = document.createElementNS(SVGNS, "svg");
    defs.setAttribute("class", "coa-defs"); defs.setAttribute("width", "0"); defs.setAttribute("height", "0");
    defs.setAttribute("aria-hidden", "true"); defs.setAttribute("focusable", "false");
    const clip = document.createElementNS(SVGNS, "clipPath"); clip.setAttribute("id", "sig-clip");
    const cp = document.createElementNS(SVGNS, "path"); cp.setAttribute("d", SIGIL_RING);
    clip.append(cp); defs.append(clip); document.body.append(defs);
  }
  const svg = document.createElementNS(SVGNS, "svg");
  svg.setAttribute("class", "sigil sigil-" + (size === "sm" ? "sm" : "md"));
  svg.setAttribute("viewBox", "0 0 100 100");
  svg.setAttribute("aria-hidden", "true"); svg.setAttribute("focusable", "false");
  const g = document.createElementNS(SVGNS, "g"); g.setAttribute("clip-path", "url(#sig-clip)");
  g.append(crestPath("M0 0H100V100H0Z", SIGIL_TINCT[ta]));
  if (SIGIL_DIV[dv]) g.append(crestPath(SIGIL_DIV[dv], SIGIL_TINCT[tb]));
  const c = crestPath(SIGIL_CHARGE[ch], SIGIL_TINCT[tc], SIGIL_TINCT[0]);
  c.setAttribute("fill-rule", "evenodd");
  g.append(c);
  svg.append(g, crestPath(SIGIL_RING, "none", SIGIL_TINCT[3]));
  return svg;
}

const BEAST_RUMOURS = [
  "Whispers only. The guild has not stood before it.",
  "Heard of, never met - and the town would keep it so.",
  "A name from the old tales. Nobody here has seen it.",
  "The sigil is all the guild has drawn of it so far.",
  "Spoken of low, behind the hand. Not yet faced.",
];
const BEAST_KINDS = { lord: "A deep lord", named: "A named one", kin: "A kin of the deep" };
let beastFilter = "all";
const BEAST_CHIPS = [["all", "All"], ["lord", "Deep lords"], ["named", "Named ones"], ["kin", "Kin of the deep"]];
const MOCK_BEAST_CHRON = [
  { t: "boss", s: "The Hollow King came up the stair and the guild met it at the door.", at: new Date(Date.now() - 50 * 60000).toISOString() },
  { t: "boss", s: "Heroes fell to the Hollow King before the watch drove it back.", at: new Date(Date.now() - 7 * 3600000).toISOString() },
  { t: "fight", s: "A bog frog the size of a cart was put down at the quarry.", at: new Date(Date.now() - 3 * 3600000).toISOString() },
  { t: "boss", s: "<img src=x onerror=alert(1)> was heard laughing in the dark.", at: new Date(Date.now() - 2 * 3600000).toISOString() },
];
function beastTerms(name) {
  const n = String(name).toLowerCase().replace(/_/g, " ").trim();
  const t = [n];
  if (/[^s]es$/.test(n)) t.push(n.replace(/es$/, ""));
  if (/s$/.test(n)) t.push(n.replace(/s$/, ""));
  return t.filter((x) => x.length >= 4);
}
// how many remembered Chronicle lines name any of the terms, and when the newest did
function beastMentions(rows, terms) {
  let n = 0, newest = 0;
  for (const r of rows) {
    const s = String(r && r.s != null ? r.s : "").toLowerCase();
    if (!s) continue;
    for (const t of terms) if (s.indexOf(t) >= 0) { n++; const ts = histTs(r); if (ts > newest) newest = ts; break; }
  }
  return { n, newest };
}
function beastNum(v) { return Number.isFinite(+v) && +v >= 0 ? Math.min(+v, 1e9) : null; }
function beastTitle(key) {
  return String(key).replace(/_/g, " ").replace(/\b[a-z]/g, (m) => m.toUpperCase());
}
function beastCard(b, rows, stats) {
  const m = beastMentions(rows, b.terms);
  const card = el("article", "beast " + (m.n ? "met" : "rumour"));
  const head = el("div", "beast-head");
  head.append(sigil(b.name, "md"));
  const hb = el("div", "beast-hb");
  hb.append(el("h3", "beast-name", b.name));
  hb.append(el("span", "beast-kind", BEAST_KINDS[b.kind] || ""));
  head.append(hb);
  card.append(head);
  if (!m.n) {
    card.append(el("span", "beast-flag", "Rumour"));
    let h = 0; for (let i = 0; i < b.name.length; i++) h = (h * 31 + b.name.charCodeAt(i)) >>> 0;
    card.append(el("p", "beast-veil", BEAST_RUMOURS[h % BEAST_RUMOURS.length]));
    return card;
  }
  card.append(el("span", "beast-flag met", "Met"));
  if (b.intro) card.append(el("p", "beast-intro", "\u201c" + b.intro + "\u201d"));
  for (const camp of arr(b.camps)) {
    const cb = el("p", "beast-camp");
    cb.append(el("strong", "", camp.name + ". "), document.createTextNode(camp.while));
    card.append(cb);
  }
  const facts = el("dl", "beast-facts");
  const add = (k, v) => { facts.append(el("dt", "", k), el("dd", "", v)); };
  add("Named in the Chronicle", num(m.n) + (m.n === 1 ? " remembered line" : " remembered lines"));
  const a = m.newest ? ago(new Date(m.newest).toISOString()) : null;
  if (a) add("Last named", a.text);
  if (stats) {
    const f = beastNum(stats.faced), k = beastNum(stats.killed), d = beastNum(stats.deepest);
    if (f != null) add("Times faced", num(f));
    if (k != null) add("Heroes it has killed", num(k));
    if (d != null) add("Deepest push against it", num(d));
    if (typeof stats.standing === "boolean") add("Today", stats.standing ? "It stands" : "It is down");
  }
  card.append(facts);
  return card;
}
// H24: the whole book as a list (page-owned lore constants), so the Bestiary and the finder agree
function beastBook() {
  const src = (MOCK === "lore" || MOCK === "bestiary") ? LORE_FROZEN_MOCK : LORE_FROZEN;
  const beasts = [];
  const li = (src && src.lord_intros) || {}, ui = (src && src.unique_intros) || {};
  for (const k of Object.keys(li)) if (typeof li[k] === "string") beasts.push({ kind: "lord", key: k, name: beastTitle(k), terms: beastTerms(k), intro: li[k] });
  for (const k of Object.keys(ui)) if (typeof ui[k] === "string") beasts.push({ kind: "named", key: k, name: beastTitle(k), terms: beastTerms(k), intro: ui[k] });
  const fam = new Map();
  for (const c of arr(src && src.events && src.events.monster_camps)) {
    if (!c || typeof c.of !== "string" || typeof c.name !== "string") continue;
    let f = fam.get(c.of);
    if (!f) { f = { kind: "kin", key: "kin:" + c.of, name: beastTitle(c.of), terms: beastTerms(c.of), camps: [] }; fam.set(c.of, f); }
    f.camps.push({ name: c.name, while: typeof c.while === "string" ? c.while : "" });
    for (const t of beastTerms(c.name)) f.terms.push(t);
  }
  for (const f of fam.values()) beasts.push(f);
  return beasts;
}
function renderBestiary(p) {
  const box = $("bestiaryBody");
  if (!box) return;
  const chipBox = $("bestiaryChips");
  if (chipBox && !chipBox.firstChild) {
    for (const [id, label] of BEAST_CHIPS) {
      const btn = el("button", "chip", label);
      btn.setAttribute("type", "button"); btn.dataset.f = id;
      btn.addEventListener("click", () => { beastFilter = id; renderBestiary(lastBeastPayload); });
      chipBox.append(btn);
    }
  }
  lastBeastPayload = p;
  if (chipBox) for (const b of chipBox.children) {
    const on = b.dataset.f === beastFilter;
    b.classList.toggle("on", on); b.setAttribute("aria-pressed", on ? "true" : "false");
  }
  box.textContent = "";
  let rows = chronMem.slice();
  const snap = p && p.bestiary && typeof p.bestiary === "object" ? p.bestiary : null;
  const statOf = (key) => (snap && Object.prototype.hasOwnProperty.call(snap, key) && snap[key] && typeof snap[key] === "object") ? snap[key] : null;
  const beasts = beastBook();
  const shown = beasts.filter((b) => beastFilter === "all" || b.kind === beastFilter);
  const metN = shown.filter((b) => beastMentions(rows, b.terms).n).length;
  const note = el("p", "beast-count", num(metN) + " met, " + num(shown.length - metN) + " still rumour");
  box.append(note);
  const grid = el("div", "beast-grid");
  // met first, then rumours; stable inside each group
  const ordered = shown.map((b, i) => ({ b, i, met: beastMentions(rows, b.terms).n ? 0 : 1 })).sort((x, y) => x.met - y.met || x.i - y.i);
  for (const o of ordered) {
    try { const bc = beastCard(o.b, rows, statOf(o.b.key)); bc.dataset.bi = String(beasts.indexOf(o.b)); grid.append(bc); } catch (e) { /* one bad entry never blanks the book */ }
  }
  box.append(grid);
}
let lastBeastPayload = null;

// ---------------------------------------------------------------- wiring
$("find").addEventListener("input", (e) => {
  heroFilter = e.target.value; heroShown = HERO_PAGE;
  if (last) renderHeroes(arr((MOCK ? withMock(last.payload) : last.payload).heroes));
});
$("boardFind").addEventListener("input", (e) => {
  boardFind = e.target.value;
  if (last) { const p = MOCK ? withMock(last.payload) : last.payload; renderBoards(arr(p.heroes), arr(p.fallen)); }
});
$("chronFind").addEventListener("input", (e) => { chronText = e.target.value; chronFocusKeep = 0; paintChronicle(); });
{
  const th = $("chronTopic");
  for (const t of CHRON_TOPICS) { const o = el("option", null, t.label); o.value = t.k; th.append(o); }
  th.addEventListener("change", () => { chronTopic = CHRON_TOPICS.some((x) => x.k === th.value) ? th.value : "all"; chronFocusKeep = 0; chronFiltSave(); paintChronicle(); });
  $("chronHero").addEventListener("change", (e) => { chronHero = ctrlStrip(e.target.value).slice(0, 40); chronFocusKeep = 0; chronFiltSave(); paintChronicle(); });
  $("chronClear").addEventListener("click", () => {
    chronHero = ""; chronTopic = "all"; chronOff = new Set(); chronText = ""; const f = $("chronFind"); if (f) f.value = "";
    chronFiltSave(); paintChronicle();
  });
}
// pause-on-hover: a poll that lands while the viewer is reading the feed is held,
// then applied when they move away, so lines don't reshuffle under the pointer.
(function () {
  const sec = $("chronicle");
  const enter = () => { chronHover = true; };
  const leave = () => { chronHover = false; if (chronPending) { chronPending = false; paintChronicle(); } };
  sec.addEventListener("mouseenter", enter);
  sec.addEventListener("mouseleave", leave);
  sec.addEventListener("focusin", enter);
  sec.addEventListener("focusout", (e) => { if (!sec.contains(e.relatedTarget)) leave(); });
})();

// ---------------------------------------------------------------- H13 tabs
// No-scroll, tabbed layout: one section at a time. The viewer picks with a nav
// button and the chosen panel's `.active` class makes it visible (see style.css).
//
// Storage is per-browser and best-effort: the last-picked tab id is kept in
// localStorage under TAB_KEY. Every READ goes through ctrlStrip + a 25-char cap
// and must match TABS (a page-authored whitelist) before it decides anything.
// The stored value is NEVER used as a URL, href, src, selector, query parameter
// or style - only to look up a known id in TABS. In a private window (storage
// throws) the page silently falls back to the default tab. (docs/HUB_SECURITY.md, H13.)
const TABS = ["boards","state","heroes","bands","chronicle","dice","roll","fallen","lore","bestiary","chat","commands"];
const TAB_KEY = "bellmire.tab";
function cleanTab(s) { return ctrlStrip(s).slice(0, 25); }
function getStoredTab() {
  try { const v = cleanTab(localStorage.getItem(TAB_KEY) || ""); return TABS.indexOf(v) >= 0 ? v : ""; }
  catch (e) { return ""; }
}
function storeTab(id) {
  try { if (TABS.indexOf(id) >= 0) localStorage.setItem(TAB_KEY, id); } catch (e) {}
}
function setActiveTab(id) {
  if (TABS.indexOf(id) < 0) id = TABS[0];
  for (const t of TABS) {
    const tab = $("tab-" + t);
    const panel = $(t);
    const on = (t === id);
    if (tab) { tab.setAttribute("aria-selected", on ? "true" : "false"); tab.tabIndex = on ? 0 : -1; }
    if (panel) { if (on) panel.classList.add("active"); else panel.classList.remove("active"); }
  }
  storeTab(id);
}
(function wireTabs() {
  const navEl = $("tabs");
  if (!navEl) return;
  navEl.addEventListener("click", (e) => {
    const b = e.target && e.target.closest ? e.target.closest("button[role='tab']") : null;
    if (!b || !navEl.contains(b)) return;
    e.preventDefault();
    const id = cleanTab(b.getAttribute("data-tab") || "");
    if (TABS.indexOf(id) >= 0) setActiveTab(id);
  });
  navEl.addEventListener("keydown", (e) => {
    const cur = e.target;
    if (!cur || cur.getAttribute == null || cur.getAttribute("role") !== "tab") return;
    const i = TABS.indexOf(cleanTab(cur.getAttribute("data-tab") || ""));
    if (i < 0) return;
    let j = -1;
    if (e.key === "ArrowRight" || e.key === "ArrowDown") j = (i + 1) % TABS.length;
    else if (e.key === "ArrowLeft" || e.key === "ArrowUp") j = (i - 1 + TABS.length) % TABS.length;
    else if (e.key === "Home") j = 0;
    else if (e.key === "End") j = TABS.length - 1;
    if (j < 0) return;
    e.preventDefault();
    setActiveTab(TABS[j]);
    const next = $("tab-" + TABS[j]);
    if (next) next.focus();
  });
  // ?open=1 opens the first hero's sheet; land on Heroes so the opened sheet is visible.
  // H21.4: "#moment-<n>" opens the Chronicle on a remembered line. n is an integer the PAGE
  // assigned to that line; it is only ever compared to the ids on rendered rows - never put
  // in a URL, src, href, selector or style - and the tab chosen is a constant from TABS.
  const momentFrom = () => { const m = /^moment-(\d{1,9})$/.exec(String(location.hash || "").replace(/^#/, "")); return m && +m[1] > 0 ? +m[1] : 0; };
  const mid = momentFrom();
  if (mid) chronFocusId = mid;
  const initial = (mid ? "chronicle" : "") || (params.get("open") ? "heroes" : "") || getStoredTab() || TABS[0];
  setActiveTab(initial);
  window.addEventListener("hashchange", () => {
    const n = momentFrom();
    if (!n) return;
    chronFocusId = n; setActiveTab("chronicle"); if (chronData) paintChronicle();
  });
})();

// ---------------------------------------------------------------- H25 night watch
// A long-session mode for a page left open beside the stream: a dimmed palette and an ambient
// layout (town strip, status line, Chronicle and Bands side by side; the finder, tabs, filters and
// footer fold away). It is ONE class on <html> (CSS does all the work) - no snapshot value is
// involved, nothing is fetched, and nothing about it touches the DOM the renderers build.
// The choice is per-browser: localStorage under a page-owned key, and the value read back is
// compared to a two-item whitelist before it decides anything (private windows throw: then the
// page simply starts in the full layout). ?watch=1 turns it on for a visit without storing it.
const WATCH_KEY = "bellmire.watch.v1";
const WATCH_LABEL = { on: "Back to the full page", off: "Night watch" };
const WATCH_HINT  = { on: "Dim and quiet: the town, the Chronicle and who is below.", off: "A dim, quiet page for a second screen." };
function getStoredWatch() {
  try { return ctrlStrip(localStorage.getItem(WATCH_KEY) || "").slice(0, 12) === "watch" ? "watch" : ""; }
  catch (e) { return ""; }
}
function applyWatch(on, keep) {
  const root = document.documentElement;
  root.classList.toggle("watch", !!on);
  const btn = $("watchBtn"), hint = $("watchHint");
  if (btn) btn.textContent = on ? WATCH_LABEL.on : WATCH_LABEL.off;
  if (hint) hint.textContent = on ? WATCH_HINT.on : WATCH_HINT.off;
  if (keep) { try { if (on) localStorage.setItem(WATCH_KEY, "watch"); else localStorage.removeItem(WATCH_KEY); } catch (e) {} }
}
(function wireWatch() {
  const btn = $("watchBtn");
  if (!btn) return;
  btn.addEventListener("click", () => applyWatch(!document.documentElement.classList.contains("watch"), true));
  applyWatch(params.get("watch") === "1" || getStoredWatch() === "watch", false);
})();

load();
setInterval(load, REFRESH_MS);
setInterval(showStatus, 15000);

// ---------------------------------------------------------------- test hooks
// Local only (?mock=...), harmless: they stand in for data the town has not
// published yet. The hostile name is deliberate - it must render as literal text.
// ?mock=lore: the hostile-name canary at the start of the crier list. The lore
// bundle is page-authored, but lore_lines.json CAN carry future viewer-shaped text,
// so this proves renderLore() escapes an attacker string before it reaches the DOM.
const LORE_FROZEN_MOCK = (function () {
  // shallow clone + splice in a hostile line; LORE_FROZEN itself is untouched.
  const c = Object.assign({}, LORE_FROZEN);
  c.town_life = Object.assign({}, LORE_FROZEN.town_life);
  c.town_life.crier = ["<img src=x onerror=alert(1)>"].concat(LORE_FROZEN.town_life.crier || []);
  c.lord_intros = Object.assign({}, LORE_FROZEN.lord_intros, {
    "<img src=x onerror=alert(1)>": "A hostile key must render as text in the lord list.",
  });
  return c;
})();

const MOCK_CHRONICLE = [
  { t: "death", s: "Grimhollow the Knight fell on floor 7, run through by a bone-knight.", at: new Date(Date.now() - 2 * 60000).toISOString() },
  { t: "fight", s: "<img src=x onerror=alert(1)> struck a cave troll for 14 and lived to say so.", at: new Date(Date.now() - 9 * 60000).toISOString() },
  { t: "loot", s: "A teal-dyed cloak and 230 gold came up out of the scar.", at: new Date(Date.now() - 24 * 60000).toISOString() },
  { t: "raid", s: "Bandits tested the west gate and were turned back by the watch.", at: new Date(Date.now() - 95 * 60000).toISOString() },
  { t: "town", s: "Bellmire reached town level 4; the treasury stands at 1,280 gold.", at: new Date(Date.now() - 3 * 3600000).toISOString() },
  { t: "delve", s: "Four delvers went down together and three came back up.", at: new Date(Date.now() - 5 * 3600000).toISOString() },
  { t: "lore", s: "The guild writes that the scar was a well before it was a wound.", at: new Date(Date.now() - 26 * 3600000).toISOString() },
  { t: "wat", s: "A kind the page has never heard of, which must still render.", at: new Date(Date.now() - 30 * 3600000).toISOString() },
  { t: "fight", s: "A stat line with no stamp at all.", at: "" },
];
// ?mock=roll: stand-in town rolls (the publisher sends no rolls yet). Exercises every
// tier, a cost-less entry, and - deliberately - the hostile name as the roller, which
// must render as literal text. The hostile entry is NOT the newest, so the die's
// announcement shows a safe name while the feed proves the escape on the hostile one.
const MOCK_ROLLS = [
  { n: 20, by: "Brum the Cooper", what: "Raise the watchtower on the west wall", tier: "crit", cost: "800 channel points",
    result: "A natural twenty — the tower is up in a day and the masons sing. The west wall has never been safer.", at: new Date(Date.now() - 1 * 60000).toISOString() },
  { n: 3, by: "<img src=x onerror=alert(1)>", what: "Lower the gate toll on outsiders", tier: "bad", cost: "500 bits",
    result: "It goes badly: smugglers slip in among the merchants and the treasury is lighter by morning.", at: new Date(Date.now() - 6 * 60000).toISOString() },
  { n: 11, by: "Sedge the Toll", what: "Call a harvest festival", tier: "mixed", cost: "300 channel points",
    result: "A mixed result — the ale flows and spirits lift, but three delvers are too merry to go down the next day.", at: new Date(Date.now() - 22 * 60000).toISOString() },
  { n: 1, by: "Cob Ashfoot", what: "Conscript the farmhands into the militia", tier: "fumble", cost: "650 bits",
    result: "A fumble. The recruits drill into each other, a hayrick catches fire, and the fields stand untended.", at: new Date(Date.now() - 55 * 60000).toISOString() },
  { n: 17, by: "The Weasel", what: "Bless the delvers before the descent", tier: "good",
    result: "It goes well: the party goes down under a good omen and all four come home whole.", at: new Date(Date.now() - 3 * 3600000).toISOString() },
];
// ?mock=bands: stand-in delving parties (the publisher sends no p.parties yet, D46).
// Exercises a healthy member, an injured member (hp/max -> real depletion), a member
// with hp but no max (flat vitality bar), a member with NO hp (name only, no bar), a
// burning member, a fallen member, and an UNKNOWN status (rendered as its own text).
// The hostile name is used as BOTH a band name and a member name - it must render as
// literal text, never execute.
const MOCK_PARTIES = [
  { name: "The Ford Wardens", floor: 7, members: [
    { name: "Brum the Cooper", hp: 34, max_hp: 40, status: "ok", class: "knight" },
    { name: "Sedge the Toll", hp: 9, max_hp: 44, status: "burning", class: "ranger" },
    { name: "<img src=x onerror=alert(1)>", hp: 0, max_hp: 38, status: "fallen", class: "mage" },
    { name: "Cob Ashfoot", hp: 21, status: "ok", class: "rogue" },
  ] },
  { name: "<img src=x onerror=alert(1)>", floor: 3, members: [
    { name: "The Weasel", hp: 12, max_hp: 26, status: "poisoned" },
    { name: "Maddock", status: "ok" },
  ] },
  { name: "Lone Delver", members: [
    { name: "Grey Pell", hp: 18, max_hp: 30, status: "ok", class: "cleric" },
  ] },
];
// ?mock=fallen: a rich memorial row, a hostile name carrying every field, a bare name-only
// row, and a row of odd types (nulls, NaN) - all must render cleanly, no "undefined".
// ?mock=sheets (H20): three sheets that must each read as finished - a fresh level-1 hero with
// almost nothing, a kitted veteran carrying every optional field, and a fallen hero - plus a
// hostile name that must render as literal text.
const MOCK_SHEET_HEROES = [
  { name: "Pip", class: "rogue", species: "human", level: 1, ac: 11, hp: 8, xp: 0, gold: 3, deepest: 0, kills: 0, delves: 0,
    gear: { main_hand: "rusty dagger", body: "rags" }, last_seen: new Date(Date.now() - 4000).toISOString(),
    events: [{ t: "town", s: "Pip signed the guild ledger.", at: new Date(Date.now() - 4000).toISOString() }] },
  { name: "Brum the Cooper", class: "knight", species: "dwarf", level: 9, rank: "Veteran", title: "the Bold", standing: 212,
    ac: 18, hp: 61, max_hp: 88, xp: 4200, xp_next: 5000, to_hit: 7, prof: 4, saves: "STR +7, CON +6", initiative: 1, speed: 25,
    stats: { str: 18, dex: 12, con: 16, int: 9, wis: 11, cha: 10 }, weapon: { name: "warhammer", dice: "1d10+4" }, armour: { name: "plate" },
    gear: { off_hand: "tower shield", head: "iron helm", hands: "gauntlets", feet: "greaves", ring: "Ring of the Ford" },
    worn: "a corgi, a crown", dye: "teal", gold: 540, oil: 2, potions: 3, kills: 140, deepest: 31, delves: 22, status: "delving",
    last_seen: new Date(Date.now() - 55 * 60000).toISOString(),
    events: [{ t: "delve", s: "Brum the Cooper led the Ford Wardens down to floor 7.", at: new Date(Date.now() - 600000).toISOString() },
             { t: "fight", s: "Brum the Cooper broke a bone-knight on floor 6.", at: new Date(Date.now() - 3600000).toISOString() }] },
  { name: "<img src=x onerror=alert(1)>", class: "mage", species: "elf", level: 4, ac: 12, hp: 14, max_hp: 22, xp: 900, gold: 12, kills: 9, deepest: 5, delves: 4,
    weapon: { name: "oak staff", dice: "1d6" }, last_seen: "<img src=x onerror=alert(1)>",
    events: [{ t: "loot", s: "<img src=x onerror=alert(1)> found a scar-touched gem.", at: new Date(Date.now() - 900000).toISOString() }] },
];
const MOCK_SHEET_FALLEN = [
  { name: "Grimhollow", class: "knight", species: "orc", level: 9, kills: 140, deepest: 31, killed_by: "a bone-knight", epitaph: "Went deepest. Came back once.", day: 12, title: "the Grim", weapon: { name: "greatsword" }, armour: { name: "mail" } },
];
const MOCK_SHEET_PARTIES = [{ name: "The Ford Wardens", floor: 7, members: [{ name: "Brum the Cooper", hp: 30, max_hp: 88, status: "burning", class: "knight" }, { name: "Pip", hp: 8, status: "ok" }] }];
const MOCK_SHEET_CHRON = [
  { t: "delve", s: "Brum the Cooper led the Ford Wardens down to floor 7.", at: new Date(Date.now() - 600000).toISOString() },
  { t: "fight", s: "Brum the Cooper broke a bone-knight on floor 6.", at: new Date(Date.now() - 3600000).toISOString() },
  { t: "death", s: "Grimhollow fell to a bone-knight on floor 31.", at: new Date(Date.now() - 7200000).toISOString() },
  { t: "loot", s: "<img src=x onerror=alert(1)> found a scar-touched gem.", at: new Date(Date.now() - 900000).toISOString() },
];
const MOCK_FALLEN = [
  { name: "Grimhollow", class: "knight", level: 9, kills: 140, deepest: 31, killed_by: "a bone-knight", epitaph: "Went deepest. Came back once.", day: 12, title: "the Bold", weapon: { name: "Warhammer" }, armour: "Chain shirt" },
  { name: "<img src=x onerror=alert(1)>", class: "mage", level: 4, kills: 1, deepest: 3, killed_by: "<b>a hostile</b>", epitaph: "<script>alert(1)</script>", day: 3, weapon: "oak staff", armour: { name: "<i>robe</i>" } },
  { name: "Wren" },
  { name: "Odd", class: null, level: "x", kills: NaN, deepest: null, killed_by: "", epitaph: "", weapon: null, armour: {} },
];
const MOCK_TOWN_CHRON = [
  { t: "raid", s: "<img src=x onerror=alert(1)> led a raid on the east gate; the watch held.", at: new Date(Date.now() - 40 * 60000).toISOString() },
  { t: "town", s: "Fire in Craft Row - a forge banked wrong, and the wind unkind.", at: new Date(Date.now() - 4 * 3600000).toISOString() },
  { t: "town", s: "Day 17 begins  -  48 souls, 1280 gold, Village (lvl 3, steady)", at: new Date(Date.now() - 4 * 3600000).toISOString() },
  { t: "town", s: "Bellmire grows into Village.  (town level 3)", at: new Date(Date.now() - 27 * 3600000).toISOString() },
  { t: "raid", s: "Bandits tested the west road; the caravans came through bled.", at: new Date(Date.now() - 52 * 3600000).toISOString() },
];
function withMock(p) {
  const out = Object.assign({}, p);
  if (MOCK === "chronicle") out.chronicle = MOCK_CHRONICLE;
  if (MOCK === "bestiary") {         // H19: one met lord with real numbers, rumours, hostile name
    out.chronicle = MOCK_BEAST_CHRON;
    out.bestiary = { hollow_king: { faced: 3, killed: 2, deepest: 7, standing: true } };
  }
  if (MOCK === "sheets") {            // H20: bare L1 hero, kitted veteran, a fallen hero; hostile strings throughout
    out.heroes = MOCK_SHEET_HEROES; out.fallen = MOCK_SHEET_FALLEN; out.parties = MOCK_SHEET_PARTIES; out.chronicle = MOCK_SHEET_CHRON;
  }
  if (MOCK === "roll") out.rolls = MOCK_ROLLS;
  if (MOCK === "bands") out.parties = MOCK_PARTIES;
  if (MOCK === "fallen") out.fallen = MOCK_FALLEN;
  if (MOCK === "town") {            // H18: a town with every new field, hostile strings included
    out.town = Object.assign({}, p.town, {
      name: "<img src=x onerror=alert(1)>", level: 3, souls: 48, day: 17, treasury: 1280, renown: 64,
      raids_turned: 5, score: 120, next_level_at: 300,
      buildings: ["The Well", { name: "<img src=x onerror=alert(1)> Forge", built: true, does: "<b>hostile</b> text that must stay text" },
                  { name: "Watchtower", built: false }, { name: "" }, 7, null],
    });
    out.chronicle = MOCK_CHRONICLE.concat(MOCK_TOWN_CHRON);
  }
  if (MOCK === "crowd") {
    const classes = ["knight", "rogue", "mage", "ranger"], species = ["dwarf", "human", "elf", "orc"];
    const weapons = ["sword", "oak staff", "shortbow", "warhammer"];
    const dyes = ["teal", "gold", "red", "purple"], titles = ["the Bold", "Scarbane", "the Quick", "Emberkin"];
    const made = [];
    // 200 heroes: H3's DONE line asks for "?mock=crowd 200 fast", and 40 never
    // exercised the HERO_PAGE=60 paging. 200 does (4 pages), and the boards rank it.
    for (let i = 0; i < 200; i++) {
      made.push({
        name: i === 0 ? "<img src=x onerror=alert(1)>" : "Hero" + String(i).padStart(2, "0"),
        class: classes[i % 4], species: species[i % 4], level: 1 + (i % 9), rank: "Delver",
        standing: (i * 37) % 300, ac: 12 + (i % 6), hp: 20 + i, gold: (i * 53) % 900,
        kills: (i * 7) % 60, deepest: i % 13, delves: i % 11, xp: i * 10, to_hit: 4, prof: 2,
        saves: "STR +4", stats: { str: 10 + (i % 8), dex: 12, con: 13, int: 9, wis: 11, cha: 8 },
        weapon: { name: weapons[i % 4], dice: "1d8", sell: 30 + (i % 20) }, armour: { name: "mail", sell: i % 4 === 0 ? 45 : undefined },
        // a few heroes carry the forward-compatible fields, to exercise the real
        // HP/XP bars, the dye swatch and a title (the publisher can add these any time)
        max_hp: i % 3 === 0 ? 40 + i * 2 : undefined,
        xp_next: i % 2 === 0 ? 100 + i * 5 : undefined,
        worn: i % 5 === 0 ? "a corgi, a crown" : "",
        dye: i % 4 === 0 ? dyes[(i / 4) % 4 | 0] : undefined,
        title: i % 6 === 0 ? titles[(i / 6) % 4 | 0] : "",
        satchel: i < 3 ? [
          { name: i === 0 ? "<img src=x onerror=alert(1)>" : "Moonlit dagger", qty: 1, sell: 120, kind: "weapon" },
          { name: "Healing draught", qty: 2, sell: 15, kind: "potion" },
          { name: "Scar-touched gem", sell: 300, kind: "gem" },
          { name: "A curio of no fixed worth", kind: "trinket" },
        ] : undefined,
        oil: i % 4, potions: i % 3, brews: "",
      });
    }
    made[3].gold = made[4].gold = 777;
    out.heroes = made.concat(arr(p.heroes));
    out.fallen = [{ name: "Grimhollow", class: "knight", level: 9, kills: 140, deepest: 31, killed_by: "a bone-knight", epitaph: "Went deepest. Came back once.", day: 12 }].concat(arr(p.fallen));
    out.chronicle = MOCK_CHRONICLE;   // so ?mock=crowd exercises the feed too
  }
  return out;
}


// ---------------------------------------------------------------- H13 tabs
// A no-scroll layout: the existing <nav>'s anchors become tab buttons that
// show one section at a time, so a viewer does not scroll one page end to
// end. Purely a layout rework (docs/WORK_PLAN H13) - NO new data, NO new
// fetch, NO CSP change, NO snapshot string reaches the DOM through this
// code. Every id below is a page-owned constant taken from the nav we
// author ourselves; a saved choice from localStorage is validated against
// that same whitelist before use and is NEVER used as a URL, selector or
// innerHTML. Reduced-motion is honoured because no transitions are added.
function setUpTabs() {
  const navEl = document.querySelector("nav");
  if (!navEl) return;
  const anchors = Array.from(navEl.querySelectorAll('a[href^="#"]'));
  if (!anchors.length) return;

  // Whitelist built from THIS page's own nav + sections; nothing else is ever
  // a candidate tab. A href whose body is not a plain id, or whose target is
  // not an actual <section>, is dropped.
  const TABS = [];
  for (const a of anchors) {
    const id = String(a.getAttribute("href") || "").replace(/^#/, "");
    if (!id || !/^[a-zA-Z][a-zA-Z0-9_-]{0,24}$/.test(id)) continue;
    const panel = document.getElementById(id);
    if (!panel || panel.tagName !== "SECTION") continue;
    TABS.push({ id, anchor: a, panel });
  }
  if (!TABS.length) return;

  const wrap = document.querySelector(".wrap");
  if (wrap) wrap.setAttribute("data-tabbed", "1");

  navEl.setAttribute("role", "tablist");
  TABS.forEach(({ id, anchor, panel }, i) => {
    anchor.setAttribute("role", "tab");
    anchor.setAttribute("aria-controls", id);
    anchor.setAttribute("id", "tab-" + id);
    anchor.setAttribute("tabindex", i === 0 ? "0" : "-1");
    anchor.setAttribute("aria-selected", "false");
    panel.setAttribute("role", "tabpanel");
    panel.setAttribute("aria-labelledby", "tab-" + id);
    panel.setAttribute("tabindex", "-1");
  });

  const TAB_KEY = "bellmire.tab";
  function readSaved() {
    try {
      const raw = localStorage.getItem(TAB_KEY) || "";
      // Control-strip + 25-cap (same shape as cleanName, see MY_HERO). The
      // cleaned value is only ever COMPARED to the whitelist - we never pass
      // it to querySelector, document.getElementById, a URL, or innerHTML.
      const clean = ctrlStrip(raw).slice(0, 25);
      for (const t of TABS) if (t.id === clean) return t.id;
    } catch (e) {}
    return "";
  }
  function writeSaved(id) {
    try { localStorage.setItem(TAB_KEY, String(id).slice(0, 25)); } catch (e) {}
  }

  function show(id, opts) {
    const save = !opts || opts.save !== false;
    const focusPanel = !!(opts && opts.focusPanel);
    const found = TABS.find(t => t.id === id);
    const chosen = found || TABS[0];
    for (const t of TABS) {
      const on = (t.id === chosen.id);
      t.anchor.setAttribute("aria-selected", on ? "true" : "false");
      t.anchor.setAttribute("tabindex", on ? "0" : "-1");
      if (on) t.panel.classList.remove("tab-hidden");
      else t.panel.classList.add("tab-hidden");
    }
    if (save) writeSaved(chosen.id);
    // H17: on a phone the tab strip scrolls sideways - keep the lit tab in view
    // (set scrollLeft directly so the page itself never scrolls sideways).
    try {
      const a = chosen.anchor;
      if (navEl.scrollWidth > navEl.clientWidth) {
        navEl.scrollLeft = Math.max(0, a.offsetLeft - (navEl.clientWidth - a.offsetWidth) / 2);
      }
    } catch (e) {}
    if (focusPanel) {
      try { chosen.panel.focus({ preventScroll: true }); } catch (e) { try { chosen.panel.focus(); } catch (e2) {} }
    }
    // Keep the sticky nav visible at the top after a switch - avoids the
    // phone-view surprise where a tab change leaves you scrolled mid-page.
    try { window.scrollTo({ top: 0, behavior: "auto" }); } catch (e) {}
  }

  navEl.addEventListener("click", (ev) => {
    const a = ev.target && ev.target.closest ? ev.target.closest('a[role="tab"]') : null;
    if (!a || !navEl.contains(a)) return;
    const id = String(a.getAttribute("aria-controls") || "");
    if (!TABS.find(t => t.id === id)) return;
    ev.preventDefault();
    show(id);
    try { history.replaceState(null, "", "#" + id); } catch (e) {}
    try { a.focus(); } catch (e) {}
  });

  navEl.addEventListener("keydown", (ev) => {
    const a = ev.target && ev.target.closest ? ev.target.closest('a[role="tab"]') : null;
    if (!a) return;
    const idx = TABS.findIndex(t => t.anchor === a);
    if (idx < 0) return;
    let to = -1;
    const k = ev.key;
    if (k === "ArrowRight" || k === "ArrowDown") to = (idx + 1) % TABS.length;
    else if (k === "ArrowLeft" || k === "ArrowUp") to = (idx - 1 + TABS.length) % TABS.length;
    else if (k === "Home") to = 0;
    else if (k === "End") to = TABS.length - 1;
    else if (k === "Enter" || k === " ") { ev.preventDefault(); show(TABS[idx].id); try { TABS[idx].anchor.focus(); } catch (e) {} return; }
    if (to >= 0) {
      ev.preventDefault();
      show(TABS[to].id);
      try { TABS[to].anchor.focus(); } catch (e) {}
    }
  });

  // Starting tab: URL hash wins (so a shared link still works), then the saved
  // choice, then the first tab. The hash and saved values are BOTH validated
  // against the whitelist above before anything is shown.
  const hashId = String((location.hash || "").replace(/^#/, ""));
  const hashMatch = TABS.find(t => t.id === hashId);
  const start = hashMatch ? hashMatch.id : (readSaved() || TABS[0].id);
  show(start, { save: !!hashMatch });

  window.addEventListener("hashchange", () => {
    const id = String((location.hash || "").replace(/^#/, ""));
    if (TABS.find(t => t.id === id)) show(id);
  });
}
setUpTabs();

// ---------------------------------------------------------------- H24 the finder
// One search field that looks across everything this page already holds in memory:
// living heroes, the fallen, bands, the Bestiary's lords and remembered Chronicle
// lines. PAGE-LOCAL ONLY: no fetch, no new origin, no write path. Every result row is
// built with el() (textContent) - a hero called <img src=x onerror=alert(1)> shows as
// text. A result addresses its target by an INTEGER index/id the page owns (data-fi,
// data-bi, #moment-n); no snapshot string is ever put in a URL, selector, src, href or
// style. It never captures keys while the viewer is typing in another field.
const FIND_MIN = 2, FIND_PER = 6, FIND_MAX = 24;
const FIND_KIND = { hero: "Hero", fallen: "Fallen", band: "Band", lord: "Lord", moment: "Moment" };
let finderRes = [], finderSel = -1;
function finderPayload() { return last ? (MOCK ? withMock(last.payload) : last.payload) : null; }
function finderQuery() { const i = $("finderInput"); return i ? ctrlStrip(i.value).slice(0, 60).trim().toLowerCase() : ""; }
function finderRank(text, q) {
  const t = String(text).toLowerCase();
  const at = t.indexOf(q);
  if (at < 0) return -1;
  if (at === 0) return 0;
  return /[^a-z0-9]/.test(t.charAt(at - 1)) ? 1 : 2;
}
function finderSearch(q) {
  const p = finderPayload();
  const groups = { hero: [], fallen: [], band: [], lord: [], moment: [] };
  const add = (g, r, rank) => { r.g = g; r.rank = rank; groups[g].push(r); };
  if (p && typeof p === "object") {
    arr(p.heroes).forEach((h, i) => {
      const n = nameOf(h); const k = n ? finderRank(n, q) : -1; if (k < 0) return;
      const lvl = Number.isFinite(+h.level) && +h.level > 0 ? "level " + num(h.level) : "";
      add("hero", { text: n, sub: [h.class ? cap(String(h.class)) : "", lvl].filter(Boolean).join(", "), i }, k);
    });
    arr(p.fallen).forEach((f, i) => {
      if (f == null || typeof f !== "object") return;
      const n = nameOf(f); const k = n ? finderRank(n, q) : -1; if (k < 0) return;
      add("fallen", { text: n, sub: f.killed_by ? "taken by " + String(f.killed_by) : "in The Fallen", i }, k);
    });
    normalizeParties(p.parties != null ? p.parties : p.bands).forEach((b, i) => {
      const k = b.name ? finderRank(b.name, q) : -1;
      if (k >= 0) add("band", { text: b.name, sub: "a band in the scar", i }, k);
      for (const m of b.members) {
        const mk = m.name ? finderRank(m.name, q) : -1;
        if (mk >= 0) add("band", { text: m.name, sub: "delving with " + (b.name || "a band"), i }, mk);
      }
    });
  }
  try {
    beastBook().forEach((b, i) => {
      let k = finderRank(b.name, q);
      for (const t of arr(b.terms)) { const kk = finderRank(t, q); if (kk >= 0 && (k < 0 || kk < k)) k = kk; }
      if (k >= 0) add("lord", { text: b.name, sub: BEAST_KINDS[b.kind] || "", i }, k);
    });
  } catch (e) { /* the book must never break the finder */ }
  chronMemEnsure();
  for (const r of chronMem) {
    if (!r || !r.n || typeof r.s !== "string") continue;
    const k = finderRank(r.s, q); if (k < 0) continue;
    const a2 = r.at ? ago(r.at) : null;
    add("moment", { text: r.s.length > 120 ? r.s.slice(0, 117) + "\u2026" : r.s, sub: a2 ? a2.text : "remembered", n: r.n | 0, ts: histTs(r) }, k);
  }
  const out = [];
  for (const g of ["hero", "fallen", "band", "lord", "moment"]) {
    groups[g].sort((x, y) => x.rank - y.rank || (g === "moment" ? y.ts - x.ts : 0));
    for (const r of groups[g].slice(0, FIND_PER)) out.push(r);
  }
  // best match first across every group (a name that STARTS with the query beats a word buried in a line);
  // the sort is stable, so ties keep the hero > fallen > band > lord > moment order
  out.sort((x, y) => x.rank - y.rank);
  return out.slice(0, FIND_MAX);
}
function finderOpenState(on) {
  const panel = $("finderPanel"), inp = $("finderInput");
  if (panel) panel.classList.toggle("hide", !on);
  if (inp) { inp.setAttribute("aria-expanded", on ? "true" : "false"); if (!on) inp.removeAttribute("aria-activedescendant"); }
}
function finderSelect(i) {
  const rows = $("finderList").children;
  if (!rows.length) { finderSel = -1; return; }
  finderSel = (i + rows.length) % rows.length;
  for (let j = 0; j < rows.length; j++) rows[j].setAttribute("aria-selected", j === finderSel ? "true" : "false");
  $("finderInput").setAttribute("aria-activedescendant", rows[finderSel].id);
  try { rows[finderSel].scrollIntoView({ block: "nearest" }); } catch (e) {}
}
function finderPaint() {
  const box = $("finderList"), note = $("finderNote");
  if (!box || !note) return;
  box.replaceChildren(); finderSel = -1; finderRes = [];
  const q = finderQuery();
  if (q.length < FIND_MIN) { note.textContent = ""; finderOpenState(false); return; }
  finderRes = finderSearch(q);
  finderOpenState(true);
  if (!finderRes.length) {
    const nothing = !finderPayload();
    note.className = "finder-note finder-none";
    note.textContent = nothing
      ? "The town has not reported yet, so there is nothing here to search."
      : "Nothing this page has seen matches \u201c" + q + "\u201d. The finder searches only what is in this browser: the town as last reported and about two days of remembered Chronicle. A name it has never seen cannot be found here.";
    return;
  }
  note.className = "finder-note";
  note.textContent = finderRes.length + (finderRes.length === 1 ? " place" : " places") + " to go. Up and down to choose, Enter to open, Escape to close.";
  finderRes.forEach((r, i) => {
    const li = el("li", "finder-row finder-" + r.g);
    li.id = "finder-opt-" + i;
    li.setAttribute("role", "option"); li.setAttribute("aria-selected", "false");
    li.append(el("span", "fkind", FIND_KIND[r.g]), el("span", "ftext", r.text));
    if (r.sub) li.append(el("span", "fsub", r.sub));
    li.addEventListener("mousedown", (ev) => ev.preventDefault());      // keep focus in the field
    li.addEventListener("click", () => finderOpen(r));
    box.append(li);
  });
  finderSelect(0);
}
function finderLand(node) {
  if (!node) return;
  node.classList.add("finder-hit");
  node.setAttribute("tabindex", "-1");
  const calm = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  try { node.scrollIntoView({ block: "center", behavior: calm ? "auto" : "smooth" }); } catch (e) {}
  try { node.focus({ preventScroll: true }); } catch (e) {}
  setTimeout(() => node.classList.remove("finder-hit"), 3200);
}
function finderOpen(r) {
  const p = finderPayload();
  const inp = $("finderInput");
  finderOpenState(false);
  if (inp) inp.value = "";
  if (!r || !p) return;
  if (r.g === "hero") {
    heroFilter = r.text; heroShown = HERO_PAGE;
    const f = $("find"); if (f) f.value = r.text;
    renderHeroes(arr(p.heroes));
    setActiveTab("heroes");
    const card = [...$("heroList").querySelectorAll("details.hero")].find((d) => (d.querySelector(".hname") || {}).textContent === r.text);
    if (card) { card.open = true; finderLand(card); }
  } else if (r.g === "fallen") {
    setActiveTab("fallen");
    finderLand($("fallenList").querySelector('[data-fi="' + (r.i | 0) + '"]'));
  } else if (r.g === "band") {
    setActiveTab("bands");
    finderLand($("bandList").querySelector('[data-bi="' + (r.i | 0) + '"]'));
  } else if (r.g === "lord") {
    beastFilter = "all";
    try { renderBestiary(p); } catch (e) {}
    setActiveTab("bestiary");
    finderLand($("bestiaryBody").querySelector('[data-bi="' + (r.i | 0) + '"]'));
  } else if (r.g === "moment") {
    chronFocusId = r.n | 0;
    setActiveTab("chronicle");
    paintChronicle();
    try { history.replaceState(null, "", "#moment-" + (r.n | 0)); } catch (e) {}
  }
}
(function setUpFinder() {
  const inp = $("finderInput"), panel = $("finderPanel");
  if (!inp || !panel) return;
  inp.addEventListener("input", finderPaint);
  inp.addEventListener("focus", () => { if (finderQuery().length >= FIND_MIN) finderPaint(); });
  inp.addEventListener("keydown", (ev) => {
    const open = !panel.classList.contains("hide");
    if (ev.key === "ArrowDown") { ev.preventDefault(); if (!open) finderPaint(); else finderSelect(finderSel + 1); }
    else if (ev.key === "ArrowUp") { ev.preventDefault(); if (open) finderSelect(finderSel - 1); }
    else if (ev.key === "Enter") { if (open && finderRes[finderSel]) { ev.preventDefault(); finderOpen(finderRes[finderSel]); } }
    else if (ev.key === "Escape") { ev.preventDefault(); if (open) finderOpenState(false); else { inp.value = ""; inp.blur(); } }
  });
  document.addEventListener("click", (ev) => { if (!ev.target || !ev.target.closest || !ev.target.closest("#finder")) finderOpenState(false); });
  // "/" jumps to the field - but never while the viewer is typing somewhere else (the guild chat above all)
  document.addEventListener("keydown", (ev) => {
    if (ev.key !== "/" || ev.ctrlKey || ev.metaKey || ev.altKey || ev.defaultPrevented) return;
    const t = ev.target, tag = t && t.tagName ? t.tagName : "";
    if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || (t && t.isContentEditable)) return;
    ev.preventDefault(); inp.focus();
  });
})();
