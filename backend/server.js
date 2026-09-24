'use strict';
// دليني الأقصى - الخادم. بدون Express: Node فقط (+ pg عند وجود DATABASE_URL).
const http = require('http');
const crypto = require('crypto');
const util = require('util');
const { sendEmail, gateway } = require('./mailer');
const { createStore } = require('./store');

const scrypt = util.promisify(crypto.scrypt);
const PORT = Number(process.env.PORT) || 10000;
const PROD = process.env.NODE_ENV === 'production';
const RESET_DEMO = process.env.RESET_DEMO_MODE === 'true' && !PROD;
const CODE_SECRET = process.env.CODE_SECRET || 'dev-only-secret-change-me';
const SESSION_MS = 30 * 24 * 3600 * 1000;
const RESET_MIN = 10;
const store = createStore();

if (PROD && !process.env.CODE_SECRET) console.warn('[warn] CODE_SECRET غير مضبوط في الإنتاج');

// ---------- ثوابت ----------
const CATEGORIES = [
  { id: 'emergency', name: 'طوارئ' }, { id: 'transport', name: 'نقل' },
  { id: 'electricity', name: 'كهرباء' }, { id: 'plumbing', name: 'سباكة' },
  { id: 'ac', name: 'تكييف' }, { id: 'appliances', name: 'صيانة أجهزة' },
  { id: 'cleaning', name: 'تنظيف' }, { id: 'cars', name: 'سيارات' },
];
const CAT_IDS = CATEGORIES.map((c) => c.id);
const OPEN = ['matching', 'offer'];
const FLOW = ['accepted', 'on_way', 'arrived', 'in_progress', 'completed'];
const CANCELLABLE = ['matching', 'offer', 'accepted', 'on_way', 'arrived'];
const ACTIVE = ['accepted', 'on_way', 'arrived', 'in_progress'];
const HISTORY = ['completed', 'cancelled'];
const ID_RX = /^[0-9a-f-]{36}$/;
const EMAIL_RX = /^[^\s@]{1,64}@[^\s@]{1,255}\.[^\s@]{2,}$/;

// ---------- أدوات ----------
const sha = (s) => crypto.createHash('sha256').update(s).digest('hex');
const normEmail = (e) => String(e || '').trim().toLowerCase();
const validEmail = (e) => e.length <= 254 && EMAIL_RX.test(e);
const codeHash = (email, code) => crypto.createHmac('sha256', CODE_SECRET).update(email + ':' + code).digest('hex');
const pubUser = (u) => ({ id: u.id, name: u.name, email: u.email, role: u.role, created_at: u.created_at });

async function hashPassword(p) {
  const salt = crypto.randomBytes(16).toString('hex');
  return salt + ':' + (await scrypt(p, salt, 64)).toString('hex');
}
async function verifyPassword(p, stored) {
  const [salt, hex] = String(stored || '').split(':');
  if (!salt || !hex) return false;
  const a = Buffer.from(hex, 'hex'); const b = await scrypt(p, salt, a.length || 64);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}
let dummy;
async function dummyVerify(p) { dummy = dummy || (await hashPassword('dummy-password')); await verifyPassword(p, dummy); }

async function startSession(uid) {
  const token = crypto.randomBytes(32).toString('hex');
  await store.addSession(sha(token), uid);
  return token;
}

// ---------- محدد المعدل ----------
const hits = new Map();
setInterval(() => { const n = Date.now(); for (const [k, v] of hits) if (v.reset < n) hits.delete(k); }, 60000).unref();
function rl(name, max, windowMs, keyFn) {
  return async (c) => {
    const key = name + ':' + (keyFn ? keyFn(c) : c.ip);
    const n = Date.now(); let h = hits.get(key);
    if (!h || h.reset < n) { h = { n: 0, reset: n + windowMs }; hits.set(key, h); }
    h.n += 1;
    if (h.n > max) { c.res.setHeader('Retry-After', String(Math.ceil((h.reset - n) / 1000))); c.fail(429, 'محاولات كثيرة، حاول لاحقاً'); return true; }
    return false;
  };
}
const emailKey = (c) => normEmail(c.body && c.body.email);

// ---------- الراوتر ----------
const routes = [];
function route(method, path, mws, handler) {
  const keys = [];
  const rx = new RegExp('^' + path.replace(/:([a-zA-Z]+)/g, (_, k) => { keys.push(k); return '([^/]+)'; }) + '/?$');
  routes.push({ method, rx, keys, mws, handler });
}

const auth = async (c) => {
  const h = String(c.req.headers.authorization || '');
  const token = h.startsWith('Bearer ') ? h.slice(7).trim() : '';
  if (!token) { c.fail(401, 'سجّل الدخول أولاً'); return true; }
  const th = sha(token);
  const uid = await store.sessionUserId(th, SESSION_MS);
  const u = uid ? await store.userById(uid) : null;
  if (!u) { c.fail(401, 'انتهت الجلسة، سجّل الدخول من جديد'); return true; }
  c.user = u; c.tokenHash = th; return false;
};
const only = (role) => async (c) => {
  if (c.user.role !== role) { c.fail(403, 'هذه العملية غير متاحة لحسابك'); return true; }
  return false;
};

// ---------- عروض البيانات ----------
async function ownerView(r) {
  const list = await store.offersForRequest(r.id);
  const offers = [];
  for (const o of list) {
    const p = await store.userById(o.provider_id);
    const stat = (await store.ratingStatsForProviders([o.provider_id]))[o.provider_id] || null;
    offers.push({ id: o.id, provider_id: o.provider_id, provider_name: p ? p.name : 'فني', price: o.price, eta_minutes: o.eta_minutes, created_at: o.created_at, rating: stat });
  }
  offers.sort((a, b) => a.price - b.price);
  let provider = null;
  if (r.provider_id) { const p = await store.userById(r.provider_id); if (p) provider = { id: p.id, name: p.name }; }
  const myRating = await store.ratingForRequest(r.id);
  return { id: r.id, category: r.category, description: r.description, area: r.area, address: r.address, status: r.status, created_at: r.created_at, provider, offers, events: await store.eventsFor(r.id), my_rating: myRating };
}
async function jobView(r) {
  const c = await store.userById(r.user_id);
  const i = FLOW.indexOf(r.status);
  return { id: r.id, category: r.category, description: r.description, area: r.area, address: r.address, status: r.status, created_at: r.created_at, customer_name: c ? c.name : '', allowed_next: i >= 0 && i < FLOW.length - 1 ? FLOW[i + 1] : null, events: await store.eventsFor(r.id) };
}
const getReq = async (id) => (ID_RX.test(id) ? store.requestById(id) : null);

// ---------- عام ----------
route('GET', '/', [], (c) => c.json(200, { name: 'Dalini Aqsa API', ok: true }));
route('GET', '/api/health', [], (c) => c.json(200, { ok: true, service: 'dalini-aqsa', storage: store.kind, email: gateway() }));
route('GET', '/api/categories', [], (c) => c.json(200, { categories: CATEGORIES }));

// ---------- الحساب ----------
route('POST', '/api/auth/register', [rl('reg', 10, 3600e3)], async (c) => {
  const name = String(c.body.name || '').trim().replace(/\s+/g, ' ');
  const email = normEmail(c.body.email);
  const password = String(c.body.password || '');
  const role = c.body.role === 'provider' ? 'provider' : 'customer';
  if (name.length < 2 || name.length > 60) return c.fail(400, 'اكتب اسمك (من حرفين إلى 60 حرفاً)');
  if (!validEmail(email)) return c.fail(400, 'أدخل بريداً إلكترونياً صحيحاً');
  if (password.length < 8 || password.length > 128) return c.fail(400, 'كلمة المرور يجب أن تكون 8 أحرف على الأقل');
  try {
    const u = await store.createUser({ id: crypto.randomUUID(), name, email, password_hash: await hashPassword(password), role });
    return c.json(201, { token: await startSession(u.id), user: pubUser(u) });
  } catch (e) {
    if (e.code === 'DUP_EMAIL') return c.fail(409, 'هذا البريد مسجّل مسبقاً');
    throw e;
  }
});

route('POST', '/api/auth/login', [rl('login-ip', 30, 900e3), rl('login-email', 8, 900e3, emailKey)], async (c) => {
  const email = normEmail(c.body.email); const password = String(c.body.password || '');
  if (!validEmail(email) || !password) return c.fail(400, 'أدخل البريد وكلمة المرور');
  const u = await store.userByEmail(email);
  if (!u) { await dummyVerify(password); return c.fail(401, 'البريد أو كلمة المرور غير صحيحة'); }
  if (!(await verifyPassword(password, u.password_hash))) return c.fail(401, 'البريد أو كلمة المرور غير صحيحة');
  return c.json(200, { token: await startSession(u.id), user: pubUser(u) });
});

route('GET', '/api/auth/me', [auth], (c) => c.json(200, { user: pubUser(c.user) }));

route('POST', '/api/auth/logout', [auth], async (c) => { await store.delSession(c.tokenHash); c.json(200, { ok: true }); });

route('PUT', '/api/profile', [auth], async (c) => {
  const name = String(c.body.name || '').trim().replace(/\s+/g, ' ');
  if (name.length < 2 || name.length > 60) return c.fail(400, 'اكتب اسمك (من حرفين إلى 60 حرفاً)');
  await store.updateName(c.user.id, name);
  return c.json(200, { user: pubUser({ ...c.user, name }) });
});

route('POST', '/api/auth/change-password', [auth, rl('chpw', 10, 3600e3, (c) => c.user.id)], async (c) => {
  const cur = String(c.body.currentPassword || ''); const next = String(c.body.newPassword || '');
  if (next.length < 8 || next.length > 128) return c.fail(400, 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل');
  if (!(await verifyPassword(cur, c.user.password_hash))) return c.fail(400, 'كلمة المرور الحالية غير صحيحة');
  await store.setPassword(c.user.id, await hashPassword(next));
  await store.delUserSessions(c.user.id, c.tokenHash);
  return c.json(200, { ok: true });
});

// ---------- استرجاع كلمة المرور بالبريد ----------
const GENERIC_FORGOT = 'إن كان البريد مسجلاً فسيصلك رمز التحقق خلال دقائق';
route('POST', '/api/auth/forgot-password', [rl('fg-ip', 10, 3600e3), rl('fg-email', 3, 3600e3, emailKey)], async (c) => {
  const email = normEmail(c.body.email);
  if (!validEmail(email)) return c.fail(400, 'أدخل بريداً إلكترونياً صحيحاً');
  const u = await store.userByEmail(email);
  const out = { ok: true, message: GENERIC_FORGOT };
  if (!u) return c.json(200, out);
  const prev = await store.getReset(email);
  if (prev && Date.now() - prev.created < 60000) return c.json(200, out); // مهلة 60 ثانية بين الرموز
  const code = String(crypto.randomInt(100000, 1000000));
  await store.saveReset(email, codeHash(email, code), Date.now() + RESET_MIN * 60000);
  // الإرسال بدون انتظار كي لا يختلف زمن الاستجابة بين بريد موجود وغير موجود
  sendEmail(email, 'رمز استرجاع كلمة المرور - دليني الأقصى',
    `رمز التحقق الخاص بك: ${code}\nصالح لمدة ${RESET_MIN} دقائق.\nإن لم تطلب هذا الرمز فتجاهل الرسالة.`)
    .then((r) => { if (!r.sent) console.warn('[mail] لم يُرسل:', r.gateway, r.reason); });
  if (RESET_DEMO) out.devCode = code;
  return c.json(200, out);
});

route('POST', '/api/auth/reset-password', [rl('rs-ip', 20, 3600e3), rl('rs-email', 10, 3600e3, emailKey)], async (c) => {
  const email = normEmail(c.body.email); const code = String(c.body.code || '').trim(); const next = String(c.body.newPassword || '');
  if (!validEmail(email)) return c.fail(400, 'أدخل بريداً إلكترونياً صحيحاً');
  if (!/^\d{6}$/.test(code)) return c.fail(400, 'رمز التحقق مكوّن من 6 أرقام');
  if (next.length < 8 || next.length > 128) return c.fail(400, 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل');
  const row = await store.getReset(email);
  if (!row || row.expires < Date.now()) return c.fail(400, 'الرمز غير صحيح أو منتهي');
  if (row.attempts >= 5) return c.fail(429, 'تجاوزت عدد المحاولات، اطلب رمزاً جديداً');
  const a = Buffer.from(codeHash(email, code)); const b = Buffer.from(row.code_hash);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) { await store.bumpReset(email); return c.fail(400, 'الرمز غير صحيح أو منتهي'); }
  const u = await store.userByEmail(email);
  if (!u) return c.fail(400, 'الرمز غير صحيح أو منتهي');
  await store.setPassword(u.id, await hashPassword(next));
  await store.delUserSessions(u.id, '');
  await store.delReset(email);
  return c.json(200, { ok: true, message: 'تم تغيير كلمة المرور، سجّل الدخول الآن' });
});

// ---------- الزبون: الطلبات ----------
route('POST', '/api/requests', [auth, only('customer'), rl('req-new', 20, 3600e3, (c) => c.user.id)], async (c) => {
  const category = String(c.body.category || ''); const description = String(c.body.description || '').trim();
  const area = String(c.body.area || '').trim(); const address = String(c.body.address || '').trim();
  if (!CAT_IDS.includes(category)) return c.fail(400, 'اختر نوع الخدمة');
  if (description.length < 4 || description.length > 2000) return c.fail(400, 'اشرح المشكلة بجملة واضحة (4 أحرف على الأقل)');
  if (area.length < 2 || area.length > 80) return c.fail(400, 'اكتب المنطقة، مثال: الكرادة');
  if (address.length > 300) return c.fail(400, 'العنوان طويل جداً');
  const r = await store.createRequest({ id: crypto.randomUUID(), user_id: c.user.id, category, description, area, address });
  await store.addEvent(r.id, 'matching', 'customer', 'تم إرسال الطلب');
  return c.json(201, { request: { id: r.id, category, description, area, status: r.status, created_at: r.created_at } });
});

route('GET', '/api/requests/mine', [auth, only('customer')], async (c) => {
  const list = await store.requestsByUser(c.user.id);
  const counts = await store.offerCounts(list.map((r) => r.id));
  return c.json(200, { requests: list.map((r) => ({ id: r.id, category: r.category, description: r.description, area: r.area, status: r.status, created_at: r.created_at, offers_count: counts[r.id] || 0 })) });
});

route('GET', '/api/requests/:id', [auth], async (c) => {
  const r = await getReq(c.params.id);
  if (r && r.user_id === c.user.id) return c.json(200, { request: await ownerView(r) });
  if (r && r.provider_id === c.user.id) return c.json(200, { request: await jobView(r) });
  return c.fail(404, 'الطلب غير موجود');
});

route('POST', '/api/requests/:id/accept-offer', [auth, only('customer')], async (c) => {
  const r = await getReq(c.params.id);
  if (!r || r.user_id !== c.user.id) return c.fail(404, 'الطلب غير موجود');
  const offerId = String(c.body.offerId || '');
  const o = ID_RX.test(offerId) ? await store.offerById(offerId) : null;
  if (!o || o.request_id !== r.id) return c.fail(400, 'هذا العرض لا يخص هذا الطلب');
  const upd = await store.updateRequestIf(r.id, OPEN, { status: 'accepted', provider_id: o.provider_id });
  if (!upd) return c.fail(409, 'لا يمكن قبول عرض على طلب بهذه الحالة');
  await store.addEvent(r.id, 'accepted', 'customer', 'تم قبول العرض');
  return c.json(200, { request: await ownerView(upd) });
});

route('POST', '/api/requests/:id/cancel', [auth, only('customer')], async (c) => {
  const r = await getReq(c.params.id);
  if (!r || r.user_id !== c.user.id) return c.fail(404, 'الطلب غير موجود');
  const upd = await store.updateRequestIf(r.id, CANCELLABLE, { status: 'cancelled' });
  if (!upd) return c.fail(409, 'لا يمكن إلغاء الطلب بعد بدء التنفيذ');
  await store.addEvent(r.id, 'cancelled', 'customer', 'تم إلغاء الطلب');
  return c.json(200, { request: await ownerView(upd) });
});

// ---------- الفني ----------
route('GET', '/api/providers/requests', [auth, only('provider')], async (c) => {
  const list = await store.openRequests(); const out = [];
  for (const r of list) {
    const mine = await store.offerOf(r.id, c.user.id);
    // بدون user_id أو العنوان الدقيق: يظهر للفني بعد قبول الزبون لعرضه فقط
    out.push({ id: r.id, category: r.category, description: r.description, area: r.area, status: r.status, created_at: r.created_at, my_offer: mine ? { price: mine.price, eta_minutes: mine.eta_minutes } : null });
  }
  return c.json(200, { requests: out });
});

route('POST', '/api/providers/requests/:id/offer', [auth, only('provider'), rl('offer', 60, 3600e3, (c) => c.user.id)], async (c) => {
  const r = await getReq(c.params.id);
  if (!r || !OPEN.includes(r.status)) return c.fail(404, 'الطلب غير متاح');
  const price = Number(c.body.price); const eta = Number(c.body.etaMinutes);
  if (!Number.isInteger(price) || price < 1000 || price > 100000000) return c.fail(400, 'أدخل سعراً صحيحاً (1,000 دينار على الأقل)');
  if (!Number.isInteger(eta) || eta < 5 || eta > 1440) return c.fail(400, 'أدخل وقت الوصول بالدقائق (5 إلى 1440)');
  const { offer, created } = await store.upsertOffer({ id: crypto.randomUUID(), request_id: r.id, provider_id: c.user.id, price, eta_minutes: eta });
  await store.updateRequestIf(r.id, ['matching'], { status: 'offer' });
  if (created) await store.addEvent(r.id, 'offer', 'provider', 'وصل عرض جديد');
  return c.json(created ? 201 : 200, { offer: { id: offer.id, price: offer.price, eta_minutes: offer.eta_minutes } });
});

route('GET', '/api/providers/jobs', [auth, only('provider')], async (c) => {
  const statuses = c.query.get('filter') === 'history' ? HISTORY : ACTIVE;
  const list = await store.jobsByProvider(c.user.id, statuses);
  const out = []; for (const r of list) out.push(await jobView(r));
  return c.json(200, { jobs: out });
});

route('POST', '/api/providers/requests/:id/status', [auth, only('provider')], async (c) => {
  const r = await getReq(c.params.id);
  if (!r || r.provider_id !== c.user.id) return c.fail(404, 'الطلب غير موجود');
  const next = String(c.body.status || '');
  const i = FLOW.indexOf(r.status);
  if (i < 0 || FLOW[i + 1] !== next) return c.json(409, { error: 'لا يمكن تغيير الحالة بهذا الترتيب', allowed_next: i >= 0 ? FLOW[i + 1] || null : null });
  const upd = await store.updateRequestIf(r.id, [r.status], { status: next });
  if (!upd) return c.fail(409, 'تغيّرت حالة الطلب، حدّث الصفحة');
  await store.addEvent(r.id, next, 'provider', '');
  return c.json(200, { request: await jobView(upd) });
});

// ---------- التقييمات ----------
route('POST', '/api/requests/:id/rate', [auth, only('customer')], async (c) => {
  const r = await getReq(c.params.id);
  if (!r || r.user_id !== c.user.id) return c.fail(404, 'الطلب غير موجود');
  if (r.status !== 'completed') return c.fail(409, 'لا يمكن تقييم طلب غير مكتمل');
  if (!r.provider_id) return c.fail(409, 'لا يوجد فني لطلبك');
  const stars = Number(c.body.stars);
  const comment = String(c.body.comment || '').trim().slice(0, 500);
  if (!Number.isInteger(stars) || stars < 1 || stars > 5) return c.fail(400, 'أدخل تقييماً من 1 إلى 5 نجوم');
  try {
    const r2 = await store.addRating({ id: crypto.randomUUID(), request_id: r.id, customer_id: c.user.id, provider_id: r.provider_id, stars, comment });
    return c.json(201, { rating: r2 });
  } catch (e) {
    if (e.code === 'DUP_RATING') return c.fail(409, 'لقد قيّمت هذا الطلب سابقاً');
    throw e;
  }
});

route('GET', '/api/providers/:id/ratings', [auth], async (c) => {
  const pid = c.params.id;
  if (!ID_RX.test(pid)) return c.fail(400, 'معرّف غير صحيح');
  const list = await store.ratingsForProvider(pid);
  const stats = (await store.ratingStatsForProviders([pid]))[pid] || { avg: 0, count: 0 };
  return c.json(200, { ratings: list, stats });
});

route('GET', '/api/providers/me/rating-stats', [auth, only('provider')], async (c) => {
  const stats = (await store.ratingStatsForProviders([c.user.id]))[c.user.id] || { avg: 0, count: 0 };
  return c.json(200, { stats });
});

// ---------- المحادثات ----------
route('GET', '/api/requests/:id/messages', [auth], async (c) => {
  const r = await getReq(c.params.id);
  if (!r) return c.fail(404, 'الطلب غير موجود');
  const isOwner = r.user_id === c.user.id;
  const isProvider = r.provider_id === c.user.id;
  if (!isOwner && !isProvider) return c.fail(404, 'الطلب غير موجود');
  if (!r.provider_id) return c.fail(409, 'لم يُقبل أي عرض بعد');
  const list = await store.messagesFor(r.id);
  return c.json(200, { messages: list });
});

route('POST', '/api/requests/:id/messages', [auth, rl('msg', 60, 60e3, (c) => c.user.id)], async (c) => {
  const r = await getReq(c.params.id);
  if (!r) return c.fail(404, 'الطلب غير موجود');
  const isOwner = r.user_id === c.user.id;
  const isProvider = r.provider_id === c.user.id;
  if (!isOwner && !isProvider) return c.fail(404, 'الطلب غير موجود');
  if (!r.provider_id) return c.fail(409, 'لم يُقبل أي عرض بعد');
  const text = String(c.body.text || '').trim();
  if (text.length < 1 || text.length > 2000) return c.fail(400, 'اكتب رسالة (1-2000 حرف)');
  const role = isOwner ? 'customer' : 'provider';
  const m = await store.addMessage({ id: crypto.randomUUID(), request_id: r.id, sender_id: c.user.id, sender_role: role, text });
  return c.json(201, { message: m });
});

// ---------- الخادم ----------
function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0; const chunks = [];
    req.on('data', (d) => { size += d.length; if (size > 65536) { reject(Object.assign(new Error('big'), { status: 413 })); req.destroy(); } else chunks.push(d); });
    req.on('end', () => {
      if (!chunks.length) return resolve({});
      try { const o = JSON.parse(Buffer.concat(chunks).toString('utf8')); resolve(o && typeof o === 'object' && !Array.isArray(o) ? o : {}); }
      catch (e) { reject(Object.assign(new Error('bad json'), { status: 400 })); }
    });
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  const c = { req, res, user: null, body: {}, params: {}, ip: '' };
  c.json = (status, obj) => {
    res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
    res.end(JSON.stringify(obj));
  };
  c.fail = (status, msg) => c.json(status, { error: msg });
  try {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,OPTIONS');
    if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
    const xf = String(req.headers['x-forwarded-for'] || '');
    c.ip = process.env.TRUST_PROXY === 'false' || !xf ? req.socket.remoteAddress || 'x' : xf.split(',').pop().trim();
    const url = new URL(req.url, 'http://local'); c.query = url.searchParams;
    let match = null, pathHit = false;
    for (const r of routes) {
      const m = url.pathname.match(r.rx); if (!m) continue;
      pathHit = true; if (r.method !== req.method) continue;
      match = r; r.keys.forEach((k, i) => { c.params[k] = decodeURIComponent(m[i + 1]); }); break;
    }
    if (!match) return c.fail(pathHit ? 405 : 404, pathHit ? 'الطريقة غير مسموحة' : 'المسار غير موجود');
    if (['POST', 'PUT'].includes(req.method)) c.body = await readBody(req);
    if (!(await rl('all', 300, 60000)(c))) {
      for (const mw of match.mws) { if (await mw(c)) return; }
      await match.handler(c);
    }
  } catch (e) {
    if (e.status === 400 || e.status === 413) return c.fail(e.status, e.status === 413 ? 'الطلب كبير جداً' : 'صيغة الطلب غير صحيحة');
    console.error('[error]', req.method, req.url, e && e.message);
    if (!res.headersSent) c.fail(500, 'حدث خطأ في الخادم، حاول لاحقاً');
  }
});

process.on('unhandledRejection', (e) => console.error('[unhandledRejection]', e && e.message));

store.init().then(() => {
  server.listen(PORT, () => console.log(`Dalini Aqsa API on :${PORT} (storage=${store.kind}, email=${gateway()})`));
}).catch((e) => { console.error('فشل تهيئة قاعدة البيانات:', e.message); process.exit(1); });
