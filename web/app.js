"use strict";
// ============================================================================
// Bellmire HD - the viewer hub (W1b). Read-only, no backend, no framework.
//
// SECURITY (docs/HUB_SECURITY.md): every string from the snapshot is viewer-
// controlled and hostile until proven otherwise. It reaches the DOM ONLY through
// createElement + textContent, via the el() helper below. The only innerHTML in
// this file is two page-owned sites (the status line, renderNothing); no snapshot
// string reaches either one - the status line also interpolates the age text and
// the fetch error, each through esc(). There is no insertAdjacentHTML,
// document.write, eval or new Function anywhere in this file, and no snapshot
// field is ever used as a URL, src or href. The strict CSP is the
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
  try { paintWelcome(); } catch (e) { /* the welcome must never break the status line */ }
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

const SECTIONS = ["watch", "boards", "state", "dice", "heroes", "bands", "chronicle", "lore", "bestiary", "shops", "season", "roll", "fallen"];

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
  try { renderRail({}); } catch (e) {}
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
const KNOWN_V = new Set(["1", "2", "3", "4", "5", "6"]);   // v4 (H23): initiative, speed, gear by slot, status, per-hero last_seen + events
function render(p) {
  if (p && p.v != null && !KNOWN_V.has(String(p.v))) {
    showProblem("Bellmire is speaking a newer dialect than this page understands (format " +
                String(p.v).slice(0, 8) + "). The page needs an update.");
    return;
  }
  $("nothing").classList.add("hide");
  for (const id of SECTIONS) $(id).classList.remove("hide");
  welcomeP = p;
  const t = p.town || {};
  $("townName").textContent = t.name ? String(t.name) : "the Guild Hall";
  renderTown(t);
  renderBoards(arr(p.heroes), arr(p.fallen));
  renderHeroes(arr(p.heroes));
  try { renderRail(p); } catch (e) { /* the rail must never break the rest of the page */ }
  renderBands(p.parties != null ? p.parties : p.bands);
  renderChronicle(p.chronicle, { auto: true });
  try { renderState(t, p); } catch (e) { /* the new tab must never break the rest of the page */ }
  renderRoll(arr(p.guild_roll));
  renderFallen(arr(p.fallen));
  renderCommands(p.commands);
  renderRolls(p.rolls);
  renderLore();
  try { renderBestiary(p); } catch (e) { /* the Bestiary must never break the rest of the page */ }
  try { renderShops(p); } catch (e) { /* the Shops tab must never break the rest of the page */ }
  try { renderSatchel(p); } catch (e) { /* the Satchel tab must never break the rest of the page */ }
  try { renderSeason(p); } catch (e) { /* the Season tab must never break the rest of the page */ }
  try { paintWelcome(); } catch (e) { /* the welcome must never break the rest of the page */ }
  try { applyHeroLink(p); } catch (e) { /* a bad link must never break the page */ }
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

// v6 MANA BAR. Reads h.mana / h.mana_max defensively: no bar unless mana_max > 0
// (non-casters publish 0/0 and a v5 row has neither - both show nothing, claiming
// nothing). Numbers only reach the DOM through el()/textContent; the fill is a CSSOM number.
function manaBar(h) {
  const max = pickNum(h.mana_max), cur = pickNum(h.mana);
  if (max == null || !(max > 0) || cur == null) return null;
  const mp = Math.max(0, Math.min(max, cur));
  const ratio = Math.max(0.03, Math.min(1, mp / max));
  const wrap = el("div", "hpbar manabar");
  wrap.setAttribute("role", "img");
  wrap.setAttribute("aria-label", "Mana " + Math.round(mp) + " of " + Math.round(max));
  const track = el("div", "hptrack");
  const fill = el("span", "hpfill");
  fill.style.setProperty("--hp", ratio);     // CSSOM number only, never snapshot text
  track.append(fill);
  wrap.append(el("span", "hpk", "MP"), track, el("span", "hpv", num(Math.round(mp)) + " / " + num(Math.round(max))));
  return wrap;
}
// v6 MINIBOSS KEY. The publisher sends the MB_NAME key ("" when none). It is attacker-
// adjacent text, so only a plain snake_case token is accepted, and it is shown as text.
function mbKey(v) { const k = typeof v === "string" ? v.trim().toLowerCase() : ""; return /^[a-z][a-z0-9_]{0,39}$/.test(k) ? k : ""; }
// v6 MINIBOSS DISPLAY NAME. The key is the file name (trade word); the PLAYER's word is the MB_NAME
// value ("Shacklemaw"), sent as parties[].miniboss_name. Letters/digits/space/'-.,  only, <=40 chars;
// anything else (angle brackets included) is dropped. Shown as text only. A key with no name shows NOTHING.
function mbName(v) { const n = typeof v === "string" ? v.replace(/\s+/g, " ").trim() : ""; return /^[\p{L}][\p{L}\p{N} '\-.,]{0,39}$/u.test(n) ? n : ""; }

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
  const out = [];
  for (const e of live.concat(rem)) {
    const m = heroMatch(e, key);          // H26.2: the town's `who` first, the name guess only for untagged lines
    if (m) { if (m === 2) e.inf = true; out.push(e); }
  }
  return out.slice(0, 8);
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
    // H28: put a link straight to this hero on the clipboard
    const cp = el("button", "pinbtn linkcopy", "Copy a link to this hero");
    cp.type = "button";
    cp.title = "Copies an address that opens this hero's sheet. The address holds a number, not the name.";
    cp.addEventListener("click", () => heroLinkCopy(h, cp));
    sid.append(cp);
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
    const mpBar = manaBar(h); if (mpBar) sheet.append(mpBar);
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
      if (e.inf) li.append(el("span", "pinf", "inferred from name"));
      const a = e.at ? ago(e.at) : (e.ts ? ago(new Date(e.ts).toISOString()) : null);
      if (a) li.append(el("span", "plw", a.text));
      ul.append(li);
    }
    life.append(ul);
    if (lines.some((e) => e.inf)) life.append(el("p", "plnote", "Lines marked \u201cinferred from name\u201d were matched by this page from the wording; the rest are tagged to this hero by the town."));
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
      miniboss: mbKey(p.miniboss),              // key kept for matching only; NEVER displayed
      minibossName: mbName(p.miniboss_name),    // the player-facing word; the chip shows this or nothing
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
  if (p.minibossName) head.append(el("span", "bandboss", "Boss fight \u00b7 " + p.minibossName));   // v6: display NAME only, charset-checked, text only; a bare key shows nothing
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
// H26: the town's own tags (D60). Each is validated to a bounded shape before it is stored or drawn:
// `day` a whole number 0..999999, `kind` a bounded identifier, `who` at most 6 names of 40 characters.
// All three are optional; absent or malformed means "untagged" and the page falls back, visibly.
const chronDay = (v) => { const n = typeof v === "number" ? v : (typeof v === "string" && /^\d{1,6}$/.test(v) ? +v : NaN); return Number.isInteger(n) && n >= 0 && n <= 999999 ? n : null; };
const chronKind = (v) => { const k = String(v == null ? "" : v).toLowerCase().trim(); return /^[a-z0-9][a-z0-9_-]{0,23}$/.test(k) ? k : ""; };
const chronWho = (v) => {
  const out = [];
  for (const w of (typeof v === "string" ? [v] : arr(v)).slice(0, 8)) {
    if (typeof w !== "string") continue;
    const n = ctrlStrip(w).slice(0, 40);
    if (n && !out.includes(n)) out.push(n);
  }
  return out.slice(0, 6);
};
function chronShape(e) {
      const rawT = String(e.t == null ? "" : e.t).toLowerCase().trim();
      const t = /^[a-z0-9][a-z0-9 _-]{0,23}$/.test(rawT) ? rawT : "other";   // sane key, else "other"
      const known = CHRON_KINDS.find((k) => k.t === t);
      return { t, known: !!known, label: known ? known.one : (t === "other" ? "Other" : titleCase(t)),
                icon: CHRON_ICON.has(t) ? t : "other",
               key: t.replace(/[^a-z0-9]+/g, "-"),           // for the CSS class only
               s: String(e.s), at: typeof e.at === "string" ? e.at : "",
               day: chronDay(e.day), kd: chronKind(e.kind), who: chronWho(e.who) };
}
// copy the validated tags from a shaped line onto a remembered row (only the ones it has)
function chronCarry(r, e) {
  if (r.day == null && e.day != null) r.day = e.day;
  if (!r.kind && e.kd) r.kind = e.kd;
  if ((!r.who || !r.who.length) && e.who && e.who.length) r.who = e.who.slice();
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
    const row = { t: /^[a-z0-9][a-z0-9 _-]{0,23}$/.test(rt) ? rt : "other", s, at,
               k: typeof r.k === "number" && isFinite(r.k) ? r.k : Date.now(),
               n: Number.isInteger(r.n) && r.n > 0 && r.n < 2e9 ? r.n : 0 };
    const d = chronDay(r.day), kd = chronKind(r.kind), w = chronWho(r.who);    // H26: re-validated after the storage round trip
    if (d != null) row.day = d;
    if (kd) row.kind = kd;
    if (w.length) row.who = w;
    out.push(row);
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
    chronCarry(r, e);
    const old = by.get(histKey(r));
    if (old) { if (!old.at && r.at) old.at = r.at; chronCarry(old, e); } else { r.n = ++chronSeq; by.set(histKey(r), r); }
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
// H26: a topic prefers the town's own `kind` tag when a line has one; only an untagged line is
// matched by its wording (the old guess), and the Event filter says how many lines that was.
const topicOf = (k, label, kinds, guess) => ({ k, label, kinds, test: (e) => (e.kd ? kinds.includes(e.kd) : guess(e)) });
const CHRON_TOPICS = [
  { k: "all", label: "Every kind of event", kinds: [], test: () => true },
  topicOf("raid", "Raids", ["raid"], (e) => e.t === "raid" || /\braid|bandit|siege/i.test(e.s)),
  topicOf("disaster", "Disasters", ["disaster", "hunger"], (e) => CHRON_DISASTER.test(e.s)),
  topicOf("festival", "Festivals", ["festival"], (e) => CHRON_FESTIVAL.test(e.s)),
  topicOf("death", "Deaths", ["death"], (e) => e.t === "death"),
  topicOf("delve", "Delves", ["delve"], (e) => e.t === "delve"),
  topicOf("find", "Finds", ["find"], (e) => e.t === "loot"),
  topicOf("growth", "Town growth", ["growth"], (e) => e.t === "town" || /grows into|town level|\bbuilt\b|raised/i.test(e.s)),
  topicOf("town", "Town life", ["day", "treasury", "caravan", "arrival", "watch", "rally"], (e) => e.t === "town"),
];
// H26.2: does this line belong to this hero (key lower-cased)? 1 = the town's own `who` tag says so,
// 2 = inferred by the page from the name in the wording (only for a line with no `who`), 0 = no.
function heroMatch(e, key) {
  if (!key) return 1;
  if (e.who && e.who.length) return e.who.some((n) => n.toLowerCase() === key) ? 1 : 0;
  return namesIn(e.s, key) ? 2 : 0;
}
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
// ---- H28 a hero you can point at
// "#hero-<n>" opens that hero's sheet. n is an integer: FNV-1a (32-bit) of the lower-cased
// name, computed by THIS page. The fragment is the only thing read from the URL, it must match
// the strict pattern below, and n is only ever COMPARED to the same number computed for each
// hero in the snapshot - never a selector, URL, src, href, style or markup. A hostile name just
// yields a number. No match -> the roster and a constant message; nothing is fetched or written.
function heroAddr(name) {
  const key = String(name == null ? "" : name).toLowerCase();
  let a = 2166136261;
  for (let i = 0; i < key.length; i++) { a ^= key.charCodeAt(i); a = Math.imul(a, 16777619) >>> 0; }
  return a >>> 0;
}
function heroLinkFrom() {
  const m = /^hero-(\d{1,10})$/.exec(String(location.hash || "").replace(/^#/, ""));
  if (!m) return /^hero-/.test(String(location.hash || "").replace(/^#/, "")) ? 4294967296 : -1;   // a malformed hero address matches nobody
  const n = +m[1];
  return n <= 4294967295 ? n : 4294967296;
}
let heroLinkHandled = -1;
function applyHeroLink(p, force) {
  const n = heroLinkFrom();
  const note = $("heroLinkNote");
  if (n < 0) { heroLinkHandled = -1; if (note) { note.classList.add("hide"); note.textContent = ""; } return; }
  if (!force && n === heroLinkHandled) return;            // the 60 s refresh must not re-land the viewer
  if (!p || typeof p !== "object") return;                // no report yet: try again when one arrives
  heroLinkHandled = n;
  const hs = arr(p.heroes);
  const idx = hs.findIndex((h) => { const nm = nameOf(h); return nm && heroAddr(nm) === n; });
  setActiveTab("heroes");
  if (idx < 0) {
    if (note) { note.textContent = "That hero is not on tonight\u2019s roll."; note.classList.remove("hide"); }
    return;
  }
  if (note) { note.classList.add("hide"); note.textContent = ""; }
  heroFilter = ""; const f = $("find"); if (f) f.value = "";
  heroShown = Math.max(heroShown, Math.ceil((idx + 2) / HERO_PAGE) * HERO_PAGE);
  renderHeroes(hs);
  const want = nameOf(hs[idx]);
  const card = [...$("heroList").querySelectorAll("details.hero")].find((d) => (d.querySelector(".hname") || {}).textContent === want);
  if (card) { card.open = true; finderLand(card); }
}
window.addEventListener("hashchange", () => { try { applyHeroLink(welcomeP, true); } catch (e) {} });
function heroLinkCopy(h, btn) {
  const nm = nameOf(h);
  const label = "Copy a link to this hero";
  const flash = (m) => { btn.textContent = m; setTimeout(() => { btn.textContent = label; }, 2000); };
  if (!nm) { flash("No link for this hero"); return; }
  const url = location.href.replace(/[#?].*$/, "") + "#hero-" + heroAddr(nm);
  try { history.replaceState(null, "", "#hero-" + heroAddr(nm)); heroLinkHandled = heroAddr(nm); } catch (e) {}
  try { navigator.clipboard.writeText(url).then(() => flash("Link copied"), () => flash("Link is in the address bar")); } catch (e) { flash("Link is in the address bar"); }
}
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
  const pass = (e) => !chronOff.has(e.t) && (!q || e.s.toLowerCase().includes(q)) && heroMatch(e, hkey) > 0 && topic.test(e);
  const anyFilter = !!(q || hkey || chronOff.size || chronTopic !== "all");
  const shownAll = entries.filter(pass);
  if (!shownAll.length) {
    note.className = "note quiet";
    note.textContent = q ? "No entries match \u201c" + q + "\u201d" + (chronOff.size ? " in the kinds shown." : ".")
      : (hkey || chronTopic !== "all") ? "Nothing in the journal matches that hero and event."
      : "Every kind is switched off - tap a chip to bring the chronicle back.";
    return;
  }

  // ---- H26.1 days, not stretches: a line that carries the town's own `day` is grouped by it; a line
  // without one (a v=3-era payload, an untagged row) falls back to the H21 wall-clock heuristic,
  // and every group says which basis it is on.
  const eps = [];
  for (const e of entries) {
    const cur = eps[eps.length - 1];
    if (e.day != null) {
      if (cur && cur.day === e.day) { cur.items.push(e); cur.last = e.ts; }
      else eps.push({ day: e.day, first: e.ts, last: e.ts, items: [e] });
    } else if (cur && cur.day == null && cur.last - e.ts <= CHRON_EP_GAP && cur.first - e.ts <= CHRON_EP_SPAN) { cur.items.push(e); cur.last = e.ts; }
    else eps.push({ day: null, first: e.ts, last: e.ts, items: [e] });
  }
  let drawn = 0, sawEarlier = false, dayGroups = 0, clockGroups = 0;
  for (const ep of eps) {
    const items = ep.items.filter(pass);
    if (!items.length) continue;
    const hasLive = ep.items.some((e) => !e.rem);
    const key = (ep.day != null ? "d" + ep.day + "-" : "e") + ep.last;
    if (ep.day != null) dayGroups++; else clockGroups++;
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
    const fresh = drawn === 0 && now - ep.first < CHRON_EP_GAP;
    const title = ep.day != null ? "Day " + num(ep.day) + (fresh ? " \u2013 now, as the town tells it" : "")
      : fresh ? "Now, as the town tells it" : dayVoice(ep.first);
    head.append(el("span", "cep-title", title),
      el("span", "cep-when", chronRange(ep.first, ep.last) + " \u00b7 " + plural(items.length, "line", "lines")),
      el("span", "cep-basis", ep.day != null ? "Grouped by the town\u2019s own day." : "No town day on these lines - grouped by gaps in this browser\u2019s clock, a guess."),
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
      if (e.who && e.who.length) ch.append(el("span", "cwho", e.who.join(", ")));   // the town's `who` tag, textContent
      if (hkey && heroMatch(e, hkey) === 2) {
        const inf = el("span", "cinf", "inferred from name");
        inf.title = "This line carries no hero tag from the town; the page matched the name in its wording.";
        ch.append(inf);
      }
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
    : "Showing " + shownAll.length + " of " + entries.length) + ", newest first, in " +
    (clockGroups === 0 ? plural(drawn, "day", "days") + " by the town\u2019s own calendar"
      : dayGroups === 0 ? plural(drawn, "stretch", "stretches") + " guessed from gaps in the clock (these lines carry no town day)"
      : plural(dayGroups, "town day", "town days") + " and " + plural(clockGroups, "clock-guessed stretch", "clock-guessed stretches")) +
    (drawn > 1 ? " - tap one to fold or open it." : ".");
  {
    const extra = [];
    if (chronTopic !== "all") {
      const noKind = entries.filter((e) => !e.kd).length, shownNoKind = shownAll.filter((e) => !e.kd).length;
      extra.push(noKind ? plural(noKind, "line", "lines") + " in the journal carry no kind from the town and could not be classified; " +
        (shownNoKind ? (shownNoKind === 1 ? "1 of them was" : num(shownNoKind) + " of them were") + " matched by wording." : "none was matched by wording.")
        : "Every line carries the town\u2019s own kind.");
    }
    if (hkey) {
      const inferred = shownAll.filter((e) => heroMatch(e, hkey) === 2).length;
      extra.push(inferred ? plural(inferred, "line is", "lines are") + " inferred from the hero\u2019s name" + (shownAll.length > inferred ? "; the other " + (shownAll.length - inferred) + " are tagged to them by the town." : ".")
        : "Every line shown is tagged to this hero by the town.");
    }
    if (extra.length) note.textContent += " " + extra.join(" ");
  }
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

function normalizeRolls(raw, cap) {
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
    .slice(0, cap || ROLL_FEED_MAX);   // cap AFTER dropping empties, so a padded publisher array still fills the feed
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
  const kind = rollKind(r);
  const li = el("li", "rentry" + (r.tier ? " tier-" + r.tier : "")
    + (kind === "crit" ? " crit" : kind === "fumble" ? " crat" : ""));
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

// ---- H27: Tales of the Die. The night's rolls are kept the way H14 keeps the Chronicle:
// per-browser, newest first, capped, day-divided. localStorage key `bellmire.rolls.v1`.
// Stored rows are re-validated on every read (storage is attacker-reachable text that has
// been through one round trip) and reach the DOM only through rollEntry() -> el()/textContent.
// A crit is the 20 (or, face unknown, tier "crit"); a fumble is the 1 (or tier "fumble").
// Nothing here writes to a network, a URL or a selector.
const ROLL_HIST_KEY = "bellmire.rolls.v1";
const ROLL_HIST_MAX = 100, ROLL_HIST_MS = 48 * 3600000, ROLL_HIST_BYTES = 60000;
let rollMem = [], rollMemLoaded = false;
function rollKind(r) {
  if (r.face === 20 || (r.face == null && r.tier === "crit")) return "crit";
  if (r.face === 1 || (r.face == null && r.tier === "fumble")) return "fumble";
  return "";
}
const rollTs = (r) => { const a = Date.parse(r.at); return isFinite(a) ? a : (r.k || 0); };
function rollsClean(a) {
  const out = [];
  for (const r of arr(a).slice(0, ROLL_HIST_MAX * 2)) {
    if (!r || typeof r !== "object") continue;
    const n = normalizeRolls([r], 1)[0];
    if (!n) continue;
    n.by = ctrlStrip(n.by); n.what = ctrlStrip(n.what); n.result = ctrlStrip(n.result); n.cost = ctrlStrip(n.cost);
    n.at = typeof n.at === "string" && n.at.length <= 40 && CHRON_AT_OK.test(n.at) ? n.at : "";
    n.k = typeof r.k === "number" && isFinite(r.k) && r.k > 0 && r.k <= Date.now() + 60000 ? r.k : Date.now();
    out.push(n);
  }
  return out;
}
function rollMemEnsure() {
  if (rollMemLoaded) return;
  rollMemLoaded = true;
  try {
    const raw = localStorage.getItem(ROLL_HIST_KEY);
    rollMem = raw && raw.length <= ROLL_HIST_BYTES * 2 ? rollsClean(JSON.parse(raw)) : [];
  } catch (e) { rollMem = []; }
}
// fold the live rolls into the history; prune by age, count and bytes; persist. Returns the rows.
function rollsRemember(live) {
  rollMemEnsure();
  const now = Date.now(), old = new Map();
  for (const r of rollMem) if (!old.has(rollKey(r))) old.set(rollKey(r), r);
  const seen = new Set(), fresh = [];
  for (const r0 of rollsClean(live)) {
    const key = rollKey(r0);
    if (seen.has(key)) continue;
    seen.add(key);
    const prev = old.get(key);
    fresh.push(prev ? Object.assign(r0, { k: prev.k }) : Object.assign(r0, { k: now }));
  }
  const rest = rollMem.filter((r) => !seen.has(rollKey(r)));
  let rows = fresh.concat(rest).filter((r) => rollTs(r) >= now - ROLL_HIST_MS)
    .sort((a, b) => rollTs(b) - rollTs(a)).slice(0, ROLL_HIST_MAX);
  let json = "";
  try {
    json = JSON.stringify(rows);
    while (json.length > ROLL_HIST_BYTES && rows.length) { rows.pop(); json = JSON.stringify(rows); }
  } catch (e) { rows = []; }
  rollMem = rows;
  try { localStorage.setItem(ROLL_HIST_KEY, json || "[]"); } catch (e) { /* full or blocked: carry on in memory */ }
  return rows;
}

function renderRolls(raw) {
  const feed = $("rollFeed"), note = $("rollNote"), tally = $("rollTally");
  if (!feed || !note) return;
  const live = normalizeRolls(raw);
  let rows = [];
  try { rows = rollsRemember(raw); } catch (e) { rows = live; }   // storage trouble never costs the live feed
  if (!rows.length && live.length) rows = live;
  feed.replaceChildren();
  if (tally) tally.replaceChildren();
  if (!rows.length) {
    lastRollKey = null;     // so the next real roll animates fresh
    note.className = "note quiet";
    note.textContent = "No rolls yet tonight. When a viewer spends channel points or bits to roll the die for the town — to pass a law, set off an event or raise a building — the roll and how it turns out will be kept here.";
    return;
  }
  let crits = 0, fumbles = 0, day = null;
  for (const r of rows) {
    const k = rollKind(r);
    if (k === "crit") crits++; else if (k === "fumble") fumbles++;
    const ts = rollTs(r), d = new Date(ts); d.setHours(0, 0, 0, 0);
    if (day !== d.getTime()) { day = d.getTime(); feed.append(el("li", "rdiv", dayVoice(ts))); }
    feed.append(rollEntry(r));
  }
  if (tally) {
    const chip = (cls, n, label) => { const c = el("span", "rtally " + cls); c.append(el("b", null, String(n)), document.createTextNode(" " + label)); return c; };
    tally.append(chip("rtally-crit", crits, crits === 1 ? "crit" : "crits"), chip("rtally-fumble", fumbles, fumbles === 1 ? "fumble" : "fumbles"));
  }
  note.className = "note";
  const liveBit = live.length ? " The die above shows the latest." : " The town has sent no rolls just now; these are the ones this browser remembers.";
  note.textContent = rows.length + (rows.length === 1 ? " roll" : " rolls") + " kept, newest first." + liveBit;
  const top = live[0];
  if (top) {
    const key = rollKey(top);
    if (key !== lastRollKey) {
      const first = lastRollKey === null;
      lastRollKey = key;
      if (top.face != null) announceTownRoll(top, first);
    }
  } else lastRollKey = null;
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
    try { if (lastShopP) renderShops(lastShopP); } catch (e) {}
    try { if (lastSatP) renderSatchel(lastSatP); } catch (e) {}
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
const LORE_SRC_SHA  = "9f38b9c8";
const LORE_SRC_DATE = "2026-11-18";
const LORE_FROZEN = {"town_life":{"crier":["Grain measured, flasks counted, door kept - Bellmire stands another day!","Fresh off the river: trout, and a tale with every one.","The guild takes names at the post. Bring your own courage.","Lamps lit, walls walked, all's well - or well enough.","Another delver down the scar. Put a copper on them coming back up.","Walls walked, gates kept, and the bell has nothing to say!","Caravan on the road - bring coin or bring your back!","New names on the guild post. Read them while they are fresh.","The apothecary has flasks and the guild has holes to put them in!","Taxes measured, not guessed - the Hall says so.","Rain by evening. The crier is never wrong twice running.","Measure the grain, count the flasks, keep the door - and the crier keeps his voice!","Two up from the scar this morning, and both of them walking!","The bell has no clapper and even less to say. All's well!","Market day! Bring coin, bring elbows!","The Watch walked the wall twice and found nothing worth a second turn.","Flasks on the shelf, grain in the measure - Bellmire keeps its own accounts!","A lord came up out of the scar and went back down in pieces - hear it twice for a copper!","E3PO stood the night gate himself. Sleep easy, Bellmire.","Three down the scar before breakfast. The guild post is open and the ink is wet!","Stone on the road, masons on the wall - look lively or be built into it!","The Ford is running high. Cross at the ferry or cross at your own funeral!","Lost: one goat, answers to nothing. Found: one goat, answers to nobody!","The Hall sits at noon. Bring your grievance and bring it short!","Bandits on the west road, says the carter. Says it every week, mind.","Flasks counted twice today, on account of yesterday!","A caravan winters here, and the lanes are tight. Mind your elbows and your purse!","The night was quiet, the gate held, and the crier slept like an honest man!","New law posted at the Hall. Read it, or have it read to you at the gallows!","'Hear it, pay it, pass it on! Bellmire, your news!'","'Second bell! Any body with hands and a name, the drill yard calls!'","'Lost: one grey cat by the ford. Found: three. Come and argue!'","'Prices on the board, honest or you'll hear about it!'","'Third bell! Reeve wants a word at the Hall!'","'New rate on the toll - read it before you cross it!'","'Lost: a grey mare. Found: a grey mare. Not the same mare!'","'Bellmire sleeps well tonight, and E3PO sleeps better!'","Eight bells and all well! The ford is low, the gate is high, the guard is cross!","New names on the guild post! Come read them, and come add your own!","Lost: one goat, brown, answers to nothing. Found: the goat. Reward withdrawn.","The smith asks that no one lean on the new anvil. It is not set. It is not yet an anvil.","Market opens at the second bell! Count your coppers twice and your fingers three times!","The Commander says the wall is sound! The Commander says everything is sound! The Commander is correct!","Heard at the well: the scar was loud last night. Heard at the gate: it is always loud.","Bring your own bucket to the new well, and your own opinions to the old!","Ferry at the ford till dusk! The boatman is sober; the river is not!","A feast is promised and a fool is wanted for the middle of it! Apply at the chapel!","Every hero in Bellmire has a name here! Give yours at the post and be remembered!","Dark by the sixth bell and the lamps are lit! Walk in pairs, and let the lamps be yours!","Wall-work resumes at first light. Bring a trowel or bring a cart.","The mill turned a full day, and the flour was weighed honest.","A hero came home last night with all ten fingers. Bellmire counts that a good night.","Lamps lit at dusk along the whole market row, and nobody asked who paid.","Roof-tile and rope at the quay, the long barge in. Fair price for fair coin.","The bell rang for a wedding. Only the one this week, and it was a loud one.","Hearths banked, doors barred, children counted. Bellmire sleeps.","The well-wardens report the water sweet. Drink freely.","A fortnight without a funeral. Do not say it too loudly.","The guild post is open late. Bring a name, and bring a lantern."],"market":["Two coppers the carp, and the carp is grinning.","Dye by the ounce - name a colour, Bellmire keeps it now.","Scarglass! Cheap, and only slightly cursed!","Boots that have walked further than you have, half off.","Ale by the jug, and the jug is honest.","Nails, hooks, and a hammer that has seen things!","Salt off the coast road - you will taste the journey.","Wool off the hill, and it still smells of the hill.","Bread this morning; bread-shaped by this afternoon.","Lamp oil! Burns slow, and you will want the slow sort.","Rope by the fathom, and it has held a man before!","Scarstone, polished - it only looks at you a little!","Candles! Burn one for the delvers, buy two for yourself!","Hooks, lines, and a river that owes you nothing!","Cheese with a crust you could roof a barn with!","Fresh ink and honest parchment - write home while you still can!","A hat that has never once been rained on. Not once!","Secondhand steel - all of it came back up. Most of it alone.","Wax and wick! Burn one for the ones still down there!","Charcoal by the sack, and the sack is nearly full!","Thread, needles, and a patch for whatever the scar did to you!","Smoked river fish - it has been through worse than you have!","Horn cups, horn combs, horn everything - we had a good year for horns!","Pickles! Older than some of my customers!","Blankets off the hill flocks, thick enough to stand up on their own!","Boots resoled while you wait, and you will wait!","Honey when the hives are ours to take it from. Today they are!","Lanterns, hooks and a long pole - everything a man needs to not go in after it!","The baker's boy is undercutting his father two stalls down.","A fishwife has a crow in a cage. She is not selling it; she wants it on record.","The salt stall weighs twice and smiles once.","The potter will take a chipped cup in trade and knock a copper off.","The chandler has a second row of lanterns - the first is spoken for.","The miller's boy throws the weight twice, out of kindness.","A new stall - saltpans by the ford, and the salt knows it.","The dyer has a run of carrion that nobody will admit to buying.","Pickled eel, three coppers, and the eel has seen things.","Iron nails by the fistful, and every nail sworn to hold.","Wool, washed, and the sheep has been told to look surprised.","Candles! Tallow, wax, and one that burns blue and is not for sale.","Come buy a flask! It is full, it is red, and it is a great deal better than it looks.","Honest scales here. Ask any man who has been wrong about it.","Smoked fish! Smoked cheese! Smoked, I say, and the smoke was well spent!","Dyer's corner: any colour in the world, and several that are not.","Rope, hemp, forty feet, and a knot the guild swears by.","Fresh bread, warm, and I will not discuss the price until you have had a bite.","Charms against the scar, two coppers. They do nothing. They comfort a great deal.","Hats, hoods, and a fine plain cap. Be visible, be remembered, be dry.","Cheese from the high farms, still sharp. Ask for the rind.","Honest weights, honest scales. The scales are the town's, so check them yourself.","Linen by the yard, dyed in the new guild blue. Sells slow, wears long.","Hot pies at the corner, and the corner is crowded.","Rope, nails and good iron. The smith is in and the smith is short-tempered.","Fresh bread, and day-old bread at half. The day-old is the better bread.","Tallow, wicks, and a lamp-oil that does not stink.","Wool by the fleece, spun by the skein, and the spinner will tell you the price twice.","Apples from the east terrace. The last of the season, so take the lot.","Silver wire and plain rings, no scarglass. Honest work for the weddings."],"growth":["The masons raised a new course on the wall today.","A second well dug, and the queue at the first one shorter.","They are building where the fields used to stop.","The guild post has two doors now. Both kept.","The smith has an apprentice, and the apprentice has eyebrows. For now.","A proper gate, hung and swinging true.","The road out is cobbled as far as the ford.","They are putting glass in the chapel windows.","A second row of stalls, and a queue for them.","The barracks took on ten more. E3PO looked almost pleased.","The ditch is dug, the stakes are in, and the masons are measuring stone.","A new row of chimneys on the east side, all of them smoking.","They have hung a lamp at the ford. It burns all night now.","The guild post took on a clerk, and the clerk took on a queue.","A tannery, downwind - and the town voted on which wind.","The market square has flagstones where the mud was.","A second smith, and the two of them already disagree.","They are cutting a road where the fields used to stop.","They have roofed the old well, and the water tastes of less sky.","A stone granary going up by the Hall, and the masons will not say how much.","Drains under the high street. The town smells of digging instead of worse.","The chapel has a clapper on order, and opinions arriving free.","A second gate cut in the north wall, because the first one had a queue.","The guild post painted its door. The door is still kept.","A bath house, of all things, and a line outside it already.","They are laying a wharf at the Ford, long enough for two boats to argue over.","The yard has a practice dummy that E3PO himself broke in half. They built a stronger one.","Lamps the whole length of the high street now. The dark stops at the wall.","Another roof goes up; another kettle gets hung.","The ward lists a new name. Nobody argues it.","A second well is being dug, and a first argument is being had over it.","Market Day has outgrown its square. The square is being argued with.","The crier is paid a second copper for the second bell.","A third guild post opens, and already the clerk is tired.","The wall ward lists two new names, and argues about a third.","Lanterns the length of the ford now. The low field can see its own grain.","A roof went up on Cobbler's Lane in a day, and the day was well spent.","The ferry has a second boat, and the first boat is looking at it nervously.","They are paving the square. The old mud will be missed by nobody but the pigs.","New smoke over the east side - three chimneys where there was one.","The guild post has a new shutter. It closes. It is considered a luxury.","Another baker has opened, and the first baker is being very polite about it.","The ditch by the wall has been dug deeper, to the guard's great satisfaction.","A second lantern at the gate, and the dark is a little thinner for it.","The chapel bell was rehung, and for the first time it rings on the hour.","Carts roll in from the west road with more timber, more nails, and more rumour.","Someone planted flowers at the guild post. They survived. This is a good sign.","A new family came down the road and took the empty house. It is no longer empty.","New thatch on the east row, and the old thatch carted off for the cattle.","The mason's boy has his own chisel now, and his own corner.","A second market day has been added, and the stalls have filled it already.","They paved the lane to the guild post. The mud has to go somewhere else.","Another smithy has opened by the ford. The first smithy is not pleased.","A bell has been hung where the old wall stood. The wall moved out a bowshot.","Stone houses along the river now, where there were reed huts last year.","The ferry has a roof, and the ferryman a bench.","The granary has a lock, and the lock has a second key.","A school on the green. It has two benches and an excellent door."]},"growth_tiers":{"tiers":[{"name":"Crossing","crier":"A handful of huts at a river crossing. Somebody calls it Bellmire.","see":"Three or four huts, a cart, a cookfire."},{"name":"Hamlet","crier":"Bellmire is a hamlet now - a well dug, and a reason to stay.","see":"A well, a few more homes, a fenced garden or two."},{"name":"The Guild Post","crier":"The guild plants a post at Bellmire. The post has a door, and the door is kept.","see":"The guild post building, and the town's first lamp."},{"name":"Village","crier":"Bellmire is a village. The scar has a name, and so do we.","see":"Homes clustered along a cart-track, chickens, a shared pen."},{"name":"Market Day","crier":"Market day comes to Bellmire. Measure the grain.","see":"A market square with a few stalls, and the first outside traders."},{"name":"The Chapel","crier":"A chapel and a bell-tower rise. The bell has no clapper, and rings anyway.","see":"The temple and its tower, and a small graveyard behind it."},{"name":"Craft Row","crier":"The smiths and masons raise Craft Row. Count the flasks.","see":"Workshops trailing smoke, a forge-glow, the mill wheel turning."},{"name":"The Garrison","crier":"Bellmire raises a garrison. The guard has a yard now - and a Commander.","see":"Barracks and a training yard, guards on patrol, E3PO up on the wall."},{"name":"Market Town","crier":"Bellmire stands as a proper market town. The caravans know the road.","see":"A paved square, more districts, a busy Ford with its Ferryman."},{"name":"The First Wall","crier":"Stone goes up where the fields used to stop. Keep the door.","see":"A low wall around the town's heart, and a gatehouse over the road."},{"name":"Walled Town","crier":"Bellmire is a walled town now. Let them come.","see":"A full curtain wall, corner towers, a district banner on each quarter."},{"name":"City in all but Charter","crier":"Bellmire is a city in all but the charter - and the scar is deeper than it has ever been.","see":"Dense districts, a second ring of homes outside the wall, traffic at every gate."}]},"e3po":{"intro":["E3PO takes the wall. The whole guard stands straighter.","The Commander is on the field. Nobody tells him to be careful.","The gate opens, and it is only E3PO coming out to meet them.","E3PO arrives at a walk. Running would suggest doubt.","The Commander's voice reaches the back of the square before he does.","E3PO comes up the stair to the wall at the same pace he always does.","The Commander takes his place at the gate and the guard stop checking the horizon.","E3PO arrives already giving orders, which saves everyone a moment.","The Commander steps onto the wall. The night gets smaller.","E3PO arrives with his helm under his arm and his opinion ready.","Boots on stone, slow and even. That will be the Commander.","E3PO comes out of the gatehouse already unimpressed.","The Commander takes the step nobody else wants and stands on it.","E3PO is here. Whatever this is, it is his problem now, and he prefers it that way.","The Commander comes through the crowd and the crowd closes behind him, facing out.","E3PO reaches the wall without hurrying, and the hurrying stops.","The Commander arrives, looks at the problem, and names it. That is usually enough.","E3PO puts his back to the gate. Everything else can be worked out from there.","The Commander walks past the trembling end of the line and stands at it.","E3PO steps out of the dark into the lamplight, which is the only warning anyone gets.","The Commander takes the wall and the whole guard remembers the drill at once.","E3PO arrives late, on purpose, so the men learn they can hold without him.","E3PO comes out at a walk. Nothing about today is going to be hurried.","The Commander is at the gate before the horn has finished.","Boots on stone, in step, one pair louder than the rest. That is him.","E3PO takes his post and the whole wall exhales.","The Commander arrives in full harness on a quiet day, because quiet days end.","E3PO steps into the gateway and makes it look narrower than it is.","The guard snaps to without being told. He has not even spoken yet.","The Commander is where he always is. That is the point of him.","'E3PO. Commander of the Guards. I have not died yet and I am not going to start.'","The Commander of the Guards stands in the gate like a hinge that has been there a thousand years.","'You will know me by the helm and the sigh. Both are standard issue.'","'I hold the door. That is the whole title. Everything else is paperwork.'","E3PO inspects you, finds nothing wrong, and is faintly disappointed.","'The Ford is safe because it is boring to attack. I make it boring.'","E3PO arrives with the sound of a decision being made.","The Commander lets the gate swing wide behind him, as if it had been waiting.","E3PO takes the high ground, which has quietly become his by habit.","The guard parts in two, and E3PO fills the gap without being asked.","E3PO checks the rooftops, the road and the sky, in that order. All are his problem.","The Commander appears at the front, and the front finally feels like one."],"says":["Hold the line. The line holds because I say so.","I have died exactly never. Let us keep the record.","Measure the grain, count the flasks, and leave the gate to me.","A guard who runs is a guard I must replace, and I hate paperwork.","They do not pay me to fall. They do not pay me at all - I simply refuse to leave.","The door stays shut. That is the whole job, and I am very good at it.","Wounded? I prefer 'briefly inconvenienced'.","Bellmire sleeps because I do not.","Shapes, not numbers. That goes for raiders too.","I do not require a monument. A kept door will do.","If the gate holds and the grain is counted, the day is a success. The rest is weather.","Call me Commander. 'Sir' is for men who might retire.","Shut the door, count the grain, and let me worry about the rest.","Courage is a habit. Start with standing still.","I was here before the wall. I will be here after it, if the masons keep this up.","A quiet night is the best work we ever do, and nobody writes it down.","The scar can have the deep. It cannot have the doorstep.","I do not need you brave. I need you where I put you.","Twenty years and no one has got past me. I would call that a record; I call it Tuesday.","If you must run, run toward something. Preferably me.","Grain, flasks, door. Everything else is a rumour.","I have no plan for losing. I never found the time to write one.","Hold your ground. Ground is the only thing here that cannot run.","You want glory. I want Thursday to be boring.","Fear is fine. Fear that moves its feet is a problem.","I have buried better men than me. That is the whole reason I stay.","Do not thank me. Shut the door behind you.","The deep sends up monsters and we send down volunteers. I do not love the trade.","There is no trick to it. Stand where you are told, for longer than you want to.","I am not brave. I am simply still here, which looks the same from a distance.","I am not the wall. I am what the wall is for.","Every door in this town shuts. Mine shuts last.","Do not ask me how old I am. Ask the gate; it remembers more.","A town is a promise that somebody is awake. I am the somebody.","You will have braver days than this. Today I want a steady one.","I do not win fights. I outlast them. Try it, it is cheaper.","The scar is patient. I have the advantage there.","Keep your spear where I can see it and your fear where you can.","I have never once been rescued and I am not starting a fashion.","Report to me, not about me.","They call me immortal. I call it a long habit of not leaving.","Bellmire has buried everyone who built it. That is the job of a town.","If you want my post, you will have to wait a very long while.","Stand here. If something comes through, it came through me first, so take your time.","Keep the door. Everything else is decoration.","I do not need sleep. I need the wall to still be there in the morning.","A gate is a promise. I am the one who keeps it.","You may panic after. I shall tell you when after is.","Two things never leave this post: the bell and me.","Courage is a habit. Start it now, you will want it later.","If the wall falls, step back one pace and be a wall.","I have no grave to visit. Count yourselves lucky it is mine.","Hold your ground. The ground has held mine for longer than you think.","The scar eats spells. It has never once eaten a spear.","Fear is fine. Moving is not.","I do not shout to frighten you. I shout so you can find me.","Drink after the gate is shut. Not one flask before.","Nobody in this town dies of my carelessness. That is the whole oath.","When I withdraw, I come back. Learn the second half.","Stand where I put you and the night is a short one.","A quiet watch is a watch that worked. Do not sulk.","I was not built for retreat and I was not built well for stairs.","Say my name if it helps. It usually does.","Measure the grain. Count the flasks. I shall keep the door.","A quiet gate is a loud compliment. Accept it.","Drill is not punishment. Drill is the price of not needing it.","The door holds because I hold the door. Help me hold the door.","Count the loaves out and the loaves back. The missing loaf tells a story.","Fear is a weather. Stand in it until it stops being news.","I have been wrong. The gate has not. Learn from the gate.","Say the watchword before you draw. Half the fights end there.","If you sleep on the wall, sleep facing out. Habits save lives.","The scar listens. Say the useful things loud, the stupid things in your head.","A bad drill is a free lesson. A bad fight is an expensive one.","If you are tired, rest where I can see you. Rest is not shame.","The town is behind you. Act like you remember.","Nobody gets a second first impression on my wall. Make this one count.","I will know your name by the end of the week. Make it worth learning.","I have outlived the town's oldest tree. I plan to outlive another.","The gate does not negotiate. Neither do I, before breakfast.","'A good wall is just stubbornness stacked in rows.'","E3PO checks the lock on the gate by hand. The lock is fine. He needed to know.","'I do not need to be liked. I need to be answered when I call.'","'The Ford has stood because somebody was too stubborn to move.'","The Commander glances at the sky, the road, the wall, and the cooks, in order of likely disaster.","'If you ever wonder why we drill, it is the same reason you wear boots.'","'Nobody is ever ready. We are merely prepared, and that is better.'","E3PO sniffs the wind like a hound and writes nothing down.","'A guard that waits is a guard that wins. Mostly I wait. Loudly.'","'I cannot fall. It is not arrogance; it is paperwork.'","'Discipline is just courage with a schedule.'","'If you are afraid, stand behind me. If you are not, stand beside me and prove it.'","'Bellmire stands. That is the entire plan. Most plans are longer and fail sooner.'","'I have been wounded. I have not been defeated. The bed rests are different things.'","'No retreat. Only repositioning, with enthusiasm.'","'Look sharp. The town is watching the wall, and the wall is watching me.'"],"town_talk":["They say E3PO has held the gate since before there was a gate.","Old-timers swear E3PO has outlived three of his own gravestones.","The children drill with sticks and name the loudest one E3PO.","No raider has taken the Keep door while the Commander draws breath - which is to say, never.","The guild keeps a chair for E3PO at every feast. He never sits; he watches the door.","The Watch say the Commander's armour has more dents than the gate has nails.","There is a standing wager at the tavern on what could fell E3PO. Nobody has collected.","The masons built the new wall a hand taller because he asked twice.","They tried to carve him a statue. He made them turn it to face the door.","Every recruit hears the same first words: 'The door stays shut.'","The Watch say the Commander sleeps standing up, and only to set an example.","They reckon E3PO has worn out more armourers than armour.","A child asked the Commander what he is afraid of. He thought about it for a long time and said 'paperwork'.","The bakers keep him a loaf he never takes, and bake it anyway.","Two generations of this town have been told off by the same man in the same voice.","Nobody can name the day E3PO arrived, which is how you know the story is old.","The Watch measure a hard night by how many times the Commander said nothing.","They say the first wall was built around wherever E3PO happened to be standing.","Three innkeepers have retired on bets about the Commander's age.","He knows every guard's mother's name. Nobody knows how.","The graveyard has no stone for E3PO. The masons keep offering.","They say if the bell ever gets a clapper, he will still hear the gate first.","Recruits are told not to try out-standing him. They try anyway. They stop.","A caravan master swore he saw E3PO on the wall at dawn and at midnight. Same posture, same dent.","The Watch say the Commander has never once been seen running, in any emergency, ever.","They say he has had three suits of armour and only one dent he keeps.","The gatekeeper's grandfather was told off by E3PO for the same thing, in the same words.","A tanner swears the Commander remembers his wedding, which was forty years back.","They say the scar has tried E3PO twice and gone back down both times.","The Watch keep a tally of nights the Commander slept. It is a short tally.","The schoolmistress uses E3PO to teach the children what reliable means.","The guild post keeps his name off the ledgers - he never asked for pay, so there is nothing to write.","A delver swore the Commander walked her home from the scar's edge without a word.","They say the architect drew the gate around the Commander's shoulders and got the measurements right.","No innkeeper in Bellmire will take his coin. He leaves it anyway, under the cup.","The gravediggers say E3PO knows where every one of them is, by row.","The children's game is called Hold The Door. Nobody wants to be the raiders.","They say Bellmire has two bells: the one with no clapper, and the Commander.","They say the mason who cut E3PO's gravestone gave up and sold it as a doorstep.","The tally-man gave up counting the Commander's years and wrote 'yes'.","Mothers tell their children E3PO sleeps. The children have never seen it.","Bets on the wall: how many winters the Commander has stood. The pot has never paid.","Half the guard copies his stance. The other half copies his voice and gets caught.","The alehouse keeps a chair for E3PO. It has never been sat in and never been moved.","They say the gate was hung around him, not the other way about.","A trader asked who the statue by the gate was. The statue answered him.","Every guard captain since has been measured against him and come up short on purpose.","They say the scar misfires every spell in Bellmire except whatever keeps the Commander standing.","A priest offered him last rites once, hopefully. He declined, politely, for the ninth time.","Children dare each other to make the Commander laugh. One claims to have done it.","The guild post keeps his old spear on the wall. He keeps asking for it back.","They say if you are lost in the valley, walk until someone shouts at you. That is the road home.","Nobody remembers hiring him. The ledger simply starts with him in it.","The town has one true relic and it answers when you call it.","They say E3PO once held the ford alone for a day and would not say how.","The children think the Commander does not sleep. The watch knows he does, briefly, upright.","Three brides have asked E3PO to give them away. He has, each time, like a parade.","The guild clerk swears the Commander never corrects a ledger. He corrects the clerk.","They say if you run from E3PO you only make the walk back longer.","The baker leaves a loaf by the gatehouse every dawn. It is always gone by noon.","The Commander remembers every name the roll has ever carried. The roll believes him.","They say he mended the old gate with his hands and the gate thinks it was his idea.","The brewers' guild named a bitter after him. He has not tried it. They will wait.","The watch keep a chair warm for him. He has never sat in it.","They say the Commander once outstared a storm. The storm turned.","A travelling priest tried to bless E3PO. The priest left blessed.","They say if the wall ever falls he will be found propping it up with his back.","The shepherds leave the top gate unlocked on nights he walks. He locks it as he passes.","They say his book has a page for every soul the gate has let through, and it adds up.","The chapel mason carved E3PO's face above the door by mistake. Nobody asked him to change it.","The miller's daughter asked him his age. He said 'enough', and she wrote it down.","They say he refused a lordship once. The letter is on the gatehouse wall, unread.","The town's oldest curse is 'may you be inspected by E3PO at supper'. It still works.","They say when he walks the wall the wall stands straighter for a week.","'The mill is clacking, the bakers are shouting. Good. Quiet towns are dying towns.'","E3PO listens to the market with the face of a man doing sums.","'A fed town does not riot. Remember that when someone asks to cut the bread.'","The Commander greets a child by name, and the child by title. Both are delighted.","'Whatever we build, we build it so that the old can sit and the young can run.'","E3PO tugs a loose shutter back into place on his way past. He did not stop walking.","'A town is a promise and a roof. Keep both good.'","'The people talk more than the wall does. Both tell me something.'","They say E3PO has never once been late, and the sun has noticed.","A cooper swears E3PO walked through a wall of arrows and straightened his collar afterward.","Children play 'Commander' and the loser always has to be the raider.","Old Margit says E3PO taught her mother to curtsey. Nobody asks which of them was nervous.","The tavern keeper holds a stool for E3PO. He has never sat on it. It is polished anyway.","Someone carved E3PO's boot-print into the gate flagstone. It is the best-kept stone in town.","They say the raiders' camp whispers his name and goes quiet.","The blacksmith claims E3PO's armour dents flatten themselves overnight.","A merchant asked E3PO the time. He is still not sure whether he was answered or inspected.","The bell-ringer says E3PO is the only man who can make the morning hour arrive on schedule.","Travellers ask who commands the guard. The answer is always a long, proud pause.","They say E3PO once outstared a winter storm. The storm blinked first."]},"lord_intros":{"hollow_king":"The braziers in the hall burn blue, and then burn cold.","grubmother":"The floor is wet, and getting wetter.","rattling_host":"Somewhere ahead, something counts its own bones out loud.","nightwing":"Every torch on the floor gutters at once.","gravewyrm":"The dungeon was built around this, and it knows it.","ossuary_lord":"It has waited a very long time. A little longer is nothing.","pale_duchess":"A lady laughs somewhere ahead, very politely.","mourncoil":"Breath steams. Then the steam freezes."},"unique_intros":{"gnawbone":"The walls squeal.","mother_silk":"The threads across the doorway are new.","weeping_bowman":"A string twangs in the dark, and something weeps after it.","cinderjack":"Someone has been playing with the firepits.","kept":"A voice the guild knew calls a name the guild remembers."},"disasters":{"volcano":{"begin":"The mountain above the scar wakes - ash on the wind, and the sky goes copper.","during":["Ash falls on Bellmire; the sun is a dull coin behind the smoke.","The river runs grey, and the fish float up dead.","Cinders tick off the roof-tiles all night; nobody opens a shutter.","The crier reads the day's news through a cloth over his mouth.","The ash drifts into the grain store through a gap nobody knew was there.","Sheep come down off the high pasture coughing, and do not go back up.","The chapel bell rings muffled, packed with grey.","Children write their names in the ash on the shutters. By morning it has written over them.","A cart leaves two clean ruts in the grey, and nothing else does.","The guild post sells cloth masks and is out of them by noon.","Lamps are lit at midday; the copper sky gives nothing to work by.","Ash sits a finger deep on the chapel steps and is swept twice a day.","Grey settles on the market bread, and the bread sells anyway.","The high pasture is gone under ash; the shepherds bring everything down.","Ash falls like grey snow and the cookfires are put out to save the air.","The mountain speaks again and every bell in Bellmire answers it badly.","Carts queue at the Ford with everything a household can lift.","The water butts are skimmed twice a day and still run grey.","A roof goes in under the weight of its own ash, and nobody was under it.","The crier's voice carries badly; the ash eats it before the far side of the square.","The guild post weighs ash out of the grain and charges for honest weight.","Every doorstep is swept, and every doorstep is grey again by dusk.","The forge works blind, the smoke of its own making lost in the bigger smoke.","Bellmire counts the flasks early this week, because the lamps burn all day.","A crust of ash forms on every water barrel by noon.","The forges damp down - no sense feeding a fire the mountain is already feeding.","Children are kept indoors; a mask of linen goes with any errand.","Horses baulk at the grit and will not be led out of the stable.","The guild post marks a line through market day.","The clapperless bell wears a cowl of grey by evening.","Ash lies in the well-rope and the bucket comes up gritty.","The mill-wheel turns slower, clogged with grey.","Nobody can tell noon from dusk; the lamplighter gives up.","A hen lays an egg dusted pale as flour.","The smith spits grey and keeps hammering, for spite.","Fine ash in the ale. The tavern charges the same.","Ash lies on the washing line, and on the washing.","The Watch wear wet rags over the face and call the hours hoarse.","Ewes stand in the pens with grey wool and will not eat.","The bellringer climbs the tower by feel; the lamps do not carry in this."],"pass":"The mountain settles. Ash greys every roof, but the air clears.","cost":"A buried harvest and sickened livestock; the worst-hit district must be rebuilt."},"fire":{"begin":"Fire in Craft Row - a forge banked wrong, and the wind unkind.","during":["The bucket line runs from the river; the Watch beats at the flames.","Smoke rolls over the square as the smiths' roofs go up.","Craft Row is a tunnel of heat; the Watch wets the next roof down and waits.","Somebody's apprentice runs back in for the tools and is dragged out again.","The wind turns, and the bucket line turns with it, cursing.","A roof-beam goes down and the whole square flinches.","They pull a smith off his own forge; he fights them the whole way out.","Sparks ride the night air toward the thatch, and every eye follows them up.","They pull down the shed between the forge and the next roof to starve it.","Buckets come up the line faster than hands can empty them.","A smith's tools glow in the ruin, too hot to carry for an hour.","Somebody counts heads in the square, twice, and then a third time.","The wind drops, and the bucket line gains a yard on it.","Soot comes off the Row and settles on the washing three streets away.","The chapel bell rings itself hoarse and nobody is spare to stop it.","They run a wet line of cloth along the next row and dare the fire to cross it.","A child is handed up the bucket line and over the heads to the far side.","The bucket line runs from the river to Craft Row and does not break.","A roof is pulled down on purpose, to stop the fire using it as a road.","Soot in the bread, soot in the ale, and the market sells both.","The smiths stand in the square with their tools and nowhere to put them.","The chapel bell rings for the line to change hands.","The guild post hands out wet sacking and writes down every one.","Somebody carries the ledgers out before the furniture, and is thanked for it.","Sparks ride the wind as far as the chapel roof; a boy on the bellrope watches for them.","Doors are left wide so the bucket line runs through, not around.","Someone's cat is handed out a window, cursing.","A second row catches - the wind has made up its mind.","The apothecary pours his own water and shuts the door against the smoke.","A ledger is thrown from a shutter and lands open in the mud.","The bucket line runs from the well to the Row, and nobody rests.","Sparks hop the lane onto a dry thatch. A shout, a splash, a close one.","The smiths drag anvils out of the heat like wounded friends.","Smoke rolls over the market; the crier calls the wards by name.","A roof beam goes with a sound like a great door closing.","The bell clangs fire-time and every hand in town answers.","The wet-sack line holds the lane; the smiths wet their own doors and stand on them.","A thatch goes up in one breath and the lane leans back from it.","The bucket line has been passing for an hour. Nobody has said a word.","Coal-dust is carried out of the cellars before it can be a second fire."],"pass":"The fire is out. A row of workshops is char and cinder.","cost":"Buildings in one district burned down and rebuilt from nothing; the smiths sit idle until then."},"drought":{"begin":"No rain since the thaw. The river drops, and the wells go shy.","during":["The crops stand yellow and brittle in the field.","The queue at the well starts before dawn.","The mill-wheel stands still in a riverbed of stones.","Dust comes off the fields in sheets and settles on the market bread.","The well rope goes down further each morning and comes up lighter.","Dust walks the cart-track where the mud used to be.","The miller stops the wheel. There is no water to turn it.","Cattle are driven to the Ford and find it ankle-deep.","The Ford can be crossed dry-shod, and nobody is pleased about it.","Water is carted from upriver and sold by the bucket.","The fields crack into plates you could lift out whole.","The chapel prays for rain at every bell, and the bell is busy.","Thunder at dusk and no rain under it. That is the cruellest part.","The garden plots are given up so the grain can drink.","The river shows its bones at the Ford and the ferryman walks across.","Water is rationed by the bucket and counted by the chapel.","The fields crack open wide enough to lose a boot in.","The well-rope is spliced longer, twice.","Cattle are walked to the river and walked back thinner.","The millrace is a mud lane; the miller sits in his own doorway.","Dust comes off the market floor and settles on everything for sale.","The chapel is full, and nobody is pretending otherwise.","Water is rationed by the bucket, and the counting is done in public.","The grain is cut early and short, because waiting costs more than cutting.","The Ford shows gravel where it used to show fish.","The brewer waters the ale and does not pretend otherwise.","Beasts of the field crowd the one pond left on Bellmire's common.","The guild post moves the market an hour earlier, out of the worst of the sun.","The miller says the wheel will not turn by week's end, and he is counting.","Dust rises off the road to the Ford as if the road itself was walking.","The well-keeper doles out water by the cup and glares at the sky.","The river shows its stones, and the children walk across.","Cracks run through the field like old script.","A cow stares at an empty trough with real reproach.","The brewer waters nothing and sells less.","Dust devils walk the fallow, tidy as sweeps.","The well-rope comes up short and the bucket comes up half.","The cattle stand at the dry river and look at the town.","The water ration is chalked on the post each dawn, and each dawn it is smaller.","Dust on the loaves, dust in the ale, dust in the prayers."],"pass":"Rain, at last. The river climbs, and Bellmire drinks easy again.","cost":"A harvest cut to nothing and thinning livestock; morale sinks until the wells fill."},"famine":{"begin":"The barns are near bare, and spring is a long way off.","during":["Rations at the guild post; the thin get thinner.","A copper will not buy bread that is not there.","The guild post weighs every portion and still sends people away short.","Children are fed first, and the adults have agreed not to discuss it.","The barn is measured twice a day now, and the number never improves.","The guild post cuts the ration and does not meet anyone's eye.","Folk eat the seed grain, which is tomorrow eaten today.","A family leaves for downriver in the dark, so nobody has to say goodbye.","The tavern serves broth and calls it broth, which is honest of it.","Snares go out along every hedge and come back empty more often than not.","The guild post weighs a child's ration against a man's and gives both to the child.","Folk eat what the hens were owed, and the hens stop laying.","The market board is bare, and the stallholders stand behind it anyway.","Nobody talks about the dogs. There are fewer of them.","The grain is measured in front of witnesses now, every morning.","People eat the seed corn and do not discuss what that means for spring.","The chapel door stays open all night and the queue does not shorten.","Bread is weighed in front of the buyer, every loaf, no exceptions.","The seed corn is guarded, because eating it ends more than this winter.","The market has stalls and no goods; people come anyway, for the company.","A household gives up its laying hen and the street notices.","Soup from the chapel, thin and hot and gone in an hour.","The guild post lends against next year's harvest and charges for the doubt.","Nobody speaks of the stores above a murmur, as if loudness would spend them.","The guild post rations by name, and the clerks keep the names honest.","Bread in the market is a quarter-loaf and a short apology.","The chapel kitchen cooks a thin stew and keeps the fire up.","Children are sent to the river with lines and told not to come back empty.","A cat is missing from Craft Row, and nobody will say.","The Ford is dragged for anything that has a mouth and a scale.","The baker's window holds a single loaf, and a guard.","Soup is mostly the word soup.","The last pig is named, which is a bad sign.","Folk trade boots for barley and think it a bargain.","A hungry quiet settles on the market; haggling is too much effort.","The granary-keeper counts the sacks, and counts them again.","The soup is mostly water now, and everyone says it is good.","The Watch walk the grain store in pairs. There is little to guard, and it is guarded.","A cart of turnips from the next village is met at the gate by half the town.","Belts are taken in. The tailor has never been busier or paid less."],"pass":"The first harvest comes in, and Bellmire eats again.","cost":"The town shrinks as the weak are lost; no growth until the barns refill."},"sickness":{"begin":"A fever walks the homes. The apothecary names it, then runs short of cures.","during":["Doors chalked with a warning mark; the healers do not sleep.","The chapel bell tolls more than anyone likes.","The healers run out of simples before they run out of patients.","Market day is called off; the square has never looked bigger.","Doors are marked in chalk, and the chalk is running out.","The apothecary works the night through and brews water with a name on it.","The chapel keeps its lamps lit for the ones who will not see morning.","The Watch carry food to the marked doors and set it down without knocking.","The healers work in shifts and lose track of which shift is theirs.","The chapel sets out water for whoever is still walking.","Nobody shakes a hand in Bellmire this week.","They bury at dawn, in ones, with the fewest hands that will do.","The Ford turns travellers back, politely, with a spear held level.","A house goes quiet, and the chalk mark stays up a week past needing to.","Doors are marked in chalk and the marks are not argued with.","The apothecary works through the night and the queue is longer at dawn.","The Watch leaves bread at the marked doors and does not knock.","The quarantine holds at the Ford; the traders shout across the water.","The apothecary works through the night and writes down every flask.","Nobody shares a cup at market, and nobody has to be told twice.","A street is shut at both ends and fed over the barricade.","The chapel takes the worst cases, because it has the room and the roof.","Work stops in Craft Row - half the benches are empty and the other half are careful.","The crier reads the day's count from a distance, and the square keeps it.","A chalk cross on a Craft Row door, then another on the next.","The apothecary's shutters never close; the queue runs down the lane.","The chapel takes in those with no kin. There are more than it has room for.","The Watch wears linen across the face and does not speak at the gate.","A child is carried out of a house wrapped, and nobody along the street looks away.","The clapperless bell swings once in a draught and everyone pretends it did not.","Doors marked with chalk; the lane goes quiet.","The apothecary brews all night and sleeps standing.","Folk speak across the street, handkerchiefs to their faces.","The chapel keeps its doors open for the sick and the sorry.","A healer's cart stops at one door, then the next, then the next.","Even the tavern is half empty, which tells you everything.","The apothecary boils linen all night and posts the count at dawn.","Doors are left on the latch and food is left on the step.","The gravedigger takes on a boy to help, and wishes he had not needed to.","The chapel holds its services in the yard, with the benches set well apart."],"pass":"The fever burns itself out. Bellmire counts its dead and opens the windows.","cost":"The population falls, and a quarantine freezes trade and work while it lasts."},"hurricane":{"begin":"A great storm drives inland, and the sky turns the colour of a bruise.","during":["Roofs peel away; the river bursts its low banks.","Nobody walks the wall in this.","The gate bar is doubled and the horses are brought inside the hall.","Something large goes past the window sideways and nobody goes to look.","Thatch goes over the square in sheets, like a flock that forgot how.","The Watch rope themselves together to cross the open ground.","Every shutter in Bellmire is either barred or gone.","The river comes up the lane and knocks at the low doors.","The road lamps are taken in; there is nothing out there to hold them.","Rain comes sideways and finds every gap in every wall.","The chapel roof holds, which surprises the mason who built it.","Nobody sleeps, and everybody pretends to.","The orchard loses its oldest tree and half the fruit of the rest.","The gate stays shut. Whatever is outside can wait out the night.","Every shutter in Bellmire is barred and half of them are not enough.","The wind takes a roof whole and sets it down in the square, almost gently.","Nobody crosses the square. The square is not crossable.","Thatch leaves the roofs in sheets and is not seen again.","The river comes over the low bank with the wind pushing it.","A tree comes down across the west road and lies there all night.","Shutters hammer all night; nobody in the low district sleeps.","The market stalls are carried away whole and found in the fields.","The bucket line forms for water coming in, not going out.","The guild post's sign is taken off its hooks and never recovered.","Shutters come loose and fly; the Watch nails what will hold and lets what will not.","The Ford climbs over its path and takes a stretch of fence with it.","A boat is up on the chapel steps and nobody knows whose.","Sign-posts lean at the same hour, in the same direction, all over Bellmire.","A sheet of rain crosses the square and the square empties behind it.","The guild post keeps its doors braced open, so the wind cannot slam them shut.","Shutters bang like a drum-corps with no rhythm.","A hay-cart takes flight and lands in the next parish.","The wind finds every gap in every wall and sings through it.","Rain comes sideways, and the thatch goes with it.","Folk huddle in the chapel and sing, loudly, to drown the wind.","A signboard sails past the window, still swinging.","Slates come off the chapel roof and go past the Keep like gulls.","The shutters hold. The shutter-pins do not.","The river is in the road and the road is in the river.","The Watch keep to the gatehouse and call the hours through the slit."],"pass":"The storm blows through. Bellmire is sodden and battered, but standing.","cost":"Roofs and buildings torn across the town, fields flooded, and days of repair."},"tornado":{"begin":"A finger of wind drops out of the storm and walks toward the town.","during":["It takes a barn whole and sets it down in splinters.","Mind the sky - it has not lifted yet.","Carts are roped to posts and the posts are not reassuring.","It walks the far field twice and turns, and the whole town watches the turn.","It takes the fence line, the hay cart and the cart's horse, in that order.","The sound arrives before the wind does, and nobody forgets it.","Folk go flat in the ditches and hold on to the grass.","A door lands in the square. Nobody owns it.","It crosses the river and takes a column of water up with it.","The pens are opened on purpose - better scattered than roofed.","It walks the hedge line, and afterward the hedge is simply not there.","The air goes green and very quiet, and then it does not.","Folk count it across the fields the way they count thunder.","It touches the mill yard, leaves the mill, and takes the yard.","It walks the fields like something deciding, and the town watches it decide.","The cellars fill with people and the bell is left to ring alone.","A barn goes up and does not come down anywhere anyone can find.","The wind takes one house and leaves its neighbour's shutters latched.","Livestock is scattered over a mile of open country.","A cart is found in a tree and left there, because nobody can reach it.","The lane it cut runs straight through the town and out the other side.","Thatch, hurdles and a chapel bench come down in the next field.","A wall stands with no house behind it, and does not fall for days.","Nobody counts the sheep until the wind has fully gone.","The sound is wrong - a train that was never built, going past.","A door is lifted off its frame and set down in a different lane entirely.","Hay from an outlying barn is in the chapel courtyard, miles from any barn.","The Watch runs people into cellars, not politely.","The Ford shows for a moment through a window where no window ought to show it.","The sky goes green, which Bellmire does not like and has learned to respect.","The funnel walks the field edge with a stately, awful patience.","A fence post flies by, upright, as if on an errand.","The roar is the loudest thing any of them has ever heard.","Cattle bolt in every direction at once.","A whole rooftop spins away like a dropped hat.","The cellar door holds, barely, against the pull.","The funnel crosses the beet field and leaves the field bare.","A hay wagon goes up and does not come down in one piece.","Everyone with a cellar is in it, and so are their neighbours.","A hush first, then a roar like a mill with no wheel."],"pass":"The wind lifts and is gone, leaving a straight scar of wreckage.","cost":"A random line of buildings flattened, and livestock scattered or lost."},"earthquake":{"begin":"The ground rolls - the scar shudders, and so does everything above it.","during":["Walls crack; the clapperless bell swings and almost rings.","Aftershocks, and nobody trusts a roof.","The well comes up muddy and the masons will not say why yet.","Every door in Bellmire sticks, and one wall leans that did not lean before.","The bell with no clapper rings anyway, and nobody finds that funny tonight.","Masonry comes off the gatehouse in the aftershock.","Folk sleep in the square rather than under their own beams.","A crack opens along the chapel floor and runs out under the door.","The masons walk the walls with chalk, marking what cannot be slept under.","The scar groans, and the delvers come up and stay up.","A chimney comes down into the lane and misses everybody.","The well water tastes of stone for three days.","Nobody rings the bell on purpose; it manages on its own.","The gate will not shut square, and the garrison props it.","The ground moves twice more while they are still counting the first.","Masons walk the walls tapping stone and shaking their heads.","Nobody sleeps indoors. The square is full of blankets.","Aftershocks come at no useful interval; nobody sleeps indoors.","The masons chalk every crack and come back to see if it has grown.","A well goes dry, and a different well comes up muddy.","The scar's mouth is wider this morning than it was last night.","The square fills with households and their bedding, by choice.","The bell with no clapper rings in its frame and unsettles everyone.","A wall is propped with timber and the timber is watched.","The chapel cross goes a hand off true and nobody has the hand to straighten it.","Wells silt up all at once, as if on a signal.","A shelf of pots in the bakers' goes over, and the cat with it, in that order.","The clapperless bell swings in the frame and nearly - nearly - rings.","A stair on Craft Row cracks across in a line too neat for weathering.","The Watch counts heads at the post and finds two short. Then one. Then none.","Plates dance off the shelves in a slow, awful waltz.","The scar groans like an old door and the whole town shivers with it.","Dust sifts from every rafter; the cellar steps feel unsure.","A crack runs up the chapel wall and everyone pretends not to see it.","The well-water slops out as the ground rolls underneath.","Chickens leave the coop an hour before the shaking begins, and are right.","A second shock brings down the chimney that the first had loosened.","Cups walk off the shelves in the tavern, and the barkeep lets them.","The masons go from wall to wall with a plumb line and a long face.","Dust drifts out of the cracks in the chapel, and then a little more."],"pass":"The shaking stops. Bellmire checks its walls, and its dead.","cost":"Walls and buildings cracked or down town-wide; the scar may gape a little deeper."},"meteor":{"begin":"A star falls - too slow, too bright - and comes down past the fields.","during":["The impact lights the night; the ground is scorched for a mile.","Something glitters in the new crater, and it hums like the scar.","Carters give the crater a wide berth; the horses refuse it outright.","The scar hums all night, as if something answered.","The orchard burns in rows, tree after tree, very neatly.","The crater glows all night and hums if you stand too close.","The first fool down the crater wall comes back up with a fistful of glass.","The guild post has a man on the crater by morning, counting.","The crater throws a light on the clouds you could read by.","Grass fires walk the field edge and are beaten out with coats.","The guild post puts a guard on the glass and a price on it by noon.","Two delvers go down the crater wall on a rope, for a wager.","Every dog in Bellmire faces the crater and will not be turned.","The stone cools slowly, and the night smells of struck flint.","The crater glows for three nights and nobody will sleep near it.","Scavengers come to the crater and the Watch turns them back at the rim.","Glass lies in the crater, and the glass remembers the heat.","The crater smokes for days and nobody will say it is safe.","Scarglass is picked out of the rim by hand and weighed at the guild post.","The orchard burns in rows, neatly, as if planted that way.","A watch is set on the crater, less for the town than for the thieves.","Everything near the fall is warm to the touch and stays warm.","Traders arrive early, asking about glass before asking about the dead.","The crier reads the toll, then the price of scarglass, in that order.","The crater at dawn is a bowl of smoking glass, and the glass is still warm.","Children are kept from the orchard road; the Watch keeps them from it harder.","The apothecary sends a flask of water to the crater and asks for a spoon of it back.","The scar hums a note it has not hummed before, and the crater hums with it.","A hawk circles the fallen star all day and will not perch anywhere near.","The guild post posts a bounty for a shard the size of a thumb.","The sky holds a second sun, brief and wrong, then the thunder arrives.","Scarglass chimes in the field where the fragments cool.","Folk shade their eyes and watch the fire-trail with open mouths.","A hiss of steam as the crater meets the stream.","The fall left a hush behind it, and a smell like struck flint.","Every dog in the valley sits and stares at one spot.","The crater glows red at night and nobody can say why it is warm.","A tinker is found at the rim with a sack, and walked away with the sack.","The scar hums a note lower than before, and the horses will not be led past the field.","Scarglass cools in the crater in dark ribs, and the guild post sends a clerk to count it."],"pass":"The fires burn out. A crater smokes where the orchard used to stand.","cost":"An outlying district or the orchard is destroyed - but the crater yields scarglass worth a fortune."},"scarstorm":{"begin":"The scar flares, and wild magic rolls up out of the dungeon mouth and over the town.","during":["Every spell cast in Bellmire goes wrong; the lamps burn strange colours.","The livestock speak for a heartbeat, and the well runs uphill.","The apothecary corks everything and sits on the box.","A delver's lamp burns green, and the dark leans in to look.","A door opens onto a different room than it did this morning.","Every candle in the chapel burns blue and will not be put out.","A cooper's barrel fills itself with river water, and nobody touches it.","The casters sit it out, hands in their laps, useless and insulted.","Shadows fall the wrong way across the square, and nobody mentions it.","A hedge flowers out of season, all at once, and then forgets.","The chapel bell rings a note that is not one of its own.","A delver's blade goes cold enough to burn the hand holding it.","The crier reads his notice twice and it says different things.","Birds fly one circle over the scar and will not break it.","The scar breathes out, and the air in the lower streets goes wrong.","Lamps burn purple at the scar's edge and the Watch pulls back a street.","Nothing comes out of the scar. That is the part that frightens people.","No spell holds while it lasts; casters stand in the square with nothing to offer.","A house is a slightly different shape by morning and will not be argued with.","The guild post's weights read differently every hour and are set aside.","Somebody comes out of the storm scar-touched, and it is not yet clear which way.","The bell with no clapper rings clean, once, and will not do it again.","The lamps burn colours and the oil is spent at twice the rate.","Nobody walks near the scar's mouth, and the watch is doubled anyway.","The baker's bread rises in the shape of a face it ought not to remember.","The Watch's horns play a chord nobody tuned, every quarter hour, exactly.","The chapel candles burn the colour of the scar for an hour, then go back.","A lamplight amulet lights every lamp in the lane at once and refuses to stop.","The guild post's ink writes a line the clerk did not write, in his own hand.","The clapperless bell rings. Bellmire does not look at it; Bellmire looks away.","Blue sparks crawl along the rooftops and spell something rude.","The cat is now two cats, briefly, and then one cat again.","A mage's staff hums and refuses to be quiet.","Colours slide off the market banners and pool on the ground.","Words in the tavern come out in the wrong order and the wrong language.","The weathervane points straight up, then down, then makes a little knot of itself.","A bucket of water rises out of the well, shivers, and goes back down.","The lamps burn blue, then green, then a colour with no name.","The Watch's shadows do not quite keep time with them.","Every spell in town goes sideways; the hedge-witch sits on her hands."],"pass":"The scar quiets. The magic settles, mostly, and the town tallies what changed.","cost":"Spellcasters are useless while it lasts; random buildings warp, and a few folk are scar-touched for good or ill."},"flood":{"begin":"The thaw comes all at once. The river climbs the banks, and keeps climbing.","during":["The low district is ankle-deep, then knee-deep.","The Ford is gone under brown water; no crossing today.","The grain store is moved up a floor by every pair of hands in town.","Boats in the lane where carts should be, and someone fishing out of a window.","The Ford is gone - only the posts show where it was.","Stores go up to the Keep a sack at a time, through knee-deep water.","A hen coop sails past the chapel with the hens still aboard.","The Watch mark the water on the gatepost each hour. The marks keep climbing.","The chapel keeps the pews stacked and the floor under an inch of river.","The low district moves upstairs and lives there.","The bridge posts are all that show of the road to the Ford.","A cellar gives up its stores in a slow brown stream.","Fish are taken in the lane, which is funny for a day and then is not.","The gatehouse step is the measure now, and everybody checks it.","The lower streets take water to the knee and then to the waist.","Boats work the market square, which nobody finds funny.","Grain goes up to the Keep sack by sack, by a line that does not stop.","The low district is moved upstairs, one household helping the next.","The grain store's bottom row is lost and counted as lost out loud.","Boats work the lanes where carts worked last week.","The traders stand on the far bank and shout their prices across.","The chapel floor is under water and the service is held on the steps.","The well is fouled by the river and roped off for drinking.","Everything that can be lifted has been lifted; the rest is being watched.","Boats where carts should be; the Watch rows the low lanes.","The Ford is a rumour under brown water.","Cellars brim. Stores float off, and nobody is quick enough.","Sandbags go up along Weir Lane and are drowned anyway.","Children are carried to high ground on shoulders.","The river takes a fence, a pig and a cart, and gives none of them back.","The Ford is gone under brown water and a dead tree rides the current.","Sandbags go up along the lane, passed hand to hand.","Folk rescue a pig from a rooftop and a priest from a barrel.","The river carries off a bridge-plank and a boot, and keeps both.","Ankle-deep in the tavern, and the barkeep refuses to close.","The water climbs the third step and pauses, thinking.","The ferryman's boat goes up Weir Lane and does good work there.","Fence rails ride past the chapel one by one, in good order.","The tavern's lowest stair is a bench now, and the drinkers sit on it with their boots in their hands.","The Watch mark the post at dusk. It is a hand higher than at noon."],"pass":"The water drops back, leaving mud in every doorway - but the town held.","cost":"Riverside buildings and stores ruined; the Ford and its trade shut until the river falls."},"blight":{"begin":"A black rot is in the grain - it came up in one field and did not stop there.","during":["Whole rows are cut and burned before the rot can walk to the next field.","The miller turns away sack after sack, and says nothing, which is worse.","The rot shows black at the stalk and climbs from there.","Field hands burn their gloves at the end of the day, just in case.","Bread goes up a copper, then another, and the baker stops apologising.","The guild post buys grain from downriver at a price it will not read aloud.","A farmer stands at his field edge all afternoon doing nothing at all.","They plough the worst acre under and sow nothing in it.","The smoke of burning rows hangs over the fields all week.","Seed grain is set aside and guarded, because next year is in the sack.","A field is written off at noon and burned by dusk.","The baker mixes in what he can and calls it bread, generously.","Hands are scrubbed at the field gate before anyone walks home.","Downriver grain comes up the road under guard and is counted twice.","The fields go black in patches that spread while you watch them.","They burn one field to save the next and argue about it for years after.","The apothecary tests the grain and will not say what she found.","Infected fields are burned, deliberately, with the whole town watching.","Grain prices climb at the market and are read out anyway.","The seed corn is locked and a guard is put on the lock.","Traders come upriver with grain and name a price nobody likes.","The reeve walks the rows daily, marking what is still clean.","Bread is smaller this week and will be smaller next week.","The stores are measured twice, by two different people, in public.","Smoke from the burn-lines hangs over the farms.","The reapers cut ahead of the rot, and lose the race row by row.","Seed-grain is hidden in cellars; the Watch is told to look the other way.","Every field gets a ditch around it and a prayer inside it.","Bread is cut thinner. The bakers say nothing, loudly.","The apothecary swears the rot is not catching. The farmers burn their boots.","The rot creeps through the grain row by row, black and silent.","Farmers burn the worst plots and stand watching the smoke.","The mill sits idle; nothing sound is left to grind.","The market loaf has gone small, and the price has not.","A sour smell lies on the fields at dusk and refuses to leave.","Folk check each ear of corn like a bad coin.","Black stalks are carried to the burning pit in sacks, and the sacks are burned too.","The miller will not take a grain that has been near the north field.","Crows will not land on the blighted rows, and that says enough.","The farmers walk their rows each dawn, looking for the first black spot."],"pass":"The blight burns out at the field edge. What is left of the harvest comes in early.","cost":"Most of the standing harvest is lost; food prices climb and the stores do not refill this season."},"coldsnap":{"begin":"The cold comes early and hard - the Ford freezes over in a night.","during":["Firewood costs what wine cost last week, and the queue for it is longer.","The Watch walk in pairs now, because one man alone stops moving.","The Ford is a road now, and nobody trusts it enough to use it.","The forge is the warmest room in Bellmire, and the smith charges for the privilege.","Water freezes in the bucket between the well and the door.","Caravans turn back at the hill, and the market has empty boards.","They bring the lambs indoors and share the floor with them.","The chapel takes in whoever has no fire, and the chapel is full.","Nails of ice hang off every eave, long enough to be dangerous.","The well head is thawed each morning with a kettle.","One oven bakes for the whole street, to save the wood.","The garrison drills indoors and complains, which keeps it warm.","Cattle breath stands in the byre like smoke that will not leave.","Two nights running, nobody goes further than the next door.","The river takes a skin of ice and the ferry stops for the first time in years.","Firewood doubles in price by noon and the Watch stands over the woodpile.","The old and the young are moved into the Keep hall together.","Livestock is brought indoors and lives among the household.","Building stops: the mortar will not set and nobody pretends it will.","The Ford is ice, so the trade is ice too - nothing moves either way.","Firewood is rationed and the rationing is read out by the crier.","The wells are broken open with a mallet each morning.","Work in Craft Row halts; the forge is the warmest room in Bellmire.","The chapel is full because the chapel is heated.","Breath smokes in the market; the stalls sell hot cider and nothing else.","The smiths run the forges all night, not for work but for warmth.","The pump is frozen. Snow is melted for the soup.","Sheep are brought into the houses. Nobody complains.","The Watch walks double shifts in every cloak it owns.","Frost cracks the water-barrels one by one, like slow thunder.","The pump is frozen solid, and the well-rope is stiff as a bar.","Breath hangs in the air like small ghosts.","Ice on the inside of the shutters; the hearth gets all the love.","A lamb is carried inside, wrapped in a good coat.","The Ford is a pale road, and the carters test it with a pole and a prayer.","The stew freezes between pot and bowl, and the cook weeps.","Ice on the inside of the shutters, and the children breathe clouds at the table.","The well-rope freezes and the Watch break it with a mallet.","Sheep are brought into the hall, and the hall smells of sheep.","Frost on every beard in the tavern, and no one takes his coat off."],"pass":"The thaw comes. The Ford runs again, and Bellmire counts who it kept.","cost":"Livestock lost and work stopped: building, trade and the fields all halt until the thaw."}},"events":{"bandit_camps":[{"name":"The Gallows Oak","leader":"Red Harl","appears":"Red Harl's lot have taken the west road. No caravan reaches the Ford unbled.","while":"Trade caravans are robbed; the market runs short and prices climb.","cleared":"Red Harl hangs from his own Gallows Oak. The west road is open again."},{"name":"The Mire Nest","leader":"Sedge the Toll","appears":"Sedge the Toll holds the fen path and taxes everyone who is not her.","while":"Every trader by the fen pays Sedge first; the town's cut shrinks.","cleared":"Sedge the Toll pays her own toll at last. The fen path clears."},{"name":"The Burnt Mill","leader":"Cob Ashfoot","appears":"Cob Ashfoot's raiders have holed up in the burnt mill, firing a field a night to keep the town afraid.","while":"A field burns most nights; harvest and morale both drop.","cleared":"The Burnt Mill burns one last time. Cob Ashfoot runs, and keeps running."},{"name":"Scarside Camp","leader":"The Weasel","appears":"The Weasel's crew squat at the scar's edge, robbing the delvers who climb out.","while":"Returning delvers are waylaid; their gold and loot never reach Bellmire.","cleared":"Scarside Camp is cleared. Delvers come up to friends now, not knives."},{"name":"The Drover's Rest","leader":"Juno Blackhand","appears":"Juno Blackhand has taken the drovers' inn on the north road and left the sign hanging.","while":"Livestock driven to market never arrive; the pens stand empty on market day.","cleared":"The Drover's Rest changes hands again. Juno Blackhand does not leave with it."},{"name":"The Quarry Camp","leader":"Old Peck","appears":"Old Peck's lot have moved into the worked-out quarry and are selling Bellmire its own stone back.","while":"Cut stone and lime go missing; building in town stalls for want of either.","cleared":"The Quarry Camp is emptied out. The stone comes down the road at an honest price."},{"name":"The Lampless Road","leader":"Wick Harrow","appears":"Wick Harrow's crew put out the road lamps one by one, and work the dark they made.","while":"Nobody travels after dusk; the night trade stops and the Ford shuts early.","cleared":"The lamps burn the whole length of the road again. Wick Harrow walks it in chains."},{"name":"The Weir Camp","leader":"Marek Two-Coin","appears":"Marek Two-Coin has fortified the old weir and charges the river for using itself.","while":"River trade pays twice; the Ford's takings fall while the weir stands.","cleared":"The Weir Camp is broken open. The river runs toll-free again."},{"name":"The Ashen Barrow","leader":"Grell the Patient","appears":"Grell the Patient has dug into the barrow mound and watches the market road out of it.","while":"Market-bound carts are picked off; stalls stand empty on market day.","cleared":"The barrow is emptied of the living. Grell the Patient stays behind in it."},{"name":"The Hollow Stand","leader":"Ivett Crow","appears":"Ivett Crow's archers hold the wood where the road bends, and they do not miss twice.","while":"Couriers and tax carts are lost at the bend; news and coin both arrive late or not at all.","cleared":"The Hollow Stand is cleared. The road bends past nothing worse than trees."},{"name":"The Shepherd's Fold","leader":"Dunn Halfhand","appears":"Dunn Halfhand has taken the high fold and keeps whatever flock he finds in it.","while":"Wool and mutton stop coming down off the hills; the cloth trade and the tavern both feel it.","cleared":"The Fold changes shepherd. Dunn Halfhand leaves with a quarter hand and no flock."},{"name":"The Lime Kiln","leader":"Mad Tibb","appears":"Mad Tibb's crew sleep in the lime kiln and come out white as ghosts to work the road.","while":"Lime and mortar never reach the masons; whatever Bellmire is building stops where it stands.","cleared":"The kiln is cold and empty. Mad Tibb is walked back to town the colour of chalk."},{"name":"The Sunken Boat","leader":"Hask the Ferryman's Brother","appears":"Hask has swamped a boat across the narrows and robs whoever stops to haul it clear.","while":"The narrows are blocked; barges wait, and what they carry spoils in the hold.","cleared":"The Sunken Boat burns to the waterline. Hask swims for the far bank and is met on it."},{"name":"Blackbrier Hide","leader":"Iver Cutgrass","appears":"Iver Cutgrass has cut a camp into the blackbrier where no horse can follow.","while":"Foot traffic on the south track is robbed; the smaller traders stop coming at all.","cleared":"Blackbrier Hide is burned out. The south track carries packs again."},{"name":"The Charcoal Camp","leader":"Mother Soot","appears":"Mother Soot and her burners hold the charcoal stands above the wood.","while":"Charcoal runs short; the forge works half days and smith prices climb.","cleared":"The Charcoal Camp is taken. The forge burns a full day again."},{"name":"The Rook Field","leader":"Carrow Dace","appears":"Carrow Dace has set his crew in the rook field, where the crop stands tall enough to hide a man.","while":"Harvest carts are stopped at the field edge; grain comes in short at the measure.","cleared":"The Rook Field is cut early and cleared. The measure fills honestly again."},{"name":"The Salt Road Camp","leader":"Tam Pell","appears":"Tam Pell has taken the salt road where it narrows, and charges the narrow part.","while":"Salt and cured stores arrive dear; preserved food in town spoils faster for want of it.","cleared":"The Salt Road Camp is broken. Salt comes in at the old price."},{"name":"The Beekeeper's Hut","leader":"Hollis Grin","appears":"Hollis Grin has turned the beekeeper out of his own hut and kept the bees.","while":"Honey, wax and candle stock dry up; the apothecary brews slower without wax.","cleared":"Hollis Grin is stung out of the hut. The beekeeper goes back to his bees."},{"name":"The Dry Ferry","leader":"Nils Odd","appears":"Nils Odd has taken the old ferry landing upriver and runs his own crossing at his own rates.","while":"Half the river trade goes around Bellmire entirely; the Ford takes less each day.","cleared":"The Dry Ferry is sunk at its moorings. The river comes back to the Ford."},{"name":"The Ox Road Camp","leader":"Bram Sallow","appears":"Bram Sallow holds the ox road and takes a beast from every team that passes.","while":"Hauling costs double; stone, timber and grain all arrive late and dear.","cleared":"The Ox Road Camp is cleared out. The teams come in whole."}],"monster_camps":[{"name":"The Bone Field","of":"risen dead","appears":"Something below spat up its dead, and they are gathering in the north field.","while":"The dead multiply nightly and gnaw at the outlying farms.","cleared":"The Bone Field is put down. The north field is only a field again."},{"name":"The Slime Warren","of":"slimes","appears":"A slime nest has taken the old quarry, and it doubles every night it is left alone.","while":"The quarry is lost, and the nest creeps toward the homes.","cleared":"The Slime Warren is burned out. The quarry stops twitching."},{"name":"The Belltower Roost","of":"cave bats","appears":"A roost of cave bats has taken the bell-tower; they foul the wells and spook every horse in town.","while":"The wells need watching, and the beasts are restless while they hang there.","cleared":"The Roost is cleared. The bell-tower is quiet. Almost."},{"name":"The Sedge Mound","of":"bog frogs","appears":"The fen has gone loud - bog frogs the size of dogs have mounded up in the sedge.","while":"The fen path is lost, and the fishers work the river or not at all.","cleared":"The Sedge Mound is cleared. The fen is merely unpleasant again."},{"name":"The Silk Barn","of":"cave spiders","appears":"A barn on the south road has gone white - cave spiders came up out of the scar and took it.","while":"The south road is spun shut; nothing moves past the barn after dusk.","cleared":"The Silk Barn burns. The south road is clear, and nothing is watching it."},{"name":"The Gnaw Pits","of":"scar rats","appears":"Scar rats have got into the old root pits, and they are not the size rats are meant to be.","while":"Stores are gnawed through nightly; what the town keeps, it keeps losing.","cleared":"The Gnaw Pits are flooded out. The stores hold their weight overnight again."},{"name":"The Drowned Pen","of":"bog lurkers","appears":"Something came up the flooded ditch and has settled in the stock pen at the water's edge.","while":"Livestock go a head a night, and the herds will not drink near the water.","cleared":"The Drowned Pen is cleared and the ditch dug out. The herds drink again."},{"name":"The Candle Wood","of":"scar wisps","appears":"Lights have taken the coppice east of town, and they walk the paths at dusk like a procession.","while":"The woodcutters refuse the coppice; firewood and charcoal run short in town.","cleared":"The Candle Wood goes dark. The cutters go back in by daylight, then by dusk."},{"name":"The Kiln Nest","of":"fire beetles","appears":"Fire beetles have bored into the brick kiln and glow in its mouth all night.","while":"The kiln cannot be fired; brick, tile and pottery all stop at once.","cleared":"The Kiln Nest is smoked out. The kiln fires clean, and the tiles come again."},{"name":"Gibbet Hill","of":"risen dead","appears":"The hanged have got up off Gibbet Hill, and they keep to the road they knew.","while":"The north road belongs to the dead after dark; nothing travels it and the post stops.","cleared":"Gibbet Hill is put down and the ground turned. The road is only a road."},{"name":"The Granary Swarm","of":"scar wasps","appears":"A nest the size of a cart hangs in the granary roof, and this is not the season for it.","while":"The granary cannot be worked; stored grain spoils where it stands.","cleared":"The Granary Swarm is burned out. The grain is turned, and most of it is saved."},{"name":"The Stone Yard","of":"cave trolls","appears":"Two things out of the deep have taken the mason's yard and are eating the mortar.","while":"Cut stone and finished work are wrecked nightly; every build in town slows.","cleared":"The Stone Yard is retaken. The masons find their tools, and a troll's tooth in a block."},{"name":"The Thornwake","of":"scar hounds","appears":"Something hound-shaped dens in the thornwake, and it hunts in a pack now.","while":"Flocks and herds are taken nightly; the pens empty and the drovers will not go out.","cleared":"The Thornwake is cleared. The flocks sleep out again."},{"name":"The Reed Hollow","of":"bog leeches","appears":"The reed hollow has gone thick with leeches the size of a forearm.","while":"Nobody will cut reed or draw water there; thatch and water both come from further off.","cleared":"The Reed Hollow is drained and burned. The reed cutters go back down."},{"name":"Potter's Field","of":"risen dead","appears":"The nameless graves in Potter's Field are opening from the inside.","while":"The dead wander in from the south each night; the gate shuts an hour earlier.","cleared":"Potter's Field is put down and dug over. The south gate keeps its hours."},{"name":"The Rookery Barn","of":"grave moths","appears":"Grave moths have taken the rookery barn, and the cloud of them is visible from the wall.","while":"Stored cloth, wool and grain sacks are eaten through; the market loses a stall a week.","cleared":"The Rookery Barn is smoked out. What is stored stays stored."},{"name":"The Split Stone","of":"cave centipedes","appears":"Something long and many-legged is coming up through the Split Stone, one after another.","while":"The quarry stands idle; building work in town stops where the stone runs out.","cleared":"The Split Stone is sealed and the nest burned. The quarry rings again."},{"name":"The Hog Mire","of":"mire boars","appears":"The mire boars have grown wrong and bold, and they hold the lower fields.","while":"The lower fields are rooted up; this season's crop is halved where they walk.","cleared":"The Hog Mire is cleared, and the town eats well for a week."},{"name":"The Chalk Pit","of":"bone crawlers","appears":"The chalk pit has filled with crawling things made mostly of other things' bones.","while":"Lime and chalk stop coming up; mortar runs out and the masons down tools.","cleared":"The Chalk Pit is cleared to the floor. The masons take up tools again."}],"wandering_boss":{"name":"The Scarred Lord","appears":"A lord has climbed out of the scar and walks the open country - and it has grown to match the town it hunts.","while":"It razes an outlying farm each day it roams, and draws the dark along behind it.","cleared":"The wandering lord falls in the open field. Bellmire drags the body home as proof.","note":"Scales to the town's level: a lesser lord early, a greater lord once Bellmire is a city. Reuse the eight canon lords; never a new one."}}};

// chapter tabs: id, label, icon (from ICON_SET), builder.
const LORE_CHAPTERS = [
  { id: "town",    label: "Town life",     icon: "town",  blurb: "What the crier says, and the market", build: loreTownLife },
  { id: "growth",  label: "The town's growth", icon: "town",  blurb: "Every stage the town can reach", build: loreGrowth   },
  { id: "e3po",    label: "Commander E3PO", icon: "shield", blurb: "The Commander, in his own words", build: loreE3po    },
  { id: "lords",   label: "The dark lords", icon: "raid",  blurb: "Who waits at the bottom", build: loreLords   },
  { id: "tales",   label: "Tales of the valley", icon: "lore", blurb: "Stories told about the valley", build: loreTales  },
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
      const btn = el("button", "chip lorecard", "");
      btn.append(icon(c.icon, "lc-ic"), el("span", "lc-t", c.label), el("span", "lc-b", c.blurb || ""));   // page-owned constants
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
  card.tabIndex = 0;
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

// ---------------------------------------------------------------- H29 the Shops tab
// Every shop and the blacksmith: level, what that level may sell, and - when the publisher
// sends it - the shelf itself. NOTHING is hard-coded: names, levels, prices, cargo and orders
// all come from the snapshot, every string through el()/textContent. Contract (payload v5, read
// defensively so the tab lights up by itself the day the publisher sends it; v<5 shows the shops
// and levels it already has and says plainly that the shelf is not published yet):
//   p.shops[]  = {name, level, sells_to, stock?: [{name, cost, qty?, tier?, rarity?}]}   (D64 + v5)
//   p.caravan  = {present, leaves_in?, cargo: [{name, cost, qty?, rarity?}]}               (v5; p.trader accepted)
//   p.orders[] = {who, item, shop, status?, walker?}                                       (v5)
// A snapshot value only ever chooses WHICH known glyph / rarity frame; it is never a URL, src,
// href, class name or style. Rarity is matched to a page-owned whitelist before it picks a class.
// C-55: the game's ladder is common < uncommon < rare < very rare < legendary < artifact (economy.gd RARITY).
// "very rare" has a space, so the CLASS is a page-owned slug from this map - never the snapshot string.
// "epic" was retired by the game build; it is kept only as a legacy alias so an old snapshot still frames.
// C-61: this reads the STORED rarity key and nothing else - the hub never bands anything by cost.
const SHOP_RARITY = new Map([["common", "common"], ["uncommon", "uncommon"], ["rare", "rare"],
  ["very rare", "very-rare"], ["very-rare", "very-rare"], ["very_rare", "very-rare"], ["epic", "very-rare"],
  ["legendary", "legendary"], ["artifact", "artifact"]]);
function rarityClass(r) { const k = String(r == null ? "" : r).toLowerCase().trim(); return SHOP_RARITY.has(k) ? "rar-" + SHOP_RARITY.get(k) : ""; }
function shopIconFor(name) { return /smith|forge|anvil/i.test(String(name || "")) ? "anvil" : "stall"; }
// ---- H32 pass 4: item pictures. SECURITY: a snapshot item NAME never becomes a URL. itemIconFile() looks the
// control-stripped, lower-cased name up in ITEM_ICONS (a Map GENERATED from web/icons/items/_manifest.json by
// web/tools/make_item_icons.py - never hand-typed); a hit yields a page-constant "slot/key" and the path is built
// from THAT, a miss falls through to the SVG glyph ("loot", a whitelisted ICON_SET id). No onerror handler, no
// snapshot value in src/href/style; alt is set as text. See docs/HUB_SECURITY.md (H32 pass 4).
// ITEM_ICONS:BEGIN (generated by web/tools/make_item_icons.py - do not edit by hand)
// source commit 2473836; 519 names; thumbnails 160px webp, 2341956 bytes
const ITEM_ICONS = new Map([
  ["amulet of the measure", "amulet/measure_amulet"],
  ["apothecary banner (green)", "banner/banner_apothecary"],
  ["apothecary's cap", "hat/apothecary_cap"],
  ["apothecary's gloves", "gloves/physic_gloves"],
  ["architect's banner", "banner/banner_architect"],
  ["architect's hat", "hat/architect_hat"],
  ["architect's ring", "ring/architect_ring"],
  ["armourer's gauntlets", "gloves/armourer_gloves"],
  ["armourer's visor", "hat/armourer_visor"],
  ["armourers' banner", "banner/banner_armourer"],
  ["ash-wood circlet", "hat/crown_of_ash"],
  ["ashfoot's boots", "boots/ashfoot_boots"],
  ["backstair cloak", "cloak/backstair_cloak"],
  ["baker's mitts", "gloves/baker_mitts"],
  ["barracks banner", "banner/banner_barracks"],
  ["barracks boots", "boots/barracks_boots"],
  ["barracks cap", "hat/barracks_cap"],
  ["barracks key", "amulet/barracks_key"],
  ["barracks watch-cloak", "cloak/barracks_cloak"],
  ["beadle's hat", "hat/beadle_hat"],
  ["beadle's ring", "ring/beadle_ring"],
  ["beekeeper's veil", "hat/beekeepers_veil"],
  ["beeswax gloves", "gloves/beeswax_gloves"],
  ["bell-ringer's gloves", "gloves/bellringer_gloves"],
  ["bell-ringer's hat", "hat/bell_ringer_hat"],
  ["bell-ringer's mitts", "gloves/bellringer_mitts"],
  ["bellfounder's coif", "hat/bellfounder_coif"],
  ["bellfounder's ring", "ring/bellfounder_ring"],
  ["bellfounders' banner (bronze)", "banner/banner_bellfounder"],
  ["bellmire felt", "hat/bellmire_felt"],
  ["bellringer's coif", "hat/bell_coif"],
  ["bellringer's wraps", "gloves/bellrope_wraps"],
  ["blightward charm", "amulet/blight_charm"],
  ["boatwright's charm", "amulet/boatwright_amulet"],
  ["bodger's gloves", "gloves/bodger_gloves"],
  ["bodger's hat", "hat/bodger_hat"],
  ["bodgers' banner", "banner/banner_bodger"],
  ["bolter's boots", "boots/bolter_boots"],
  ["boots of the west road", "boots/road_boots"],
  ["bowyer's cap", "hat/bowyer_cap"],
  ["bowyer's shoulder-cloak", "cloak/bowyer_cloak"],
  ["bowyer's wraps", "gloves/bowyer_wraps"],
  ["brewster's banner", "banner/banner_brewster"],
  ["brewster's charm", "amulet/brewster_amulet"],
  ["brewster's coif", "hat/brewster_coif"],
  ["brickfield banner", "banner/banner_brickmaker"],
  ["brickmaker's boots", "boots/brickmaker_boots"],
  ["brickmaker's cap", "hat/brickmaker_cap"],
  ["bridgeward's helm", "hat/bridgeward_helm"],
  ["bridgeward's ring", "ring/bridgeward_ring"],
  ["brood-iron ring", "ring/chitin_ring"],
  ["bucket-line banner", "banner/banner_bucketline"],
  ["bucket-line cap", "hat/bucketline_cap"],
  ["bucket-line cloak", "cloak/bucketline_cloak"],
  ["bucket-line gloves", "gloves/bucketline_gloves"],
  ["butcher's cap", "hat/butcher_cap"],
  ["butcher's oilcloth", "cloak/butcher_cloak"],
  ["caravan cloak", "cloak/caravan_cloak"],
  ["caravan road banner", "banner/banner_caravan_road"],
  ["carder's gloves", "gloves/carder_gloves"],
  ["carp banner (river-green)", "banner/banner_carp"],
  ["carter's boots", "boots/carter_boots"],
  ["cartwright's cap", "hat/cartwright_cap"],
  ["cartwright's flat cap", "hat/cartwright_flat_cap"],
  ["cartwright's ring", "ring/cartwright_ring"],
  ["chainsmith's coif", "hat/chainsmith_coif"],
  ["chainsmith's mitts", "gloves/chainsmith_gloves"],
  ["chainsmiths' banner", "banner/banner_chainsmith"],
  ["chalker's cap", "hat/chalk_cap"],
  ["chalkline banner (white)", "banner/banner_chalk"],
  ["chalkline gloves", "gloves/chalkline_gloves"],
  ["chandler's amulet", "amulet/chandler_amulet"],
  ["chapel bell banner", "banner/banner_chapel_bell"],
  ["chapel candle amulet", "amulet/chapel_amulet"],
  ["chapel clogs", "boots/chapel_clogs"],
  ["chapman's charm", "amulet/chapman_amulet"],
  ["chronicle banner (ink)", "banner/banner_chronicle"],
  ["chronicler's cap", "hat/chronicle_cap"],
  ["chronicler's cloak", "cloak/chronicle_cloak"],
  ["clapperless bell amulet", "amulet/clapperless_amulet"],
  ["clapperless bell banner", "banner/banner_clapper"],
  ["clapperless charm", "amulet/bell_amulet"],
  ["clapperless ring", "ring/clapper_ring"],
  ["clogger's cap", "hat/clogger_cap"],
  ["clogger's clogs", "boots/clogger_boots"],
  ["cloggers' banner", "banner/banner_clogger"],
  ["cold-forge banner (char)", "banner/banner_coldforge"],
  ["cold-forge mask", "hat/coldforge_mask"],
  ["cold-forge mitts", "gloves/coldforge_mitts"],
  ["collier's band", "ring/collier_ring"],
  ["collier's banner", "banner/banner_collier"],
  ["collier's hood", "hat/collier_hood"],
  ["commander's banner", "banner/banner_commander"],
  ["commander's cloak", "cloak/commander_cloak"],
  ["commander's crested helm", "hat/commander_helm"],
  ["commander's field mantle", "cloak/commander_mantle"],
  ["constable's cloak", "cloak/constable_cloak"],
  ["cooper's banner", "banner/banner_cooper"],
  ["cooper's cap", "hat/cooper_cap"],
  ["cooper's ring", "ring/cooper_ring"],
  ["cordwainer's boots", "boots/cordwainer_boots"],
  ["cordwainer's cap", "hat/cordwainer_cap"],
  ["cordwainers' banner", "banner/banner_cordwainer"],
  ["craft banner (yellow)", "banner/banner_yellow"],
  ["cranesman's cloak", "cloak/crane_cloak"],
  ["cranesman's helm", "hat/crane_helm"],
  ["cranesmen's banner (rope grey)", "banner/banner_crane"],
  ["crater banner", "banner/banner_crater"],
  ["crater-glass coronet", "hat/crater_coronet"],
  ["crater-glass ring", "ring/crater_ring"],
  ["craterglass boots", "boots/craterglass_boots"],
  ["creeler's boots", "boots/creeler_boots"],
  ["crier's cloak", "cloak/crier_cloak"],
  ["crier's plume", "hat/crier_plume"],
  ["crier's tall hat", "hat/crier_hat"],
  ["crown of carp scales", "hat/carp_crown"],
  ["currier's gloves", "gloves/currier_gloves"],
  ["currier's hood", "hat/currier_hood"],
  ["cutler's ring", "ring/cutler_ring"],
  ["cutler's visor", "hat/cutler_visor"],
  ["cutlers' banner", "banner/banner_cutler"],
  ["dauber's boots", "boots/dauber_boots"],
  ["deep-lamp amulet", "amulet/deeplamp_amulet"],
  ["deepwarden's cloak", "cloak/deep_cloak"],
  ["delver's boots", "boots/delvers_boots"],
  ["delver's lamp cap", "hat/delvers_lamp_cap"],
  ["door-kept banner", "banner/banner_door_kept"],
  ["doorkeeper's amulet", "amulet/doorkeep_amulet"],
  ["doorkeeper's band", "ring/doorkeeper_ring"],
  ["doorkeeper's helm", "hat/doorkeeper_helm"],
  ["drover's boots", "boots/drover_boots"],
  ["drover's flat cap", "hat/drover_cap"],
  ["drover's spurs", "boots/drover_spurs"],
  ["e3po's signet", "ring/e3po_signet"],
  ["e3po's standard (guard blue)", "banner/banner_e3po"],
  ["eeler's cap", "hat/eeler_cap"],
  ["eeler's waders", "boots/eeler_boots"],
  ["falconer's hood", "hat/falconer_hood"],
  ["falconer's vervel", "amulet/falconer_amulet"],
  ["falconers' banner", "banner/banner_falconer"],
  ["farrier's mitts", "gloves/farrier_mitts"],
  ["farrier's nail", "amulet/farrier_amulet"],
  ["farrier's visor", "hat/farrier_visor"],
  ["farriers' banner (anvil black)", "banner/banner_farrier"],
  ["feast-night banner", "banner/banner_feast_night"],
  ["feast-night cloak", "cloak/feast_cloak"],
  ["feathered cap", "hat/feather_cap"],
  ["fen-strider's boots", "boots/fen_boots"],
  ["fenwalker's hood", "hat/fen_hood"],
  ["ferry banner", "banner/banner_ferry"],
  ["ferrybell amulet", "amulet/ferrybell_amulet"],
  ["ferrybell circlet", "hat/ferrybell_circlet"],
  ["ferryman's hood", "hat/ferry_hood"],
  ["ferryman's ring", "ring/ferryman_ring"],
  ["ferrystep boots", "boots/ferrystep_boots"],
  ["ferrywife's locket", "amulet/ferry_locket"],
  ["festival garland", "hat/festival_garland"],
  ["first light boots", "boots/firstlight_boots"],
  ["first light circlet", "hat/firstlight_circlet"],
  ["first wall banner", "banner/banner_wall_first"],
  ["fisher's oilskin hood", "hat/fisher_hood"],
  ["flask-count banner", "banner/banner_flask_count"],
  ["flask-count pendant", "amulet/flask_amulet"],
  ["flask-counter's amulet", "amulet/flaskcount_amulet"],
  ["flask-counter's cap", "hat/flaskcounter_cap"],
  ["flask-counter's coif", "hat/flask_coif"],
  ["fletcher's gloves", "gloves/archer_gloves"],
  ["fletcher's hood", "hat/fletcher_hood"],
  ["fletcher's tabs", "gloves/fletcher_tabs"],
  ["fletcher's thumb-ring", "ring/fletcher_ring"],
  ["fletchers' banner (goose grey)", "banner/banner_fletcher"],
  ["fog-run banner (fog)", "banner/banner_fogrun"],
  ["fog-run cloak", "cloak/fogrun_cloak"],
  ["fog-run hood", "hat/fogrun_hood"],
  ["ford banner (river)", "banner/banner_ford"],
  ["ford circlet", "hat/ford_circlet"],
  ["ford crossing banner", "banner/banner_ford_crossing"],
  ["ford-wader's boots", "boots/ford_boots"],
  ["ford-wader's hat", "hat/ford_wader_hat"],
  ["ford-wader's tarred boots", "boots/fordwader_boots"],
  ["fordwarden boots", "boots/fordwarden_boots"],
  ["forgemaster's grips", "gloves/forge_grips"],
  ["fuller's coif", "hat/fuller_coif"],
  ["fuller's grips", "gloves/fuller_grips"],
  ["fuller's token", "amulet/fuller_amulet"],
  ["fullers' banner (cloth white)", "banner/banner_fuller"],
  ["gaoler's coif", "hat/gaoler_coif"],
  ["gaoler's keyring", "amulet/gaoler_amulet"],
  ["garrison banner (steel)", "banner/banner_garrison"],
  ["gatehouse whistle", "amulet/gate_whistle"],
  ["gatewarden's boots", "boots/gate_boots"],
  ["glazier's gloves", "gloves/glazier_gloves"],
  ["glazier's visor", "hat/glazier_visor"],
  ["glaziers' banner (glass blue)", "banner/banner_glazier"],
  ["grain-measure banner", "banner/banner_grain_measured"],
  ["grainmeasure charm", "amulet/grainmeasure_charm"],
  ["grainmeasurer's hat", "hat/grainmeasure_hat"],
  ["grainward amulet", "amulet/grainward_amulet"],
  ["grainward charm", "amulet/grain_amulet"],
  ["gravewyrm helm", "hat/gravewyrm_helm"],
  ["gravewyrm hide cloak", "cloak/gravewyrm_cloak"],
  ["grinning carp charm", "amulet/carp_charm"],
  ["grubmother banner (pale)", "banner/banner_grubmother"],
  ["guard's helm", "hat/guard_helm"],
  ["guild banner (grey)", "banner/banner_guild"],
  ["guild cloak", "cloak/guild_cloak"],
  ["guild hood", "hat/guild_hood"],
  ["guild post banner", "banner/banner_guild_post"],
  ["guild scribe's seal", "amulet/scribe_amulet"],
  ["harvest crown", "hat/harvest_crown"],
  ["harvest gloves", "gloves/harvest_gloves"],
  ["harvest-cart banner", "banner/banner_harvest_cart"],
  ["harvest-saved banner", "banner/banner_harvest"],
  ["hayward's boots", "boots/hayward_boots"],
  ["hearthstone amulet", "amulet/hearth_amulet"],
  ["hearthwarden's hat", "hat/hearthwarden_hat"],
  ["hearthwarden's ring", "ring/hearth_ring"],
  ["hedgeward's cloak", "cloak/hedgeward_cloak"],
  ["hero-home banner", "banner/banner_hero_home"],
  ["hollowbone ring", "ring/hollow_ring"],
  ["homecomer's boots", "boots/hero_home_boots"],
  ["homes banner (green)", "banner/banner_green"],
  ["horner's hood", "hat/horner_hood"],
  ["horner's pendant", "amulet/horner_amulet"],
  ["horners' banner", "banner/banner_horner"],
  ["hurdler's cap", "hat/hurdler_cap"],
  ["hurdler's cloak", "cloak/hurdler_cloak"],
  ["hurdlers' banner", "banner/banner_hurdler"],
  ["joiner's cap", "hat/joiner_cap"],
  ["joiner's gloves", "gloves/joiner_gloves"],
  ["joiners' banner", "banner/banner_joiner"],
  ["keep banner (blue)", "banner/banner_blue"],
  ["keep the door banner", "banner/banner_keepdoor"],
  ["kennelman's boots", "boots/kennel_boots"],
  ["kindling amulet", "amulet/kindling_amulet"],
  ["kindling banner (first-beam gold)", "banner/banner_kindling"],
  ["kindling crown", "hat/kindling_crown"],
  ["lampfast ring", "ring/lampfast_ring"],
  ["lamplight banner (amber)", "banner/banner_lamplight"],
  ["lamplighter's amulet", "amulet/lamplight_amulet"],
  ["lamplighter's cloak", "cloak/lamp_cloak"],
  ["lampwright's cap", "hat/lampwright_cap"],
  ["lampwright's ring", "ring/lampwright_ring"],
  ["lanternman's amulet", "amulet/lanternman_amulet"],
  ["lanternman's cap", "hat/lanternman_cap"],
  ["last coin ring", "ring/lastcoin_ring"],
  ["ledger banner", "banner/banner_ledger_black"],
  ["ledger-keeper's cowl", "hat/ledger_cowl"],
  ["ledger-keeper's gloves", "gloves/ledger_gloves"],
  ["ledger-keeper's ring", "ring/ledger_ring"],
  ["lighterman's mantle", "cloak/lighterman_cloak"],
  ["limeburner's mantle", "cloak/limeburner_cloak"],
  ["limeburner's mask", "hat/limeburner_mask"],
  ["limeburners' banner", "banner/banner_limeburner"],
  ["limner's ring", "ring/limner_ring"],
  ["lockkeeper's cap", "hat/lockkeep_cap"],
  ["lockkeeper's gloves", "gloves/lockkeep_gloves"],
  ["lockkeeper's oilcloth", "cloak/lockkeep_cloak"],
  ["lockkeeper's ring", "ring/lockkeep_ring"],
  ["lockkeeper's waders", "boots/lockkeep_waders"],
  ["lockkeepers' banner (weir green)", "banner/banner_lockkeep"],
  ["long count banner (iron)", "banner/banner_longcount"],
  ["long count boots", "boots/longcount_boots"],
  ["long count hood", "hat/longcount_hood"],
  ["lord-felled banner", "banner/banner_lord_felled"],
  ["lorimer's cap", "hat/lorimer_cap"],
  ["lorimer's ring", "ring/lorimer_ring"],
  ["lorimers' banner", "banner/banner_lorimer"],
  ["lye-boiler's gloves", "gloves/soaper_gloves"],
  ["lye-boiler's wrap", "hat/soaper_wrap"],
  ["lye-yard banner", "banner/banner_soaper"],
  ["maltster's banner", "banner/banner_maltster"],
  ["maltster's cap", "hat/maltster_cap"],
  ["maltster's ring", "ring/maltster_ring"],
  ["market banner (red)", "banner/banner_red"],
  ["market day banner (saffron)", "banner/banner_marketday"],
  ["market seal", "ring/market_ring"],
  ["mason's band", "ring/mason_ring"],
  ["mason's dust cap", "hat/mason_dustcap"],
  ["mason's mitts", "gloves/mason_mitts"],
  ["memorial banner (grey-violet)", "banner/banner_memorial"],
  ["memorial veil", "hat/memorial_veil"],
  ["mender's coif", "hat/mender_coif"],
  ["mender's wraps", "gloves/mender_wraps"],
  ["menders' banner (pale green)", "banner/banner_mender"],
  ["mill banner (wheat)", "banner/banner_mill"],
  ["miller's cap", "hat/miller_cap"],
  ["miller's clogs", "boots/miller_clogs"],
  ["miller's felt", "hat/miller_felt"],
  ["millhand's mitts", "gloves/mill_mitts"],
  ["millrace boots", "boots/millrace_boots"],
  ["millwright's amulet", "amulet/millwright_amulet"],
  ["millwright's cap", "hat/millwright_cap"],
  ["miner's grips", "gloves/miner_grips"],
  ["mire hood", "hat/mire_hood"],
  ["mire-walker's cloak", "cloak/mire_cloak"],
  ["mortarman's gloves", "gloves/mortar_gloves"],
  ["mourncoil banner", "banner/banner_mourncoil"],
  ["mourncoil scale", "amulet/mourncoil_amulet"],
  ["mourner's black veil", "hat/mourners_black_veil"],
  ["mourner's grey", "cloak/mourner_cloak"],
  ["mourner's veil", "hat/mourner_veil"],
  ["mudplank boots", "boots/mudplank_boots"],
  ["nailer's hood", "hat/nailer_hood"],
  ["nailer's ring", "ring/nailer_ring"],
  ["nailers' banner", "banner/banner_nailer"],
  ["netmender's ring", "ring/netmender_ring"],
  ["nightwing banner", "banner/banner_nightwing"],
  ["nightwing boots", "boots/nightwing_boots"],
  ["nightwing hood", "hat/nightwing_hood"],
  ["ninth bell amulet", "amulet/ninthbell_amulet"],
  ["ninth bell banner (bronze)", "banner/banner_ninthbell"],
  ["ninth bell coif", "hat/ninthbell_coif"],
  ["oar-maker's boots", "boots/oarmaker_boots"],
  ["oathkeeper's amulet", "amulet/oath_amulet"],
  ["oathkeeper's ring", "ring/oath_ring"],
  ["orchard banner", "banner/banner_orchard"],
  ["orchard ring", "ring/orchard_ring"],
  ["orchard straw hat", "hat/orchard_straw"],
  ["orchardman's cloak", "cloak/orchard_cloak"],
  ["osier-cutter's cloak", "cloak/osier_cloak"],
  ["osier-cutter's hat", "hat/osier_hat"],
  ["ossuary banner", "banner/banner_ossuary"],
  ["ossuary circlet", "hat/ossuary_circlet"],
  ["ossuary mantle", "cloak/ossuary_cloak"],
  ["ostler's amulet", "amulet/ostler_amulet"],
  ["pale duchess's gloves", "gloves/duchess_gloves"],
  ["pale veil", "hat/pale_veil"],
  ["paver's boots", "boots/pavers_boots"],
  ["paver's cap", "hat/paver_cap"],
  ["pavers' banner (stone)", "banner/banner_paver"],
  ["peat-cutter's cloak", "cloak/turbary_cloak"],
  ["peat-cutter's hood", "hat/turbary_hood"],
  ["pewterer's cap", "hat/pewterer_cap"],
  ["pewterer's ring", "ring/pewterer_ring"],
  ["pewterers' banner", "banner/banner_pewterer"],
  ["pickman's gloves", "gloves/pick_gloves"],
  ["pieman's banner", "banner/banner_pieman"],
  ["pieman's hood", "hat/pieman_hood"],
  ["pilgrim's cloak", "cloak/pilgrim_cloak"],
  ["pilgrim's hood", "hat/pilgrim_hood"],
  ["pilgrim's ring", "ring/pilgrim_ring"],
  ["pilgrim's wide hat", "hat/pilgrims_wide"],
  ["pilgrims' banner (road brown)", "banner/banner_pilgrim"],
  ["pinder's hat", "hat/pinder_hat"],
  ["pinder's ring", "ring/pinder_ring"],
  ["pitwalker's boots", "boots/pitwalk_boots"],
  ["pitwalker's hood", "hat/pitwalk_hood"],
  ["plasterer's gloves", "gloves/plaster_gloves"],
  ["plumed helm", "hat/plumed_helm"],
  ["potter's headwrap", "hat/potter_wrap"],
  ["potter's kiln boots", "boots/kiln_boots"],
  ["potter's thumbmark", "amulet/potter_amulet"],
  ["potters' banner (kiln red)", "banner/banner_potter"],
  ["quarreller's cap", "hat/quarreller_cap"],
  ["quarreller's tabs", "gloves/quarreller_gloves"],
  ["quarrellers' banner", "banner/banner_quarreller"],
  ["quarry banner (slate)", "banner/banner_quarry"],
  ["quarryman's cap", "hat/quarry_cap"],
  ["quarryman's gloves", "gloves/quarry_gloves"],
  ["quarryman's helm", "hat/quarry_helm"],
  ["quarryman's ring", "ring/quarryman_ring"],
  ["quarrymen's banner (dust)", "banner/banner_quarryman"],
  ["raftsman's cloak", "cloak/raftsman_cloak"],
  ["raid-held banner", "banner/banner_raid_held"],
  ["raidbreaker's gauntlets", "gloves/raidbreaker_gloves"],
  ["raidbreaker's helm", "hat/raiders_bane_helm"],
  ["raider's trophy cloak", "cloak/raid_cloak"],
  ["rattling coif", "hat/host_coif"],
  ["rattling gauntlets", "gloves/rattling_gauntlets"],
  ["rattling host amulet", "amulet/host_amulet"],
  ["red harl's cloak", "cloak/harl_cloak"],
  ["reedcutter's boots", "boots/reedcutter_boots"],
  ["reedcutter's hat", "hat/reedcutter_hat"],
  ["reedcutters' banner", "banner/banner_reedcutter"],
  ["reeve's banner", "banner/banner_reeve"],
  ["reeve's hat", "hat/reeve_hat"],
  ["reeve's signet", "ring/reeve_ring"],
  ["retter's gloves", "gloves/retter_gloves"],
  ["ring of the night watch", "ring/nightwatch_ring"],
  ["ring of the scar-guard", "ring/scar_guard_ring"],
  ["ring of the thaw", "ring/thaw_ring"],
  ["rivet mitts", "gloves/rivet_mitts"],
  ["roll-keeper's ring", "ring/rollkeeper_ring"],
  ["rope-burn cap", "hat/ropeburn_cap"],
  ["rope-burn gloves", "gloves/ropeburn_gloves"],
  ["ropewalk gloves", "gloves/ropewalk_gloves"],
  ["ropeworks banner (hemp)", "banner/banner_ropeworks"],
  ["rotwarden's mask", "hat/rot_mask"],
  ["saddler's gloves", "gloves/saddler_gloves"],
  ["saddler's hood", "hat/saddler_hood"],
  ["saddlers' banner", "banner/banner_saddler"],
  ["saltboiler's cap", "hat/saltboiler_cap"],
  ["saltboiler's cloak", "cloak/saltboiler_cloak"],
  ["saltline amulet", "amulet/saltline_amulet"],
  ["saltline banner (pale blue)", "banner/banner_saltline"],
  ["saltline hood", "hat/saltline_hood"],
  ["saltworks banner", "banner/banner_saltline_works"],
  ["sawyer's token", "amulet/sawyer_amulet"],
  ["scar banner (violet)", "banner/banner_scar"],
  ["scar-marked hood", "hat/scarmarked_hood"],
  ["scar-mouth banner", "banner/banner_scar_mouth"],
  ["scarforged banner", "banner/banner_scarforged"],
  ["scarforged ring", "ring/scarforged_ring"],
  ["scarglass circlet", "hat/scarglass_circlet"],
  ["scarglass ring", "ring/scar_ring"],
  ["scarward ring", "ring/scarward_ring"],
  ["scarwatch cloak", "cloak/scarwatch_cloak"],
  ["scarwatch hood", "hat/scarwatch_hood"],
  ["scarweave cloak", "cloak/scarweave_cloak"],
  ["scout's boots", "boots/scout_boots"],
  ["second flask amulet", "amulet/secondflask_amulet"],
  ["sedge's toll-ring", "ring/sedge_ring"],
  ["sexton's banner (grave black)", "banner/banner_sexton"],
  ["sexton's black", "cloak/sexton_cloak"],
  ["sexton's hobnails", "boots/gravepath_boots"],
  ["sexton's low hat", "hat/sexton_hat"],
  ["sexton's ring", "ring/sexton_ring"],
  ["shambles banner", "banner/banner_butcher"],
  ["shepherd's banner", "banner/banner_shepherd"],
  ["shepherd's charm", "amulet/shepherd_charm"],
  ["shepherd's hood", "hat/shepherd_hood"],
  ["shingler's cloak", "cloak/shingler_cloak"],
  ["skepward's charm", "amulet/skep_amulet"],
  ["skepward's gloves", "gloves/hive_gloves"],
  ["skepward's soft boots", "boots/hive_boots"],
  ["skepward's veil", "hat/skep_veil"],
  ["skepwards' banner (wax gold)", "banner/banner_skep"],
  ["sluicekeeper's amulet", "amulet/sluice_amulet"],
  ["smith's gauntlets", "gloves/smith_gloves"],
  ["smith's mark banner", "banner/banner_smiths_mark"],
  ["soft boots", "boots/quiet_boots"],
  ["spare wall cloak", "cloak/sparewall_cloak"],
  ["spinner's gloves", "gloves/spinner_gloves"],
  ["splint-wrap gloves", "gloves/splintwrap_gloves"],
  ["spurrier's cap", "hat/spurrier_cap"],
  ["spurrier's ring", "ring/spurrier_ring"],
  ["spurriers' banner", "banner/banner_spurrier"],
  ["stair-walker's boots", "boots/stairwalker_boots"],
  ["stairhold banner (grey-blue)", "banner/banner_stair"],
  ["stairhold boots", "boots/stairhold_boots"],
  ["stairholder's helm", "hat/stairhold_helm"],
  ["straw hat", "hat/straw_hat"],
  ["tallykeeper's ring", "ring/tally_ring"],
  ["tanner's apron-cloak", "cloak/tanner_cloak"],
  ["tanner's cap", "hat/tanner_cap"],
  ["tanner's gloves", "gloves/tanner_gloves"],
  ["tanner's ring", "ring/tanner_ring"],
  ["tanners' banner (hide brown)", "banner/banner_tanner"],
  ["tanyard boots", "boots/tanyard_boots"],
  ["tavern banner", "banner/banner_taverner"],
  ["tavern banner (ale)", "banner/banner_tavern"],
  ["taverner's cap", "hat/taverner_cap"],
  ["taverner's token", "amulet/taverner_amulet"],
  ["temple banner (white)", "banner/banner_temple"],
  ["thatcher's cap", "hat/thatcher_cap"],
  ["thatcher's cloak", "cloak/thatcher_cloak"],
  ["thatchers' banner (reed gold)", "banner/banner_thatch"],
  ["thaw banner", "banner/banner_thaw"],
  ["thaw circlet", "hat/thaw_circlet"],
  ["thaw hood", "hat/thaw_hood"],
  ["thaw-bell amulet", "amulet/thawbell_amulet"],
  ["the weasel's gloves", "gloves/weasel_gloves"],
  ["thresher's gloves", "gloves/thresher_gloves"],
  ["threshing charm", "amulet/threshing_amulet"],
  ["tiler's hood", "hat/tiler_hood"],
  ["tiler's shoulder-cloak", "cloak/tiler_cloak"],
  ["tilers' banner", "banner/banner_tiler"],
  ["tinker's boots", "boots/tinker_boots"],
  ["tithe banner (wax-white)", "banner/banner_tithe"],
  ["tithe cap", "hat/tithe_cap"],
  ["tithe ring", "ring/tithe_ring"],
  ["tithe-collector's hat", "hat/tithe_collector_hat"],
  ["toll banner", "banner/banner_toll"],
  ["toll ring", "ring/toll_ring"],
  ["toll-gate boots", "boots/tollgate_boots"],
  ["toll-keeper's cap", "hat/toll_cap"],
  ["toll-taker's hood", "hat/toll_hood"],
  ["tollkeep's ring", "ring/tollkeep_ring"],
  ["towpath banner (bank green)", "banner/banner_towpath"],
  ["towpath boots", "boots/towpath_boots"],
  ["towpath hood", "hat/towpath_hood"],
  ["turbary banner", "banner/banner_turbary"],
  ["votive amulet", "amulet/votive_amulet"],
  ["votive veil", "hat/votive_veil"],
  ["wake-ward banner (slate)", "banner/banner_wakeward"],
  ["wake-ward cloak", "cloak/wakeward_cloak"],
  ["wake-ward veil", "hat/wakeward_veil"],
  ["wall banner (stone)", "banner/banner_wall"],
  ["wall-walker's cap", "hat/wall_walker_cap"],
  ["wall-walker's cloak", "cloak/wall_cloak"],
  ["wardstone pendant", "amulet/ward_pendant"],
  ["warhorn mantle", "cloak/warhorn_mantle"],
  ["warrener's boots", "boots/warrener_boots"],
  ["watch banner (black)", "banner/banner_watch"],
  ["watchfire banner (ember)", "banner/banner_watchfire"],
  ["watchfire helm", "hat/watchfire_helm"],
  ["watchfire hood", "hat/watchfire_hood"],
  ["watchfire ring", "ring/watchfire_ring"],
  ["watchman's kettle-helm", "hat/watch_helm"],
  ["watchman's mantle", "cloak/watch_mantle"],
  ["weaver's long cloak", "cloak/weaver_cloak"],
  ["weighstone amulet", "amulet/weighstone_amulet"],
  ["weir banner", "banner/banner_weirkeep"],
  ["weir-keeper's charm", "amulet/weirkeep_amulet"],
  ["weir-keeper's hood", "hat/weirkeep_hood"],
  ["wellhead banner", "banner/banner_wellhead"],
  ["wellhead ring", "ring/wellhead_ring"],
  ["wellkeeper's coif", "hat/wellkeep_coif"],
  ["wheelwright's gloves", "gloves/wheelwright_gloves"],
  ["wide-brimmed hat", "hat/wide_hat"],
  ["winterwatch banner", "banner/banner_winterwatch"],
  ["winterwatch cloak", "cloak/winterwatch_cloak"],
  ["winterwatch helm", "hat/winterwatch_helm"],
  ["withy-bed banner", "banner/banner_osier"],
  ["woodward's banner", "banner/banner_woodward"],
  ["woodward's green", "cloak/woodward_cloak"],
  ["woodward's hood", "hat/woodward_hood"],
  ["wrong-hand ring", "ring/oathwrong_ring"],
]);
// ITEM_ICONS:END
function itemIconFile(name) {
  const k = ctrlStrip(name).replace(/\s+/g, " ").toLowerCase();
  const v = ITEM_ICONS.get(k);
  return v ? "icons/items/" + v + ".webp" : "";
}
function itemPic(name, cls) {
  const box = el("span", "ipic " + (cls || ""));
  const f = itemIconFile(name);
  if (f) {
    const img = document.createElement("img");
    img.className = "ipic-img";
    img.src = f;                                  // a page-constant path chosen by the whitelist, never snapshot text
    img.alt = ctrlStrip(name).slice(0, 60);      // alt is text, not a URL
    img.loading = "lazy"; img.decoding = "async"; img.width = 80; img.height = 80; img.draggable = false;
    box.append(img);
  } else {
    box.classList.add("nopic");
    box.append(icon("loot", "ipic-fb"));
  }
  return box;
}
let lastShopP = null;
// H32 pass 4: a stock item as a CARD (picture, name, category pill, price) with a hover/focus PREVIEW that
// reveals more without a click - the way Twitch previews a stream. The preview is an overlay INSIDE the card's
// fixed box, so nothing reflows. Every string goes through el()/textContent; the picture is itemPic() (a
// whitelist lookup, never a snapshot URL); rarity picks a page-owned frame class via SHOP_RARITY.
function shopCard(g, passing, shopName) {
  const li = el("li", "gcard" + (passing ? " passing" : ""));
  const rc = rarityClass(g && g.rarity);
  if (rc) li.classList.add(rc);
  const nm = g && g.name != null && String(g.name).trim() ? ctrlStrip(g.name).slice(0, 60) : "(unnamed)";
  const rar = g && g.rarity ? ctrlStrip(g.rarity).slice(0, 16) : "";
  const cost = g && Number.isFinite(+g.cost) ? num(g.cost) : "-";
  li.tabIndex = 0;
  li.append(itemPic(nm));
  li.append(el("span", "gc-name", nm));
  const foot = el("span", "gc-foot");
  if (rar) foot.append(el("span", "gc-pill", rar));
  const price = el("span", "gcost");
  price.append(icon("coin"), document.createTextNode(" " + cost));
  foot.append(price);
  li.append(foot);
  const peek = el("span", "gc-peek");
  peek.append(itemPic(nm, "big"));
  peek.append(el("span", "gc-pname", nm));
  peek.append(el("span", "gc-pline", "Costs " + cost + " gold" + (g && g.qty != null && Number.isFinite(+g.qty) ? "  \u00b7  " + num(g.qty) + " on the shelf" : "")));
  if (rar) peek.append(el("span", "gc-pline", cap(rar) + (rc ? "" : "")));
  if (passing) peek.append(el("span", "gc-pline", "Passing through with the caravan"));
  else if (shopName) peek.append(el("span", "gc-pline", "At " + ctrlStrip(shopName).slice(0, 40)));
  li.append(peek);
  return li;
}
function renderShops(p) {
  const box = $("shopsBody");
  if (!box) return;
  lastShopP = p;
  box.textContent = "";
  const shops = arr(p && p.shops).filter((s) => s && typeof s === "object");
  const caravan = p && (p.caravan || p.trader);
  const orders = arr(p && p.orders).filter((o) => o && typeof o === "object");
  if (!shops.length && !caravan) {
    box.append(el("p", "shop-empty", "Bellmire has not reported its shops yet. Once the town's records carry them, every shop and the blacksmith appear here with their level and shelf."));
    return;
  }
  const grid = el("div", "shop-grid");
  for (const s of shops) {
    const card = el("article", "shop-card");
    const head = el("header", "shop-head");
    head.append(icon(shopIconFor(s.name)));
    head.append(el("h3", "shop-name", s.name != null && String(s.name).trim() ? ctrlStrip(s.name).slice(0, 48) : "(unnamed shop)"));
    head.append(el("span", "shop-lvl", "Lv " + (Number.isFinite(+s.level) ? num(s.level) : "?")));
    card.append(head);
    if (s.sells_to != null && String(s.sells_to).trim()) {
      const st = el("p", "shop-sells", "Sells up to ");
      const rc = rarityClass(s.sells_to);
      st.append(el("b", rc, ctrlStrip(s.sells_to).slice(0, 20)));
      card.append(st);
    }
    const stock = Array.isArray(s.stock) ? s.stock.filter((g) => g && typeof g === "object") : null;
    if (stock && stock.length) {
      const ul = el("ul", "shop-stock good-grid");
      stock.slice().sort((a, b) => (+a.cost || 0) - (+b.cost || 0)).slice(0, 80).forEach((g) => ul.append(shopCard(g, false, s.name)));
      card.append(ul);
    } else if (stock) {
      card.append(el("p", "shop-empty", "The shelf is bare."));
    } else {
      card.append(el("p", "shop-empty", "The shelf has not been published yet."));
    }
    grid.append(card);
  }
  box.append(grid);
  // the trader: marked as passing through - the only place a higher tier shows at a low level
  const tr = el("section", "shop-card shop-trader");
  const th = el("header", "shop-head");
  th.append(icon("coin"), el("h3", "shop-name", "The trader's caravan"));
  const here = !!(caravan && caravan.present);
  th.append(el("span", "shop-lvl", here ? "In town" : "Away"));
  tr.append(th);
  if (here) {
    tr.append(el("p", "shop-sells", "Passing through" + (caravan.leaves_in != null && Number.isFinite(+caravan.leaves_in) ? ", leaves in " + num(caravan.leaves_in) + " min" : "") + ". What it carries is worth a look."));
    const cargo = arr(caravan.cargo).filter((g) => g && typeof g === "object");
    if (cargo.length) { const ul = el("ul", "shop-stock good-grid"); cargo.slice(0, 80).forEach((g) => ul.append(shopCard(g, true))); tr.append(ul); }
    else tr.append(el("p", "shop-empty", "The cargo list has not been published yet."));
  } else {
    tr.append(el("p", "shop-empty", "No caravan is in town. When one arrives its cargo is listed here."));
  }
  box.append(tr);
  // orders: public, drawn as text; the signed-in viewer's own are marked
  const ord = el("section", "shop-card shop-orders");
  const oh = el("header", "shop-head");
  oh.append(icon("loot"), el("h3", "shop-name", "Orders waiting to be collected"));
  oh.append(el("span", "shop-lvl", num(orders.length)));
  ord.append(oh);
  if (orders.length) {
    const ul = el("ul", "shop-stock");
    for (const o of orders.slice(0, 60)) {
      const li = el("li", "shop-good");
      const mine = !!(twLogin && String(o.who || "").toLowerCase() === twLogin);
      if (mine) li.classList.add("mine");
      li.append(el("span", "gname", ctrlStrip(o.item).slice(0, 60) || "(an order)"));
      li.append(el("span", "gqty", (mine ? "yours - " : "") + (ctrlStrip(o.who).slice(0, 30) || "someone")));
      li.append(el("span", "grar", (ctrlStrip(o.shop).slice(0, 40) || "a shop") + (o.walker ? " - " + ctrlStrip(o.walker).slice(0, 30) + " walking" : o.status ? " - " + ctrlStrip(o.status).slice(0, 20) : "")));
      ul.append(li);
    }
    ord.append(ul);
  } else ord.append(el("p", "shop-empty", "No orders are waiting."));
  box.append(ord);
}

// ---------------------------------------------------------------- H30 the Satchel tab
// A signed-in viewer's OWN things: what the hero carries (weight against capacity, shown as a
// bar), the vault at the Adventurer Hall, the viewer's outstanding orders, and where the hero is
// walking. Sort by slot / weight / value / VALUE-PER-POUND (the sort that teaches the game: the
// party drops the lowest value-per-pound first, D80). Every action is a button that sends the
// CHAT COMMAND over the IRC socket H6 already opened - no backend, no new scope, no CSP change.
//
// Who is the viewer: ONLY the Twitch login from H6's sign-in (twLogin). A hero is the viewer's
// only if its name equals that login exactly. Signed out the tab shows nothing personal and the
// page never guesses (the H11 "my hero" pin is a browser convenience and is deliberately NOT used).
//
// Contract, read defensively so the tab lights up by itself when the publisher sends it (v5+):
//   hero.satchel[] = {name, qty?, weight? (per unit, lb), sell|value? (per unit), slot|kind?, rarity?, worn?}
//   hero.carry     = {weight?, cap|capacity?, band?}   (or hero.encumbrance = ""/"encumbered"/"heavily encumbered")
//   hero.vault     = [items] | {items: [...], slots?}
//   hero.where | hero.doing   - where the hero is walking / what they are doing (free text)
//   p.orders[]     - the same list H29 shows; the viewer's own are the rows whose `who` is their login
// Missing weight / capacity / band are shown as "not published" - never faked. Capacity falls back
// to 5e's STR x 15 lb ONLY when the hero's STR is published, and says it is derived.
//
// SECURITY: every snapshot string reaches the DOM through el()/textContent. A snapshot value never
// becomes a URL, src, href, class name or style: slot/rarity only choose a known glyph / frame
// class; the bar is a CSSOM number. The ONE place a snapshot string leaves the page is the chat
// command a viewer presses a button for, and it is built by satCommand() from a fixed verb table
// plus ONE argument with every control / line-separator character removed, so an item name can
// never carry a second IRC line or a second command.
const SAT_VERBS = { use: "!use", sell: "!sell", store: "!store", wear: "!wear", take: "!withdraw" };
const SAT_STONE = "!stone";                    // the teleportation stone (1,000 channel points): fixed, takes no argument
const SAT_NAME_MAX = 80;
let lastSatP = null, satSort = "vpp", satDesc = true, satSlot = "all", satText = "", satLastAt = 0, satStoneArm = 0;
function satArg(s) {
  return String(s == null ? "" : s).replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g, " ").replace(/\s+/g, " ").trim().slice(0, SAT_NAME_MAX);
}
// The ONLY way a command string is made. verb must be a key of SAT_VERBS; returns "" otherwise.
function satCommand(verb, name) {
  if (verb === "stone") return SAT_STONE;
  const v = Object.prototype.hasOwnProperty.call(SAT_VERBS, verb) ? SAT_VERBS[verb] : "";
  const a = satArg(name);
  return v && a ? v + " " + a : "";
}
function satSay(text, cls) {
  const s = $("satStatus"); if (!s) return;
  s.className = "chatstatus" + (cls ? " " + cls : "");
  s.textContent = text;                         // page-authored text + the (already stripped) command
}
function satIsMock() { return !!(MOCK && /^satchel/.test(MOCK)); }
function satViewer() {                          // the signed-in login, or "" - never a guess
  if (MOCK === "satchelout") return "";
  if (satIsMock()) return "mockviewer";
  return twToken && twLogin ? twLogin : "";
}
function satSend(verb, name) {
  const cmd = satCommand(verb, name);
  if (!cmd) { satSay("That item has no name the game could be told.", "warn"); return false; }
  if (satIsMock()) { satSay("Mock - would send: " + cmd, ""); return true; }
  if (!(twToken && twLogin)) { satSay("Sign in with Twitch (under Heroes) first.", "warn"); return false; }
  if (!chatWS || chatWS.readyState !== 1) {
    if (!chatOpened) openGuildChat();           // opens the socket H6/H8 already use; nothing new is contacted
    satSay("Connecting to the guild hall - press it again in a moment.", "warn");
    return false;
  }
  const now = Date.now();
  if (now - satLastAt < 1200) { satSay("Easy - one command a breath.", "warn"); return false; }
  satLastAt = now;
  chatWS.send("PRIVMSG #" + TWITCH_CHANNEL + " :" + cmd);
  chatLine(twLogin, cmd, "me", "", twLogin);    // Twitch does not echo your own line back
  satSay("Sent: " + cmd + " - your hero acts on it when they can; the Chronicle will say.", "ok");
  return true;
}
function satN(v) { if (v == null || v === "") return null; const n = +v; return Number.isFinite(n) ? n : null; }
function satLb(n) { return (Math.round(n * 10) / 10).toLocaleString("en"); }
function satBandKey(s) {                        // -> "" | "encumbered" | "heavily encumbered" | null (unknown); constants only
  if (s == null) return null;
  const k = String(s).toLowerCase().replace(/[^a-z ]/g, "").trim();
  if (k === "heavily encumbered" || k === "heavy") return "heavily encumbered";
  if (k === "encumbered") return "encumbered";
  if (k === "" || k === "none" || k === "light" || k === "unencumbered" || k === "normal") return "";
  return null;
}
function satRow(it) {
  if (typeof it === "string") it = { name: it };
  if (!it || typeof it !== "object") return null;
  const name = ctrlStrip(firstStr(it.name, it.item)).slice(0, SAT_NAME_MAX) || "(unnamed)";
  const qty = Math.max(1, Math.floor(satN(it.qty) || 1));
  const weight = satN(it.weight != null ? it.weight : it.wt != null ? it.wt : it.lb);
  const value = satN(it.sell != null ? it.sell : it.value != null ? it.value : it.worth);
  const slot = ctrlStrip(firstStr(it.slot, it.kind, it.type, it.cat)).toLowerCase().slice(0, 16) || "other";
  let vpp = null;
  if (value != null && weight != null) vpp = weight > 0 ? value / weight : (value > 0 ? Infinity : null);
  return { name, qty, weight, value, slot, vpp, rarity: it.rarity, worn: !!(it.worn || it.equipped), raw: it };
}
function satRows(list) { const out = []; for (const it of arr(list)) { const r = satRow(it); if (r) out.push(r); } return out; }
// capacity + band + carried, with an honest note about where each number came from
function satCarry(h, rows) {
  const c = h && typeof h.carry === "object" && h.carry ? h.carry : {};
  const str = satN(h && h.stats && h.stats.str);
  let weight = satN(c.weight != null ? c.weight : c.carried != null ? c.carried : h && h.carried), wnote = "";
  if (weight == null) {
    const known = rows.filter((r) => r.weight != null);
    if (known.length) { weight = known.reduce((a, r) => a + r.weight * r.qty, 0); wnote = known.length < rows.length ? "from the items that publish a weight" : "summed from the items below"; }
  }
  let cap = satN(c.cap != null ? c.cap : c.capacity != null ? c.capacity : h && h.capacity), cnote = "";
  if (cap == null && str != null) { cap = str * 15; cnote = "STR " + num(str) + " x 15 lb (5e), worked out here"; }
  let band = satBandKey(c.band != null ? c.band : h && h.encumbrance), bnote = "";
  if (band == null && weight != null && str != null) {
    band = weight > str * 10 ? "heavily encumbered" : weight > str * 5 ? "encumbered" : "";
    bnote = "worked out from STR";
  }
  return { weight, cap, band, wnote, cnote, bnote, str };
}
function satCmp(a, b) {
  const key = (r) => satSort === "slot" ? r.slot : satSort === "weight" ? (r.weight == null ? null : r.weight * r.qty)
    : satSort === "value" ? (r.value == null ? null : r.value * r.qty) : satSort === "name" ? r.name.toLowerCase() : r.vpp;
  const x = key(a), y = key(b);
  if (x == null && y == null) return a.name.localeCompare(b.name);
  if (x == null) return 1;                       // unknowns last, whichever way it sorts
  if (y == null) return -1;
  if (x === y) return a.name.localeCompare(b.name);
  const d = x < y ? -1 : 1;
  return satDesc ? -d : d;
}
function satBtn(label, verb, name, title) {
  const b = el("button", "sat-btn", label); b.type = "button";
  b.title = title;
  b.addEventListener("click", () => satSend(verb, name));
  return b;
}
function satItemRow(r, where, dropFirst) {
  const li = el("li", "sat-item");
  const rc = rarityClass(r.rarity); if (rc) li.classList.add(rc);
  if (r.worn) li.classList.add("worn");
  li.append(icon(satchelIconId(r.slot)));
  const nm = el("span", "sat-name", r.name);
  if (r.qty > 1) nm.append(el("small", "sat-qty", " x" + num(r.qty)));
  if (r.worn) nm.append(el("small", "sat-tag", " worn"));
  if (dropFirst) nm.append(el("small", "sat-tag drop", " drop first"));
  li.append(nm, el("span", "sat-slot", r.slot));
  li.append(el("span", "sat-num", r.weight == null ? "- lb" : satLb(r.weight * r.qty) + " lb"));
  const v = el("span", "sat-num"); v.append(icon("coin"), document.createTextNode(" " + (r.value == null ? "-" : num(r.value * r.qty)))); li.append(v);
  li.append(el("span", "sat-num sat-vpp", r.vpp == null ? "- /lb" : r.vpp === Infinity ? "free" : (Math.round(r.vpp * 10) / 10).toLocaleString("en") + " /lb"));
  const act = el("span", "sat-acts");
  if (where === "vault") act.append(satBtn("Take out", "take", r.name, "Sends: " + satCommand("take", r.name)));
  else {
    act.append(satBtn("Use", "use", r.name, "Sends: " + satCommand("use", r.name)));
    if (!r.worn) act.append(satBtn("Wear", "wear", r.name, "Sends: " + satCommand("wear", r.name)));
    act.append(satBtn("Store", "store", r.name, "Sends: " + satCommand("store", r.name)));
    act.append(satBtn("Sell", "sell", r.name, "Sends: " + satCommand("sell", r.name)));
  }
  li.append(act);
  return li;
}
function satCard(title, glyph, count) {
  const card = el("section", "shop-card sat-card");
  const hd = el("header", "shop-head");
  hd.append(icon(glyph), el("h3", "shop-name", title));
  if (count != null) hd.append(el("span", "shop-lvl", count));
  card.append(hd);
  return card;
}
function satNote(box, text) { box.append(el("p", "shop-empty", text)); }
function renderSatchel(p) {
  const box = $("satBody"), ctl = $("satControls");
  if (!box) return;
  lastSatP = p;
  box.textContent = "";
  const viewer = satViewer();
  if (ctl) ctl.classList.add("hide");
  if (!viewer) {
    const c = satCard("Sign in to see your satchel", "loot", null);
    satNote(c, "This tab is only ever about YOUR hero, so it shows nothing until you sign in with Twitch. Nothing here is guessed from a name you typed.");
    c.append(el("p", "shop-sells", "Once signed in you will see what you carry, how heavy it is against what you can bear, your vault at the Adventurer Hall, and your orders - and every button sends the chat command you could have typed yourself."));
    const go = el("button", "sat-btn", "Sign in (under Heroes)"); go.type = "button";
    go.addEventListener("click", () => setActiveTab("heroes"));
    c.append(go);
    box.append(c);
    return;
  }
  const hero = arr(p && p.heroes).find((h) => h && String(h.name || "").toLowerCase() === viewer);
  if (!hero) {
    const c = satCard("No hero under your name yet", "loot", null);
    satNote(c, "You are signed in as " + viewer + ", but no living hero carries that name. Type !enlist in chat to raise one; if your hero has fallen, what they carried is gone, but the vault is not.");
    box.append(c);
    return;
  }
  if (ctl) ctl.classList.remove("hide");
  const rows = satRows(hero.satchel != null ? hero.satchel : hero.inventory != null ? hero.inventory : hero.items);
  const cy = satCarry(hero, rows);
  // ---- who, where, and the weight bar
  const top = satCard(ctrlStrip(hero.name).slice(0, 40) + "'s satchel", "loot", num(rows.length) + (rows.length === 1 ? " item" : " items"));
  const where = firstStr(hero.where, hero.walking_to, hero.doing);
  if (where) top.append(el("p", "shop-sells", "Right now: " + ctrlStrip(where).slice(0, 120)));
  if (cy.weight != null && cy.cap != null && cy.cap > 0) {
    const ratio = Math.max(0.02, Math.min(1, cy.weight / cy.cap));
    const grade = cy.band === "heavily encumbered" ? "low" : cy.band === "encumbered" ? "mid" : cy.band === "" ? "ok" : "flat";
    const bar = el("div", "hpbar sat-bar " + grade);
    bar.setAttribute("role", "img");
    bar.setAttribute("aria-label", "Carrying " + satLb(cy.weight) + " of " + satLb(cy.cap) + " pounds");
    const track = el("div", "hptrack");
    const fill = el("span", "hpfill"); fill.style.setProperty("--hp", ratio);      // CSSOM number only
    track.append(fill);
    for (const t of [1 / 3, 2 / 3]) { const tk = el("i", "sat-tick"); tk.style.setProperty("--at", t); track.append(tk); }
    bar.append(el("span", "hpk", "Carry"), track, el("span", "hpv", satLb(cy.weight) + " of " + satLb(cy.cap) + " lb"));
    top.append(bar);
    const bandName = cy.band === "heavily encumbered" ? "Heavily encumbered" : cy.band === "encumbered" ? "Encumbered" : cy.band === "" ? "Unencumbered" : "Band not published";
    const bp = el("p", "sat-band " + (cy.band === "heavily encumbered" ? "b2" : cy.band === "encumbered" ? "b1" : "b0"));
    bp.append(el("b", null, bandName));
    bp.append(document.createTextNode(cy.band === "heavily encumbered" ? " - speed -20 ft, disadvantage on attacks and on STR, DEX and CON checks and saves."
      : cy.band === "encumbered" ? " - speed -10 ft." : cy.band === "" ? " - no penalty." : "."));
    top.append(bp);
    const notes = [cy.wnote && "weight " + cy.wnote, cy.cnote && "capacity " + cy.cnote, cy.bnote && "band " + cy.bnote].filter(Boolean);
    if (notes.length) top.append(el("p", "sat-src", notes.join("; ") + "."));
    top.append(el("p", "sat-src", "Encumbered past a third of capacity, heavily past two thirds (the ticks on the bar). Stored items weigh nothing."));
  } else {
    satNote(top, "Carry weight is not published yet - the bar appears when the game reports weight and capacity (or your STR, from which capacity is worked out).");
  }
  box.append(top);
  // ---- the list, filtered and sorted
  const slots = []; for (const r of rows) if (slots.indexOf(r.slot) < 0) slots.push(r.slot);
  slots.sort();
  if (satSlot !== "all" && slots.indexOf(satSlot) < 0) satSlot = "all";
  const chips = $("satChips");
  if (chips) {
    chips.textContent = "";
    for (const s of ["all"].concat(slots)) {
      const b = el("button", "chip" + (satSlot === s ? " on" : ""), s === "all" ? "All" : s); b.type = "button";
      b.setAttribute("aria-pressed", satSlot === s ? "true" : "false");
      b.addEventListener("click", () => { satSlot = s; if (lastSatP) renderSatchel(lastSatP); });
      chips.append(b);
    }
  }
  const q = satText.toLowerCase();
  const shown = rows.filter((r) => (satSlot === "all" || r.slot === satSlot) && (!q || r.name.toLowerCase().indexOf(q) >= 0)).sort(satCmp);
  // the "drop first" hint: the lowest value-per-pound carried item, only when the hero is over a band
  let dropRow = null;
  if (cy.band) for (const r of rows) if (!r.worn && r.vpp != null && r.vpp !== Infinity && r.weight > 0 && (!dropRow || r.vpp < dropRow.vpp)) dropRow = r;
  const list = satCard("Carried", "loot", null);
  list.classList.add("sat-list-card");
  if (!rows.length) satNote(list, "Your satchel is empty. Buy something at a shop (it is an order - your hero walks to collect it) or bring something up from the delve.");
  else if (!shown.length) satNote(list, "Nothing matches that filter.");
  else {
    const ul = el("ul", "sat-list");
    shown.slice(0, 120).forEach((r) => ul.append(satItemRow(r, "satchel", r === dropRow)));
    list.append(ul);
    if (dropRow && shown.indexOf(dropRow) >= 0) list.append(el("p", "sat-src", "When a band is over capacity at the stairs, it drops the lowest value-per-pound first - that is the row marked \"drop first\"."));
  }
  box.append(list);
  // ---- the vault
  const vraw = hero.vault;
  const vrows = satRows(Array.isArray(vraw) ? vraw : vraw && typeof vraw === "object" ? vraw.items : null);
  const vslots = vraw && typeof vraw === "object" && !Array.isArray(vraw) ? satN(vraw.slots != null ? vraw.slots : vraw.cap) : null;
  const vc = satCard("Your vault at the Adventurer Hall", "tower", vraw == null ? null : num(vrows.length) + (vslots != null ? " of " + num(vslots) : ""));
  if (vraw == null) satNote(vc, "The vault is not published yet.");
  else if (!vrows.length) satNote(vc, "Your vault is empty. Store something and your hero walks it to the Hall; stored items weigh nothing and survive a death.");
  else { const ul = el("ul", "sat-list"); vrows.slice(0, 120).sort(satCmp).forEach((r) => ul.append(satItemRow(r, "vault", false))); vc.append(ul); }
  box.append(vc);
  // ---- orders
  const mine = arr(p && p.orders).filter((o) => o && typeof o === "object" && String(o.who || "").toLowerCase() === viewer);
  const oc = satCard("Your outstanding orders", "stall", num(mine.length));
  if (!mine.length) satNote(oc, "No orders are waiting for you.");
  else {
    const ul = el("ul", "shop-stock");
    for (const o of mine.slice(0, 40)) {
      const li = el("li", "shop-good mine");
      li.append(el("span", "gname", ctrlStrip(o.item).slice(0, 60) || "(an order)"));
      li.append(el("span", "grar", (ctrlStrip(o.shop).slice(0, 40) || "a shop") + (o.walker ? " - " + ctrlStrip(o.walker).slice(0, 30) + " walking" : o.status ? " - " + ctrlStrip(o.status).slice(0, 20) : "")));
      ul.append(li);
    }
    oc.append(ul);
  }
  box.append(oc);
  // ---- the stone: a panic button, one deliberate double-press, never an argument
  const sc = satCard("The teleportation stone", "flask", "1,000 points");
  sc.append(el("p", "shop-sells", "Cashed in with channel points; this sends " + SAT_STONE + " to chat. Press twice to be sure - the second press must come within four seconds."));
  const stone = el("button", "sat-btn stone", "Use the stone"); stone.type = "button";
  stone.addEventListener("click", () => {
    const now = Date.now();
    if (now - satStoneArm < 4000) { satStoneArm = 0; stone.textContent = "Use the stone"; satSend("stone", ""); }
    else { satStoneArm = now; stone.textContent = "Really? Press again"; setTimeout(() => { if (satStoneArm === now) { satStoneArm = 0; stone.textContent = "Use the stone"; } }, 4000); }
  });
  sc.append(stone);
  box.append(sc);
}

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

// ============================================================ SEASON (H31)
// The Season tab: standings over the whole season, from the snapshot only - who went deepest, who
// earned most, who died hardest, who kept a hero alive longest. Heroes + fallen are the data; nothing
// is stored or invented. Fields are read DEFENSIVELY and the tab says plainly which board has no data:
//   earned   : hero.earned | gold_earned | total_gold | lifetime_gold   (else current gold, labelled "held")
//   lifespan : hero.days_alive | age_days | lived_days | age            (else day - born_day for the fallen,
//              town.day - born_day for the living)
//   hardest  : fallen only - deepest floor reached, then level, then kills; killed_by / day shown
// Every name/killer/epitaph goes through el()/textContent; the bar width is a CSSOM number.
const SEASON_TOP = 10;
function seaPick(r, keys) { for (const k of keys) { const v = r && r[k]; if (v != null && v !== "" && Number.isFinite(+v)) return +v; } return null; }
function seaName(r) { const n = r && r.name != null ? ctrlStrip(r.name).slice(0, 40) : ""; return n || "(no name)"; }
function seaBoards(heroes, fallen, townDay) {
  const live = heroes.filter((h) => h && typeof h === "object").map((r) => ({ r, dead: false }));
  const gone = fallen.filter((f) => f && typeof f === "object").map((r) => ({ r, dead: true }));
  const all = live.concat(gone);
  const rank = (rows, tie) => {
    rows.sort((a, b) => b.v - a.v || tie(b) - tie(a) || seaName(a.r).localeCompare(seaName(b.r), "en", { sensitivity: "base" }));
    let place = 0, prev = null;
    rows.forEach((e, i) => { if (e.v !== prev) { place = i + 1; prev = e.v; } e.place = place; });
    return rows;
  };
  const deep = rank(all.map((e) => Object.assign({}, e, { v: n0(e.r.deepest) })).filter((e) => e.v > 0), (e) => n0(e.r.level));
  let earnedReal = false;
  const rich = rank(all.map((e) => {
    const x = seaPick(e.r, ["earned", "gold_earned", "total_gold", "lifetime_gold"]);
    if (x != null) earnedReal = true;
    return Object.assign({}, e, { v: x != null ? x : n0(e.r.gold), held: x == null });
  }).filter((e) => e.v > 0), (e) => n0(e.r.level));
  const hard = rank(gone.map((e) => Object.assign({}, e, { v: n0(e.r.deepest) })).filter((e) => e.v > 0), (e) => n0(e.r.level) * 1000 + n0(e.r.kills));
  let lifeData = false;
  const lived = rank(all.map((e) => {
    let d = seaPick(e.r, ["days_alive", "age_days", "lived_days", "age"]);
    if (d == null) {
      const born = seaPick(e.r, ["born_day", "joined_day", "enlisted_day"]);
      const end = e.dead ? seaPick(e.r, ["day"]) : (Number.isFinite(+townDay) ? +townDay : null);
      if (born != null && end != null) d = Math.max(0, end - born);
    }
    if (d != null) lifeData = true;
    return Object.assign({}, e, { v: d == null ? 0 : d });
  }).filter((e) => e.v > 0), (e) => n0(e.r.level));
  return { deep, rich, hard, lived, earnedReal, lifeData, total: all.length };
}
function seaRow(e, max, unit, sub) {
  const li = el("li", "sea-row" + (e.dead ? " gone" : "") + (e.place === 1 ? " lead" : ""));
  li.style.setProperty("--fill", max > 0 ? Math.max(0, Math.min(1, e.v / max)) : 0);
  li.append(el("span", "sea-rank", "#" + e.place));
  const mid = el("span", "sea-mid");
  const nm = el("span", "sea-name");
  if (e.place <= 5) nm.append(coat(seaName(e.r), "sm"));
  nm.append(document.createTextNode(seaName(e.r)));
  if (e.dead) nm.append(el("span", "tag", "fallen"));
  mid.append(nm);
  if (sub) mid.append(el("span", "sea-sub", sub));
  li.append(mid);
  const val = el("span", "sea-val");
  val.append(el("b", null, num(e.v)), el("span", "bunit", unit));
  li.append(val);
  return li;
}
function seaCard(title, ic, rows, unit, subFn, emptyMsg, note) {
  const card = el("article", "shop-card sea-card");
  const head = el("header", "shop-head");
  head.append(icon(ic), el("h3", "shop-name", title));
  if (rows.length) head.append(el("span", "shop-lvl", rows.length > SEASON_TOP ? "top " + SEASON_TOP + " of " + num(rows.length) : num(rows.length) + " ranked"));
  card.append(head);
  if (note) card.append(el("p", "shop-empty", note));
  if (!rows.length) { card.append(el("p", "shop-empty", emptyMsg)); return card; }
  const ol = el("ol", "sea-list");
  const max = rows[0].v;
  rows.slice(0, SEASON_TOP).forEach((e) => ol.append(seaRow(e, max, unit, subFn(e))));
  card.append(ol);
  return card;
}
function renderSeason(p) {
  const box = $("seasonBody");
  if (!box) return;
  box.textContent = "";
  const heroes = arr(p && p.heroes), fallen = arr(p && p.fallen);
  const day = p && p.town ? seaPick(p.town, ["day"]) : null;
  const b = seaBoards(heroes, fallen, day);
  const sub = (e) => {
    const r = e.r, bits = [];
    if (r.class) bits.push(cap(ctrlStrip(r.class).slice(0, 16)));
    if (r.level != null && Number.isFinite(+r.level)) bits.push("level " + num(r.level));
    return bits.join(", ");
  };
  if (!b.total) {
    box.append(el("p", "shop-empty", "No heroes have been published this season yet. Type !enlist in chat to raise one; the standings fill in as the town reports."));
    return;
  }
  const grid = el("div", "shop-grid sea-grid");
  grid.append(seaCard("Went deepest", "delve", b.deep, "floor", (e) => sub(e), "Nobody has been below the first floor yet."));
  grid.append(seaCard("Earned most", "coin", b.rich, "gold",
    (e) => (e.held ? "held now" : "earned") + (sub(e) ? "  ·  " + sub(e) : ""),
    "Nobody has gold to their name yet.",
    b.earnedReal ? "" : "The town publishes only gold in hand for now, so this ranks what heroes hold, not what they earned."));
  grid.append(seaCard("Died hardest", "death", b.hard, "floor", (e) => {
    const bits = [];
    if (e.r.killed_by != null && String(e.r.killed_by).trim()) bits.push("to " + ctrlStrip(e.r.killed_by).slice(0, 40));
    if (e.r.day != null && Number.isFinite(+e.r.day)) bits.push("day " + num(e.r.day));
    const s = sub(e); if (s) bits.push(s);
    return bits.join("  ·  ");
  }, "Nobody has fallen yet - or the fallen have not reported a floor.", "Ranked by the deepest floor reached before the end."));
  grid.append(seaCard("Lived longest", "town", b.lived, "days", (e) => (e.dead ? "fell" : "still living") + (sub(e) ? "  ·  " + sub(e) : ""),
    "The town has not published how long a hero has lived yet.",
    b.lifeData ? "" : "No hero carries an age or a birth day in the town's records yet; this fills in by itself when they do."));
  box.append(grid);
}

(function () {   // H30 controls: the select / direction / filter live outside the re-rendered body so typing keeps focus
  const sel = $("satSort"), dir = $("satDir"), find = $("satFind");
  const again = () => { if (lastSatP) renderSatchel(lastSatP); };
  if (sel) sel.addEventListener("change", () => { satSort = ["vpp", "value", "weight", "slot", "name"].indexOf(sel.value) >= 0 ? sel.value : "vpp"; again(); });
  if (dir) dir.addEventListener("click", () => { satDesc = !satDesc; dir.textContent = satDesc ? "Highest first" : "Lowest first"; again(); });
  if (find) find.addEventListener("input", () => { satText = find.value.slice(0, 40); again(); });
})();
// ---------------------------------------------------------------- H13 tabs
// Every nav// No-scroll, tabbed layout: one section at a time. The viewer picks with a nav
// button and the chosen panel's `.active` class makes it visible (see style.css).
//
// Storage is per-browser and best-effort: the last-picked tab id is kept in
// localStorage under TAB_KEY. Every READ goes through ctrlStrip + a 25-char cap
// and must match TABS (a page-authored whitelist) before it decides anything.
// The stored value is NEVER used as a URL, href, src, selector, query parameter
// or style - only to look up a known id in TABS. In a private window (storage
// throws) the page silently falls back to the default tab. (docs/HUB_SECURITY.md, H13.)
// ============================================================ H32: THE RAIL AND THE LIVE STAGE
// Mr. E, 16 Nov: "make the hub feel like you are navigating on twitch". The page borrows Twitch's
// NAVIGATION GRAMMAR: a persistent left rail of LIVE THINGS (a hero mid-delve is a live channel: a
// sigil for the avatar, a name, one line of what they are doing, a LIVE dot, and a number where
// Twitch puts the viewer count). Picking one puts it on the STAGE with an info row beneath it.
// Layout only: the rail is built from the snapshot the page already holds (p.heroes, p.parties),
// no new fetch, no new data, no CSP change. SECURITY: every name and line below reaches the DOM
// through el()/textContent; sigil() only HASHES a name to choose a known drawing; no snapshot
// value is ever a URL, src, href, selector or style (the HP fills are CSSOM numbers). The selection
// is held in a JS variable and compared against names - never put in a selector.
// The number on a LIVE hero is FLOOR DEPTH (it moves, and it is what the delve is about); a band's
// is its head-count; an idle hero shows level, dimmed. The fallen are not on the rail (they have
// their own tab): a hero who is not breathing is not "live".
const RAIL_KEY = "bellmire.rail.v1";            // "min" | "full" - whitelist-checked on read
const RAIL_IDLE_CAP = 60;
let railItems = [];                              // the built model, newest snapshot
let railSel = null;                              // {k: "hero"|"band", n: lower-cased name} or null (auto)
let railAutoPick = null;
function railGetMode() { try { return localStorage.getItem(RAIL_KEY) === "min" ? "min" : "full"; } catch (e) { return "full"; } }
function railSetMode(m, keep) {
  const app = $("app"); if (!app) return;
  app.setAttribute("data-rail", m === "min" ? "min" : "full");
  const b = $("railToggle");
  if (b) {
    b.setAttribute("aria-expanded", m === "min" ? "false" : "true");
    b.setAttribute("aria-label", m === "min" ? "Expand the rail" : "Collapse the rail to sigils only");
    b.title = m === "min" ? "Expand the rail" : "Collapse the rail";
  }
  if (keep !== false) { try { localStorage.setItem(RAIL_KEY, m === "min" ? "min" : "full"); } catch (e) {} }
}
function railBuild(p) {
  const parties = normalizeParties(p && p.parties != null ? p.parties : (p && p.bands));
  const heroes = arr(p && p.heroes).filter((h) => h && typeof h === "object");
  const inBand = new Map();
  parties.forEach((b, bi) => b.members.forEach((m) => {
    if (m.name && m.status !== "fallen") inBand.set(m.name.toLowerCase(), { bi, floor: b.floor, band: b.name });
  }));
  const bands = parties.map((b) => {
    const alive = b.members.filter((m) => m.status !== "fallen").length;
    return { kind: "band", live: true, name: b.name || "A band", key: (b.name || "a band").toLowerCase(),
      what: (b.floor != null ? "Floor " + num(b.floor) + " · " : "") + alive + (alive === 1 ? " delver" : " delvers"),
      num: alive, numLab: alive === 1 ? "delver" : "delvers", floor: b.floor, party: b };
  }).sort((a, b) => n0(b.floor) - n0(a.floor));
  const hs = heroes.map((h) => {
    const key = nameOf(h).toLowerCase();
    const bd = inBand.get(key);
    const own = firstStr(h.status, h.state, h.activity, h.where).toLowerCase().trim();
    const live = !!bd || own === "delving" || own === "active" || PARTY_STATUS[own] === "burning";
    const max = pickNum(h.max_hp, h.hp_max, h.maxhp, h.hpmax), hp = pickNum(h.hp);
    const lv = pickNum(h.level);
    const floor = bd && bd.floor != null ? bd.floor : null;
    const cls = (cap(h.species) + " " + cap(h.class)).trim();
    let what, numTxt, numLab;
    if (live) {
      what = floor != null ? "Floor " + num(floor) + (bd.band ? " · " + bd.band : "") : "Delving now";
      numTxt = floor != null ? num(floor) : "—"; numLab = "floor";
    } else {
      what = (cls || "Adventurer") + (lv != null && lv > 0 ? ", level " + num(lv) : "");
      numTxt = lv != null && lv > 0 ? "Lv " + num(lv) : ""; numLab = "level";
    }
    return { kind: "hero", live, name: nameOf(h) || "(no name)", key, what, num: numTxt, numLab,
      floor, hp, max, lv: lv || 0, h, band: bd ? bd.band : "" };
  });
  const liveH = hs.filter((x) => x.live).sort((a, b) => (b.floor != null ? b.floor : -1) - (a.floor != null ? a.floor : -1));
  const idleH = hs.filter((x) => !x.live).sort((a, b) => b.lv - a.lv);
  return { bands, liveH, idleH };
}
function railSame(it, sel) { return !!sel && it.kind === sel.k && it.key === sel.n; }
function railCurrent() {
  if (railSel) { const f = railItems.find((it) => railSame(it, railSel)); if (f) return f; }
  const live = railItems.find((it) => it.kind === "band") || railItems.find((it) => it.kind === "hero" && it.live);
  return live || null;
}
function railItemEl(it, idx, selected) {
  const d = el("div", "rail-item" + (it.live ? " live" : " idle") + (it.kind === "band" ? " isband" : ""));
  d.setAttribute("role", "option");
  d.setAttribute("aria-selected", selected ? "true" : "false");
  d.tabIndex = selected ? 0 : -1;
  d.dataset.ri = String(idx);                      // an integer the page owns
  d.title = it.name;
  const av = el("span", "rail-av");
  av.append(sigil(it.name, "sm"));
  const txt = el("span", "rail-txt");
  txt.append(el("span", "rail-name", it.name));
  txt.append(el("span", "rail-what", it.what));
  if (it.kind === "hero" && it.live && it.hp != null && it.max != null && it.max > 0) {
    const tr = el("span", "rail-hp"); tr.setAttribute("aria-hidden", "true");
    const f = el("span", "rail-hpf");
    f.style.setProperty("--hp", Math.max(0.03, Math.min(1, it.hp / it.max)));   // CSSOM number only
    tr.append(f); txt.append(tr);
  }
  const right = el("span", "rail-num");
  if (it.live) { const dot = el("span", "live-dot"); dot.setAttribute("aria-hidden", "true"); right.append(dot); }
  if (it.num !== "" && it.num != null) {
    const n = el("span", "rail-n", it.num);
    right.append(n);
    if (it.numLab) right.append(el("span", "rail-nl", it.numLab));
  }
  if (it.live) right.append(el("span", "rail-live-sr", "live"));
  d.append(av, txt, right);
  return d;
}
function renderRail(p) {
  const box = $("railList");
  if (!box) return;
  const hadFocus = box.contains(document.activeElement);
  const focusKey = hadFocus && document.activeElement.dataset ? document.activeElement.dataset.ri : null;
  const prevFocus = focusKey != null && railItems[+focusKey] ? railItems[+focusKey] : null;
  const m = railBuild(p || {});
  const idleShown = m.idleH.slice(0, RAIL_IDLE_CAP);
  railItems = [].concat(m.bands, m.liveH, idleShown);
  const cur = railCurrent();
  railAutoPick = cur;
  box.replaceChildren();
  const group = (label, list, startIdx) => {
    if (!list.length) return;
    const g = el("div", "rail-group");
    g.setAttribute("role", "group");
    g.setAttribute("aria-label", label);
    g.append(el("span", "rail-h", label));
    list.forEach((it, i) => g.append(railItemEl(it, startIdx + i, cur === it)));
    box.append(g);
  };
  group("Bands in the scar", m.bands, 0);
  group("Heroes delving now", m.liveH, m.bands.length);
  group("Heroes in town", idleShown, m.bands.length + m.liveH.length);
  if (m.idleH.length > idleShown.length) {
    const more = el("button", "rail-more", "+" + (m.idleH.length - idleShown.length) + " more in Heroes");
    more.type = "button";
    more.addEventListener("click", () => setActiveTab("heroes"));
    box.append(more);
  }
  if (!railItems.length) box.append(el("p", "rail-empty", "Nobody is on the roll yet. When a hero enlists - or a band goes down into the scar - they appear here, live."));
  // exactly one item is in the tab order
  if (!box.querySelector('[tabindex="0"]')) { const f = box.querySelector(".rail-item"); if (f) f.tabIndex = 0; }
  const nl = $("nLive");
  const liveN = m.liveH.length + m.bands.length;
  if (nl) nl.textContent = liveN ? liveN : "";
  const cnt = $("railCount"); if (cnt) cnt.textContent = liveN ? liveN + " live" : "";
  if (prevFocus) {
    const again = railItems.findIndex((it) => it.kind === prevFocus.kind && it.key === prevFocus.key);
    if (again >= 0) { const e = box.querySelector('[data-ri="' + again + '"]'); if (e) { e.tabIndex = 0; try { e.focus({ preventScroll: true }); } catch (x) {} } }
  }
  try { renderStage(); } catch (e) { /* the stage must never break the rest of the page */ }
}
function railPick(idx) {
  const it = railItems[idx]; if (!it) return;
  railSel = { k: it.kind, n: it.key };
  const box = $("railList");
  if (box) for (const e of box.querySelectorAll(".rail-item")) {
    const on = e.dataset.ri === String(idx);
    e.setAttribute("aria-selected", on ? "true" : "false");
  }
  setActiveTab("watch");
  try { renderStage(); } catch (e) {}
  const st = $("stageScroll"); if (st) st.scrollTop = 0;
}
// ---- the stage: what the rail selected, with an info row beneath it the way Twitch puts the
// title, the streamer and the tags under the player. Reuses the sheet and band card the page
// already has; adds only layout and the "Follow" toggle (the existing pinned-hero setting).
function stageTag(text, cls) { return el("span", "sw-tag" + (cls ? " " + cls : ""), text); }
function stageInfo(it) {
  const info = el("div", "sw-info");
  const av = el("span", "sw-av"); av.append(sigil(it.name, "md"));
  const mid = el("div", "sw-infomid");
  const title = it.kind === "band"
    ? (it.floor != null ? "Delving on floor " + num(it.floor) : "Delving in the scar")
    : (it.live ? (it.floor != null ? "On floor " + num(it.floor) + (it.band ? " with " + it.band : "") : "Delving now") : "In town, between delves");
  mid.append(el("div", "sw-title", title));
  const who = el("div", "sw-who");
  who.append(el("span", "sw-whoname", it.name));
  if (it.kind === "hero" && it.h.title) who.append(el("span", "sw-whotitle", String(it.h.title)));
  mid.append(who);
  const tags = el("div", "sw-tags");
  if (it.kind === "band") {
    tags.append(stageTag(it.num + (it.num === 1 ? " delver" : " delvers")));
    if (it.floor != null) tags.append(stageTag("Floor " + num(it.floor)));
    const fl = it.party.members.filter((x) => x.status === "fallen").length;
    if (fl) tags.append(stageTag(fl + " fallen", "bad"));
  } else {
    const h = it.h;
    if (h.class) tags.append(stageTag(cap(h.class)));
    if (h.species) tags.append(stageTag(cap(h.species)));
    if (it.lv) tags.append(stageTag("Level " + num(it.lv)));
    if (h.rank) tags.append(stageTag(String(h.rank)));
    if (it.band) tags.append(stageTag(it.band, "inband"));
  }
  mid.append(tags);
  info.append(av, mid);
  if (it.kind === "hero") {
    const mine = isMyHero(it.h);
    const f = el("button", "sw-follow" + (mine ? " on" : ""), mine ? "Following" : "Follow");
    f.type = "button";
    f.setAttribute("aria-pressed", mine ? "true" : "false");
    f.title = mine ? "This is your pinned hero. Click to unpin." : "Pin this hero as yours - it floats to the top of Heroes.";
    f.addEventListener("click", () => { setMyHero(mine ? "" : nameOf(it.h)); renderStage(); });
    info.append(f);
  }
  return info;
}
function stagePlayer(it) {
  const pl = el("div", "sw-player" + (it.live ? " live" : ""));
  const art = el("div", "sw-art");
  art.append(it.kind === "hero" ? coat(it.name, "lg") : sigil(it.name, "md"));
  const mid = el("div", "sw-pmid");
  const badge = el("span", "sw-badge" + (it.live ? " live" : ""));
  if (it.live) badge.append(el("span", "live-dot"));
  badge.append(document.createTextNode(it.live ? "LIVE" : "IN TOWN"));
  mid.append(badge);
  if (it.live) {
    const f = it.floor;
    const big = el("div", "sw-depth");
    big.append(el("span", "sw-depth-k", it.kind === "band" ? "Delving on floor" : "On floor"), el("span", "sw-depth-n", f != null ? num(f) : "—"));
    mid.append(big);
  } else {
    mid.append(el("div", "sw-depth-k", "Not in the scar right now"));
    const deep = it.kind === "hero" ? pickNum(it.h.deepest) : null;
    if (deep != null && deep > 0) mid.append(el("div", "sw-depth-k", "Deepest so far: floor " + num(deep)));
  }
  if (it.kind === "hero" && it.hp != null) {
    const bar = hpBar(it.h); bar.classList.add("sw-hp"); mid.append(bar);
  }
  pl.append(art, mid);
  return pl;
}
function renderStage() {
  const box = $("watchBody");
  if (!box) return;
  box.replaceChildren();
  const it = railCurrent();
  if (!it) {
    const e = el("div", "sw-empty");
    e.append(el("h2", "sw-empty-h", "Nobody is delving right now"));
    e.append(el("p", null, "When a hero goes down into the scar, or a band does, they appear on the rail on the left and the stage fills with them. Until then, the Chronicle, the Boards and the rest are along the tabs above."));
    box.append(e);
    return;
  }
  box.append(stagePlayer(it), stageInfo(it));
  const sheet = el("div", "panel sw-sheet");
  if (it.kind === "hero") {
    sheet.append(heroSheet(it.h));
  } else {
    const btns = el("div", "sw-members");
    btns.append(el("p", "eyebrow", "Pick a delver to watch"));
    const row = el("div", "sw-memberrow");
    const heroByName = new Map(); railItems.forEach((x, i) => { if (x.kind === "hero") heroByName.set(x.key, i); });
    for (const m of it.party.members) {
      const idx = heroByName.get(String(m.name || "").toLowerCase());
      const b = el("button", "chip", m.name || "(no name)");
      b.type = "button";
      if (idx == null) { b.disabled = true; b.title = "No sheet published for this delver"; }
      else b.addEventListener("click", () => railPick(idx));
      row.append(b);
    }
    btns.append(row);
    sheet.append(btns, partyCard(it.party));
  }
  box.append(sheet);
}
(function wireRail() {
  const box = $("railList"), tog = $("railToggle");
  if (tog) tog.addEventListener("click", () => railSetMode((($("app") && $("app").getAttribute("data-rail")) === "min") ? "full" : "min"));
  railSetMode(railGetMode(), false);
  if (!box) return;
  box.addEventListener("click", (e) => {
    const t = e.target && e.target.closest ? e.target.closest(".rail-item") : null;
    if (!t || !box.contains(t)) return;
    railPick(+t.dataset.ri);
  });
  box.addEventListener("keydown", (e) => {
    const t = e.target && e.target.closest ? e.target.closest(".rail-item") : null;
    if (!t) return;
    const all = Array.from(box.querySelectorAll(".rail-item"));
    const i = all.indexOf(t);
    let j = -1;
    if (e.key === "Enter" || e.key === " ") { e.preventDefault(); railPick(+t.dataset.ri); return; }
    if (e.key === "ArrowDown" || e.key === "ArrowRight") j = Math.min(all.length - 1, i + 1);
    else if (e.key === "ArrowUp" || e.key === "ArrowLeft") j = Math.max(0, i - 1);
    else if (e.key === "Home") j = 0;
    else if (e.key === "End") j = all.length - 1;
    if (j < 0) return;
    e.preventDefault();
    all.forEach((x) => { x.tabIndex = -1; });
    all[j].tabIndex = 0; all[j].focus();
  });
})();

// ---- H32 pass 3: the guild chat column. The chat that used to be tab fourteen now sits beside the
// stage, always present (the H8 native chat, unchanged and still OPT-IN: nothing contacts Twitch until
// the viewer presses "Open the guild chat"). Collapsible to a thin strip on a wide screen; on a narrow
// one the column is hidden and a top-bar button opens it full-screen. Layout only: no snapshot value
// is involved; the only stored state is one whitelisted localStorage value (bellmire.chatcol.v1).
const CHATCOL_KEY = "bellmire.chatcol.v1";
const NARROW = window.matchMedia ? window.matchMedia("(max-width: 900px)") : { matches: false };
function chatColGetMode() { try { return localStorage.getItem(CHATCOL_KEY) === "min" ? "min" : "full"; } catch (e) { return "full"; } }
function chatColSet(mode, keep) {
  const app = $("app"); if (!app) return;
  app.setAttribute("data-chat", mode === "min" ? "min" : "full");
  const b = $("chatToggle");
  if (b) {
    b.setAttribute("aria-expanded", mode === "min" ? "false" : "true");
    b.setAttribute("aria-label", mode === "min" ? "Expand the chat column" : "Collapse the chat column");
    b.title = mode === "min" ? "Show the chat" : "Collapse the chat";
  }
  if (keep !== false) { try { localStorage.setItem(CHATCOL_KEY, mode === "min" ? "min" : "full"); } catch (e) {} }
}
function chatNarrowOpen(on) {
  const app = $("app"); if (!app) return;
  app.setAttribute("data-chatopen", on ? "1" : "0");
  const nb = $("chatNarrowBtn"); if (nb) nb.setAttribute("aria-expanded", on ? "true" : "false");
  const tg = $("chatToggle");
  if (tg && NARROW.matches) { tg.setAttribute("aria-label", on ? "Close the chat" : "Collapse the chat column"); tg.setAttribute("aria-expanded", on ? "true" : "false"); }
}
(function wireChatCol() {
  const tog = $("chatToggle"), nb = $("chatNarrowBtn");
  chatColSet(chatColGetMode(), false);
  chatNarrowOpen(false);
  if (tog) tog.addEventListener("click", () => {
    if (NARROW.matches) { chatNarrowOpen(false); if (nb) nb.focus(); return; }
    chatColSet((($("app") && $("app").getAttribute("data-chat")) === "min") ? "full" : "min");
  });
  if (nb) nb.addEventListener("click", () => { chatNarrowOpen(true); const f = $("chatLoad") && !$("chatLoad").classList.contains("hide") ? $("chatLoad") : $("chatInput"); if (f && f.focus) { try { f.focus(); } catch (e) {} } });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && NARROW.matches && $("app") && $("app").getAttribute("data-chatopen") === "1") { chatNarrowOpen(false); if (nb) nb.focus(); }
  });
  if (NARROW.addEventListener) NARROW.addEventListener("change", () => chatNarrowOpen(false));
})();

const TABS = ["watch","boards","state","heroes","bands","chronicle","dice","roll","fallen","lore","bestiary","shops","satchel","season","commands"];
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
  // H32 pass 5: keep the chosen tab inside the (horizontally scrolling) section bar
  const cur = $("tab-" + id);
  if (cur && cur.scrollIntoView) { try { cur.scrollIntoView({ block: "nearest", inline: "nearest" }); } catch (e) {} }
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
  const initial = (mid ? "chronicle" : "") || (heroLinkFrom() >= 0 ? "heroes" : "") || (params.get("open") ? "heroes" : "") || getStoredTab() || TABS[0];
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

// ---------------------------------------------------------------- H22 the first minute
// A short welcome for someone who arrives mid-raid knowing nothing. The copy is static markup in
// index.html. The ONE live line is built here from the snapshot the page already holds: no new
// fetch, no new origin, no write path. Every value reaches the DOM through el()/textContent; the
// three doors carry a page-owned data-door id that is matched against TABS before it does anything.
// Honest by construction: it reads the same `last` / lastError / STALE_MIN the status line reads, so
// an empty, stale or failed snapshot says so here too instead of showing numbers as if they were live.
// Dismissal is per-browser: localStorage under a page-owned key, compared to a one-item whitelist.
const WELCOME_KEY = "bellmire.welcome.v1";
let welcomeP = null;       // the payload render() last drew (internal only)
let welcomeShow = true;
function getWelcomeSeen() {
  try { return ctrlStrip(localStorage.getItem(WELCOME_KEY) || "").slice(0, 8) === "seen" ? "seen" : ""; }
  catch (e) { return ""; }
}
function setWelcome(show, keep) {
  welcomeShow = !!show;
  const box = $("welcome"), btn = $("welcomeBtn");
  if (box) box.classList.toggle("hide", !welcomeShow);
  if (btn) btn.classList.toggle("hide", welcomeShow);
  if (keep) { try { if (!welcomeShow) localStorage.setItem(WELCOME_KEY, "seen"); } catch (e) {} }
}
function paintWelcome() {
  const box = $("welcomeLive");
  if (!box) return;
  box.replaceChildren();
  box.classList.remove("stale");
  if (!last) {
    box.classList.add("stale");
    box.append(el("p", null, lastError
      ? "The town's records are out of reach just now, so there are no live numbers here yet. The page asks again every minute."
      : "Bellmire has not reported in yet, so there are no live numbers to show. They appear here the moment the game is running."));
    return;
  }
  if (!welcomeP || typeof welcomeP !== "object") {     // the version gate refused the payload: say so, show no numbers
    box.classList.add("stale");
    box.append(el("p", null, "The town's latest report is in a format this page does not understand yet, so there are no live numbers here."));
    return;
  }
  const p = welcomeP;
  const t = p.town && typeof p.town === "object" ? p.town : {};
  const a = ago(last.updated_at);
  const age = a ? a.text : "at an unknown time";
  const stale = TEST === "stale" || !a || a.s > STALE_MIN * 60;
  const tiers = arr(LORE_FROZEN && LORE_FROZEN.growth_tiers && LORE_FROZEN.growth_tiers.tiers).filter((x) => x && typeof x === "object" && x.name);
  const lvl = t.level != null && t.level !== "" && Number.isFinite(+t.level) && tiers.length ? Math.max(1, Math.min(tiers.length, Math.floor(+t.level))) : 0;
  const bits = [];
  if (lvl) bits.push("The town stands at stage " + lvl + " of " + tiers.length + " - " + String(tiers[lvl - 1].name) + ".");
  const heroes = arr(p.heroes).filter((h) => h && typeof h === "object").length;
  const hasBands = p.parties != null || p.bands != null;
  const bands = hasBands ? normalizeParties(p.parties != null ? p.parties : p.bands) : [];
  const abroad = bands.reduce((n, b) => n + b.members.length, 0);
  if (heroes > 0) {
    let s = num(heroes) + (heroes === 1 ? " hero is" : " heroes are") + " on the roll";
    if (hasBands) s += abroad > 0 ? ", " + num(abroad) + " abroad in " + bands.length + (bands.length === 1 ? " band." : " bands.") : ", none abroad just now.";
    else s += ".";
    bits.push(s);
  } else if (Array.isArray(p.heroes)) bits.push("No hero has signed the guild post yet.");
  if (!bits.length) bits.push("The town has not sent its numbers yet.");
  let lead;
  if (lastError) { lead = "Couldn't reach the town just now; as of " + age + ":"; box.classList.add("stale"); }
  else if (stale) { lead = "As of " + age + " (the game is probably not running now):"; box.classList.add("stale"); }
  else lead = "Live, updated " + age + ":";
  const line = el("p", "wl-line");
  line.append(el("b", "wl-lead", lead + " "), el("span", null, bits.join(" ")));
  box.append(line);
  const first = chronEntries(p.chronicle)[0];
  if (first) box.append(el("p", "wl-last", "The latest word in the Chronicle: \u201c" + first.s.slice(0, 140) + (first.s.length > 140 ? "\u2026" : "") + "\u201d"));
}
(function wireWelcome() {
  const box = $("welcome");
  if (!box) return;
  box.addEventListener("click", (e) => {
    const b = e.target && e.target.closest ? e.target.closest("button[data-door]") : null;
    if (!b || !box.contains(b)) return;
    const id = cleanTab(b.getAttribute("data-door") || "");
    if (TABS.indexOf(id) < 0) return;
    setActiveTab(id);
    const tab = $("tab-" + id);
    if (tab) { try { tab.scrollIntoView({ block: "start" }); tab.focus({ preventScroll: true }); } catch (err) {} }
  });
  const d = $("welcomeDismiss");
  if (d) d.addEventListener("click", () => setWelcome(false, true));
  const r = $("welcomeBtn");
  if (r) r.addEventListener("click", () => setWelcome(true, false));
  setWelcome(params.get("welcome") === "1" || !getWelcomeSeen(), false);
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
// ?mock=journal (H26): a D60-era payload - rows carry the town's `day`, and tagged rows carry `kind` and
// `who`. "The Cooper" / "Brum" never spell the roster name "Brum the Cooper", so only `who` finds them.
// Hostile strings sit in a `who` entry and in a `kind` value (the kind is not a bounded identifier, so
// it must be treated as untagged). ?mock=journal3 is the SAME rows with the new fields stripped - a v=3 payload.
const MOCK_JOURNAL = [
  { t: "death", s: "The Cooper fell on floor 7, run through by a bone-knight.", at: new Date(Date.now() - 4 * 60000).toISOString(), day: 41, kind: "death", who: ["Brum the Cooper"] },
  { t: "fight", s: "Brum's hammer rang true on floor 6.", at: new Date(Date.now() - 12 * 60000).toISOString(), day: 41, kind: "delve", who: ["Brum the Cooper"] },
  { t: "loot", s: "A teal-dyed cloak came up out of the scar.", at: new Date(Date.now() - 30 * 60000).toISOString(), day: 41, kind: "find", who: ["<img src=x onerror=alert(1)>"] },
  { t: "raid", s: "Bandits tested the west gate and were turned back.", at: new Date(Date.now() - 50 * 60000).toISOString(), day: 41, kind: "raid" },
  { t: "town", s: "A line the town sent with a malformed kind.", at: new Date(Date.now() - 70 * 60000).toISOString(), day: 41, kind: "<img src=x onerror=alert(1)>", who: [7, null, "Pip"] },
  { t: "town", s: "Day 40 begins - 48 souls, 1280 gold.", at: new Date(Date.now() - 20 * 3600000).toISOString(), day: 40, kind: "day" },
  { t: "town", s: "Pip signed the guild ledger, and Brum the Cooper stood witness.", at: new Date(Date.now() - 21 * 3600000).toISOString(), day: 40 },
  { t: "town", s: "Fire in Craft Row - a forge banked wrong.", at: new Date(Date.now() - 22 * 3600000).toISOString(), day: 40, kind: "disaster" },
  { t: "delve", s: "Four delvers went down together and three came back up.", at: new Date(Date.now() - 44 * 3600000).toISOString(), day: 39, kind: "delve", who: ["Pip", "Brum the Cooper"] },
  { t: "lore", s: "An old line with no day, no kind, no who.", at: new Date(Date.now() - 46 * 3600000).toISOString() },
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
  if (MOCK === "journal" || MOCK === "journal3") {
    out.heroes = MOCK_SHEET_HEROES; out.fallen = MOCK_SHEET_FALLEN;
    out.chronicle = MOCK === "journal" ? MOCK_JOURNAL : MOCK_JOURNAL.map((r) => ({ t: r.t, s: r.s, at: r.at }));
    if (MOCK === "journal3") out.v = "3";
  }
  if (MOCK === "season" || MOCK === "season0" || MOCK === "season3") {   // H31: full season / empty season / a v3 payload with no age fields. Hostile strings on purpose
    const bad = "<img src=x onerror=alert(1)>";
    if (MOCK === "season0") { out.heroes = []; out.fallen = []; }
    else {
      out.town = Object.assign({}, out.town, { day: 20 });
      out.heroes = [
        { name: "Brum the Cooper", class: "knight", level: 9, deepest: 31, gold: 540, earned: 4100, born_day: 3 },
        { name: bad, class: "mage", level: 4, deepest: 12, gold: 90, earned: 700, days_alive: 11 },
        { name: "Pip", class: "rogue", level: 2, deepest: 5, gold: 15, earned: 60, born_day: 18 },
      ];
      out.fallen = [
        { name: "Grimhollow", class: "knight", level: 9, deepest: 31, kills: 140, killed_by: "a bone-knight", day: 12, born_day: 2, earned: 3000 },
        { name: "<b>Ash</b>", class: "<i>mage</i>", level: 6, deepest: 22, kills: 40, killed_by: bad, day: 9, age_days: 4, earned: 900 },
      ];
      if (MOCK === "season3") { for (const r of out.heroes.concat(out.fallen)) { delete r.earned; delete r.born_day; delete r.days_alive; delete r.age_days; } out.v = "3"; }
    }
  }
  if (MOCK === "roll") out.rolls = MOCK_ROLLS;
  if (MOCK === "bands") out.parties = MOCK_PARTIES;
  if (MOCK === "v6") {   // v6: mana bars + a boss-fight chip; hostile strings on purpose (the bad miniboss key must be dropped, the bad name shown as text)
    const bad = "<img src=x onerror=alert(1)>";
    out.v = "6";
    out.heroes = [
      { name: "Ysolde", class: "mage", level: 7, hp: 30, max_hp: 44, mana: 18, mana_max: 40, deepest: 9, gold: 120 },
      { name: bad, class: "cleric", level: 4, hp: 22, mana: 0, mana_max: 25, deepest: 4, gold: 10 },
      { name: "Brum the Cooper", class: "knight", level: 9, hp: 80, max_hp: 80, mana: 0, mana_max: 0, deepest: 12, gold: 540 },
    ];
    out.parties = [
      { name: "The Salt Wolves", floor: 5, miniboss: "the_gaoler", miniboss_name: "Shacklemaw", members: [{ name: "Ysolde", class: "mage", hp: 30, max_hp: 44 }] },
      { name: bad + " Band", floor: 3, miniboss: bad, miniboss_name: bad, members: [{ name: "Brum the Cooper", class: "knight", hp: 80, max_hp: 80 }] },
      { name: "Quiet Band", floor: 2, miniboss: "", members: [] },
      { name: "Key-Only Band", floor: 4, miniboss: "the_gaoler", members: [] },   // key, no name: must show NO chip
    ];
  }
  if (MOCK === "fallen") out.fallen = MOCK_FALLEN;
  if (MOCK === "shops" || MOCK === "shops1") {   // H29: shelf states; every string below is hostile-ish on purpose
    const bad = "<img src=x onerror=alert(1)>";
    if (MOCK === "shops1") {
      out.shops = ["The Provisioner", "The Chandler", "The Blacksmith"].map((n) => ({ name: n, level: 1, sells_to: "common", stock: [{ name: "Loaf", cost: 2 }, { name: "Jug of Ale", cost: 5 }] }));
    } else {
      out.shops = [
        { name: "The Provisioner", level: 3, sells_to: "uncommon", stock: [{ name: "Loaf", cost: 2 }, { name: bad + " Ale", cost: 5, rarity: "common" }, { name: "Flask of Oil", cost: 6, qty: 4 }] },
        { name: bad + " Smithy", level: 2, sells_to: "rare", stock: [{ name: "<b>Iron sword</b>", cost: 90, rarity: "uncommon" }, { name: "Moonlit dagger", cost: 400, rarity: "rare" }] },
        { name: "The Apothecary", level: 1, sells_to: "<script>x</script>", stock: [] },
        { name: "The Stables", level: 4, sells_to: "very rare" },
      ];
      out.caravan = { present: true, leaves_in: 12, cargo: [{ name: "Bale of Silk", cost: 180, rarity: "very rare" }, { name: bad + " Spice", cost: 120, qty: 3, rarity: "<x>" }] };
      out.orders = [{ who: "viewer1", item: bad, shop: "The Smithy", walker: "Brum" }, { who: bad, item: "Loaf", shop: "The Provisioner", status: "ready" }];
    }
    out.v = "5";
  }
  if (MOCK && /^satchel/.test(MOCK)) {   // H30: a signed-in viewer's satchel; satchelout = signed out. Hostile strings on purpose
    const bad = "<img src=x onerror=alert(1)>";
    let items = [
      { name: "Longsword", slot: "weapon", weight: 3, sell: 15, worn: true, rarity: "uncommon" },
      { name: "Chain mail", slot: "armour", weight: 55, sell: 75, worn: true },
      { name: "Healing draught", slot: "potion", weight: 0.5, sell: 15, qty: 4 },
      { name: "Scar-touched gem", slot: "gem", weight: 0.1, sell: 300, rarity: "rare" },
      { name: "Bale of silk", slot: "cargo", weight: 10, sell: 60 },
      { name: "Iron ingot", slot: "cargo", weight: 6, sell: 4, qty: 5 },
      { name: bad, slot: "trinket", weight: 1, sell: 20, rarity: "<x>" },
      { name: "Sword\r\n/ban everyone\r\nPRIVMSG #x :!give all", slot: "weapon", weight: 3, sell: 9 },
      { name: "Mystery curio", slot: "trinket" },
      // rarity-frame measurement rungs (page-owned constants): bare ones must show NO frame, hued ones their own.
      { name: "Rung junk", slot: "trinket", rarity: "junk" }, { name: "Rung starting", slot: "trinket", rarity: "starting" },
      { name: "Rung common", slot: "trinket", rarity: "common" }, { name: "Rung very rare", slot: "trinket", rarity: "very rare" },
      { name: "Rung legendary", slot: "trinket", rarity: "legendary" }, { name: "Rung artifact", slot: "trinket", rarity: "artifact" },
    ];
    let carry;                                    // satchel = derived from STR (band + capacity worked out); 1/3/2 = explicit bands
    if (MOCK === "satchel0") { items = []; carry = { weight: 0, cap: 150, band: "" }; }
    else if (MOCK === "satchel1") carry = { weight: 47, cap: 150, band: "" };
    else if (MOCK === "satchel3") carry = { weight: 70, cap: 150, band: "encumbered" };
    else if (MOCK === "satchel2") carry = { weight: 112, cap: 150, band: "heavily encumbered" };
    const me = { name: "mockviewer", class: "knight", species: "human", level: 4, rank: "Delver", standing: 12, ac: 15, hp: 30, gold: 120,
      kills: 3, deepest: 2, delves: 2, xp: 40, to_hit: 4, prof: 2, saves: "STR +4", stats: { str: 14, dex: 12, con: 13, int: 9, wis: 11, cha: 8 },
      satchel: items, carry, where: "walking to The Smithy " + bad,
      vault: MOCK === "satchel0" ? { slots: 12, items: [] } : { slots: 12, items: [{ name: bad + " Hoard", slot: "gem", weight: 0, sell: 500 }, { name: "Spare boots", slot: "armour", weight: 4, sell: 12 }] } };
    out.heroes = [me].concat(arr(p.heroes));
    out.orders = [{ who: "mockviewer", item: bad + " Helm", shop: "The Smithy", walker: "mockviewer" }, { who: "someone-else", item: "Loaf", shop: "The Provisioner" }];
    out.v = "5";
  }
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

// ---------------------------------------------------------------- H32 pass 5: keyboard
// Twitch-style shortcuts, only while the viewer is not typing: "[" folds the rail, "]" folds the
// chat column, "g" jumps to the rail (then Up/Down/Enter as usual). Page-local, no data.
(function wireShortcuts() {
  document.addEventListener("keydown", (ev) => {
    if (ev.ctrlKey || ev.metaKey || ev.altKey || ev.defaultPrevented) return;
    if (ev.key !== "[" && ev.key !== "]" && ev.key !== "g") return;
    const t = ev.target, tag = t && t.tagName ? t.tagName : "";
    if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || (t && t.isContentEditable)) return;
    const app = $("app"); if (!app) return;
    if (ev.key === "[") { if (NARROW.matches) return; railSetMode(railGetMode() === "min" ? "full" : "min"); ev.preventDefault(); }
    else if (ev.key === "]") {
      if (NARROW.matches) { chatNarrowOpen(app.getAttribute("data-chatopen") !== "1"); }
      else chatColSet(app.getAttribute("data-chat") === "min" ? "full" : "min");
      ev.preventDefault();
    } else {
      const r = $("railList"), f = r && (r.querySelector('[tabindex="0"]') || r.querySelector('[role="option"]'));
      if (f) { try { f.focus(); } catch (e) {} ev.preventDefault(); }
    }
  });
})();

// ===========================================================================
// Suggestion Box (supervisor directive, 25 Nov 2026).
// POSTs to Supabase's suggestions table via the REST API with the same
// publishable key the snapshot uses. Anonymous INSERT is allowed by RLS;
// no SELECT/UPDATE/DELETE. Client-side: 60-second cooldown between sends,
// body length 10-2000, category required. No new CSP origin needed.
// ===========================================================================
(function () {
  var form = document.getElementById("suggestForm");
  if (!form) return;
  var catEl  = document.getElementById("sugCat");
  var bodyEl = document.getElementById("sugBody");
  var userEl = document.getElementById("sugUser");
  var btn    = document.getElementById("sugSend");
  var stat   = document.getElementById("sugStatus");
  var URL_SUG = "https://paaukwaffaamazgrndbv.supabase.co/rest/v1/suggestions";
  var cooldown = false;

  function setStatus(msg, ok) {
    stat.textContent = msg;
    stat.className = "suggest-status " + (ok ? "ok" : "err");
  }

  form.addEventListener("submit", async function (ev) {
    ev.preventDefault();
    if (cooldown) { setStatus("Please wait a minute between submissions.", false); return; }
    var cat  = catEl.value;
    var body = bodyEl.value.trim();
    var user = userEl.value.trim();
    if (!cat) { setStatus("Pick a category.", false); catEl.focus(); return; }
    if (body.length < 10) { setStatus("Description needs at least 10 characters.", false); bodyEl.focus(); return; }
    if (body.length > 2000) { setStatus("Description is too long (2000 max).", false); bodyEl.focus(); return; }

    btn.disabled = true;
    setStatus("Sending…", true);
    try {
      var res = await fetch(URL_SUG, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: KEY,
          Authorization: "Bearer " + KEY,
          Prefer: "return=minimal"
        },
        body: JSON.stringify({ category: cat, body: body, username: user || "" })
      });
      if (!res.ok) throw new Error("server " + res.status);
      setStatus("Sent! Thank you — Mr. E will see this.", true);
      bodyEl.value = "";
      catEl.value = "";
      userEl.value = "";
      cooldown = true;
      setTimeout(function () { cooldown = false; btn.disabled = false; }, 60000);
    } catch (e) {
      setStatus("Could not send — try again in a moment.", false);
      btn.disabled = false;
    }
  });
})();
