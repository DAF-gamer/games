// Visitor counter for fightscramble.com (Cloudflare Pages Function, served at /api/visits).
// Needs a D1 database bound to this Pages project under the variable name DB.
// The table is created automatically on first use.
//   POST /api/visits -> records one page view for this visitor (each page calls this once on load)
//   GET  /api/visits -> {today, week, people, views, since}
// A "person" is one IP address (stored only as a salted hash), counted once per day.

const HDR = {
  'content-type': 'application/json',
  'access-control-allow-origin': '*', // so the local stats file can read the numbers
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'cache-control': 'no-store',
};
const json = (o, status = 200) => new Response(JSON.stringify(o), { status, headers: HDR });
const BOT = /bot|crawl|spider|slurp|headless|preview|lighthouse/i;
const day = (ms) => new Date(ms).toISOString().slice(0, 10); // UTC date

let ready = false;
async function setup(db) {
  if (ready) return;
  await db.prepare('CREATE TABLE IF NOT EXISTS visits (day TEXT NOT NULL, who TEXT NOT NULL, n INTEGER NOT NULL, PRIMARY KEY (day, who))').run();
  ready = true;
}

async function hash(s) {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('fightscramble-visits:' + s));
  return [...new Uint8Array(d)].slice(0, 12).map(b => b.toString(16).padStart(2, '0')).join('');
}

export const onRequestOptions = () => new Response(null, { status: 204, headers: HDR });

export async function onRequestPost({ request, env }) {
  if (!env.DB) return json({ error: 'Visitor counter is not set up yet.' }, 503);
  if (BOT.test(request.headers.get('user-agent') || '')) return json({ ok: true });
  await setup(env.DB);
  const who = await hash(request.headers.get('cf-connecting-ip') || 'local');
  await env.DB.prepare('INSERT INTO visits (day, who, n) VALUES (?, ?, 1) ON CONFLICT (day, who) DO UPDATE SET n = n + 1')
    .bind(day(Date.now()), who).run();
  return json({ ok: true });
}

export async function onRequestGet({ env }) {
  if (!env.DB) return json({ error: 'Visitor counter is not set up yet.' }, 503);
  await setup(env.DB);
  const now = Date.now();
  const r = await env.DB.prepare(`SELECT
      (SELECT COUNT(*) FROM visits WHERE day = ?) AS today,
      (SELECT COUNT(DISTINCT who) FROM visits WHERE day >= ?) AS week,
      (SELECT COUNT(DISTINCT who) FROM visits) AS people,
      (SELECT COALESCE(SUM(n), 0) FROM visits) AS views,
      (SELECT MIN(day) FROM visits) AS since`).bind(day(now), day(now - 6 * 864e5)).first();
  return json(r);
}
