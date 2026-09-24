import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  Map<String, dynamic> sub = <String, dynamic>{};
  bool loading = true;
  bool busy = false;
  String? busyPlan;

  static const List<Map<String, dynamic>> plans = <Map<String, dynamic>>[
    {'id': 'free',    'name': 'مجاني',    'price': 0,     'features': <String>['5 طلبات شهرياً', 'ظهور عادي']},
    {'id': 'basic',   'name': 'أساسي',    'price': 15000, 'features': <String>['طلبات غير محدودة', 'شارة "نشط"', 'ظهور عادي']},
    {'id': 'pro',     'name': 'احترافي',  'price': 30000, 'features': <String>['كل مزايا الأساسي', 'ظهور أول', 'إبراز عرضين شهرياً']},
    {'id': 'vip',     'name': 'VIP',      'price': 60000, 'features': <String>['كل مزايا الاحترافي', 'بانر في الرئيسية', 'دعم أولوية']},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Api.get('/api/providers/me/subscription');
    if (!mounted) return;
    setState(() {
      loading = false;
      if (r.ok) sub = asMap(r.map['subscription']);
    });
  }

  Future<void> _subscribe(String planId) async {
    setState(() => busyPlan = planId);
    final r = await Api.post('/api/providers/me/subscribe', <String, dynamic>{'plan': planId});
    if (!mounted) return;
    setState(() => busyPlan = null);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر تفعيل الباقة', error: true);
      return;
    }
    showAqSnack(context, s(r.map['message'], 'تم تفعيل الباقة'));
    _load();
  }

  Future<void> _verify() async {
    setState(() => busy = true);
    final r = await Api.post('/api/providers/me/verify');
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر إرسال الطلب', error: true);
      return;
    }
    showAqSnack(context, s(r.map['message'], 'تم الإرسال'));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final curPlan = s(sub['plan'], 'free');
    final verified = sub['verified'] == true;
    final verifyStatus = s(sub['verify_status'], 'none');
    return Scaffold(
      backgroundColor: AQ.sand,
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const TabHeader(title: 'ترقية حسابي', subtitle: 'باقات وشارات للفنيين'),
          if (loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AQ.gold)))
          else ...<Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: AqCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Icon(verified ? Icons.verified_rounded : Icons.verified_outlined, size: 48, color: verified ? AQ.gold : AQ.muted),
                    const SizedBox(height: 10),
                    Text(verified ? 'حساب موثّق' : 'شارة "موثّق"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AQ.text)),
                    const SizedBox(height: 6),
                    const Text('الفني الموثّق يظهر بشارة ذهبية ويحصل على طلبات أكثر.', textAlign: TextAlign.center, style: TextStyle(color: AQ.muted, height: 1.5, fontSize: 13)),
                    const SizedBox(height: 16),
                    if (verified)
                      const Text('✅ أنت موثّق', style: TextStyle(color: AQ.ok, fontWeight: FontWeight.w900))
                    else if (verifyStatus == 'pending')
                      const Text('⏳ طلب التوثيق قيد المراجعة', style: TextStyle(color: AQ.gold, fontWeight: FontWeight.w900))
                    else
                      AqButton(label: 'طلب التوثيق — 15,000 د.ع', icon: Icons.verified_user, gold: true, busy: busy, onPressed: _verify),
                  ],
                ),
              ),
            ),
            const SectionTitle('الباقات'),
            ...plans.map((p) => _PlanCard(plan: p, current: p['id'] == curPlan, busy: busyPlan == p['id'], onTap: () => _subscribe(s(p['id'])))),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.current, required this.busy, required this.onTap});
  final Map<String, dynamic> plan;
  final bool current;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final features = (plan['features'] as List<dynamic>).cast<String>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AqCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(child: Text(s(plan['name']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AQ.text))),
              if (current) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: aa(AQ.ok, 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Text('حالياً', style: TextStyle(color: AQ.ok, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(plan['price'] == 0 ? 'مجاني' : '${money(plan['price'])} / شهرياً', style: const TextStyle(color: AQ.gold, fontWeight: FontWeight.w900, fontSize: 15)),
            const Divider(height: 20),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: <Widget>[
                const Icon(Icons.check_circle, color: AQ.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: const TextStyle(color: AQ.text, fontSize: 13.5))),
              ]),
            )),
            if (!current && plan['id'] != 'free') ...<Widget>[
              const SizedBox(height: 12),
              AqButton(label: 'اشترك الآن', icon: Icons.arrow_circle_up, busy: busy, onPressed: onTap),
            ],
          ],
        ),
      ),
    );
  }
}
