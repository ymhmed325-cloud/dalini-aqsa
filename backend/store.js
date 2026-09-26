'use strict';
// طبقة التخزين: ذاكرة (للتجربة) أو PostgreSQL. كل الجداول بالبادئة aq_ حتى لا تتعارض مع المشروع القديم.

const SCHEMA = [
  `CREATE TABLE IF NOT EXISTS aq_users (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'customer',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS aq_sessions (
    token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES aq_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS aq_resets (
    email TEXT PRIMARY KEY, code_hash TEXT NOT NULL, expires BIGINT NOT NULL,
    created BIGINT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0)`,
  `CREATE TABLE IF NOT EXISTS aq_requests (
    id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES aq_users(id) ON DELETE CASCADE,
    category TEXT NOT NULL, description TEXT NOT NULL, area TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'matching',
    provider_id TEXT REFERENCES aq_users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS aq_offers (
    id TEXT PRIMARY KEY, request_id TEXT NOT NULL REFERENCES aq_requests(id) ON DELETE CASCADE,
    provider_id TEXT NOT NULL REFERENCES aq_users(id) ON DELETE CASCADE,
    price INTEGER NOT NULL, eta_minutes INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), UNIQUE (request_id, provider_id))`,
  `CREATE TABLE IF NOT EXISTS aq_events (
    id SERIAL PRIMARY KEY, request_id TEXT NOT NULL REFERENCES aq_requests(id) ON DELETE CASCADE,
    status TEXT NOT NULL, actor TEXT NOT NULL, note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS aq_ratings (
    id TEXT PRIMARY KEY, request_id TEXT NOT NULL REFERENCES aq_requests(id) ON DELETE CASCADE,
    customer_id TEXT NOT NULL REFERENCES aq_users(id) ON DELETE CASCADE,
    provider_id TEXT NOT NULL REFERENCES aq_users(id) ON DELETE CASCADE,
    stars INTEGER NOT NULL, comment TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), UNIQUE (request_id))`,
  `CREATE TABLE IF NOT EXISTS aq_messages (
    id TEXT PRIMARY KEY, request_id TEXT NOT NULL REFERENCES aq_requests(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL REFERENCES aq_users(id) ON DELETE CASCADE,
    sender_role TEXT NOT NULL, text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE INDEX IF NOT EXISTS aq_messages_request_idx ON aq_messages (request_id)`,
  `CREATE TABLE IF NOT EXISTS aq_subscriptions (
    user_id TEXT PRIMARY KEY REFERENCES aq_users(id) ON DELETE CASCADE,
    plan TEXT NOT NULL DEFAULT 'free',
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    verify_status TEXT NOT NULL DEFAULT 'none',
    expires_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE INDEX IF NOT EXISTS aq_requests_user_idx ON aq_requests (user_id)`,
  `CREATE INDEX IF NOT EXISTS aq_requests_status_idx ON aq_requests (status)`,
  `CREATE INDEX IF NOT EXISTS aq_offers_request_idx ON aq_offers (request_id)`,
];

function dupError() { const e = new Error('duplicate'); e.code = 'DUP_EMAIL'; return e; }

const RATING = (r) => (r ? { id: r.id, request_id: r.request_id, customer_id: r.customer_id, provider_id: r.provider_id, stars: r.stars, comment: r.comment, created_at: (r.created_at instanceof Date ? r.created_at.toISOString() : r.created_at) } : null);

const MSG = (r) => (r ? { id: r.id, request_id: r.request_id, sender_id: r.sender_id, sender_role: r.sender_role, text: r.text, created_at: (r.created_at instanceof Date ? r.created_at.toISOString() : r.created_at) } : null);

const SUB = (r) => (r ? { user_id: r.user_id, plan: r.plan, verified: r.verified, verify_status: r.verify_status, expires_at: (r.expires_at instanceof Date ? r.expires_at.toISOString() : r.expires_at) } : null);

function memoryStore() {
  const users = new Map(), byEmail = new Map(), sessions = new Map(), resets = new Map();
  const requests = new Map(), offers = new Map(); const events = []; const ratings = new Map(); const messages = new Map(); const subs = new Map();
  const now = () => new Date().toISOString();
  return {
    kind: 'memory',
    async init() {},
    async createUser(u) {
      if (byEmail.has(u.email)) throw dupError();
      const row = { ...u, created_at: now() };
      users.set(row.id, row); byEmail.set(row.email, row.id); return { ...row };
    },
    async userByEmail(e) { const id = byEmail.get(e); return id ? { ...users.get(id) } : null; },
    async userById(id) { const u = users.get(id); return u ? { ...u } : null; },
    async updateName(id, name) { const u = users.get(id); if (u) u.name = name; },
    async setPassword(id, h) { const u = users.get(id); if (u) u.password_hash = h; },
    async addSession(th, uid) { sessions.set(th, { user_id: uid, at: Date.now() }); },
    async sessionUserId(th, maxAge) {
      const s = sessions.get(th); if (!s) return null;
      if (Date.now() - s.at > maxAge) { sessions.delete(th); return null; }
      return s.user_id;
    },
    async delSession(th) { sessions.delete(th); },
    async delUserSessions(uid, except) {
      for (const [k, v] of [...sessions]) if (v.user_id === uid && k !== except) sessions.delete(k);
    },
    async saveReset(email, codeHash, expires) { resets.set(email, { code_hash: codeHash, expires, created: Date.now(), attempts: 0 }); },
    async getReset(email) { const r = resets.get(email); return r ? { ...r } : null; },
    async bumpReset(email) { const r = resets.get(email); if (r) r.attempts += 1; },
    async delReset(email) { resets.delete(email); },
    async createRequest(r) {
      const row = { ...r, status: 'matching', provider_id: null, created_at: now(), updated_at: now() };
      requests.set(row.id, row); return { ...row };
    },
    async requestById(id) { const r = requests.get(id); return r ? { ...r } : null; },
    async requestsByUser(uid) {
      return [...requests.values()].filter((r) => r.user_id === uid).sort((a, b) => b.created_at.localeCompare(a.created_at)).map((r) => ({ ...r }));
    },
    async openRequests() {
      return [...requests.values()].filter((r) => r.status === 'matching' || r.status === 'offer').sort((a, b) => b.created_at.localeCompare(a.created_at)).map((r) => ({ ...r }));
    },
    async jobsByProvider(pid, statuses) {
      return [...requests.values()].filter((r) => r.provider_id === pid && statuses.includes(r.status)).sort((a, b) => b.updated_at.localeCompare(a.updated_at)).map((r) => ({ ...r }));
    },
    async updateRequestIf(id, expected, patch) {
      const r = requests.get(id);
      if (!r || !expected.includes(r.status)) return null;
      r.status = patch.status; if (patch.provider_id) r.provider_id = patch.provider_id; r.updated_at = now();
      return { ...r };
    },
    async upsertOffer(o) {
      for (const x of offers.values()) {
        if (x.request_id === o.request_id && x.provider_id === o.provider_id) {
          x.price = o.price; x.eta_minutes = o.eta_minutes; return { offer: { ...x }, created: false };
        }
      }
      const row = { ...o, created_at: now() }; offers.set(row.id, row); return { offer: { ...row }, created: true };
    },
    async offersForRequest(rid) { return [...offers.values()].filter((o) => o.request_id === rid).map((o) => ({ ...o })); },
    async offerById(id) { const o = offers.get(id); return o ? { ...o } : null; },
    async offerOf(rid, pid) {
      for (const o of offers.values()) if (o.request_id === rid && o.provider_id === pid) return { ...o };
      return null;
    },
    async offerCounts(ids) {
      const out = {}; for (const o of offers.values()) if (ids.includes(o.request_id)) out[o.request_id] = (out[o.request_id] || 0) + 1;
      return out;
    },
    async addRating(r) {
      if (ratings.has(r.request_id)) throw new Error('DUP_RATING');
      const row = { ...r, created_at: now() }; ratings.set(row.id, row); return { ...row };
    },
    async ratingForRequest(rid) {
      for (const x of ratings.values()) if (x.request_id === rid) return { ...x };
      return null;
    },
    async ratingsForProvider(pid) {
      return [...ratings.values()].filter((x) => x.provider_id === pid)
        .sort((a, b) => b.created_at.localeCompare(a.created_at)).map((x) => ({ ...x }));
    },
    async ratingStatsForProviders(ids) {
      const out = {};
      for (const id of ids) {
        const list = [...ratings.values()].filter((x) => x.provider_id === id);
        if (list.length) {
          const sum = list.reduce((a, x) => a + x.stars, 0);
          out[id] = { avg: sum / list.length, count: list.length };
        }
      }
      return out;
    },
    async addMessage(m) {
      const row = { ...m, created_at: now() }; messages.set(row.id, row); return { ...row };
    },
    async messagesFor(rid) {
      return [...messages.values()].filter((x) => x.request_id === rid)
        .sort((a, b) => a.created_at.localeCompare(b.created_at)).map((x) => ({ ...x }));
    },
    async getSub(uid) {
      const s = subs.get(uid);
      return s ? { ...s } : { user_id: uid, plan: 'free', verified: false, verify_status: 'none', expires_at: null };
    },
    async upsertSub(uid, patch) {
      const cur = subs.get(uid) || { user_id: uid, plan: 'free', verified: false, verify_status: 'none', expires_at: null };
      const row = { ...cur, ...patch, updated_at: now() };
      subs.set(uid, row);
      return { ...row };
    },
    async verifiedMap(ids) {
      const out = {};
      for (const id of ids) { const s = subs.get(id); out[id] = s ? s.verified : false; }
      return out;
    },
    async pendingVerifications() {
      return [...subs.values()].filter((x) => x.verify_status === 'pending').map((x) => ({ ...x }));
    },
    async addEvent(rid, status, actor, note) { events.push({ request_id: rid, status, actor, note: note || '', created_at: now() }); },
    async eventsFor(rid) { return events.filter((e) => e.request_id === rid).map(({ status, actor, note, created_at }) => ({ status, actor, note, created_at })); },
  };
}

function pgStore(url) {
  const { Pool } = require('pg');
  const pool = new Pool({
    connectionString: url,
    ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: process.env.DB_SSL_STRICT === 'true' },
    max: 5,
  });
  const iso = (d) => (d instanceof Date ? d.toISOString() : d);
  const q = (sql, p) => pool.query(sql, p);
  const U = (r) => (r ? { id: r.id, name: r.name, email: r.email, role: r.role, password_hash: r.password_hash, created_at: iso(r.created_at) } : null);
  const R = (r) => (r ? { id: r.id, user_id: r.user_id, category: r.category, description: r.description, area: r.area, address: r.address, status: r.status, provider_id: r.provider_id, created_at: iso(r.created_at), updated_at: iso(r.updated_at) } : null);
  const O = (r) => (r ? { id: r.id, request_id: r.request_id, provider_id: r.provider_id, price: r.price, eta_minutes: r.eta_minutes, created_at: iso(r.created_at) } : null);
  return {
    kind: 'postgres',
    async init() { for (const sql of SCHEMA) await q(sql); },
    async createUser(u) {
      try {
        const r = await q('INSERT INTO aq_users (id,name,email,password_hash,role) VALUES ($1,$2,$3,$4,$5) RETURNING *', [u.id, u.name, u.email, u.password_hash, u.role]);
        return U(r.rows[0]);
      } catch (e) { if (e.code === '23505') throw dupError(); throw e; }
    },
    async userByEmail(e) { return U((await q('SELECT * FROM aq_users WHERE email=$1', [e])).rows[0]); },
    async userById(id) { return U((await q('SELECT * FROM aq_users WHERE id=$1', [id])).rows[0]); },
    async updateName(id, name) { await q('UPDATE aq_users SET name=$1 WHERE id=$2', [name, id]); },
    async setPassword(id, h) { await q('UPDATE aq_users SET password_hash=$1 WHERE id=$2', [h, id]); },
    async addSession(th, uid) { await q('INSERT INTO aq_sessions (token_hash,user_id) VALUES ($1,$2)', [th, uid]); },
    async sessionUserId(th, maxAge) {
      const r = await q('SELECT user_id, created_at FROM aq_sessions WHERE token_hash=$1', [th]);
      if (!r.rows[0]) return null;
      if (Date.now() - new Date(r.rows[0].created_at).getTime() > maxAge) { await q('DELETE FROM aq_sessions WHERE token_hash=$1', [th]); return null; }
      return r.rows[0].user_id;
    },
    async delSession(th) { await q('DELETE FROM aq_sessions WHERE token_hash=$1', [th]); },
    async delUserSessions(uid, except) { await q('DELETE FROM aq_sessions WHERE user_id=$1 AND token_hash <> $2', [uid, except || '']); },
    async saveReset(email, codeHash, expires) {
      await q('INSERT INTO aq_resets (email,code_hash,expires,created,attempts) VALUES ($1,$2,$3,$4,0) ON CONFLICT (email) DO UPDATE SET code_hash=$2, expires=$3, created=$4, attempts=0', [email, codeHash, expires, Date.now()]);
    },
    async getReset(email) {
      const r = (await q('SELECT * FROM aq_resets WHERE email=$1', [email])).rows[0];
      return r ? { code_hash: r.code_hash, expires: Number(r.expires), created: Number(r.created), attempts: r.attempts } : null;
    },
    async bumpReset(email) { await q('UPDATE aq_resets SET attempts = attempts + 1 WHERE email=$1', [email]); },
    async delReset(email) { await q('DELETE FROM aq_resets WHERE email=$1', [email]); },
    async createRequest(r) {
      const x = await q('INSERT INTO aq_requests (id,user_id,category,description,area,address) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [r.id, r.user_id, r.category, r.description, r.area, r.address]);
      return R(x.rows[0]);
    },
    async requestById(id) { return R((await q('SELECT * FROM aq_requests WHERE id=$1', [id])).rows[0]); },
    async requestsByUser(uid) { return (await q('SELECT * FROM aq_requests WHERE user_id=$1 ORDER BY created_at DESC LIMIT 200', [uid])).rows.map(R); },
    async openRequests() { return (await q("SELECT * FROM aq_requests WHERE status IN ('matching','offer') ORDER BY created_at DESC LIMIT 100")).rows.map(R); },
    async jobsByProvider(pid, statuses) { return (await q('SELECT * FROM aq_requests WHERE provider_id=$1 AND status = ANY($2) ORDER BY updated_at DESC LIMIT 100', [pid, statuses])).rows.map(R); },
    async updateRequestIf(id, expected, patch) {
      const r = await q('UPDATE aq_requests SET status=$1, provider_id=COALESCE($2, provider_id), updated_at=NOW() WHERE id=$3 AND status = ANY($4) RETURNING *', [patch.status, patch.provider_id || null, id, expected]);
      return R(r.rows[0]);
    },
    async upsertOffer(o) {
      const r = await q('INSERT INTO aq_offers (id,request_id,provider_id,price,eta_minutes) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (request_id,provider_id) DO UPDATE SET price=EXCLUDED.price, eta_minutes=EXCLUDED.eta_minutes RETURNING *, (xmax = 0) AS inserted', [o.id, o.request_id, o.provider_id, o.price, o.eta_minutes]);
      return { offer: O(r.rows[0]), created: r.rows[0].inserted === true };
    },
    async offersForRequest(rid) { return (await q('SELECT * FROM aq_offers WHERE request_id=$1 ORDER BY price ASC', [rid])).rows.map(O); },
    async offerById(id) { return O((await q('SELECT * FROM aq_offers WHERE id=$1', [id])).rows[0]); },
    async offerOf(rid, pid) { return O((await q('SELECT * FROM aq_offers WHERE request_id=$1 AND provider_id=$2', [rid, pid])).rows[0]); },
    async offerCounts(ids) {
      if (!ids.length) return {};
      const r = await q('SELECT request_id, COUNT(*)::int AS n FROM aq_offers WHERE request_id = ANY($1) GROUP BY request_id', [ids]);
      const out = {}; for (const x of r.rows) out[x.request_id] = x.n; return out;
    },
    async addRating(r) {
      try {
        const x = await q('INSERT INTO aq_ratings (id,request_id,customer_id,provider_id,stars,comment) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *', [r.id, r.request_id, r.customer_id, r.provider_id, r.stars, r.comment]);
        return RATING(x.rows[0]);
      } catch (e) { if (e.code === '23505') { const err = new Error('DUP_RATING'); err.code = 'DUP_RATING'; throw err; } throw e; }
    },
    async ratingForRequest(rid) {
      const r = (await q('SELECT * FROM aq_ratings WHERE request_id=$1', [rid])).rows[0];
      return r ? RATING(r) : null;
    },
    async ratingsForProvider(pid) {
      return (await q('SELECT * FROM aq_ratings WHERE provider_id=$1 ORDER BY created_at DESC LIMIT 100', [pid])).rows.map(RATING);
    },
    async ratingStatsForProviders(ids) {
      if (!ids.length) return {};
      const r = await q('SELECT provider_id, AVG(stars)::float AS avg, COUNT(*)::int AS count FROM aq_ratings WHERE provider_id = ANY($1) GROUP BY provider_id', [ids]);
      const out = {};
      for (const x of r.rows) out[x.provider_id] = { avg: x.avg, count: x.count };
      return out;
    },
    async addMessage(m) {
      const x = await q('INSERT INTO aq_messages (id,request_id,sender_id,sender_role,text) VALUES ($1,$2,$3,$4,$5) RETURNING *', [m.id, m.request_id, m.sender_id, m.sender_role, m.text]);
      return MSG(x.rows[0]);
    },
    async messagesFor(rid) {
      return (await q('SELECT * FROM aq_messages WHERE request_id=$1 ORDER BY created_at ASC LIMIT 500', [rid])).rows.map(MSG);
    },
    async getSub(uid) {
      const r = (await q('SELECT * FROM aq_subscriptions WHERE user_id=$1', [uid])).rows[0];
      return r ? SUB(r) : { user_id: uid, plan: 'free', verified: false, verify_status: 'none', expires_at: null };
    },
    async upsertSub(uid, patch) {
      const cur = await this.getSub(uid);
      const merged = { ...cur, ...patch };
      await q('INSERT INTO aq_subscriptions (user_id, plan, verified, verify_status, expires_at) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id) DO UPDATE SET plan=$2, verified=$3, verify_status=$4, expires_at=$5, updated_at=NOW()', [uid, merged.plan, merged.verified, merged.verify_status, merged.expires_at]);
      return await this.getSub(uid);
    },
    async verifiedMap(ids) {
      if (!ids.length) return {};
      const r = await q('SELECT user_id, verified FROM aq_subscriptions WHERE user_id = ANY($1) AND verified = true', [ids]);
      const out = {};
      for (const x of r.rows) out[x.user_id] = true;
      return out;
    },
    async pendingVerifications() {
      return (await q("SELECT * FROM aq_subscriptions WHERE verify_status = 'pending' ORDER BY updated_at DESC LIMIT 100")).rows.map(SUB);
    },
    async addEvent(rid, status, actor, note) { await q('INSERT INTO aq_events (request_id,status,actor,note) VALUES ($1,$2,$3,$4)', [rid, status, actor, note || '']); },
    async eventsFor(rid) {
      return (await q('SELECT status,actor,note,created_at FROM aq_events WHERE request_id=$1 ORDER BY id ASC', [rid])).rows.map((e) => ({ status: e.status, actor: e.actor, note: e.note, created_at: iso(e.created_at) }));
    },
  };
}

function createStore() {
  return process.env.DATABASE_URL ? pgStore(process.env.DATABASE_URL) : memoryStore();
}

module.exports = { createStore };
