import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';

const String kZainCashNumber = '07773845222';
const String kSuperQiNumber = '2507372551';
const String kWhatsAppNumber = '9647773845222';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.planName, required this.planPrice});
  final String planName;
  final int planPrice;
  @override
  State<PaymentScreen> createState() => _S();
}

class _S extends State<PaymentScreen> {
  bool busy = false;
  Future<void> _copy(String t) async {
    await Clipboard.setData(ClipboardData(text: t));
    if (mounted) showAqSnack(context, 'تم النسخ');
  }
  Future<void> _send() async {
    setState(() => busy = true);
    final n = s(Session.user?['name'], 'فني');
    final e = s(Session.user?['email']);
    final m = 'أريد تفعيل اشتراك دليني:\n• $n\n• $e\n• ${widget.planName}\n• ${money(widget.planPrice)}';
    final u = Uri.parse('https://wa.me/$kWhatsAppNumber?text=${Uri.encodeComponent(m)}');
    try {
      if (await canLaunchUrl(u)) {
        await launchUrl(u, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    if (mounted) setState(() => busy = false);
  }
  Widget _card(IconData i, String t, String n, Color c) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: AqCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Row(children: <Widget>[
        Container(width: 46, height: 46, decoration: BoxDecoration(color: aa(c, 0.14), borderRadius: BorderRadius.circular(14)), child: Icon(i, color: c, size: 24)),
        const SizedBox(width: 12),
        Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AQ.text)),
      ]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), decoration: BoxDecoration(color: AQ.sand, borderRadius: BorderRadius.circular(12)), child: Row(children: <Widget>[
        Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Text(n, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AQ.text)))),
        IconButton(onPressed: () => _copy(n), icon: const Icon(Icons.copy_rounded, color: AQ.teal)),
      ])),
    ])));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AQ.sand, body: ListView(padding: EdgeInsets.zero, children: <Widget>[
      TabHeader(title: 'إتمام الدفع', subtitle: widget.planName),
      Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        AqCard(padding: const EdgeInsets.all(20), child: Column(children: <Widget>[
          Text(widget.planName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AQ.text)),
          const SizedBox(height: 6),
          Text(money(widget.planPrice), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AQ.gold)),
        ])),
        const SizedBox(height: 16),
        _card(Icons.account_balance_wallet_rounded, 'زين كاش', kZainCashNumber, const Color(0xFFE74C3C)),
        _card(Icons.account_balance_rounded, 'سوبر كي', kSuperQiNumber, const Color(0xFF2E7DD1)),
        const SizedBox(height: 8),
        AqButton(label: 'أرسلت المبلغ — افتح واتساب', icon: Icons.send_rounded, gold: true, busy: busy, onPressed: _send),
      ])),
    ]));
  }
}
