"use strict";
// ---- where the town's word is kept (publishable key: read-only by row-level security)
const URL_SNAPSHOT = "https://paaukwaffaamazgrndbv.supabase.co/rest/v1/snapshot?select=payload,updated_at";
const KEY = "sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc";
const REFRESH_MS = 60000;      // the game publishes every 60 s
const STALE_MIN = 5;           // past this, the town has gone quiet (the game is likely off)
const TIMEOUT_MS = 12000;      // a fetch that hangs is a failed fetch
const HERO_PAGE = 60;          // heroes drawn at once (a busy night has 200+)

const TEST = new URLSearchParams(location.search).get("state");   // empty | fail | stale (local checks)
const MOCK = new URLSearchParams(location.search).get("mock");    // chronicle | crowd (local checks)
const $ = (id) => document.getElementById(id);
let last = null;               // {payload, updated_at} of the last good read
let lastError = "";
let heroFilter = "";
let heroShown = HERO_PAGE;

// every string from the game (viewers' names!) goes through esc() before it touches HTML
function esc(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
const cap = (s) => String(s ?? "").replace(/\b\w/g, (c) => c.toUpperCase());
const num = (n) => Number.isFinite(+n) ? (+n).toLocaleString("en") : "-";
const mod = (v) => { const m = Math.floor((+v - 10) / 2); return (m >= 0 ? "+" : "") + m; };
const arr = (a) => Array.isArray(a) ? a : [];

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

// ---- the status line: always says how old the word is, and is honest about it
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
  st.innerHTML = html;
  const r = $("retry");
  if (r) r.onclick = () => { r.disabled = true; r.textContent = "Asking…"; load(); };
}

// ---- the fetch: a timeout, a plain message on any failure, never a spinner forever
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

function renderNothing(failed) {
  const box = $("nothing");
  box.classList.remove("hide");
  box.innerHTML = failed
    ? `<h2>The town's records are out of reach</h2><p>Nothing could be read just now. Check your connection; the page tries again every minute on its own.</p>`
    : `<h2>Bellmire has not reported in yet</h2><p>The town sends its news here while the stream's game is running. Once it does, every hero's sheet, the Guild Roll and the Fallen appear on this page.</p>`;
  for (const id of ["boards", "heroes", "chronicle", "roll", "fallen"]) $(id).classList.add("hide");
  $("town").innerHTML = "";
  $("nHeroes").textContent = "";
  $("nFallen").textContent = "";
  renderCommands(null);
}

// ---- the page from the payload (scripts/snapshot_pub.gd, v1)
function render(p) {
  // The publisher stamps a schema version. If it is not the one this page was written for,
  // say so plainly rather than rendering a shape we do not understand.
  if (p && p.v != null && String(p.v) !== "1") {
    showProblem("Bellmire is speaking a newer dialect than this page understands (format " +
                String(p.v).slice(0, 8) + "). The page needs an update.");
    return;
  }
  $("nothing").classList.add("hide");
  for (const id of ["boards", "heroes", "chronicle", "roll", "fallen"]) $(id).classList.remove("hide");
  const t = p.town || {};
  $("townName").textContent = t.name ? String(t.name) : "the Guild Hall";     // the game's own words ("a market town")
  const bits = [];
  if (t.level != null) bits.push(`Town level <b>${esc(t.level)}</b>`);
  if (t.souls != null) bits.push(`<b>${num(t.souls)}</b> souls`);
  if (t.day != null) bits.push(`Day <b>${esc(t.day)}</b>`);
  if (t.treasury != null) bits.push(`<b>${num(t.treasury)}</b> gold in the treasury`);
  if (t.renown) bits.push(`Renown <b>${num(t.renown)}</b>`);
  if (t.score != null && t.next_level_at != null && +t.next_level_at > 0) bits.push(`Growth <b>${num(t.score)}</b> / ${num(t.next_level_at)}`);
  $("town").innerHTML = bits.map((b) => `<li>${b}</li>`).join("");
  renderHeroes(arr(p.heroes));
  renderBoards(arr(p.heroes), arr(p.fallen));
  renderChronicle(p.chronicle);
  renderRoll(arr(p.guild_roll));
  renderFallen(arr(p.fallen));
  renderCommands(p.commands);
}

function renderHeroes(hs) {
  $("nHeroes").textContent = hs.length ? hs.length : "";
  $("heroesNote").textContent = hs.length ? `${hs.length} living` : "";
  const q = heroFilter.trim().toLowerCase();
  const list = q ? hs.filter((h) => String(h.name || "").toLowerCase().includes(q)) : hs;
  const box = $("heroList");
  if (!hs.length) { box.innerHTML = `<p class="empty">No living heroes yet. Type <code>!enlist</code> in chat to raise one.</p>`; $("heroMore").classList.add("hide"); return; }
  if (!list.length) { box.innerHTML = `<p class="empty">No hero by that name. (Fallen heroes are in The Fallen.)</p>`; $("heroMore").classList.add("hide"); return; }
  const open = new Set([...box.querySelectorAll("details[open]")].map((d) => d.dataset.name));
  if (new URLSearchParams(location.search).get("open") && !open.size && list[0]) open.add(String(list[0].name));
  box.innerHTML = list.slice(0, heroShown).map((h) => heroCard(h, open.has(String(h.name)))).join("");
  const more = $("heroMore");
  if (list.length > heroShown) {
    more.classList.remove("hide");
    more.innerHTML = `Showing ${heroShown} of ${list.length}. <button type="button" id="moreBtn" class="find morebtn">Show more</button>`;
    $("moreBtn").onclick = () => { heroShown += HERO_PAGE; renderHeroes(hs); };
  } else more.classList.add("hide");
}

function heroCard(h, isOpen) {
  const s = h.stats || {};
  const order = ["str", "dex", "con", "int", "wis", "cha"];
  const w = h.weapon || {}, ar = h.armour || {};
  const kit = [];
  // brews already counts the healing potions (as "Mending" - roster.brews_line); potions alone when it is missing
  if (h.brews) kit.push(esc(h.brews));
  else if (+h.potions) kit.push(`${num(h.potions)} Mending`);
  kit.push(`${num(h.oil)} oil`);
  kit.push(`${num(h.gold)} gold`);
  return `<details class="hero" data-name="${esc(h.name)}"${isOpen ? " open" : ""}>
    <summary>
      <span class="hname">${esc(h.name)}</span>
      <span class="hquick">AC <b>${esc(h.ac)}</b> &middot; HP <b>${esc(h.hp)}</b></span>
      <span class="hwhat">${esc(cap(h.species))} ${esc(cap(h.class))}, level ${esc(h.level)} &middot; ${esc(h.rank)}${h.title ? ` &middot; <span class="htitle">${esc(h.title)}</span>` : ""}</span>
    </summary>
    <div class="sheet">
      <div class="stats">${order.map((k) => `<div class="stat"><div class="k">${k}</div><div class="v">${esc(s[k] ?? "-")}</div><div class="m">${s[k] != null ? mod(s[k]) : ""}</div></div>`).join("")}</div>
      <p class="sub-h">In a fight</p>
      <dl class="kv">
        <dt>Weapon</dt><dd>${esc(cap(w.name || "bare hands"))} &middot; <b>${esc(w.dice || "-")}</b> damage</dd>
        <dt>To hit</dt><dd>+${esc(h.to_hit)} (proficiency +${esc(h.prof)})</dd>
        <dt>Armour</dt><dd>${esc(cap(ar.name || "none"))} &middot; AC ${esc(h.ac)}</dd>
        <dt>Saves</dt><dd>${esc(h.saves || "-")}</dd>
      </dl>
      <p class="sub-h">Carrying</p>
      <dl class="kv">
        <dt>Pack</dt><dd>${kit.join(" &middot; ")}</dd>
        <dt>Wearing</dt><dd>${h.worn ? esc(h.worn) : "nothing fancy yet"}</dd>
      </dl>
      <p class="sub-h">Record</p>
      <dl class="kv">
        <dt>Deeds</dt><dd>${num(h.kills)} kills &middot; deepest floor ${num(h.deepest)} &middot; ${num(h.delves)} delves</dd>
        <dt>Standing</dt><dd>${num(h.standing)} &middot; ${num(h.xp)} xp</dd>
      </dl>
    </div>
  </details>`;
}

function renderRoll(rows) {
  const box = $("rollList");
  if (!rows.length) { box.innerHTML = `<li class="empty">The roll is empty - nobody has earned a place yet.</li>`; return; }
  box.innerHTML = rows.map((r, i) => `<li class="${r.alive === false ? "gone" : ""}">
      <span class="pos">${i + 1}</span>
      <span class="rname">${esc(r.name)}</span>
      <span class="score"><b>${num(r.standing)}</b><br>${num(r.kills)} kills &middot; floor ${num(r.deepest)}</span>
      <span class="rank">${esc(r.rank)}, level ${esc(r.level)}${r.alive === false ? " &middot; fallen" : ""}</span>
    </li>`).join("");
}

function renderFallen(fs) {
  $("nFallen").textContent = fs.length ? fs.length : "";
  const box = $("fallenList");
  if (!fs.length) { box.innerHTML = `<p class="empty">No one has fallen. Yet.</p>`; return; }
  box.innerHTML = fs.map((f) => `<div class="grave">
      <div class="who">${esc(f.name)} <span class="rec">the ${esc(f.class)}, level ${esc(f.level)}</span></div>
      <div class="how">Slain by ${esc(f.killed_by || "the dark")}${+f.day ? `, day ${esc(f.day)}` : ""}</div>
      <div class="rec">${num(f.kills)} kills &middot; deepest floor ${num(f.deepest)}</div>
      ${f.epitaph ? `<div class="epi">&ldquo;${esc(f.epitaph)}&rdquo;</div>` : ""}
    </div>`).join("");
}

// the command list: from the snapshot when there is one; with no town yet, the page still
// shows how to join (a short built-in list - the full one arrives with the first snapshot)
const FALLBACK_CMDS = { order: ["enlist", "hero", "delve", "help"], commands: {
  enlist: { args: "[class] [people]", short: "Raise your hero: a calling and a people, either order.", example: "!enlist knight dwarf" },
  hero: { short: "Your hero's sheet.", example: "!hero" },
  delve: { short: "Go down into the scar with your hero.", example: "!delve" },
  help: { args: "[command]", short: "The command list; !help <command> for one in detail.", example: "!help forge" } } };

function renderCommands(c) {
  const src = c && c.commands && Object.keys(c.commands).length ? c : FALLBACK_CMDS;
  const cs = src.commands;
  const order = arr(src.order).filter((k) => cs[k]).concat(Object.keys(cs).filter((k) => !arr(src.order).includes(k)));
  $("cmdList").innerHTML = order.map((k) => {
    const d = cs[k] || {};
    const al = arr(d.aliases).length ? `<div>Also: ${arr(d.aliases).map((a) => `<code>!${esc(a)}</code>`).join(" ")}</div>` : "";
    return `<details class="cmd">
      <summary><span class="cname">!${esc(k)}</span> ${d.args ? `<span class="cargs">${esc(d.args)}</span>` : ""}
        <span class="cshort">${esc(d.short || d.what || "")}</span></summary>
      <div class="cbody">
        ${d.what && d.what !== d.short ? `<div>${esc(d.what)}</div>` : ""}
        ${d.cost ? `<div><b>Cost:</b> ${esc(d.cost)}</div>` : ""}
        ${d.needs_hero ? `<div>Needs a living hero.</div>` : ""}
        ${al}
        ${d.example ? `<div>Try: <code>${esc(d.example)}</code></div>` : ""}
      </div>
    </details>`;
  }).join("");
}

$("find").addEventListener("input", (e) => {
  heroFilter = e.target.value;
  heroShown = HERO_PAGE;
  if (last) renderHeroes(arr(last.payload.heroes));
});

load();
setInterval(load, REFRESH_MS);
setInterval(showStatus, 15000);   // "updated N minutes ago" keeps counting between fetches


// Shown when the payload is a version this page was not written for.
// Something we cannot safely render - e.g. a payload in a format this page predates.
// Routed through elements that exist, with textContent/createElement only: never
// document.body (which would wipe the page) and never innerHTML with the message.
function showProblem(msg) {
  const box = $("nothing");
  if (box) {
    box.classList.remove("hide");
    box.replaceChildren();
    const h = document.createElement("h2");
    h.textContent = "This page needs an update";
    const p = document.createElement("p");
    p.textContent = msg;
    box.append(h, p);
  }
  for (const id of ["boards", "heroes", "chronicle", "roll", "fallen", "commands"]) {
    const el = $(id);
    if (el) el.classList.add("hide");
  }
  const st = $("status");
  if (st) { st.className = "status bad"; st.textContent = "Showing nothing rather than guessing."; }
}


/* ============================================================================
   W1b phase 1: the Boards, the Chronicle, the die.

   Every node below is built with createElement + textContent. No innerHTML,
   no insertAdjacentHTML, nothing that parses a snapshot string as markup -
   see docs/HUB_SECURITY.md, layer 2. A hostile hero name renders as the
   literal text a hostile hero typed, which is the whole point.
   ========================================================================= */

// a tiny element builder: text goes in as text, always
function el(tag, cls, text) {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text != null) n.textContent = String(text);
  return n;
}
const n0 = (v) => { const x = +v; return Number.isFinite(x) ? x : 0; };
const nameOf = (r) => String(r && r.name != null ? r.name : "");

/* ---------------------------------------------------------------- the Boards
   Five boards over the data the town already publishes - no backend.
   Deepest and Deadliest also count the dead: a hero's deepest floor and kill
   count stand after they fall, and leaving them out would quietly erase the
   valley's best delve. Gold, delves and standing are a living hero's to hold,
   and the payload does not carry them for the fallen, so those boards are the
   living only. Each board says which it is, rather than leaving you to guess.

   Ties: the primary number, then a second number that means something for that
   board, then the name - so the order is stable between refreshes instead of
   shuffling two equal heroes about.                                         */
const BOARDS = [
  { key: "gold",     tab: "Gold",     title: "Most gold",      unit: "gold",   dead: false, second: "level",   secondLabel: "level" },
  { key: "deepest",  tab: "Deepest",  title: "Deepest floor",  unit: "floor",  dead: true,  second: "kills",   secondLabel: "kills" },
  { key: "kills",    tab: "Deadliest",tab2: "Deadliest", title: "Deadliest",   unit: "kills",  dead: true,  second: "deepest", secondLabel: "floor" },
  { key: "delves",   tab: "Delves",   title: "Most delves",    unit: "delves", dead: false, second: "deepest", secondLabel: "floor" },
  { key: "standing", tab: "Standing", title: "Highest standing", unit: "standing", dead: false, second: "kills", secondLabel: "kills" },
];
const BOARD_TOP = 10;
let boardKey = "gold";

function boardRows(spec, heroes, fallen) {
  const living = heroes.map((h) => ({ r: h, dead: false }));
  const gone = spec.dead ? fallen.map((f) => ({ r: f, dead: true })) : [];
  const rows = living.concat(gone).filter((e) => e.r && typeof e.r === "object");
  rows.sort((a, b) =>
    n0(b.r[spec.key]) - n0(a.r[spec.key]) ||
    n0(b.r[spec.second]) - n0(a.r[spec.second]) ||
    nameOf(a.r).localeCompare(nameOf(b.r), "en", { sensitivity: "base" }));
  return rows;
}

function renderBoards(heroes, fallen) {
  const spec = BOARDS.find((b) => b.key === boardKey) || BOARDS[0];

  // the tabs
  const tabs = $("boardTabs");
  tabs.replaceChildren();
  for (const b of BOARDS) {
    const t = el("button", "chip" + (b.key === spec.key ? " on" : ""), b.tab);
    t.type = "button";
    t.setAttribute("role", "tab");
    t.setAttribute("aria-selected", b.key === spec.key ? "true" : "false");
    t.addEventListener("click", () => {
      boardKey = b.key;
      renderBoards(heroes, fallen);
      // keep the board in view when the list length changes under the tap
      $("boards").scrollIntoView({ block: "nearest" });
    });
    tabs.append(t);
  }

  const box = $("boardList");
  box.replaceChildren();
  const note = $("boardNote");
  const all = boardRows(spec, heroes, fallen);
  const ranked = all.filter((e) => n0(e.r[spec.key]) > 0);

  if (!ranked.length) {
    box.append(el("li", "empty", heroes.length
      ? "Nobody has earned a place on this board yet."
      : "No heroes yet. Type !enlist in chat to raise one."));
    note.textContent = "";
    return;
  }

  const top = ranked.slice(0, BOARD_TOP);
  let place = 0, prev = null;
  top.forEach((e, i) => {
    const v = n0(e.r[spec.key]);
    if (v !== prev) { place = i + 1; prev = v; }        // equal numbers share a place
    const li = el("li", "brow" + (e.dead ? " gone" : "") + (place === 1 ? " first" : ""));

    li.append(el("span", "pos", place));

    const who = el("span", "bname");
    who.append(document.createTextNode(nameOf(e.r) || "(no name)"));
    // a space before the badge, so the name does not read as "NameFALLEN"
    // when it is copied or spoken aloud
    if (e.dead) { who.append(document.createTextNode(" ")); who.append(el("span", "tag", "fallen")); }
    li.append(who);

    const val = el("span", "bval");
    val.append(el("b", null, num(e.r[spec.key])));
    val.append(el("span", "bunit", spec.unit));
    li.append(val);

    const sub = [];
    const cls = e.r.class ? cap(e.r.class) : "";
    if (e.r.level != null) sub.push((cls ? cls + ", " : "") + "level " + e.r.level);
    else if (cls) sub.push(cls);
    // the tie-breaker, unless the line already says it (gold breaks ties on level,
    // and "Knight, level 7 - 7 level" reads like a mistake)
    if (e.r[spec.second] != null && spec.secondLabel !== "level" && spec.second !== spec.key)
      sub.push(num(e.r[spec.second]) + " " + spec.secondLabel);
    li.append(el("span", "bsub", sub.join("  ·  ")));

    box.append(li);
  });

  const counted = spec.dead ? "the living and the fallen" : "living heroes";
  note.textContent = ranked.length > BOARD_TOP
    ? spec.title + ": top " + top.length + " of " + ranked.length + ", counting " + counted + "."
    : spec.title + ", counting " + counted + ".";
}

/* ------------------------------------------------------------ the Chronicle
   payload.chronicle is OPTIONAL: up to 50 entries, newest first, each
   { t, s, at }. t is one of the kinds below. While the desktop has not
   started publishing it, the section says so calmly and renders nothing -
   an absent field is not an error.                                         */
const CHRON_KINDS = [
  { t: "fight", label: "Fights" },
  { t: "death", label: "Deaths" },
  { t: "raid",  label: "Raids" },
  { t: "town",  label: "Town" },
  { t: "lore",  label: "Lore" },
  { t: "loot",  label: "Loot" },
  { t: "delve", label: "Delves" },
];
const CHRON_MAX = 50;
let chronOff = new Set();          // kinds the viewer has switched OFF (default: all on)

function chronEntries(raw) {
  return arr(raw)
    .filter((e) => e && typeof e === "object" && typeof e.s === "string" && e.s.trim() !== "")
    .slice(0, CHRON_MAX)
    .map((e) => ({
      // an unknown kind is not a reason to drop the line - it files under "other"
      t: CHRON_KINDS.some((k) => k.t === e.t) ? e.t : "other",
      s: String(e.s),
      at: typeof e.at === "string" ? e.at : "",
    }));
}

function renderChronicle(raw) {
  const chips = $("chronChips");
  const list = $("chronList");
  const note = $("chronNote");
  chips.replaceChildren();
  list.replaceChildren();

  if (raw == null || !Array.isArray(raw)) {
    note.textContent = "The chronicle will appear here once the town reports it.";
    note.className = "chronnote quiet";
    return;
  }

  const entries = chronEntries(raw);
  if (!entries.length) {
    note.textContent = "Nothing has been written in the chronicle yet.";
    note.className = "chronnote quiet";
    return;
  }

  // a chip for each kind actually present, plus "other" if anything landed there
  const present = CHRON_KINDS.filter((k) => entries.some((e) => e.t === k.t));
  if (entries.some((e) => e.t === "other")) present.push({ t: "other", label: "Other" });

  for (const k of present) {
    const count = entries.filter((e) => e.t === k.t).length;
    const on = !chronOff.has(k.t);
    const c = el("button", "chip kind-" + k.t + (on ? " on" : ""));
    c.type = "button";
    c.setAttribute("aria-pressed", on ? "true" : "false");
    c.append(document.createTextNode(k.label));
    c.append(el("span", "cnt", count));
    c.addEventListener("click", () => {
      if (chronOff.has(k.t)) chronOff.delete(k.t); else chronOff.add(k.t);
      renderChronicle(raw);
    });
    chips.append(c);
  }
  if (chronOff.size) {
    const clear = el("button", "chip clear", "Show all");
    clear.type = "button";
    clear.addEventListener("click", () => { chronOff.clear(); renderChronicle(raw); });
    chips.append(clear);
  }

  const shown = entries.filter((e) => !chronOff.has(e.t));
  if (!shown.length) {
    note.textContent = "Every kind is switched off - tap a chip to bring the chronicle back.";
    note.className = "chronnote quiet";
    return;
  }

  for (const e of shown) {
    const li = el("li", "centry kind-" + e.t);
    const head = el("div", "chead");
    const kind = CHRON_KINDS.find((k) => k.t === e.t);
    // the same word the chip uses, so the filter and the entry agree
    head.append(el("span", "ckind", kind ? kind.label.replace(/s$/, "") : "Other"));
    const a = ago(e.at);
    if (a) {
      const t = el("time", "cwhen", a.text);
      t.dateTime = e.at;                                 // an ISO stamp the game wrote, as an attribute value only
      t.title = when(e.at);
      head.append(t);
    }
    li.append(head);
    li.append(el("p", "cline", e.s));                    // viewer-shaped text: textContent, never markup
    list.append(li);
  }

  note.className = "chronnote";
  note.textContent = shown.length === entries.length
    ? entries.length + (entries.length === 1 ? " entry" : " entries") + ", newest first."
    : "Showing " + shown.length + " of " + entries.length + ", newest first.";
}

/* ------------------------------------------------------------------ the die
   A toy. The roll is made here in the browser from crypto.getRandomValues and
   goes nowhere - no fetch, no record, nothing to do with the game's dice.
   Rejection sampling (drop 240-255) keeps all twenty faces equally likely;
   a plain % 20 over 0-255 would favour 1-16.                                */
function rollD20() {
  const b = new Uint8Array(1);
  for (let i = 0; i < 64; i++) {
    crypto.getRandomValues(b);
    if (b[0] < 240) return (b[0] % 20) + 1;              // 240 = 12 x 20
  }
  crypto.getRandomValues(b);
  return (b[0] % 20) + 1;                                // unreachable in practice
}

const D20_HIST = 8;
let d20hist = [];
let d20busy = false;

function d20Verdict(v) {
  if (v === 20) return "A natural twenty. The hall roars.";
  if (v === 1)  return "A one. The hall goes quiet.";
  if (v >= 15)  return "A good roll.";
  if (v >= 8)   return "A fair roll.";
  return "A poor roll.";
}

function paintD20Hist() {
  const box = $("d20hist");
  box.replaceChildren();
  if (!d20hist.length) { box.append(el("li", "empty", "Nothing rolled yet.")); return; }
  for (const v of d20hist) {
    box.append(el("li", "hroll" + (v === 20 ? " crit" : v === 1 ? " crat" : ""), v));
  }
}

function setUpD20() {
  const btn = $("d20"), out = $("d20num"), say = $("d20result");
  if (!btn) return;
  const calm = matchMedia("(prefers-reduced-motion: reduce)").matches;

  btn.addEventListener("click", () => {
    if (d20busy) return;
    d20busy = true;
    const value = rollD20();                             // decided up front; the tumble is only show
    btn.classList.add("rolling");
    say.textContent = "Rolling…";

    const land = () => {
      btn.classList.remove("rolling");
      out.textContent = value;
      btn.classList.toggle("crit", value === 20);
      btn.classList.toggle("crat", value === 1);
      say.textContent = value + " · " + d20Verdict(value);
      d20hist.unshift(value);
      if (d20hist.length > D20_HIST) d20hist.length = D20_HIST;
      paintD20Hist();
      d20busy = false;
    };

    if (calm) { land(); return; }
    const started = Date.now(), SPIN = 620;
    const tick = setInterval(() => {
      out.textContent = rollD20();                       // the blur of faces
      if (Date.now() - started >= SPIN) { clearInterval(tick); land(); }
    }, 55);
  });

  // the die is a button, so Enter and Space already work; make that plain to a reader
  btn.setAttribute("aria-label", "Roll the twenty-sided die");
  paintD20Hist();
}
setUpD20();


/* ---------------------------------------------------------------- test hooks
   Local checks only (?mock=...), and harmless: they alter nothing that is
   fetched or sent - they only stand in for data the town has not published
   yet, so the Chronicle and the Boards can be exercised before it does.
   The hostile name below is deliberate: it must appear on screen as the
   literal characters a viewer typed, and never run.                        */
const MOCK_CHRONICLE = [
  { t: "death", s: "Grimhollow the Knight fell on floor 7, run through by a bone-knight.", at: new Date(Date.now() - 2 * 60000).toISOString() },
  { t: "fight", s: "<img src=x onerror=alert(1)> struck a cave troll for 14 and lived to say so.", at: new Date(Date.now() - 9 * 60000).toISOString() },
  { t: "loot",  s: "A teal-dyed cloak and 230 gold came up out of the scar.", at: new Date(Date.now() - 24 * 60000).toISOString() },
  { t: "raid",  s: "Bandits tested the west gate and were turned back by the watch.", at: new Date(Date.now() - 95 * 60000).toISOString() },
  { t: "town",  s: "Bellmire reached town level 4; the treasury stands at 1,280 gold.", at: new Date(Date.now() - 3 * 3600000).toISOString() },
  { t: "delve", s: "Four delvers went down together and three came back up.", at: new Date(Date.now() - 5 * 3600000).toISOString() },
  { t: "lore",  s: "The guild writes that the scar was a well before it was a wound.", at: new Date(Date.now() - 26 * 3600000).toISOString() },
  { t: "wat",   s: "A kind the page has never heard of, which must still render.", at: new Date(Date.now() - 30 * 3600000).toISOString() },
  { t: "fight", s: "A stat line with no stamp at all.", at: "" },
];
function withMock(p) {
  const out = Object.assign({}, p);
  if (MOCK === "chronicle") out.chronicle = MOCK_CHRONICLE;
  if (MOCK === "crowd") {
    const classes = ["knight", "rogue", "mage", "ranger"], species = ["dwarf", "human", "elf", "orc"];
    const made = [];
    for (let i = 0; i < 40; i++) {
      made.push({
        name: i === 0 ? "<img src=x onerror=alert(1)>" : "Hero" + String(i).padStart(2, "0"),
        class: classes[i % 4], species: species[i % 4], level: 1 + (i % 9),
        rank: "Delver", standing: (i * 37) % 300, ac: 12 + (i % 6), hp: 20 + i,
        gold: (i * 53) % 900, kills: (i * 7) % 60, deepest: i % 13, delves: i % 11,
        xp: i * 10, to_hit: 4, prof: 2, saves: "STR +4",
        stats: { str: 10 + (i % 8), dex: 12, con: 13, int: 9, wis: 11, cha: 8 },
        weapon: { name: "sword", dice: "1d8" }, armour: { name: "mail" },
        worn: "", title: "", oil: i % 4, potions: i % 3, brews: "",
      });
    }
    // two heroes dead level on gold, to see the shared place and the name tie-break
    made[3].gold = made[4].gold = 777;
    out.heroes = made.concat(arr(p.heroes));
    // a fallen hero good enough to hold a place, so the boards that count the dead
    // actually show one rather than only being able to
    out.fallen = [{ name: "Grimhollow", class: "knight", level: 9, kills: 140, deepest: 31,
                    killed_by: "a bone-knight", epitaph: "Went deepest. Came back once.", day: 12 }]
                  .concat(arr(p.fallen));
    out.chronicle = MOCK_CHRONICLE;
  }
  return out;
}
