'use strict';
// اختبار شامل لمسارات الخادم: يشغّل الخادم بالذاكرة ويجرب التدفق كاملاً.
const { spawn } = require('child_process');
const path = require('path');
const PORT = 4500 + Math.floor(Math.random() * 400);
const BASE = `http://127.0.0.1:${PORT}`;
let passed = 0; const failed = [];

function check(name, cond, extra) {
  if (cond) { passed += 1; console.log('  ✅', name); }
  else { failed.push(name); console.log('  ❌', name, extra !== undefined ? JSON.stringify(extra) : ''); }
}
async function call(method, p, body, token) {
  const r = await fetch(BASE + p, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) }, body: body ? JSON.stringify(body) : undefined });
  let data = null; try { data = await r.json(); } catch (e) { /* no body */ }
  return { status: r.status, data: data || {} };
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const env = { ...process.env, PORT: String(PORT), DATABASE_URL: '', NODE_ENV: 'test', RESET_DEMO_MODE: 'true', RESEND_API_KEY: '', BREVO_API_KEY: '', EMAIL_FROM: '' };
  const srv = spawn('node', [path.join(__dirname, '..', 'server.js')], { env, stdio: ['ignore', 'pipe', 'pipe'] });
  srv.stderr.on('data', (d) => process.stderr.write(d));
  for (let i = 0; i < 50; i++) { try { const h = await fetch(BASE + '/api/health'); if (h.ok) break; } catch (e) { /* wait */ } await sleep(100); }

  try {
    console.log('— عام');
    let r = await call('GET', '/api/health');
    check('health', r.status === 200 && r.data.ok === true && r.data.storage === 'memory', r);
    r = await call('GET', '/api/categories');
    check('categories', r.data.categories && r.data.categories.length === 6);

    console.log('— التسجيل');
    r = await call('POST', '/api/auth/register', { name: 'علي', email: 'bad-email', password: '12345678' });
    check('رفض بريد غير صالح', r.status === 400, r);
    r = await call('POST', '/api/auth/register', { name: 'علي', email: 'ali@example.com', password: '123' });
    check('رفض كلمة مرور قصيرة', r.status === 400, r);
    r = await call('POST', '/api/auth/register', { name: 'علي أحمد', email: 'Ali@Example.com', password: 'Pass12345', role: 'customer' });
    check('تسجيل زبون', r.status === 201 && r.data.token && r.data.user.email === 'ali@example.com' && !r.data.user.password_hash, r);
    let cust = r.data.token; const custId = r.data.user.id;
    r = await call('POST', '/api/auth/register', { name: 'آخر', email: 'ali@example.com', password: 'Pass12345' });
    check('رفض بريد مكرر', r.status === 409, r);

    console.log('— الدخول');
    r = await call('POST', '/api/auth/login', { email: 'ali@example.com', password: 'wrong-pass-1' });
    check('رفض كلمة مرور خاطئة', r.status === 401, r);
    r = await call('POST', '/api/auth/login', { email: 'ALI@example.com', password: 'Pass12345' });
    check('دخول بالبريد (غير حساس للحروف)', r.status === 200 && r.data.token, r);
    r = await call('GET', '/api/auth/me', null, cust);
    check('me', r.status === 200 && r.data.user.id === custId && !r.data.user.password_hash, r);
    r = await call('GET', '/api/auth/me');
    check('me بدون توكن = 401', r.status === 401);

    console.log('— استرجاع كلمة المرور');
    r = await call('POST', '/api/auth/forgot-password', { email: 'nobody@example.com' });
    check('بريد غير مسجل: رد عام بدون رمز', r.status === 200 && !r.data.devCode, r);
    r = await call('POST', '/api/auth/forgot-password', { email: 'not-an-email' });
    check('بريد غير صالح = 400 (رسالة بريد لا هاتف)', r.status === 400 && /بريد/.test(r.data.error) && !/هاتف/.test(r.data.error), r);
    r = await call('POST', '/api/auth/forgot-password', { email: 'ali@example.com' });
    const code = r.data.devCode;
    check('طلب رمز لبريد مسجل', r.status === 200 && /^\d{6}$/.test(code || ''), r);
    r = await call('POST', '/api/auth/reset-password', { email: 'ali@example.com', code: '000000', newPassword: 'NewPass9876' });
    check('رمز خاطئ مرفوض', r.status === 400, r);
    r = await call('POST', '/api/auth/reset-password', { email: 'ali@example.com', code, newPassword: 'short' });
    check('كلمة مرور جديدة قصيرة مرفوضة', r.status === 400, r);
    r = await call('POST', '/api/auth/reset-password', { email: 'ali@example.com', code, newPassword: 'NewPass9876' });
    check('تغيير كلمة المرور بالرمز', r.status === 200, r);
    r = await call('POST', '/api/auth/reset-password', { email: 'ali@example.com', code, newPassword: 'Another1234' });
    check('الرمز لا يُستخدم مرتين', r.status === 400, r);
    r = await call('POST', '/api/auth/login', { email: 'ali@example.com', password: 'Pass12345' });
    check('كلمة المرور القديمة لم تعد تعمل', r.status === 401);
    r = await call('GET', '/api/auth/me', null, cust);
    check('الجلسة القديمة أُلغيت بعد التغيير', r.status === 401);
    r = await call('POST', '/api/auth/login', { email: 'ali@example.com', password: 'NewPass9876' });
    check('دخول بكلمة المرور الجديدة', r.status === 200, r);
    cust = r.data.token;

    console.log('— الطلبات والعروض');
    r = await call('POST', '/api/auth/register', { name: 'فني أول', email: 'p1@example.com', password: 'Pass12345', role: 'provider' });
    const p1 = r.data.token; const p1Id = r.data.user.id;
    r = await call('POST', '/api/auth/register', { name: 'فني ثاني', email: 'p2@example.com', password: 'Pass12345', role: 'provider' });
    const p2 = r.data.token; const p2Id = r.data.user.id;
    r = await call('POST', '/api/requests', { category: 'nope', description: 'مشكلة كهرباء', area: 'الكرادة' }, cust);
    check('رفض خدمة غير معروفة', r.status === 400, r);
    r = await call('POST', '/api/requests', { category: 'electricity', description: 'انقطاع الكهرباء في غرفة النوم', area: 'الكرادة', address: 'شارع 62، بناية 5، الطابق 2' }, cust);
    check('إنشاء طلب', r.status === 201 && r.data.request.id, r);
    const reqId = r.data.request.id;
    r = await call('POST', '/api/requests', { category: 'electricity', description: 'x', area: 'الكرادة' }, p1);
    check('الفني لا ينشئ طلباً (403)', r.status === 403, r);

    r = await call('GET', '/api/providers/requests', null, p1);
    const seen = (r.data.requests || []).find((x) => x.id === reqId);
    check('الطلب يظهر للفني', r.status === 200 && !!seen, r);
    check('بدون كشف بيانات العميل (user_id/العنوان/الاسم)', seen && !('user_id' in seen) && !('address' in seen) && !('customer_name' in seen) && !JSON.stringify(seen).includes('شارع 62'), seen);
    r = await call('GET', '/api/providers/requests', null, cust);
    check('الزبون لا يصل لقائمة الفنيين (403)', r.status === 403, r);

    r = await call('POST', `/api/providers/requests/${reqId}/offer`, { price: 10, etaMinutes: 30 }, p1);
    check('رفض سعر غير صحيح', r.status === 400, r);
    r = await call('POST', `/api/providers/requests/${reqId}/offer`, { price: 25000, etaMinutes: 40 }, p1);
    check('الفني الأول يقدم عرضاً', r.status === 201, r);
    r = await call('POST', `/api/providers/requests/${reqId}/offer`, { price: 20000, etaMinutes: 25 }, p2);
    check('الفني الثاني يقدم عرضاً', r.status === 201, r);
    r = await call('POST', `/api/providers/requests/${reqId}/offer`, { price: 22000, etaMinutes: 20 }, p2);
    check('تعديل العرض لا ينشئ عرضاً ثانياً', r.status === 200, r);

    r = await call('GET', `/api/requests/${reqId}`, null, cust);
    const v = r.data.request || {};
    check('العميل يرى العرضين', r.status === 200 && v.offers && v.offers.length === 2 && v.status === 'offer', r);
    check('العروض فيها اسم الفني والسعر', v.offers && v.offers.every((o) => o.provider_name && o.price > 0));
    const offer1 = v.offers.find((o) => o.provider_id === p1Id); const offer2 = v.offers.find((o) => o.provider_id === p2Id);
    check('عرض الفني الثاني بالسعر المعدّل', offer2 && offer2.price === 22000, offer2);
    r = await call('GET', '/api/requests/mine', null, cust);
    check('قائمة طلباتي فيها عدد العروض', r.data.requests[0].offers_count === 2, r);
    r = await call('GET', `/api/requests/${reqId}`, null, p2);
    check('الفني غير المقبول لا يرى تفاصيل الطلب (404)', r.status === 404, r);

    r = await call('POST', `/api/requests/${reqId}/accept-offer`, { offerId: '00000000-0000-0000-0000-000000000000' }, cust);
    check('رفض عرض غير موجود', r.status === 400, r);
    r = await call('POST', `/api/requests/${reqId}/accept-offer`, { offerId: offer2.id }, p1);
    check('الفني لا يقبل عروضاً (403)', r.status === 403, r);
    r = await call('POST', `/api/requests/${reqId}/accept-offer`, { offerId: offer2.id }, cust);
    check('قبول العرض الصحيح', r.status === 200 && r.data.request.status === 'accepted', r);
    check('provider يصبح صاحب العرض المقبول', r.data.request.provider && r.data.request.provider.id === p2Id, r.data.request && r.data.request.provider);
    r = await call('POST', `/api/requests/${reqId}/accept-offer`, { offerId: offer1.id }, cust);
    check('لا يمكن قبول عرض ثانٍ بعد القبول (409)', r.status === 409, r);
    r = await call('POST', `/api/providers/requests/${reqId}/offer`, { price: 15000, etaMinutes: 10 }, p1);
    check('لا عروض جديدة على طلب مقبول', r.status === 404, r);

    console.log('— تنفيذ الفني');
    r = await call('GET', `/api/requests/${reqId}`, null, p1);
    check('الفني الخاسر لا يصل للطلب', r.status === 404, r);
    r = await call('POST', `/api/providers/requests/${reqId}/status`, { status: 'on_way' }, p1);
    check('الفني الخاسر لا يغير الحالة', r.status === 404, r);
    r = await call('GET', `/api/requests/${reqId}`, null, p2);
    check('الفني المقبول يرى العنوان الدقيق واسم العميل', r.status === 200 && r.data.request.address.includes('شارع 62') && r.data.request.customer_name === 'علي أحمد', r);
    r = await call('POST', `/api/providers/requests/${reqId}/status`, { status: 'completed' }, p2);
    check('لا قفز في الحالات (409)', r.status === 409 && r.data.allowed_next === 'on_way', r);
    for (const st of ['on_way', 'arrived', 'in_progress', 'completed']) {
      r = await call('POST', `/api/providers/requests/${reqId}/status`, { status: st }, p2);
      check('الحالة → ' + st, r.status === 200 && r.data.request.status === st, r);
    }
    r = await call('POST', `/api/requests/${reqId}/cancel`, {}, cust);
    check('لا إلغاء بعد الاكتمال (409)', r.status === 409, r);
    r = await call('GET', '/api/providers/jobs?filter=history', null, p2);
    check('الطلب في سجل الفني', r.data.jobs && r.data.jobs.some((j) => j.id === reqId), r);
    r = await call('GET', `/api/requests/${reqId}`, null, cust);
    check('سجل الأحداث مكتمل', r.data.request.events.length >= 6, r.data.request.events);

    console.log('— الصلاحيات والإلغاء');
    r = await call('POST', '/api/auth/register', { name: 'غريب', email: 'x@example.com', password: 'Pass12345' });
    const stranger = r.data.token;
    r = await call('GET', `/api/requests/${reqId}`, null, stranger);
    check('غريب لا يرى الطلب (404)', r.status === 404, r);
    r = await call('GET', '/api/requests/not-a-uuid', null, cust);
    check('معرّف خاطئ لا يوقف الخادم (404)', r.status === 404, r);
    r = await call('POST', '/api/requests', { category: 'plumbing', description: 'تسريب مياه من الحوض', area: 'المنصور' }, cust);
    const req2 = r.data.request.id;
    r = await call('POST', `/api/requests/${req2}/cancel`, {}, stranger);
    check('غريب لا يلغي طلب غيره (404)', r.status === 404, r);
    r = await call('POST', `/api/requests/${req2}/cancel`, {}, cust);
    check('الزبون يلغي طلبه', r.status === 200 && r.data.request.status === 'cancelled', r);

    console.log('— اشتراك الفنيين والتوثيق');
    r = await call('GET', '/api/providers/me/subscription');
    check('بدون توكن = 401', r.status === 401, r);
    r = await call('GET', '/api/providers/me/subscription', null, cust);
    check('الزبون لا يصل لمسار اشتراك الفنيين (403)', r.status === 403, r);
    r = await call('POST', '/api/auth/register', { name: 'فني ثالث', email: 'p3@example.com', password: 'Pass12345', role: 'provider' });
    const p3 = r.data.token;
    r = await call('GET', '/api/providers/me/subscription', null, p3);
    check('الاشتراك الافتراضي مجاني', r.status === 200 && r.data.subscription.plan === 'free' && r.data.plan.name === 'مجاني', r);
    r = await call('POST', '/api/providers/me/subscribe', { plan: 'غير-موجودة' }, p3);
    check('رفض باقة غير معروفة', r.status === 400, r);
    r = await call('POST', '/api/providers/me/subscribe', { plan: 'pro' }, p3);
    check('الاشتراك بباقة احترافي', r.status === 200 && r.data.subscription.plan === 'pro', r);
    r = await call('GET', '/api/providers/me/subscription', null, p3);
    check('الباقة الجديدة محفوظة بعد إعادة القراءة', r.status === 200 && r.data.subscription.plan === 'pro', r);
    r = await call('POST', '/api/providers/me/verify', {}, p3);
    check('طلب التوثيق يُقبل', r.status === 200 && r.data.subscription.verify_status === 'pending', r);

    console.log('— الحساب');
    r = await call('PUT', '/api/profile', { name: 'علي الجديد' }, cust);
    check('تعديل الاسم', r.status === 200 && r.data.user.name === 'علي الجديد', r);
    r = await call('POST', '/api/auth/change-password', { currentPassword: 'bad', newPassword: 'Brand9999new' }, cust);
    check('تغيير كلمة المرور بكلمة حالية خاطئة', r.status === 400, r);
    r = await call('POST', '/api/auth/change-password', { currentPassword: 'NewPass9876', newPassword: 'Brand9999new' }, cust);
    check('تغيير كلمة المرور', r.status === 200, r);
    r = await call('POST', '/api/auth/logout', {}, cust);
    check('تسجيل الخروج', r.status === 200, r);
    r = await call('GET', '/api/auth/me', null, cust);
    check('بعد الخروج التوكن لا يعمل', r.status === 401, r);

    console.log('— حماية');
    let hit429 = false;
    for (let i = 0; i < 12; i++) { r = await call('POST', '/api/auth/login', { email: 'p1@example.com', password: 'wrongwrong1' }); if (r.status === 429) hit429 = true; }
    check('تحديد محاولات الدخول (429)', hit429);

    console.log('— حجم الطلب (رفع الصور)');
    // أكبر من الحد القديم (64 كيلوبايت) وأصغر من الحد الجديد (3 ميغابايت): يجب أن ينجح.
    const midSize = 'a'.repeat(500 * 1024);
    r = await call('POST', '/api/auth/register', { name: 'صاحب صورة', email: 'img-ok@example.com', password: 'Pass12345', extra: midSize });
    check('طلب 500 كيلوبايت (أكبر من الحد القديم) ينجح الآن', r.status === 201, r);
    // أكبر من الحد الجديد (3 ميغابايت): يجب أن يصل رد 413 صريح، وليس انقطاع اتصال (502).
    const overSize = 'a'.repeat(4 * 1024 * 1024);
    r = await call('POST', '/api/auth/register', { name: 'صورة كبيرة', email: 'img-big@example.com', password: 'Pass12345', extra: overSize });
    check('طلب أكبر من 3 ميغابايت يُرفض بردّ 413 واضح', r.status === 413, r);
  } catch (e) {
    failed.push('استثناء: ' + e.message); console.error(e);
  } finally {
    srv.kill();
  }
  console.log(`\nالنتيجة: ${passed} نجح، ${failed.length} فشل`);
  if (failed.length) { console.log('الفاشلة:', failed.join(' | ')); process.exit(1); }
})();
