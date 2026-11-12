"use strict";
// ---- where the town's word is kept (publishable key: read-only by row-level security)
const URL_SNAPSHOT = "https://paaukwaffaamazgrndbv.supabase.co/rest/v1/snapshot?select=payload,updated_at";
const KEY = "sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc";
const REFRESH_MS = 60000;      // the game publishes every 60 s
const STALE_MIN = 5;           // past this, the town has gone quiet (the game is likely off)
const TIMEOUT_MS = 12000;      // a fetch that hangs is a failed fetch
const HERO_PAGE = 60;          // heroes drawn at once (a busy night has 200+)

const TEST = new URLSearchParams(location.search).get("state");   // empty | fail | stale (local checks)
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
      render(row.payload);
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
  for (const id of ["heroes", "roll", "fallen"]) $(id).classList.add("hide");
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
  for (const id of ["heroes", "roll", "fallen"]) $(id).classList.remove("hide");
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
  for (const id of ["heroes", "roll", "fallen", "commands"]) {
    const el = $(id);
    if (el) el.classList.add("hide");
  }
  const st = $("status");
  if (st) { st.className = "status bad"; st.textContent = "Showing nothing rather than guessing."; }
}
