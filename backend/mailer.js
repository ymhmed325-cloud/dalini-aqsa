'use strict';
// إرسال البريد عبر HTTP فقط (Resend أو Brevo) بدون مكتبات إضافية.

function gateway() {
  if (process.env.RESEND_API_KEY && process.env.EMAIL_FROM) return 'resend';
  if (process.env.BREVO_API_KEY && process.env.EMAIL_FROM) return 'brevo';
  return 'none';
}

function parseFrom(v) {
  const m = String(v).match(/^\s*(.*?)\s*<([^>]+)>\s*$/);
  return m ? { name: m[1] || 'Dalini Aqsa', email: m[2] } : { name: 'Dalini Aqsa', email: String(v).trim() };
}

async function sendEmail(to, subject, text) {
  const g = gateway();
  if (g === 'none') return { sent: false, gateway: g, reason: 'not-configured' };
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 10000);
  try {
    let res;
    if (g === 'resend') {
      res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { Authorization: 'Bearer ' + process.env.RESEND_API_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ from: process.env.EMAIL_FROM, to: [to], subject, text }),
        signal: ctrl.signal,
      });
    } else {
      res = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: { 'api-key': process.env.BREVO_API_KEY, 'Content-Type': 'application/json', accept: 'application/json' },
        body: JSON.stringify({ sender: parseFrom(process.env.EMAIL_FROM), to: [{ email: to }], subject, textContent: text }),
        signal: ctrl.signal,
      });
    }
    return res.ok ? { sent: true, gateway: g } : { sent: false, gateway: g, reason: 'http-' + res.status };
  } catch (e) {
    return { sent: false, gateway: g, reason: e && e.name === 'AbortError' ? 'timeout' : 'network' };
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { sendEmail, gateway };
