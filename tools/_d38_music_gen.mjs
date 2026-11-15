// D38/D22b: generate the town's music beds + stings with Mr. E's music-studio, run IN PLACE and READ-ONLY.
// Starts music-studio's own vite dev server (writes nothing tracked), drives it in headless Edge over the
// Chrome DevTools Protocol, and saves every WAV + listen report into OUT (outside the music-studio repo).
// Usage (Windows): node tools/_d38_music_gen.mjs <out-dir>
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const MS = 'C:\\Users\\morta\\music-studio';
const EDGE = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const OUT = path.resolve(process.argv[2] || 'build/_d38_music');
const PORT = 5179, DBG = 9339;
fs.mkdirSync(OUT, { recursive: true });
const LOG = path.join(OUT, 'gen.log');
fs.writeFileSync(LOG, '');
const log = (...a) => { const s = a.map(x => typeof x === 'string' ? x : JSON.stringify(x)).join(' '); console.log(s); fs.appendFileSync(LOG, s + '\n'); };
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// Mr. E's approved mapping (WORK_PLAN D38). seconds = loop length asked of the composer.
const BEDS0 = [
  { name: 'day',   style: 'playful_pizzicato', mood: 'playful', role: 'bed',   seconds: 64, seed: 1101, bright: [0], dens: [0, -1.5], seeds: 10 },
  { name: 'night', style: 'ambient_calm',      mood: 'lowkey',  role: 'bed',   seconds: 72, seed: 2202, bright: [0], dens: [0, -1.5], seeds: 10 },
  { name: 'raid',  style: 'epic_cinematic',    mood: 'hype',    role: 'music', seconds: 48, seed: 3303, bright: [0], dens: [0, 1], seeds: 8, targetBpm: 100 },
  { name: 'delve', style: 'lofi_chill',        mood: 'lowkey',  role: 'bed',   seconds: 64, seed: 4404, bright: [0], dens: [-2.5, -1.5], seeds: 10 },
];
const BEDS = BEDS0.map(j => ({ ...j, ...(process.env.D38_GRID ? JSON.parse(process.env.D38_GRID) : {}),
  ...(process.env['D38_GRID_' + j.name] ? JSON.parse(process.env['D38_GRID_' + j.name]) : {}) }));
// the 2-5 s sting maker (src/ui/stingPanel.ts presets: whoosh / hit / riser / blip)
const STINGS = [
  { name: 'sting_victory', preset: 'riser', duration: 3.2, pitch: 72, brightness: 0.75, intensity: 0.8, seed: 7 },
  { name: 'sting_defeat',  preset: 'hit',   duration: 3.8, pitch: 41, brightness: 0.2,  intensity: 0.75, seed: 9 },
];

let vite, edge, ws;
function cleanup() { try { ws && ws.close(); } catch {} try { edge && edge.kill(); } catch {} try { vite && vite.kill(); } catch {} }
process.on('exit', cleanup);

async function waitHttp(url, tries = 120) {
  for (let i = 0; i < tries; i++) { try { const r = await fetch(url); if (r.ok) return r; } catch {} await sleep(500); }
  throw new Error('timeout waiting for ' + url);
}

let nextId = 1; const pending = new Map();
function send(method, params = {}, sessionId) {
  const id = nextId++;
  ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
  return new Promise((res, rej) => pending.set(id, { res, rej }));
}
async function evalIn(sid, expr) {
  const r = await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true }, sid);
  if (r.exceptionDetails) throw new Error('page: ' + JSON.stringify(r.exceptionDetails).slice(0, 800));
  return r.result.value;
}
const newFiles = (before) => fs.readdirSync(OUT).filter(f => !before.has(f) && !f.endsWith('.crdownload') && !f.endsWith('.tmp'));
async function waitDownloads(before, wantWav, ms = 60000) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    const nf = newFiles(before);
    if (nf.some(f => f.endsWith('.wav')) && (!wantWav || nf.length >= wantWav)) { await sleep(800); return newFiles(before); }
    await sleep(300);
  }
  return newFiles(before);
}

async function main() {
  log('music-studio dir', MS, 'out', OUT);
  vite = spawn(process.execPath, [path.join(MS, 'node_modules', 'vite', 'bin', 'vite.js'), '--port', String(PORT), '--strictPort', '--host', '127.0.0.1'], { cwd: MS, stdio: ['ignore', 'pipe', 'pipe'] });
  vite.stderr.on('data', d => fs.appendFileSync(LOG, '[vite] ' + d));
  await waitHttp(`http://127.0.0.1:${PORT}/`);
  log('vite up');
  edge = spawn(EDGE, ['--headless=new', `--remote-debugging-port=${DBG}`, `--user-data-dir=${path.join(OUT, '_edgeprof')}`, '--autoplay-policy=no-user-gesture-required', '--no-first-run', '--no-default-browser-check', 'about:blank'], { stdio: 'ignore' });
  const ver = await (await waitHttp(`http://127.0.0.1:${DBG}/json/version`)).json();
  ws = new WebSocket(ver.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });
  ws.onmessage = (m) => { const d = JSON.parse(m.data); if (d.id && pending.has(d.id)) { const p = pending.get(d.id); pending.delete(d.id); d.error ? p.rej(new Error(JSON.stringify(d.error))) : p.res(d.result); } };
  await send('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: OUT, eventsEnabled: false });
  const { targetId } = await send('Target.createTarget', { url: `http://127.0.0.1:${PORT}/` });
  const { sessionId: sid } = await send('Target.attachToTarget', { targetId, flatten: true });
  await send('Runtime.enable', {}, sid);
  for (let i = 0; i < 120; i++) { if (await evalIn(sid, 'typeof window.musicStudio === "object"')) break; await sleep(500); }
  log('musicStudio', await evalIn(sid, 'window.musicStudio.version'));
  const summary = { version: await evalIn(sid, 'window.musicStudio.version'), beds: [], stings: [] };

  const ONLY = process.env.D38_ONLY || '';
  // the composer's own knobs (src/style/compose.ts ComposeBrief): brightnessBias adds 0.1 x bias to the
  // style brightness, densityBias scales density by (1 + 0.25 x bias). Searched until the tool's OWN
  // listen report says mood.pass, speechRoom pass (beds) and seam ok - or the best score is kept and flagged.
  // window.musicStudio.compose() drops the bias knobs (commands.ts briefFrom), so this calls the tool's own
  // modules exactly as its describe()/exportWav() do: composeProject -> renderAndNormalize -> buildListenReport
  // -> encodeWav. Same functions, same numbers - only the UI shell is skipped.
  const tryOne = (brief, k) => evalIn(sid, `(async (b, k) => {
    const { composeProject } = await import('/src/style/compose.ts');
    const { newProject } = await import('/src/model/defaults.ts');
    const { renderAndNormalize } = await import('/src/io/exportProject.ts');
    const { buildListenReport } = await import('/src/analysis/listen.ts');
    const { encodeWav } = await import('/src/audio/render/wav.ts');
    const made = composeProject(newProject(), b);
    if (made.refused) return { error: made.refused };
    const pj = made.project;
    const run = async (proj) => {
      const rr = await renderAndNormalize(proj, { snap: true, crossfadeMs: 0 });
      const rep = buildListenReport(proj, rr.norm.left, rr.norm.right, rr.loop.sampleRate, rr.norm.report, rr.seam);
      return { rr, rep };
    };
    let { rr, rep } = await run(pj);
    let pocket = false;
    if (b.role === 'bed' && rep.speechRoom && rep.speechRoom.verdict !== 'pass') {
      pj.master.speechPocket = true; pj.master.speechDipDb = b.dip ?? -6; pocket = true;
      ({ rr, rep } = await run(pj));
    }
    const row = { pocket, bpm: pj.bpm, bars: pj.bars, pass: rep.mood.pass, score: rep.mood.scores[b.mood], best: rep.mood.best,
      speech: rep.speechRoom && rep.speechRoom.verdict, seam: rep.seam && rep.seam.status, sugg: rep.mood.suggestions, pm: Object.fromEntries(Object.entries(rep.mood.perMetric || {}).map(([k2, v]) => [k2, +(+v.value).toFixed(2)])) };
    const admissible = (b.role !== 'bed' || row.speech === 'pass') && row.seam === 'ok';
    window.__d38 = window.__d38 || {};
    const cur = window.__d38[b.name];
    // rank: a strict pass first, then admissible (speech pass for a bed, seam ok), then the mood score
    const rank = (x) => (x.pass && x.admissible ? 2 : 0) + (x.admissible ? 1 : 0) + x.score;
    if (!cur || rank({ ...row, admissible }) > rank(cur)) {
      window.__d38[b.name] = { score: row.score, pass: row.pass, admissible, wav: encodeWav(rr.norm.left, rr.norm.right, rr.loop.sampleRate, 16, pj.seed || 1),
        report: rep, project: { bpm: pj.bpm, bars: pj.bars, key: pj.key, style: pj.style, master: pj.master, seed: pj.seed }, brief: b, pocket, norm: rr.norm.report };
    }
    return row;
  })(${JSON.stringify(brief)}, ${k})`);
  const fetchBest = (name) => evalIn(sid, `(() => {
    const e = window.__d38 && window.__d38[${JSON.stringify(name)}]; if (!e) return null;
    let s = ''; const w = e.wav; for (let i = 0; i < w.length; i += 0x8000) s += String.fromCharCode.apply(null, w.subarray(i, i + 0x8000));
    return JSON.stringify({ b64: btoa(s), report: e.report, project: e.project, brief: e.brief, pocket: e.pocket, norm: e.norm });
  })()`);
  for (const job of BEDS) {
    if (ONLY && !ONLY.split(',').includes(job.name)) continue;
    const tries = []; let strict = false; let k = 0;
    outer: for (const bb of job.bright) for (const db of job.dens) for (let n = 0; n < job.seeds; n++) {
      const brief = { role: job.role, mood: job.mood, seconds: job.seconds, seed: job.seed + n * 37, style: job.style,
        brightnessBias: bb, densityBias: db, ...(job.targetBpm ? { targetBpm: job.targetBpm } : {}), ...(job.dip ? { dip: job.dip } : {}), name: 'bellmire_' + job.name };
      if (job.seedList) brief.seed = job.seedList[n % job.seedList.length];
      const row = { bb, db, seed: brief.seed, ...(await tryOne(brief, k++)) };
      tries.push(row);
      log('TRY', job.name, JSON.stringify({ bb, db, seed: brief.seed, pass: row.pass, score: row.score && +row.score.toFixed(3), best: row.best, speech: row.speech, seam: row.seam, pocket: row.pocket, pm: row.pm, err: row.error }));
      if (row.pass === true && (job.role !== 'bed' || row.speech === 'pass') && row.seam === 'ok') { strict = true; break outer; }
    }
    const got = await fetchBest('bellmire_' + job.name);
    if (!got) { log('BED', job.name, 'NOTHING ADMISSIBLE'); summary.beds.push({ name: job.name, ok: false, tries }); continue; }
    const e = JSON.parse(got);
    fs.writeFileSync(path.join(OUT, job.name + '.wav'), Buffer.from(e.b64, 'base64'));
    const r = e.report;
    const rec = { name: job.name, mapping: { style: job.style, mood: job.mood, role: job.role }, brief: e.brief, pocket: e.pocket,
      project: e.project, norm: e.norm, searched: tries.length, strictPass: strict,
      moodPass: r.mood.pass, moodScore: r.mood.scores[job.mood], moodBest: r.mood.best, suggestions: r.mood.suggestions,
      speechRoom: r.speechRoom, seam: r.seam && r.seam.status, paragraph: r.summary && r.summary.paragraph };
    fs.writeFileSync(path.join(OUT, job.name + '.listen.json'), JSON.stringify(r, null, 2));
    fs.writeFileSync(path.join(OUT, job.name + '.d38.json'), JSON.stringify({ ...rec, tries }, null, 2));
    summary.beds.push(rec);
    log('BED', job.name, JSON.stringify({ moodPass: rec.moodPass, score: rec.moodScore, speech: r.speechRoom && r.speechRoom.verdict, seam: rec.seam, brief: rec.brief }));
  }

  for (const st of (process.env.D38_NOSTING ? [] : STINGS)) {
    const b64 = await evalIn(sid, `(async (st) => {
      const { renderSting } = await import('/src/audio/render/offline.ts');
      const { normalizeToTarget } = await import('/src/dsp/normalize.ts');
      const { encodeWav } = await import('/src/audio/render/wav.ts');
      const p = { duration: st.duration, pitch: st.pitch, brightness: st.brightness, intensity: st.intensity, seed: st.seed };
      const buf = await renderSting(st.preset, p);
      const proj = window.musicStudio.getProject();
      const norm = normalizeToTarget(buf.left, buf.right, 44100, { targetLufs: proj.master.targetLufs, ceilingDbtp: proj.master.ceilingDbtp });
      const wav = encodeWav(norm.left, norm.right, 44100, 16, st.seed);
      let s = ''; for (let i = 0; i < wav.length; i += 0x8000) s += String.fromCharCode.apply(null, wav.subarray(i, i + 0x8000));
      return JSON.stringify({ b64: btoa(s), report: norm.report || null });
    })(${JSON.stringify(st)})`);
    const o = JSON.parse(b64);
    fs.writeFileSync(path.join(OUT, st.name + '.wav'), Buffer.from(o.b64, 'base64'));
    summary.stings.push({ ...st, norm: o.report });
    log('STING', st.name, JSON.stringify(o.report));
  }
  fs.writeFileSync(path.join(OUT, 'summary.json'), JSON.stringify(summary, null, 2));
  log('D38_GEN DONE');
}
main().then(() => { cleanup(); process.exit(0); }, (e) => { log('D38_GEN FAIL', e && e.stack || String(e)); cleanup(); process.exit(1); });
