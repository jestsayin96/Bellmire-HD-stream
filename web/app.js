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
const MOCK = params.get("mock");    // chronicle | crowd (local checks)
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
function sigil(name) {
  const letters = String(name || "").replace(/[^A-Za-z0-9]/g, "");
  return (letters.slice(0, 2) || "?").toUpperCase();
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
    if (!row || !row.payload || typeof row.payload !== "object") {
      last = null;
      renderNothing();
    } else {
      last = row;
      render(MOCK ? withMock(row.payload) : row.payload);
    }
  } catch (e) {
    lastError = e && e.name === "AbortError" ? "no answer in " + TIMEOUT_MS / 1000 + " s" :
      (e && e.message && !/fetch|network/i.test(e.message) ? e.message : "you may be offline, or the records are down");
    if (!last) renderNothing(true);
  }
  showStatus();
}

const SECTIONS = ["boards", "dice", "heroes", "chronicle", "roll", "fallen"];

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
  renderCommands(null);
}

// ---------------------------------------------------------------- the page
function render(p) {
  if (p && p.v != null && String(p.v) !== "1") {
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
  renderChronicle(p.chronicle, { auto: true });
  renderRoll(arr(p.guild_roll));
  renderFallen(arr(p.fallen));
  renderCommands(p.commands);
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
function renderHeroes(hs) {
  $("nHeroes").textContent = hs.length ? hs.length : "";
  $("heroesNote").textContent = hs.length ? `${hs.length} living` : "";
  const q = heroFilter.trim().toLowerCase();
  const list = q ? hs.filter((h) => String(h.name || "").toLowerCase().includes(q)) : hs;
  const box = $("heroList");
  box.replaceChildren();
  if (!hs.length) { box.append(el("p", "empty", "No living heroes yet. Type !enlist in chat to raise one.")); $("heroMore").classList.add("hide"); return; }
  if (!list.length) { box.append(el("p", "empty", "No hero by that name. (Fallen heroes are in The Fallen.)")); $("heroMore").classList.add("hide"); return; }
  const openNames = new Set();
  if (params.get("open") && list[0]) openNames.add(String(list[0].name));
  for (const h of list.slice(0, heroShown)) box.append(heroCard(h, openNames.has(String(h.name))));
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

function heroCard(h, isOpen) {
  const det = el("details", "hero");
  const sum = el("summary");
  // the crest: the hero's initials in a class-tinted ring, with the calling's icon
  const sg = el("span", "hsigil cls-" + classIcon(h.class), sigil(h.name));
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
  sum.append(sg, idb);
  det.append(sum);

  // lazy-render: the full sheet is built on first open, not for all 60+ cards up
  // front. A busy night is 200 heroes; most cards are never opened.
  let built = false;
  const build = () => { if (built) return; built = true; det.append(heroSheet(h)); };
  det.addEventListener("toggle", () => { if (det.open) build(); });
  if (isOpen) { det.open = true; build(); }
  return det;
}

function heroSheet(h) {
  const s = h.stats || {};
  const order = ["str", "dex", "con", "int", "wis", "cha"];
  const w = h.weapon || {}, armr = h.armour || {};
  const sheet = el("div", "sheet");

  sheet.append(hpBar(h));
  sheet.append(xpBar(h));

  const stats = el("div", "stats");
  for (const k of order) {
    const cell = el("div", "stat");
    cell.append(el("div", "k", k), el("div", "v", s[k] != null ? s[k] : "-"), el("div", "m", s[k] != null ? modOf(s[k]) : ""));
    stats.append(cell);
  }
  sheet.append(stats);

  // Equipped: weapon and armour as gear cards with item icons
  sheet.append(el("p", "eyebrow", "Equipped"));
  const gear = el("div", "gearstrip");
  gear.append(
    gearCard(weaponIcon(w.name), "Weapon", `${cap(w.name || "bare hands")}  ·  ${w.dice || "-"}`,
             `${cap(w.name || "bare hands")} — ${w.dice || "-"} damage`),
    gearCard("shield", "Armour", `${cap(armr.name || "none")}  ·  AC ${h.ac}`,
             `${cap(armr.name || "none")} — armour class ${h.ac}`),
  );
  sheet.append(gear);

  sheet.append(el("p", "eyebrow", "In a fight"));
  const f = el("dl", "kvlist");
  f.append(
    kv("To hit", `+${n0(h.to_hit)} (proficiency +${n0(h.prof)})`),
    kv("Saves", h.saves || "-"),
  );
  sheet.append(f);

  // Carrying: icon chips
  sheet.append(el("p", "eyebrow", "Carrying"));
  const carry = el("div", "carry");
  const brew = h.brews ? String(h.brews) : (+h.potions ? `${num(h.potions)} Mending` : "no brews");
  carry.append(
    carryChip("potion", brew),
    carryChip("flask", `${num(h.oil)} oil`),
    carryChip("coin", `${num(h.gold)} gold`),
  );
  sheet.append(carry);

  // Worn: cosmetics and any dye. A dye swatch colour comes from a WHITELISTED
  // class (dye-<known colour>), never an inline style built from snapshot data;
  // an unknown dye string shows as plain text only.
  if (h.worn || h.dye) {
    sheet.append(el("p", "eyebrow", "Worn"));
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
    sheet.append(cos);
  }

  sheet.append(el("p", "eyebrow", "Record"));
  const rec = el("dl", "kvlist");
  rec.append(
    kv("Deeds", `${num(h.kills)} kills  ·  deepest floor ${num(h.deepest)}  ·  ${num(h.delves)} delves`),
    kv("Standing", num(h.standing)),
  );
  sheet.append(rec);
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

// ============================================================ THE FALLEN
function renderFallen(fs) {
  $("nFallen").textContent = fs.length ? fs.length : "";
  const box = $("fallenList");
  box.replaceChildren();
  if (!fs.length) { box.append(el("p", "empty", "No one has fallen. Yet.")); return; }
  for (const f of fs) {
    const g = el("div", "grave");
    const who = el("div", "gwho");
    who.append(document.createTextNode(nameOf(f)));
    who.append(el("span", "grec", `the ${f.class}, level ${f.level}`));
    g.append(who);
    // their earned title, if they carried one, kept with them on the memorial
    if (f.title) g.append(el("div", "gtitle", String(f.title)));
    g.append(el("div", "ghow", `Slain by ${f.killed_by || "the dark"}` + (+f.day ? `, day ${f.day}` : "")));
    g.append(el("div", "grec", `${num(f.kills)} kills  ·  deepest floor ${num(f.deepest)}`));
    if (f.epitaph) g.append(el("div", "gepi", "“" + String(f.epitaph) + "”"));
    box.append(g);
  }
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
let chronData = null;              // the latest raw chronicle (for hover-paused repaints)
let chronHover = false;            // true while the pointer is over the feed
let chronPending = false;          // an auto-refresh arrived while hovering

const titleCase = (s) => String(s).replace(/[_-]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

function chronEntries(raw) {
  return arr(raw)
    .filter((e) => e && typeof e === "object" && typeof e.s === "string" && e.s.trim() !== "")
    .slice(0, CHRON_MAX)
    .map((e) => {
      const rawT = String(e.t == null ? "" : e.t).toLowerCase().trim();
      const t = /^[a-z0-9][a-z0-9 _-]{0,23}$/.test(rawT) ? rawT : "other";   // sane key, else "other"
      const known = CHRON_KINDS.find((k) => k.t === t);
      return { t, known: !!known, label: known ? known.one : (t === "other" ? "Other" : titleCase(t)),
                icon: CHRON_ICON.has(t) ? t : "other",
               key: t.replace(/[^a-z0-9]+/g, "-"),           // for the CSS class only
               s: String(e.s), at: typeof e.at === "string" ? e.at : "" };
    });
}

// store the latest data and repaint. An AUTO refresh (from the 60 s poll) is held
// back while the viewer is reading the feed (pointer over it), so a busy moment
// does not reshuffle lines under them; the held update is applied when they leave.
// A user action (chip, search, clear) always paints at once.
function renderChronicle(raw, opts) {
  if (raw !== undefined) chronData = raw;
  const auto = opts && opts.auto;
  if (auto && chronHover && $("chronList").childElementCount) { chronPending = true; return; }
  chronPending = false;
  paintChronicle();
}

function paintChronicle() {
  const raw = chronData;
  const chips = $("chronChips"), list = $("chronList"), note = $("chronNote"), find = $("chronFind");
  chips.replaceChildren();
  list.replaceChildren();
  const hasData = Array.isArray(raw);
  if (find) find.classList.toggle("hide", !hasData);
  if (!hasData) {
    note.textContent = "The chronicle will appear here once the town reports it.";
    note.className = "note quiet";
    return;
  }
  const entries = chronEntries(raw);
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
    c.addEventListener("click", () => { if (chronOff.has(g.t)) chronOff.delete(g.t); else chronOff.add(g.t); paintChronicle(); });
    chips.append(c);
  }
  if (chronOff.size) {
    const clear = el("button", "chip clear", "Show all kinds");
    clear.type = "button";
    clear.addEventListener("click", () => { chronOff.clear(); paintChronicle(); });
    chips.append(clear);
  }

  const q = chronText.trim().toLowerCase();
  const shown = entries.filter((e) => !chronOff.has(e.t) && (!q || e.s.toLowerCase().includes(q)));
  if (!shown.length) {
    note.className = "note quiet";
    note.textContent = q
      ? "No entries match “" + q + "”" + (chronOff.size ? " in the kinds shown." : ".")
      : "Every kind is switched off - tap a chip to bring the chronicle back.";
    return;
  }
  for (const e of shown) {
    const li = el("li", "centry kind-" + e.key);
    const badge = el("span", "cbadge");
    badge.setAttribute("aria-hidden", "true");
    badge.append(icon(e.icon));                 // whitelisted glyph id
    li.append(badge);
    const body = el("div", "cbody");
    const head = el("div", "chead");
    head.append(el("span", "ckind", e.label));  // textContent; a novel kind shows its own name, escaped
    const a = ago(e.at);
    if (a) {
      const time = el("time", "cwhen", a.text);
      time.dateTime = e.at;
      time.title = when(e.at);
      head.append(time);
    }
    body.append(head, el("p", "cline", e.s));   // viewer text: textContent
    li.append(body);
    list.append(li);
  }
  note.className = "note";
  const tail = q || chronOff.size ? " (" + entries.length + " in all)" : "";
  note.textContent = (shown.length === entries.length
    ? entries.length + (entries.length === 1 ? " entry" : " entries")
    : "Showing " + shown.length + " of " + entries.length) + ", newest first." + (tail && shown.length !== entries.length ? "" : "");
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

// ---------------------------------------------------------------- Twitch chat (H5)
// Opt-in: the iframe is created ONLY when the viewer clicks. The channel is a
// hard-coded constant and the parent is THIS page's own hostname - no snapshot
// value is ever used to build the URL (docs/HUB_SECURITY.md). The page stays
// read-only; the embed is a separate, cross-origin browsing context.
const TWITCH_CHANNEL = "jestsayin96";    // Mr. E's channel - a constant, never snapshot data
function loadTwitchChat() {
  const box = $("chatBox");
  if (!box || box.querySelector("iframe")) return;
  const host = location.hostname || "localhost";
  const frame = document.createElement("iframe");
  frame.id = "twitchChatFrame";
  frame.title = "Twitch chat for " + TWITCH_CHANNEL;
  frame.setAttribute("loading", "lazy");
  // official chat embed: https://www.twitch.tv/embed/<channel>/chat?parent=<host>
  frame.src = "https://www.twitch.tv/embed/" + TWITCH_CHANNEL + "/chat?parent=" +
              encodeURIComponent(host) + "&darkpopout";
  box.replaceChildren(frame);
}
(function () {
  const btn = $("chatLoad");
  if (btn) btn.addEventListener("click", loadTwitchChat);
})();

// ---------------------------------------------------------------- Twitch sign-in (H6)
// Device-code OAuth. A viewer signs in so the page can spotlight THEIR hero instead of
// making them scroll. Strictly read-only: the token is the viewer's own, used only
// client-side to read their own Twitch login and match a hero. It is held in memory
// only (never localStorage), never sent to our backend, never used to write anything.
//
// LIVE: TWITCH_CLIENT_ID is Mr. E's registered public client id (Bellmire Hub Login),
// baked in as a const and not overridable at runtime. Clicking the button runs the
// device grant below (per the Twitch docs); nothing contacts Twitch before the click.
// The empty-id branch in twitchSignIn() is kept as a defensive fallback only.
const TWITCH_CLIENT_ID = "mpblygfdxvdpnr0dvi3andjlvb4y0r";  // Bellmire Hub Login: PUBLIC client, device-code grant, no scopes. Not overridable at runtime.
const TW_DEVICE = "https://id.twitch.tv/oauth2/device";
const TW_TOKEN = "https://id.twitch.tv/oauth2/token";
const TW_USERS = "https://api.twitch.tv/helix/users";
const TW_SCOPES = "";                            // read-only: we need only the user's login; no scopes
let twToken = null;                              // in memory only, this session only
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
    highlightMyHero(login);
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

// ---------------------------------------------------------------- wiring
$("find").addEventListener("input", (e) => {
  heroFilter = e.target.value; heroShown = HERO_PAGE;
  if (last) renderHeroes(arr((MOCK ? withMock(last.payload) : last.payload).heroes));
});
$("boardFind").addEventListener("input", (e) => {
  boardFind = e.target.value;
  if (last) { const p = MOCK ? withMock(last.payload) : last.payload; renderBoards(arr(p.heroes), arr(p.fallen)); }
});
$("chronFind").addEventListener("input", (e) => { chronText = e.target.value; paintChronicle(); });
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

load();
setInterval(load, REFRESH_MS);
setInterval(showStatus, 15000);

// ---------------------------------------------------------------- test hooks
// Local only (?mock=...), harmless: they stand in for data the town has not
// published yet. The hostile name is deliberate - it must render as literal text.
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
function withMock(p) {
  const out = Object.assign({}, p);
  if (MOCK === "chronicle") out.chronicle = MOCK_CHRONICLE;
  if (MOCK === "crowd") {
    const classes = ["knight", "rogue", "mage", "ranger"], species = ["dwarf", "human", "elf", "orc"];
    const weapons = ["sword", "oak staff", "shortbow", "warhammer"];
    const dyes = ["teal", "gold", "red", "purple"], titles = ["the Bold", "Scarbane", "the Quick", "Emberkin"];
    const made = [];
    for (let i = 0; i < 40; i++) {
      made.push({
        name: i === 0 ? "<img src=x onerror=alert(1)>" : "Hero" + String(i).padStart(2, "0"),
        class: classes[i % 4], species: species[i % 4], level: 1 + (i % 9), rank: "Delver",
        standing: (i * 37) % 300, ac: 12 + (i % 6), hp: 20 + i, gold: (i * 53) % 900,
        kills: (i * 7) % 60, deepest: i % 13, delves: i % 11, xp: i * 10, to_hit: 4, prof: 2,
        saves: "STR +4", stats: { str: 10 + (i % 8), dex: 12, con: 13, int: 9, wis: 11, cha: 8 },
        weapon: { name: weapons[i % 4], dice: "1d8" }, armour: { name: "mail" },
        // a few heroes carry the forward-compatible fields, to exercise the real
        // HP/XP bars, the dye swatch and a title (the publisher can add these any time)
        max_hp: i % 3 === 0 ? 40 + i * 2 : undefined,
        xp_next: i % 2 === 0 ? 100 + i * 5 : undefined,
        worn: i % 5 === 0 ? "a corgi, a crown" : "",
        dye: i % 4 === 0 ? dyes[(i / 4) % 4 | 0] : undefined,
        title: i % 6 === 0 ? titles[(i / 6) % 4 | 0] : "",
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
