import 'dart:async';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'logo.dart';
import 'api.dart';
import 'widgets.dart';
import 'profile.dart';
import 'home_tab.dart';
import 'drawer_menu.dart';
import 'notifications_screen.dart';
import 'city_picker.dart';
import 'rating_screen.dart';
import 'chat_screen.dart';

// ================= الإطار الرئيسي للزبون =================
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int tab = 0;
  String _city = 'بغداد';

  Future<void> _pickCity() async {
    final c = await pickCity(context, _city);
    if (c != null && mounted) setState(() => _city = c);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> newRequest([String? service]) async {
    final done = await Navigator.of(context).push<bool>(fadeRoute<bool>(NewRequestScreen(service: service)));
    if (done == true && mounted) setState(() => tab = 1);
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = tab == 0 ? NewHomeTab(onNew: newRequest, onMenu: () => _scaffoldKey.currentState?.openDrawer(), onNotif: () => Navigator.of(context).push(fadeRoute<void>(const NotificationsScreen())), onCity: _pickCity) : (tab == 1 ? const OrdersTab() : (tab == 2 ? const _ChatsTab() : const ProfileTab()));
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(onNew: newRequest, onGo: (i) => setState(() => tab = i)),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey<int>(tab), child: page),
      ),
      bottomNavigationBar: AqNavBar(
        index: tab,
        onTap: (i) => setState(() => tab = i),
        items: const <NavItem>[
          NavItem(Icons.home_rounded, 'الرئيسية'),
          NavItem(Icons.receipt_long_rounded, 'طلباتي'),
          NavItem(Icons.chat_bubble_outline_rounded, 'المحادثات'),
          NavItem(Icons.person_rounded, 'حسابي'),
        ],
      ),
    );
  }
}

// ================= الرئيسية =================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNew});
  final Future<void> Function([String?]) onNew;

  @override
  Widget build(BuildContext context) {
    final name = s(Session.user?['name'], 'بك');
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        AqHeader(
          height: 250,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: const <Widget>[
                      DaliniLogo(size: 42),
                      SizedBox(width: 10),
                      Text('دليني', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const Spacer(),
                  FadeSlide(child: Text('أهلاً $name', style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900))),
                  const FadeSlide(
                    delay: Duration(milliseconds: 140),
                    child: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('شنو تحتاج اليوم؟ اطلب فنّياً بضغطة واحدة.', style: TextStyle(color: AQ.goldSoft, fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 46),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Transform.translate(
            offset: const Offset(0, -30),
            child: FadeSlide(
              delay: const Duration(milliseconds: 250),
              child: Pressable(
                onTap: () => onNew(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(colors: <Color>[AQ.goldSoft, AQ.gold], begin: Alignment.topRight, end: Alignment.bottomLeft),
                    boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.gold, 0.45), blurRadius: 22, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: <Widget>[
                      const Pulse(amount: 0.10, child: Icon(Icons.add_circle_rounded, color: AQ.ink, size: 40)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const <Widget>[
                            Text('أنشئ طلباً جديداً', style: TextStyle(color: AQ.ink, fontSize: 18, fontWeight: FontWeight.w900)),
                            SizedBox(height: 2),
                            Text('استلم عروضاً من عدة فنيين واختر الأنسب', style: TextStyle(color: AQ.ink, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios_new_rounded, color: AQ.ink, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SectionTitle('الخدمات'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: kServices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.18),
          itemBuilder: (context, i) => FadeSlide(
            delay: Duration(milliseconds: 250 + i * 80),
            child: _ServiceCard(service: kServices[i], onTap: () => onNew(kServices[i].id)),
          ),
        ),
        const SectionTitle('كيف يعمل دليني؟'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              Expanded(child: FadeSlide(delay: Duration(milliseconds: 500), child: _HowStep(Icons.touch_app_rounded, 'اختر الخدمة', 'صِف مشكلتك بجملة'))),
              SizedBox(width: 10),
              Expanded(child: FadeSlide(delay: Duration(milliseconds: 620), child: _HowStep(Icons.local_offer_rounded, 'استلم العروض', 'أسعار ووقت وصول'))),
              SizedBox(width: 10),
              Expanded(child: FadeSlide(delay: Duration(milliseconds: 740), child: _HowStep(Icons.verified_rounded, 'اختر الأنسب', 'وتابع الفني لحظة بلحظة'))),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});
  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.ink, 0.07), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: <Widget>[
              Positioned(left: -12, bottom: -14, child: Icon(service.icon, size: 92, color: aa(service.color, 0.09))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Hero(
                      tag: 'svc-${service.id}',
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: aa(service.color, 0.14), borderRadius: BorderRadius.circular(16)),
                        child: Icon(service.icon, color: service.color, size: 27),
                      ),
                    ),
                    Text(service.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AQ.text)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return AqCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AQ.teal, size: 30),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: AQ.text)),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AQ.muted, height: 1.4)),
        ],
      ),
    );
  }
}

// ================= طلب جديد =================
class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key, this.service});
  final String? service;

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  String? service;
  final TextEditingController desc = TextEditingController();
  final TextEditingController area = TextEditingController();
  final TextEditingController address = TextEditingController();
  bool busy = false;
  bool done = false;

  @override
  void initState() {
    super.initState();
    service = widget.service;
  }

  @override
  void dispose() {
    desc.dispose();
    area.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (service == null) {
      showAqSnack(context, 'اختر نوع الخدمة أولاً', error: true);
      return;
    }
    if (desc.text.trim().length < 4) {
      showAqSnack(context, 'اشرح المشكلة بجملة واضحة', error: true);
      return;
    }
    if (area.text.trim().length < 2) {
      showAqSnack(context, 'اكتب المنطقة، مثال: الكرادة', error: true);
      return;
    }
    setState(() => busy = true);
    final r = await Api.post('/api/requests', <String, dynamic>{
      'category': service,
      'description': desc.text.trim(),
      'area': area.text.trim(),
      'address': address.text.trim(),
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر إرسال الطلب', error: true);
      return;
    }
    setState(() => done = true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _success() {
    return Center(
      key: const ValueKey<String>('done'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ScaleIn(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: <Color>[AQ.tealLight, AQ.teal]),
                boxShadow: <BoxShadow>[BoxShadow(color: aa(AQ.teal, 0.4), blurRadius: 30)],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 80),
            ),
          ),
          const SizedBox(height: 24),
          const FadeSlide(delay: Duration(milliseconds: 300), child: Text('تم إرسال طلبك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AQ.text))),
          const SizedBox(height: 6),
          const FadeSlide(delay: Duration(milliseconds: 450), child: Text('الفنيون القريبون سيرسلون عروضهم الآن', style: TextStyle(color: AQ.muted, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _form() {
    final sel = service == null ? null : serviceOf(service!);
    return SingleChildScrollView(
      key: const ValueKey<String>('form'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: <Widget>[
          AqHeader(
            height: 180,
            radius: 28,
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
                        if (widget.service != null && sel != null)
                          Hero(
                            tag: 'svc-${widget.service}',
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(color: aa(Colors.white, 0.16), borderRadius: BorderRadius.circular(18)),
                              child: Icon(sel.icon, color: AQ.gold, size: 32),
                            ),
                          )
                        else
                          const Icon(Icons.add_task_rounded, color: AQ.gold, size: 44),
                        const SizedBox(height: 10),
                        const Text('طلب جديد', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('نوع الخدمة'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List<Widget>.generate(kServices.length, (i) {
                final sv = kServices[i];
                final on = service == sv.id;
                return FadeSlide(
                  delay: Duration(milliseconds: i * 50),
                  child: Pressable(
                    onTap: () => setState(() => service = sv.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: on ? sv.color : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: on ? sv.color : aa(AQ.teal, 0.18)),
                        boxShadow: on ? <BoxShadow>[BoxShadow(color: aa(sv.color, 0.4), blurRadius: 14, offset: const Offset(0, 5))] : <BoxShadow>[],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(sv.icon, size: 20, color: on ? Colors.white : sv.color),
                          const SizedBox(width: 7),
                          Text(sv.name, style: TextStyle(fontWeight: FontWeight.w800, color: on ? Colors.white : AQ.text)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SectionTitle('التفاصيل'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: <Widget>[
                TextField(controller: desc, minLines: 3, maxLines: 5, maxLength: 500, textInputAction: TextInputAction.newline, decoration: aqInput('اشرح المشكلة', Icons.edit_note_rounded)),
                const SizedBox(height: 6),
                TextField(controller: area, textInputAction: TextInputAction.next, decoration: aqInput('المنطقة', Icons.place_outlined, hint: 'مثال: الكرادة')),
                const SizedBox(height: 14),
                TextField(controller: address, textInputAction: TextInputAction.done, decoration: aqInput('العنوان بالتفصيل (اختياري)', Icons.home_outlined)),
                const SizedBox(height: 8),
                Row(
                  children: const <Widget>[
                    Icon(Icons.lock_outline, size: 15, color: AQ.muted),
                    SizedBox(width: 6),
                    Expanded(child: Text('العنوان التفصيلي لا يظهر إلا للفني الذي تقبل عرضه.', style: TextStyle(fontSize: 12.5, color: AQ.muted))),
                  ],
                ),
                const SizedBox(height: 22),
                AqButton(label: 'إرسال الطلب', icon: Icons.send_rounded, busy: busy, onPressed: send),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: done ? _success() : _form()),
    );
  }
}

// ================= طلباتي =================
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await Api.get('/api/requests/mine');
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
      body = const EmptyState(icon: Icons.inbox_rounded, title: 'لا توجد طلبات بعد', subtitle: 'ابدأ بطلب أول فني من الصفحة الرئيسية وستظهر عروضه هنا.');
    } else {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        child: Column(
          children: List<Widget>.generate(items.length, (i) {
            final it = items[i];
            return FadeSlide(
              delay: Duration(milliseconds: (i > 8 ? 8 : i) * 60),
              child: _OrderCard(
                item: it,
                onTap: () async {
                  await Navigator.of(context).push<void>(fadeRoute<void>(RequestDetailScreen(id: s(it['id']))));
                  if (mounted) load();
                },
              ),
            );
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
        children: <Widget>[const TabHeader(title: 'طلباتي', subtitle: 'تابع حالة طلباتك وعروض الفنيين'), body],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sv = serviceOf(s(item['category']));
    final st = s(item['status']);
    final offers = int.tryParse(s(item['offers_count'], '0')) ?? 0;
    final waiting = (st == 'matching' || st == 'offer') && offers > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Pressable(
        onTap: onTap,
        child: AqCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: aa(sv.color, 0.14), borderRadius: BorderRadius.circular(15)),
                child: Icon(sv.icon, color: sv.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(sv.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AQ.text))),
                        StatusChip(status: st),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(s(item['description']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AQ.muted, height: 1.4)),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.place_outlined, size: 15, color: AQ.muted),
                        const SizedBox(width: 3),
                        Text(s(item['area']), style: const TextStyle(fontSize: 12.5, color: AQ.muted)),
                        const SizedBox(width: 12),
                        Text(timeAgo(item['created_at']), style: const TextStyle(fontSize: 12.5, color: AQ.muted)),
                        const Spacer(),
                        if (waiting)
                          Pulse(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AQ.gold, borderRadius: BorderRadius.circular(14)),
                              child: Text('$offers ${offers == 1 ? 'عرض' : 'عروض'}', style: const TextStyle(color: AQ.ink, fontWeight: FontWeight.w900, fontSize: 12.5)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= تفاصيل الطلب والعروض =================
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;
  bool acting = false;
  String? busyOffer;
  Timer? _timer;

  static const List<String> _steps = <String>['matching', 'accepted', 'on_way', 'arrived', 'in_progress', 'completed'];
  static const List<String> _labels = <String>['بحث', 'قبول', 'بالطريق', 'وصل', 'تنفيذ', 'اكتمل'];

  @override
  void initState() {
    super.initState();
    load();
    _timer = Timer.periodic(const Duration(seconds: 10), (t) => load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> load({bool silent = false}) async {
    final r = await Api.get('/api/requests/${widget.id}');
    if (!mounted) return;
    setState(() {
      loading = false;
      if (r.ok) {
        error = null;
        data = asMap(r.map['request']);
      } else if (!silent || data == null) {
        error = r.error;
      }
    });
  }

  int _stage(String st) {
    if (st == 'offer' || st == 'matching') return 0;
    final i = _steps.indexOf(st);
    return i < 0 ? 0 : i;
  }

  Future<void> accept(Map<String, dynamic> o) async {
    final ok = await confirmDialog(context, 'قبول العرض', 'هل تقبل عرض ${s(o['provider_name'])} بسعر ${money(o['price'])}؟', confirmLabel: 'قبول العرض');
    if (!ok || !mounted) return;
    setState(() => busyOffer = s(o['id']));
    final r = await Api.post('/api/requests/${widget.id}/accept-offer', <String, dynamic>{'offerId': o['id']});
    if (!mounted) return;
    setState(() => busyOffer = null);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر قبول العرض', error: true);
      load(silent: true);
      return;
    }
    showAqSnack(context, 'تم قبول العرض، الفني في الطريق إليك قريباً');
    setState(() => data = asMap(r.map['request']));
  }

  Future<void> cancel() async {
    final ok = await confirmDialog(context, 'إلغاء الطلب', 'هل تريد إلغاء هذا الطلب؟', confirmLabel: 'إلغاء الطلب', danger: true);
    if (!ok || !mounted) return;
    setState(() => acting = true);
    final r = await Api.post('/api/requests/${widget.id}/cancel');
    if (!mounted) return;
    setState(() => acting = false);
    if (!r.ok) {
      showAqSnack(context, r.error ?? 'تعذر الإلغاء', error: true);
      return;
    }
    setState(() => data = asMap(r.map['request']));
  }

  Widget _stageBar(int stage) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final seg = i ~/ 2;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 500), height: 3, color: seg < stage ? AQ.teal : aa(AQ.teal, 0.15)),
                ),
              );
            }
            final idx = i ~/ 2;
            final on = idx <= stage;
            return SizedBox(
              width: 42,
              child: Column(
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: on ? AQ.teal : Colors.white, border: Border.all(color: on ? AQ.teal : aa(AQ.teal, 0.28), width: 2)),
                    child: on ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 5),
                  Text(_labels[idx], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: on ? FontWeight.w900 : FontWeight.w500, color: on ? AQ.teal : AQ.muted)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _offerCard(Map<String, dynamic> o, int i) {
    final name = s(o['provider_name'], 'فني');
    final busy = busyOffer == s(o['id']);
    return FadeSlide(
      delay: Duration(milliseconds: i * 90),
      offset: const Offset(0.12, 0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AqCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(radius: 24, backgroundColor: aa(AQ.gold, 0.22), child: Text(name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w900, color: AQ.ink, fontSize: 19))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(children: <Widget>[
                          Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AQ.text))),
                          if (asMap(o['rating']).isNotEmpty && (asMap(o['rating'])['count'] as num? ?? 0) >= 5) ...<Widget>[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AQ.gold, size: 16),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Row(children: <Widget>[
                          const Icon(Icons.schedule_rounded, size: 15, color: AQ.muted),
                          const SizedBox(width: 4),
                          Text('يصل خلال ${s(o['eta_minutes'])} دقيقة', style: const TextStyle(fontSize: 12.5, color: AQ.muted)),
                        ]),
                        if (asMap(o['rating']).isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(children: <Widget>[
                            const Icon(Icons.star_rounded, size: 15, color: AQ.gold),
                            const SizedBox(width: 4),
                            Text('${(asMap(o['rating'])['avg'] as num).toStringAsFixed(1)} (${asMap(o['rating'])['count']})', style: const TextStyle(fontSize: 12.5, color: AQ.gold, fontWeight: FontWeight.w800)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Text(money(o['price']), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AQ.teal)),
                ],
              ),
              const SizedBox(height: 14),
              AqButton(label: 'قبول هذا العرض', icon: Icons.check_circle_outline, busy: busy, onPressed: busyOffer != null ? null : () => accept(o)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AQ.teal)));
    }
    if (data == null) {
      return Scaffold(
        body: Column(children: <Widget>[
          Align(alignment: AlignmentDirectional.centerStart, child: SafeArea(child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward_rounded)))),
          EmptyState(icon: Icons.error_outline, title: 'تعذر فتح الطلب', subtitle: error ?? 'حاول مرة أخرى'),
        ]),
      );
    }
    final d = data!;
    final st = s(d['status']);
    final sv = serviceOf(s(d['category']));
    final offers = asList(d['offers']);
    final provider = asMap(d['provider']);
    final events = asList(d['events']);
    final cancelled = st == 'cancelled';
    final open = st == 'matching' || st == 'offer';
    final canCancel = const <String>['matching', 'offer', 'accepted', 'on_way', 'arrived'].contains(st);

    return Scaffold(
      body: RefreshIndicator(
        color: AQ.teal,
        onRefresh: load,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            AqHeader(
              height: 200,
              radius: 28,
              child: SafeArea(
                child: Stack(
                  children: <Widget>[
                    Align(alignment: AlignmentDirectional.topStart, child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white))),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(color: aa(Colors.white, 0.16), borderRadius: BorderRadius.circular(18)),
                            child: Icon(sv.icon, color: AQ.gold, size: 32),
                          ),
                          const SizedBox(height: 8),
                          Text('طلب ${sv.name}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          StatusChip(status: st),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (cancelled)
                    AqCard(
                      color: aa(AQ.danger, 0.08),
                      child: Row(children: const <Widget>[
                        Icon(Icons.cancel_outlined, color: AQ.danger),
                        SizedBox(width: 10),
                        Expanded(child: Text('تم إلغاء هذا الطلب', style: TextStyle(color: AQ.danger, fontWeight: FontWeight.w900))),
                      ]),
                    )
                  else
                    AqCard(padding: const EdgeInsets.fromLTRB(10, 18, 10, 14), child: _stageBar(_stage(st))),
                  const SizedBox(height: 16),
                  if (open) ...<Widget>[
                    Text(offers.isEmpty ? 'العروض' : 'العروض المقدمة (${offers.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AQ.text)),
                    const SizedBox(height: 12),
                    if (offers.isEmpty)
                      AqCard(
                        child: Column(children: const <Widget>[
                          Pulse(child: Icon(Icons.hourglass_top_rounded, color: AQ.gold, size: 40)),
                          SizedBox(height: 10),
                          Text('بانتظار عروض الفنيين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AQ.text)),
                          SizedBox(height: 4),
                          Text('ستظهر العروض هنا فور وصولها، والصفحة تتحدث تلقائياً.', textAlign: TextAlign.center, style: TextStyle(color: AQ.muted, height: 1.5)),
                        ]),
                      )
                    else
                      ...List<Widget>.generate(offers.length, (i) => _offerCard(offers[i], i)),
                    const SizedBox(height: 4),
                  ],
                  if (provider.isNotEmpty && !cancelled) ...<Widget>[
                    AqCard(
                      child: Row(children: <Widget>[
                        CircleAvatar(radius: 26, backgroundColor: aa(AQ.teal, 0.14), child: const Icon(Icons.engineering_rounded, color: AQ.teal)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                            const Text('فنّيك', style: TextStyle(color: AQ.muted, fontSize: 12.5)),
                            Text(s(provider['name']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AQ.text)),
                          ]),
                        ),
                        StatusChip(status: st),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    AqButton(
                      label: 'محادثة الفني',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => Navigator.of(context).push(fadeRoute<void>(
                        ChatScreen(requestId: widget.id, otherName: s(provider['name'], 'الفني')),
                      )),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AqCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      const Text('تفاصيل الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AQ.text)),
                      const SizedBox(height: 10),
                      Text(s(d['description']), style: const TextStyle(height: 1.6, color: AQ.text)),
                      const Divider(height: 26),
                      Row(children: <Widget>[const Icon(Icons.place_outlined, size: 18, color: AQ.teal), const SizedBox(width: 6), Text(s(d['area']))]),
                      if (s(d['address']).isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Icon(Icons.home_outlined, size: 18, color: AQ.teal), const SizedBox(width: 6), Expanded(child: Text(s(d['address'])))]),
                      ],
                    ]),
                  ),
                  if (events.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    AqCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        const Text('سجل الطلب', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AQ.text)),
                        const SizedBox(height: 10),
                        ...events.reversed.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(children: <Widget>[
                                Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor(s(e['status'])))),
                                const SizedBox(width: 10),
                                Expanded(child: Text(s(e['note']).isNotEmpty ? s(e['note']) : (kStatusAr[s(e['status'])] ?? ''), style: const TextStyle(color: AQ.text))),
                                Text(timeAgo(e['created_at']), style: const TextStyle(fontSize: 12, color: AQ.muted)),
                              ]),
                            )),
                      ]),
                    ),
                  ],
                  if (canCancel) ...<Widget>[
                    const SizedBox(height: 20),
                    AqButton(label: 'إلغاء الطلب', icon: Icons.close_rounded, danger: true, busy: acting, onPressed: cancel),
                  ],
                  if (st == 'completed' && asMap(d['my_rating']).isEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    AqButton(
                      label: 'قيّم الفني',
                      icon: Icons.star_rounded,
                      gold: true,
                      onPressed: () async {
                        final pname = s(provider['name'], 'الفني');
                        final ok = await Navigator.of(context).push<bool>(
                          fadeRoute<bool>(RatingScreen(requestId: widget.id, providerName: pname)),
                        );
                        if (ok == true) load();
                      },
                    ),
                  ],
                  if (st == 'completed' && asMap(d['my_rating']).isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    AqCard(
                      child: Row(children: <Widget>[
                        const Icon(Icons.star_rounded, color: AQ.gold, size: 30),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          const Text('تقييمك', style: TextStyle(fontWeight: FontWeight.w900, color: AQ.text)),
                          const SizedBox(height: 4),
                          Text('${asMap(d['my_rating'])['stars']} من 5', style: const TextStyle(color: AQ.muted, fontSize: 13)),
                        ])),
                        Text('⭐', style: TextStyle(fontSize: 20 + (asMap(d['my_rating'])['stars'] as int? ?? 0) * 2.0)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// تبويب المحادثات (مؤقت — قائمة فارغة)
// ═══════════════════════════════════════════════════════════
class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const <Widget>[
        TabHeader(title: 'المحادثات', subtitle: 'تواصلك مع الفنيين'),
        EmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'لا توجد محادثات بعد',
          subtitle: 'بعد قبول عرض فني، تُفتح محادثة تلقائياً هنا.',
        ),
      ],
    );
  }
}
