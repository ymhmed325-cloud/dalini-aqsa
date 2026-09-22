import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _editName() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NameSheet(),
    );
    if (ok == true && mounted) {
      setState(() {});
      showAqSnack(context, 'تم تحديث الاسم');
    }
  }

  Future<void> _changePassword() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _PasswordSheet(),
    );
    if (ok == true && mounted) showAqSnack(context, 'تم تغيير كلمة المرور');
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, 'تسجيل الخروج', 'هل تريد تسجيل الخروج من حسابك؟', confirmLabel: 'خروج', danger: true);
    if (!ok) return;
    await Api.post('/api/auth/logout');
    final f = Api.onSessionEnd;
    if (f != null) await f();
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.user ?? <String, dynamic>{};
    final name = s(u['name'], 'مستخدم');
    final provider = s(u['role']) == 'provider';
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        AqHeader(
          height: 250,
          radius: 34,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScaleIn(
                    child: Container(
                      width: 92,
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: <Color>[AQ.goldSoft, AQ.gold]),
                        boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.gold, 0.45), blurRadius: 24)],
                      ),
                      child: Text(name.substring(0, 1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AQ.ink)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlide(delay: const Duration(milliseconds: 200), child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
                  const SizedBox(height: 4),
                  FadeSlide(delay: const Duration(milliseconds: 300), child: Text(s(u['email']), style: const TextStyle(color: AQ.goldSoft, fontSize: 13.5))),
                  const SizedBox(height: 10),
                  FadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(color: aa(Colors.white, 0.16), borderRadius: BorderRadius.circular(20)),
                      child: Text(provider ? 'فنّي / مزوّد خدمة' : 'زبون', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
          child: Column(
            children: <Widget>[
              FadeSlide(delay: const Duration(milliseconds: 300), child: _Tile(icon: Icons.badge_outlined, title: 'تعديل الاسم', onTap: _editName)),
              FadeSlide(delay: const Duration(milliseconds: 380), child: _Tile(icon: Icons.lock_outline, title: 'تغيير كلمة المرور', onTap: _changePassword)),
              FadeSlide(delay: const Duration(milliseconds: 460), child: _Tile(icon: Icons.logout_rounded, title: 'تسجيل الخروج', danger: true, onTap: _logout)),
              const SizedBox(height: 26),
              const Text('دليني الأقصى • الإصدار 1.0', style: TextStyle(color: AQ.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? AQ.danger : AQ.teal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: onTap,
        child: AqCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: aa(c, 0.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: danger ? AQ.danger : AQ.text))),
              Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: aa(AQ.ink, 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sheetFrame(BuildContext context, String title, List<Widget> children) {
  return Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(color: AQ.sand, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: aa(AQ.ink, 0.18), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AQ.text)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet();

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController c = TextEditingController(text: s(Session.user?['name']));
  bool busy = false;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (c.text.trim().length < 2) {
      showAqSnack(context, 'اكتب اسمك (حرفان على الأقل)', error: true);
      return;
    }
    setState(() => busy = true);
    final r = await Api.call('PUT', '/api/profile', body: <String, dynamic>{'name': c.text.trim()});
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر الحفظ', error: true);
      return;
    }
    await Session.save(Session.token, asMap(r.map['user']));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return _sheetFrame(context, 'تعديل الاسم', <Widget>[
      TextField(controller: c, decoration: aqInput('الاسم الكامل', Icons.person_outline)),
      const SizedBox(height: 16),
      AqButton(label: 'حفظ', busy: busy, onPressed: save),
    ]);
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final TextEditingController cur = TextEditingController();
  final TextEditingController next = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    cur.dispose();
    next.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (cur.text.isEmpty) {
      showAqSnack(context, 'أدخل كلمة المرور الحالية', error: true);
      return;
    }
    if (next.text.length < 8) {
      showAqSnack(context, 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل', error: true);
      return;
    }
    setState(() => busy = true);
    final r = await Api.post('/api/auth/change-password', <String, dynamic>{'currentPassword': cur.text, 'newPassword': next.text});
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر تغيير كلمة المرور', error: true);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return _sheetFrame(context, 'تغيير كلمة المرور', <Widget>[
      TextField(controller: cur, obscureText: true, textDirection: TextDirection.ltr, decoration: aqInput('كلمة المرور الحالية', Icons.lock_outline)),
      const SizedBox(height: 14),
      TextField(controller: next, obscureText: true, textDirection: TextDirection.ltr, decoration: aqInput('كلمة المرور الجديدة', Icons.lock_reset)),
      const SizedBox(height: 16),
      AqButton(label: 'تغيير كلمة المرور', busy: busy, onPressed: save),
    ]);
  }
}
