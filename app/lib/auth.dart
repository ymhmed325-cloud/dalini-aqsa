import 'dart:async';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'logo.dart';
import 'api.dart';
import 'widgets.dart';
import 'customer.dart';
import 'provider.dart';

final RegExp _emailRx = RegExp(r'^[^\s@]{1,64}@[^\s@]{1,255}\.[^\s@]{2,}$');

Widget homeFor(Map<String, dynamic> user) {
  return s(user['role']) == 'provider' ? const ProviderShell() : const CustomerShell();
}

// ================= تسجيل الدخول / حساب جديد =================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController name = TextEditingController();
  bool register = false;
  bool busy = false;
  bool hide = true;
  String role = 'customer';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final e = email.text.trim().toLowerCase();
    if (!_emailRx.hasMatch(e)) {
      showAqSnack(context, 'أدخل بريداً إلكترونياً صحيحاً مثل name@example.com', error: true);
      return;
    }
    if (password.text.length < 8) {
      showAqSnack(context, 'كلمة المرور يجب أن تكون 8 أحرف على الأقل', error: true);
      return;
    }
    if (register && name.text.trim().length < 2) {
      showAqSnack(context, 'اكتب اسمك الكامل', error: true);
      return;
    }
    setState(() => busy = true);
    final body = <String, dynamic>{'email': e, 'password': password.text};
    if (register) {
      body['name'] = name.text.trim();
      body['role'] = role;
    }
    final r = await Api.call('POST', register ? '/api/auth/register' : '/api/auth/login', body: body, auth: false);
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر إتمام العملية', error: true);
      return;
    }
    final user = asMap(r.map['user']);
    await Session.save(s(r.map['token']), user);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(fadeRoute<void>(homeFor(user)), (route) => false);
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: active ? AQ.teal : AQ.muted),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AQ.sand, borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: <Widget>[
          AnimatedAlign(
            alignment: register ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.ink, 0.10), blurRadius: 8, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(child: _tabBtn('تسجيل الدخول', !register, () => setState(() => register = false))),
              Expanded(child: _tabBtn('حساب جديد', register, () => setState(() => register = true))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: <Widget>[
            AqHeader(
              height: 270,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      ScaleIn(child: DaliniLogo(size: 86)),
                      SizedBox(height: 14),
                      FadeSlide(
                        delay: Duration(milliseconds: 250),
                        child: Text('دليني الأقصى', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                      ),
                      SizedBox(height: 4),
                      FadeSlide(
                        delay: Duration(milliseconds: 400),
                        child: Text('فنيّك الموثوق بلمسة واحدة', style: TextStyle(color: AQ.goldSoft, fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -38),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeSlide(
                  delay: const Duration(milliseconds: 300),
                  child: AqCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _tabs(),
                        const SizedBox(height: 20),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: register ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: const SizedBox(width: double.infinity),
                          secondChild: Column(
                            children: <Widget>[
                              TextField(controller: name, textInputAction: TextInputAction.next, decoration: aqInput('الاسم الكامل', Icons.person_outline)),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          textDirection: TextDirection.ltr,
                          decoration: aqInput('البريد الإلكتروني', Icons.mail_outline, hint: 'name@example.com'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: password,
                          obscureText: hide,
                          textDirection: TextDirection.ltr,
                          onSubmitted: (_) => submit(),
                          decoration: aqInput(
                            'كلمة المرور',
                            Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () => setState(() => hide = !hide),
                              icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AQ.muted),
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: register ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(fadeRoute<void>(ForgotScreen(initialEmail: email.text.trim()))),
                              child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: AQ.teal, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _RoleCard(
                                    selected: role == 'customer',
                                    icon: Icons.home_work_outlined,
                                    title: 'أحتاج فنياً',
                                    subtitle: 'زبون',
                                    onTap: () => setState(() => role = 'customer'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _RoleCard(
                                    selected: role == 'provider',
                                    icon: Icons.handyman_outlined,
                                    title: 'أنا فنّي',
                                    subtitle: 'مزوّد خدمة',
                                    onTap: () => setState(() => role = 'provider'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AqButton(label: register ? 'إنشاء الحساب' : 'دخول', busy: busy, onPressed: submit),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.selected, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? aa(AQ.teal, 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AQ.teal : aa(AQ.teal, 0.18), width: selected ? 2 : 1),
        ),
        child: Column(
          children: <Widget>[
            AnimatedScale(scale: selected ? 1.18 : 1.0, duration: const Duration(milliseconds: 250), child: Icon(icon, color: selected ? AQ.teal : AQ.muted, size: 30)),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: selected ? AQ.teal : AQ.text)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AQ.muted)),
          ],
        ),
      ),
    );
  }
}

// ================= استرجاع كلمة المرور =================
class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  late final TextEditingController email = TextEditingController(text: widget.initialEmail);
  final TextEditingController code = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController pass2 = TextEditingController();
  int step = 0; // 0 بريد، 1 رمز وكلمة مرور، 2 نجاح
  bool busy = false;
  bool hide = true;
  int cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    email.dispose();
    code.dispose();
    pass.dispose();
    pass2.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => cooldown -= 1);
      if (cooldown <= 0) t.cancel();
    });
  }

  Future<void> sendCode() async {
    final e = email.text.trim().toLowerCase();
    if (!_emailRx.hasMatch(e)) {
      showAqSnack(context, 'أدخل بريداً إلكترونياً صحيحاً مثل name@example.com', error: true);
      return;
    }
    setState(() => busy = true);
    final r = await Api.call('POST', '/api/auth/forgot-password', body: <String, dynamic>{'email': e}, auth: false);
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر الإرسال', error: true);
      return;
    }
    setState(() => step = 1);
    _startCooldown();
    final dev = r.map['devCode'];
    showAqSnack(context, dev != null ? 'رمز التجربة: $dev' : s(r.map['message'], 'تم إرسال الرمز إلى بريدك'));
  }

  Future<void> reset() async {
    if (!RegExp(r'^\d{6}$').hasMatch(code.text.trim())) {
      showAqSnack(context, 'رمز التحقق مكوّن من 6 أرقام', error: true);
      return;
    }
    if (pass.text.length < 8) {
      showAqSnack(context, 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل', error: true);
      return;
    }
    if (pass.text != pass2.text) {
      showAqSnack(context, 'كلمتا المرور غير متطابقتين', error: true);
      return;
    }
    setState(() => busy = true);
    final r = await Api.call('POST', '/api/auth/reset-password',
        body: <String, dynamic>{'email': email.text.trim().toLowerCase(), 'code': code.text.trim(), 'newPassword': pass.text}, auth: false);
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر تغيير كلمة المرور', error: true);
      return;
    }
    setState(() => step = 2);
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(2, (i) {
        final on = i <= step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == step ? 26 : 9,
          height: 9,
          decoration: BoxDecoration(color: on ? AQ.gold : aa(Colors.white, 0.35), borderRadius: BorderRadius.circular(6)),
        );
      }),
    );
  }

  Widget _stepEmail() {
    return Column(
      key: const ValueKey<int>(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('أدخل بريدك الإلكتروني وسنرسل لك رمز تحقق من 6 أرقام.', style: TextStyle(color: AQ.muted, height: 1.6)),
        const SizedBox(height: 16),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textDirection: TextDirection.ltr,
          onSubmitted: (_) => sendCode(),
          decoration: aqInput('البريد الإلكتروني', Icons.mail_outline, hint: 'name@example.com'),
        ),
        const SizedBox(height: 18),
        AqButton(label: 'إرسال الرمز', icon: Icons.send_rounded, busy: busy, onPressed: sendCode),
      ],
    );
  }

  Widget _stepReset() {
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('أرسلنا الرمز إلى ${email.text.trim()}', style: const TextStyle(color: AQ.muted, height: 1.6)),
        const SizedBox(height: 16),
        TextField(
          controller: code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textDirection: TextDirection.ltr,
          decoration: aqInput('رمز التحقق', Icons.pin_outlined).copyWith(counterText: ''),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: pass,
          obscureText: hide,
          textDirection: TextDirection.ltr,
          decoration: aqInput('كلمة المرور الجديدة', Icons.lock_outline,
              suffix: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AQ.muted))),
        ),
        const SizedBox(height: 14),
        TextField(controller: pass2, obscureText: hide, textDirection: TextDirection.ltr, decoration: aqInput('تأكيد كلمة المرور', Icons.lock_reset)),
        const SizedBox(height: 18),
        AqButton(label: 'تغيير كلمة المرور', icon: Icons.check_circle_outline, busy: busy, onPressed: reset),
        const SizedBox(height: 6),
        TextButton(
          onPressed: cooldown > 0 || busy ? null : sendCode,
          child: Text(cooldown > 0 ? 'إعادة الإرسال بعد $cooldown ثانية' : 'لم يصلك الرمز؟ أعد الإرسال', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _stepDone() {
    return Column(
      key: const ValueKey<int>(2),
      children: <Widget>[
        const SizedBox(height: 10),
        ScaleIn(
          child: Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: <Color>[AQ.tealLight, AQ.teal])),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
          ),
        ),
        const SizedBox(height: 20),
        const Text('تم تغيير كلمة المرور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AQ.text)),
        const SizedBox(height: 6),
        const Text('سجّل الدخول الآن بكلمة المرور الجديدة.', style: TextStyle(color: AQ.muted)),
        const SizedBox(height: 22),
        AqButton(label: 'العودة لتسجيل الدخول', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: <Widget>[
            AqHeader(
              height: 210,
              child: SafeArea(
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white)),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const ScaleIn(child: Icon(Icons.lock_reset_rounded, color: AQ.gold, size: 58)),
                          const SizedBox(height: 8),
                          const Text('استرجاع كلمة المرور', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          _dots(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AqCard(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim), child: child),
                    ),
                    child: step == 0 ? _stepEmail() : (step == 1 ? _stepReset() : _stepDone()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
