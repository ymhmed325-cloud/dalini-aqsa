import 'package:flutter/material.dart';
import 'theme.dart';
import 'api.dart';
import 'widgets.dart';
import 'profile.dart';

// ================= إطار الفني =================
class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final Widget page = tab == 0 ? const AvailableTab() : (tab == 1 ? const JobsTab() : const ProfileTab());
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey<int>(tab), child: page),
      ),
      bottomNavigationBar: AqNavBar(
        index: tab,
        onTap: (i) => setState(() => tab = i),
        items: const <NavItem>[
          NavItem(Icons.travel_explore_rounded, 'طلبات متاحة'),
          NavItem(Icons.assignment_turned_in_rounded, 'مهامي'),
          NavItem(Icons.person_rounded, 'حسابي'),
        ],
      ),
    );
  }
}

// ================= الطلبات المتاحة =================
class AvailableTab extends StatefulWidget {
  const AvailableTab({super.key});

  @override
  State<AvailableTab> createState() => _AvailableTabState();
}

class _AvailableTabState extends State<AvailableTab> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Api.get('/api/providers/requests');
    if (!mounted) return;
    setState(() {
      loading = false;
      if (r.ok) {
        error = null;
        items = asList(r.map['requests']);
      } else {
        error = r.error;
      }
    });
  }

  Future<void> offer(Map<String, dynamic> req) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OfferSheet(request: req),
    );
    if (ok == true && mounted) {
      showAqSnack(context, 'تم إرسال عرضك للزبون');
      load();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const SkeletonList();
    } else if (error != null && items.isEmpty) {
      body = Column(children: <Widget>[
        EmptyState(icon: Icons.wifi_off_rounded, title: 'تعذر تحميل الطلبات', subtitle: error!),
        AqButton(label: 'إعادة المحاولة', onPressed: () {
          setState(() => loading = true);
          load();
        }),
      ]);
    } else if (items.isEmpty) {
      body = const EmptyState(icon: Icons.search_rounded, title: 'لا توجد طلبات الآن', subtitle: 'اسحب للأسفل للتحديث. ستظهر هنا طلبات الزبائن فور وصولها.');
    } else {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        child: Column(
          children: List<Widget>.generate(items.length, (i) {
            final it = items[i];
            return FadeSlide(delay: Duration(milliseconds: (i > 8 ? 8 : i) * 60), child: _AvailableCard(item: it, onOffer: () => offer(it)));
          }),
        ),
      );
    }
    return RefreshIndicator(
      color: AQ.teal,
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[const TabHeader(title: 'طلبات متاحة', subtitle: 'قدّم عرضك بالسعر ووقت الوصول'), body],
      ),
    );
  }
}

class _AvailableCard extends StatelessWidget {
  const _AvailableCard({required this.item, required this.onOffer});
  final Map<String, dynamic> item;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final sv = serviceOf(s(item['category']));
    final mine = asMap(item['my_offer']);
    final has = mine.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AqCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: aa(sv.color, 0.14), borderRadius: BorderRadius.circular(14)),
                  child: Icon(sv.icon, color: sv.color, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(sv.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AQ.text))),
                Text(timeAgo(item['created_at']), style: const TextStyle(fontSize: 12.5, color: AQ.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Text(s(item['description']), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AQ.text, height: 1.5)),
            const SizedBox(height: 10),
            Row(children: <Widget>[
              const Icon(Icons.place_outlined, size: 16, color: AQ.teal),
              const SizedBox(width: 4),
              Text(s(item['area']), style: const TextStyle(color: AQ.muted, fontSize: 13)),
            ]),
            if (has) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: aa(AQ.gold, 0.18), borderRadius: BorderRadius.circular(12)),
                child: Text('عرضك: ${money(mine['price'])} • ${s(mine['eta_minutes'])} دقيقة', style: const TextStyle(fontWeight: FontWeight.w800, color: AQ.ink, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 14),
            AqButton(label: has ? 'تعديل عرضي' : 'قدّم عرضك', icon: Icons.local_offer_rounded, gold: !has, onPressed: onOffer),
          ],
        ),
      ),
    );
  }
}

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.request});
  final Map<String, dynamic> request;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  late final TextEditingController price = TextEditingController(text: s(asMap(widget.request['my_offer'])['price']));
  int eta = 30;
  bool busy = false;
  static const List<int> _etas = <int>[15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final e = int.tryParse(s(asMap(widget.request['my_offer'])['eta_minutes']));
    if (e != null) eta = e;
  }

  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final p = int.tryParse(price.text.replaceAll(',', '').trim());
    if (p == null || p < 1000) {
      showAqSnack(context, 'أدخل السعر بالدينار (1,000 على الأقل)', error: true);
      return;
    }
    setState(() => busy = true);
    final r = await Api.post('/api/providers/requests/${widget.request['id']}/offer', <String, dynamic>{'price': p, 'etaMinutes': eta});
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر إرسال العرض', error: true);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final sv = serviceOf(s(widget.request['category']));
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
              Text('عرضك على طلب ${sv.name}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AQ.text)),
              const SizedBox(height: 16),
              TextField(controller: price, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: aqInput('السعر (دينار عراقي)', Icons.payments_outlined, hint: '25000')),
              const SizedBox(height: 16),
              const Text('وقت الوصول (بالدقائق)', style: TextStyle(fontWeight: FontWeight.w800, color: AQ.text)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _etas.map((m) {
                  final on = eta == m;
                  return Pressable(
                    onTap: () => setState(() => eta = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: on ? AQ.teal : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: on ? AQ.teal : aa(AQ.teal, 0.2))),
                      child: Text('$m', style: TextStyle(fontWeight: FontWeight.w900, color: on ? Colors.white : AQ.text)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              AqButton(label: 'إرسال العرض', icon: Icons.send_rounded, busy: busy, onPressed: send),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= مهامي =================
class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  bool loading = true;
  bool history = false;
  String? error;
  String? busyId;
  List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Api.get('/api/providers/jobs?filter=${history ? 'history' : 'active'}');
    if (!mounted) return;
    setState(() {
      loading = false;
      if (r.ok) {
        error = null;
        items = asList(r.map['jobs']);
      } else {
        error = r.error;
      }
    });
  }

  Future<void> advance(Map<String, dynamic> job) async {
    final next = s(job['allowed_next']);
    if (next.isEmpty) return;
    if (next == 'completed') {
      final ok = await confirmDialog(context, 'إتمام العمل', 'هل انتهيت من تنفيذ العمل فعلاً؟', confirmLabel: 'نعم، تم');
      if (!ok || !mounted) return;
    }
    setState(() => busyId = s(job['id']));
    final r = await Api.post('/api/providers/requests/${job['id']}/status', <String, dynamic>{'status': next});
    if (!mounted) return;
    setState(() => busyId = null);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر تحديث الحالة', error: true);
    }
    load();
  }

  Widget _toggle() {
    Widget btn(String label, bool on, VoidCallback tap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: on ? AQ.teal : AQ.muted))),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: aa(AQ.teal, 0.10), borderRadius: BorderRadius.circular(16)),
      child: Row(children: <Widget>[
        btn('نشطة', !history, () {
          if (history) {
            setState(() {
              history = false;
              loading = true;
            });
            load();
          }
        }),
        btn('السجل', history, () {
          if (!history) {
            setState(() {
              history = true;
              loading = true;
            });
            load();
          }
        }),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const SkeletonList(count: 3);
    } else if (error != null && items.isEmpty) {
      body = EmptyState(icon: Icons.wifi_off_rounded, title: 'تعذر تحميل المهام', subtitle: error!);
    } else if (items.isEmpty) {
      body = EmptyState(
        icon: Icons.assignment_outlined,
        title: history ? 'السجل فارغ' : 'لا توجد مهام نشطة',
        subtitle: history ? 'ستظهر هنا الأعمال المكتملة.' : 'عندما يقبل زبون عرضك ستظهر مهمتك هنا مع العنوان الكامل.',
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          children: List<Widget>.generate(items.length, (i) {
            final j = items[i];
            return FadeSlide(delay: Duration(milliseconds: (i > 8 ? 8 : i) * 60), child: _JobCard(job: j, busy: busyId == s(j['id']), onAdvance: () => advance(j)));
          }),
        ),
      );
    }
    return RefreshIndicator(
      color: AQ.teal,
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[const TabHeader(title: 'مهامي', subtitle: 'الأعمال التي قبل الزبائن عروضك عليها'), _toggle(), body],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.busy, required this.onAdvance});
  final Map<String, dynamic> job;
  final bool busy;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final sv = serviceOf(s(job['category']));
    final st = s(job['status']);
    final next = s(job['allowed_next']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AqCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(children: <Widget>[
              Container(width: 46, height: 46, decoration: BoxDecoration(color: aa(sv.color, 0.14), borderRadius: BorderRadius.circular(14)), child: Icon(sv.icon, color: sv.color, size: 25)),
              const SizedBox(width: 12),
              Expanded(child: Text(sv.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AQ.text))),
              StatusChip(status: st),
            ]),
            const SizedBox(height: 10),
            Text(s(job['description']), style: const TextStyle(color: AQ.text, height: 1.5)),
            const Divider(height: 24),
            Row(children: <Widget>[const Icon(Icons.person_outline, size: 17, color: AQ.teal), const SizedBox(width: 6), Text(s(job['customer_name'], 'الزبون'), style: const TextStyle(fontWeight: FontWeight.w700))]),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Icon(Icons.place_outlined, size: 17, color: AQ.teal),
              const SizedBox(width: 6),
              Expanded(child: Text(s(job['address']).isNotEmpty ? '${s(job['area'])} - ${s(job['address'])}' : s(job['area']), style: const TextStyle(height: 1.4))),
            ]),
            if (next.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              AqButton(label: kActionAr[next] ?? 'التالي', icon: Icons.arrow_circle_left_outlined, busy: busy, onPressed: onAdvance),
            ],
          ],
        ),
      ),
    );
  }
}
