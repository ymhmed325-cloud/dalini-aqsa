import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.onNew, required this.onGo});
  final Future<void> Function([String?]) onNew;
  final void Function(int) onGo;

  @override
  Widget build(BuildContext context) {
    final name = s(Session.user?['name'], 'مستخدم');
    final email = s(Session.user?['email']);
    return Drawer(
      backgroundColor: AQ.sand,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AQ.navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AQ.gold,
                    child: Text(name.substring(0, 1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AQ.navy)),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  Text(email, style: const TextStyle(color: AQ.goldSoft, fontSize: 12)),
                ],
              ),
            ),
            _Item(Icons.home_rounded, 'الرئيسية', () { Navigator.pop(context); onGo(0); }),
            _Item(Icons.receipt_long_rounded, 'طلباتي', () { Navigator.pop(context); onGo(1); }),
            _Item(Icons.chat_bubble_outline_rounded, 'المحادثات', () { Navigator.pop(context); onGo(2); }),
            _Item(Icons.person_rounded, 'حسابي', () { Navigator.pop(context); onGo(3); }),
            const Divider(),
            _Item(Icons.add_circle_outline, 'طلب جديد', () { Navigator.pop(context); onNew(); }),
            _Item(Icons.help_outline, 'كيف يعمل دليني؟', () { Navigator.pop(context); }),
            const Spacer(),
            Padding(padding: const EdgeInsets.all(16), child: Text('دليني • v1.0', style: TextStyle(color: AQ.muted, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AQ.navy),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AQ.text)),
        onTap: onTap,
      );
}
